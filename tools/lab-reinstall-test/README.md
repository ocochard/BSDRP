# lab-reinstall-test — remote reinstall via RAM-boot + external dd

Recipe for wiping and reinstalling a BSDRP system remotely, without
console access, by rerooting into a RAM disk and streaming a fresh
image over ssh onto the (now-idle) boot disk.

**Status: end-to-end tested in bhyve.** Sequence completes cleanly:
kernel reroots into memory-backed UFS, sshd comes back on the same
IP, external `dd` writes a fresh GPT image to `/dev/vtbd0`, `/cfg`
contents are restored from a tarball preserved on the RAM disk, and
the VM reboots into the fresh install.

## Files

- `reinstall-prepare.sh` — runs on the target. Builds a
  ~15 MB RAM rootfs (init, sh, sshd + sshd-session, mount, ifconfig,
  tar, gpart, and their shared libraries), copies the current system's
  SSH host keys and `root/.ssh/authorized_keys`, tars up `/cfg` into
  `/root/cfg-backup.tar.gz` on the RAM root, then `kenv
  vfs.root.mountfrom=ufs:/dev/md42; reboot -r`. Dry-run mode (no args)
  leaves the RAM disk mounted at `/tmp/newroot` for inspection.

- `reinstall-finalize.sh` — runs on the RAM-booted target after the
  fresh image has been dd'd. Mounts `/dev/gpt/cfg`, restores the
  preserved config, syncs, and reboots.

- `user-data.yaml` — cloud-init user-data for the bhyve test VM.
  Static IP `10.99.0.2/24` on `vtnet0`, sshd enabled,
  operator's `authorized_keys` injected.

## Full recipe

```sh
# 1. Prepare target for RAM boot. This kills all processes, mounts a
#    memory-backed UFS at /, and starts sshd on the same IP. The
#    ssh session dies mid-command; that is expected.
ssh root@target 'nohup sh /tmp/reinstall-prepare.sh --commit \
    > /tmp/prep.log 2>&1 &'

# 2. Wait for sshd to come back (10–30 s):
until ssh root@target true; do sleep 3; done

# 3. Stream the fresh image directly onto the target's now-idle boot
#    disk. `bs=1M` on the LOCAL side (GNU dd), `bs=1m` on the REMOTE
#    side (BSD dd).
dd if=BSDRP-full-amd64.img bs=1M status=progress \
    | ssh -T root@target 'dd of=/dev/DISK bs=1m'

# 4. Push finalize (target's rootfs is now the RAM disk, so scp has
#    to be re-run) and execute it.
cat reinstall-finalize.sh \
    | ssh -T root@target 'cat > /tmp/reinstall-finalize.sh \
        && sh /tmp/reinstall-finalize.sh'

# 5. Reboot fires from inside finalize. The ssh session dies again.
#    Wait for the target to come back on the freshly-installed disk.
```

On real hardware `DISK` is `ada0`, `nda0`, or `da0` depending on the
controller. In bhyve with virtio-blk it is `vtbd0`.

## Under bhyve

Full workflow to reproduce the test:

```sh
# From /usr/home/olivier/BSDRP:
sudo tools/BSDRP-lab-bhyve.sh \
    -i /usr/local/poudriere/data/images/BSDRP-n311066-full-amd64.img \
    -m 2G -u tools/lab-reinstall-test/user-data.yaml
```

The launcher runs the VM in the foreground with serial attached to
`/dev/nmdm-BSDRP.1A` (bhyve side; operator connects on `.1B`). Once
`tap0` and `bridge2` appear:

```sh
sudo ifconfig bridge2 inet 10.99.0.1/24 alias
```

After ~30 s cloud-init finishes and `10.99.0.2:22` is reachable.

## Talk to the VM

```sh
# SSH (host keys change every boot):
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@10.99.0.2

# Serial console:
sudo cu -l /dev/nmdm-BSDRP.1B -s 115200
```

For programmatic serial access (drives the console with LF, since the
guest tty does not translate CR to NL in single-user mode):

```python
import os, select, time
fd = os.open('/dev/nmdm-BSDRP.1B', os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
os.write(fd, b'ls /\n')
time.sleep(1)
while select.select([fd], [], [], 0.5)[0]:
    print(os.read(fd, 4096).decode(errors='replace'))
```

## Reset the lab

```sh
sudo tools/BSDRP-lab-bhyve.sh -d
```

Destroys VM disks and tears down bridges/taps.

## Notes on limitations we hit and worked around

- `/rescue` is absent on BSDRP (`WITHOUT_RESCUE=` in `BSDRPj-src.conf`),
  so the RAM rootfs cherry-picks individual binaries + their shared
  libraries via `ldd`.

- FreeBSD 16's `sshd(8)` split its per-connection handler into
  `/usr/libexec/sshd-session` (and `sshd-auth`). Both must be copied
  into the RAM rootfs, or sshd exits 255 with "sshd-session does not
  exist or is not executable" on the very first accept.

- `basename(1)` and a few other userland utilities are missing on the
  minimal RAM rootfs by default. `reinstall-finalize.sh` uses shell
  parameter expansion instead.

- `gpart recover` on the RAM disk fails ("Unknown command: recover")
  because BSDRP ships a stripped `gpart`. The GPT backup at end of
  disk is recreated automatically by the fresh install anyway, so
  this is a warning, not a failure.

- **SSH host keys are preserved automatically across all three
  phases.** `reinstall-prepare.sh` copies `/etc/ssh/ssh_host_*_key*`
  from the running system into the RAM rootfs, so sshd on the RAM
  boot presents the same host key as before. And BSDRP's diskless
  framework mounts `/dev/gpt/cfg` at `/etc` on the fresh install's
  first boot (via `/conf/default/etc/remount`), which surfaces
  `/cfg/ssh/ssh_host_*_key*` as `/etc/ssh/…` — same keys again.
  Net effect: zero `known_hosts` churn on the client. Verified by
  comparing keys before, during, and after the test.

- On real hardware, remember that `dd`'s block-size flag is
  case-sensitive: `bs=1M` on Linux, `bs=1m` on FreeBSD. Getting it
  wrong gives you "invalid number" and a zero-byte transfer.
