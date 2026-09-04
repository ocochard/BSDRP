# BSDRP lab and test tools

This directory contains the scripts that launch BSDRP test labs and run the
tests against a built image.

**Test drivers**

- `regression-test.sh` — the automated feature regression driver: launches a
  lab, then asserts on its state. This is what "run the regression test"
  means; see [regression-test.sh](#regression-testsh) below.
- `ci-qemu-test.sh` — single-VM boot smoke test for CI: mounts the image's s3
  cfg partition, drops an `rc.conf.local` printing "Hello world" then powering
  off, boots it under QEMU with a 300 s timeout and greps the serial log. It
  exercises no networking or routing — it only proves the image POSTs and
  reaches userland.
- `validate-image.sh` — boots an image until the `login:` prompt and records
  the result in `/tmp/validate-images-status.txt`.

**Lab launchers** (host topology + VMs, no assertions)

- `BSDRP-lab-bhyve.sh` — bhyve (FreeBSD native hypervisor), documented below
- `BSDRP-lab-qemu.sh` — QEMU
- `BSDRP-lab-vbox.sh` / `.ps1` / `.vbs` — VirtualBox (shell, PowerShell, VBScript)
- `lab-reinstall-test/` — cloud-init driven upgrade/reinstall test (own `README.md`)

**Build / debug helpers**

- `bisection-gen.sh` — builds one image per FreeBSD git hash from a list (or,
  for a Phabricator review, a patched and an unpatched image) to bisect a
  regression.
- `review-generate.sh` — builds the reference + patched image pair for a
  FreeBSD Phabricator review.
- `image_tool.sh` — `mount`/`umount` an image's partitions, `update` the
  mounted root from `BSDRP/Files/`, or convert an image to qcow2 (`qemu`).
- `mputconfig.sh` — pushes commands to several remote devices (needs only
  `expect`).
- `defaults.sh` — legacy nanobsd `defaults.sh` (Poul-Henning Kamp, 2005).
  Nothing in the tree references it since the switch to poudriere-image; it is
  not part of the build.

## regression-test.sh

```sh
sudo tools/regression-test.sh BSDRP-<version>-full-amd64.img.xz full
```

Wipes any prior lab state, launches the lab through `BSDRP-lab-bhyve.sh` with
the VM count it derives from the lab name, waits `--boot-delay` seconds
(default 60) for cloud-init/labconfig to finish, then drives each VM's serial
console with `expect(1)` and matches command output against per-VM assertions.
Each check is retried to absorb convergence delays.

Exit codes: `0` all assertions passed, `1` at least one failed, `2`
setup/usage error.

| Flag                | Description                                                      |
|---------------------|------------------------------------------------------------------|
| `--boot-delay <s>`  | Seconds to wait after launch before probing consoles (default 60) |
| `--no-launch`       | Skip the wipe+launch step and only run the assertions against an already-running lab (alias: `--already-running`) |

- The script re-execs itself under `sudo` when not run as root, so the leading
  `sudo` is optional.
- **Prerequisite**: `expect` on the host (`pkg install expect`). Raw
  redirection to `/dev/nmdm*` does not drive the guest's `login(1)` reliably.
- **Scope**: assertions exist only for the `full` lab, derived from the
  [maximum features lab](https://bsdrp.net/documentation/examples/maximum_bsdrp_features_lab)
  wiki page. Any other lab exits with `lab '<name>' has no assertions
  implemented yet`.
- `--no-launch` is the inner loop when writing assertions: launch the lab once
  by hand (see below), then re-run the driver as many times as needed.
- Its `lab_vm_count()` table duplicates the per-lab VM counts of `labconfig` —
  keep both in sync.

## BSDRP-lab-bhyve.sh

`BSDRP-lab-bhyve.sh` provisions one or more BSDRP VMs on a FreeBSD host
using bhyve. By default each VM is fully meshed (point-to-point links to
every other VM) and optionally shares one or more LAN broadcast domains.

### Requirements

- FreeBSD host with bhyve support (kernel module `vmm`)
- Root access (script uses `sudo` when not run as root)
- `bhyve-firmware` package (for UEFI mode, the default on amd64)
- A BSDRP disk image (`.img`, `.img.xz`, or `.img.bz2`)

The script auto-loads `vmm`, `nmdm`, and `if_tap`/`if_tuntap` as needed.

### Synopsis

```
BSDRP-lab-bhyve.sh [-aBdeghqsvV] -i FreeBSD-disk-image.img \
                   [-n vm-number] [-l LAN-number] [-c cores] \
                   [-t threads] [-m RAM] [-A add-disks] [-S size] \
                   [-D disk-ctrl] [-r lab] [-w workdir]
```

### Options

| Flag         | Description                                                          |
|--------------|----------------------------------------------------------------------|
| `-i FILE`    | BSDRP disk image (xz, bz2, or raw); required on first run            |
| `-n N`       | Number of VMs to start (default: 1, max: 255)                        |
| `-l N`       | Number of shared LANs across all VMs (default: 0)                    |
| `-a`         | Disable full mesh between VMs                                        |
| `-c N`       | Cores per VM (default: 1)                                            |
| `-t N`       | Threads per core (default: 1)                                        |
| `-m SIZE`    | RAM per VM (default: 1G)                                             |
| `-A N`       | Number of additional disks per VM                                    |
| `-S SIZE`    | Size of each additional disk (default: 8G)                           |
| `-D CTRL`    | Disk controller: `virtio-blk` (default), `ahci-hd`, `virtio-scsi`, `nvme` |
| `-e`         | Use Intel e1000 NIC instead of virtio-net                            |
| `-V`         | Use vale (netmap) switches instead of bridge + tap                   |
| `-B`         | BIOS boot (amd64 default is UEFI)                                    |
| `-v`         | Attach a framebuffer + VNC server                                    |
| `-g`         | Enable remote kgdb                                                   |
| `-r LAB`     | Generate a cloud-init disk that runs `labconfig <lab>_vmN` on boot   |
| `-u FILE`    | Custom cloud-init user-data, attached to every VM (overrides `-r`'s) |
| `-w DIR`     | Working directory (default: `~/BSDRP-VMs`)                           |
| `-d`         | Delete all VMs and the template, then exit                           |
| `-s`         | Stop all running BSDRP VMs and exit                                  |
| `-q`         | Quiet                                                                |
| `-h`         | Help                                                                 |

If `-n 1` and `-l 0` are used together, the script forces `-l 1` so the
single VM still gets one NIC.

### Files and layout

The script keeps state under `${WRK_DIR}` (default `~/BSDRP-VMs`):

```
~/BSDRP-VMs/
├── vm_template            # decompressed disk image, copied per VM
├── BSDRP_1                # disk for VM 1
├── BSDRP_2                # disk for VM 2
└── cloudinit/             # only when -r is used
    ├── full_vm1/
    │   ├── meta-data
    │   └── user-data
    ├── full_vm1.img       # 2 MB FAT12 cidata image
    └── ...
```

### Networking

- **Mesh links** (`-a` to disable): every pair of VMs gets a dedicated
  bridge + tap (or vale switch) named `MESH_<lo>-<hi>`.
- **LAN links** (`-l N`): N bridges named `LAN_<j>` are shared by all VMs.
- **MAC addresses** use the locally administered prefix `58:9c:fc:`. The
  layout encodes link membership so partners are identifiable from the MAC.

NIC PCI assignment: NICs start at PCI bus 2, slot 0, with 8 slots per bus.

### Connecting to a VM

The script prints the `cu` command for each VM's serial console after launch:

```
- VM 1 : sudo cu -l /dev/nmdm-BSDRP.1B
```

To exit `cu`: type `~.` on a new line.

### Examples

Single VM with one LAN, default specs (UEFI on amd64):

```sh
sudo ./BSDRP-lab-bhyve.sh -i ../BSDRP-2.1-full-amd64.img.xz
```

Three fully-meshed VMs, 2 cores, 2 GB RAM each, plus one shared LAN:

```sh
sudo ./BSDRP-lab-bhyve.sh -i ../BSDRP-2.1-full-amd64.img.xz \
    -n 3 -l 1 -c 2 -m 2G
```

Re-run an existing template (no `-i` needed once the template is built):

```sh
sudo ./BSDRP-lab-bhyve.sh -n 3 -l 1
```

Stop everything and clean up:

```sh
sudo ./BSDRP-lab-bhyve.sh -s     # stop all running BSDRP VMs
sudo ./BSDRP-lab-bhyve.sh -d     # destroy VMs, template, and interfaces
```

### Cloud-init / regression-lab example (`-r`)

The `-r LAB` flag builds a small FAT12 cidata image per VM and attaches it
as an extra virtio-blk disk. cloud-init inside BSDRP picks it up on first
boot, sets the hostname to `<lab>_vm<N>.lab.bsdrp.net`, and runs:

```
/usr/local/sbin/labconfig <lab>_vm<N>
```

This lets you ship a predefined topology config (the `labconfig` script in
the BSDRP image) and have every VM auto-configure itself for that lab.

Example: bring up a 3-VM lab using the `full` labconfig family:

```sh
sudo ./BSDRP-lab-bhyve.sh -i ../BSDRP-2.1-full-amd64.img.xz \
    -n 3 -l 1 -r full
```

This produces:

- `~/BSDRP-VMs/cloudinit/full_vm1/{meta-data,user-data}` and `full_vm1.img`
- `~/BSDRP-VMs/cloudinit/full_vm2/...` and `full_vm2.img`
- `~/BSDRP-VMs/cloudinit/full_vm3/...` and `full_vm3.img`

Each `user-data` looks like:

```yaml
#cloud-config
runcmd:
  - /usr/local/sbin/labconfig full_vm1
```

and each `meta-data`:

```yaml
#cloud-config
hostname: full_vm1.lab.bsdrp.net
```

On first boot, VM 1 runs `labconfig full_vm1`, VM 2 runs `labconfig
full_vm2`, etc. To re-run the lab from scratch (so cloud-init triggers
again), destroy the VM disks first with `-d`.

To use your own cloud-init payload, pass it with `-u FILE`: that user-data is
attached to every VM (the per-VM `meta-data` is still generated) and takes
precedence over the one `-r` would write.

## Regression labs: labconfig + cloud-init

A regression lab is three pieces working together:

1. **`BSDRP-lab-bhyve.sh -r <lab>`** builds the host side: per-VM disks, the
   full-mesh bridge/tap topology, and one cloud-init cidata disk per VM
   (attached at PCI slot `1:7`), as described above.
2. **`BSDRP/Files/usr/local/sbin/labconfig`**, shipped on the image, is the
   in-VM configurator. It is a flat shell script of functions named
   `<lab>_vm<N>` (`full_vm1`, `frr_vm3`, ...); each one writes that VM's role
   into `rc.conf` with `sysrc`, restarts the services, and runs
   `/usr/local/sbin/config save` to persist to nanobsd's `/cfg`. The `$1`
   argument is called as a function name.
3. **cloud-init inside the image** reads the cidata disk on first boot and
   runs the `runcmd` line.

**Lab families and their VM counts** (grep `^<name>_vm[0-9]* *() *{` in
`labconfig`):

- `full` (5), `frr` (7), `bgp` (7), `vpn` (5), `mlvpn` (6), `mlppp` (6),
  `ecmp` (4), `fairshape` (5), `jailpf` (5), `pimsm` (4), `vrrp` (4)
- Single-VM jails-based: `bird_jails`, `frr_jails`, `graphpath`. Their
  function carries no `_vmN` suffix, so they run as `labconfig <lab>` and
  require `-n 1`.

Launching a lab by hand (`full`, 5 VMs):

```sh
sudo tools/BSDRP-lab-bhyve.sh -d    # stop VMs, wipe ~/BSDRP-VMs, tear down bridges/taps
sudo tools/BSDRP-lab-bhyve.sh -i BSDRP-<version>-full-amd64.img.xz -n 5 -r full
```

`-d` destroys running VMs (`erase_all_vm` → `destroy_vm` → `bhyvectl
--destroy`) before erasing the disks, so `-s` first is unnecessary. Use `-s`
only to stop VMs while keeping their disks for a later resume.

**Gotchas**

- `-n` MUST match the lab's VM count: extra VMs get no labconfig function and
  fail, missing VMs leave the topology incomplete. The script rejects a
  mismatched `-n`, and an unknown `-r` name, up front by counting the lab's
  functions in the in-tree `labconfig`.
- cloud-init `runcmd` only fires on **first boot**. To re-run a lab, `-d`
  first: otherwise the existing `/cfg` keeps the old config and labconfig is
  never re-executed.
- With `-n > 1`, `-l` defaults to 0 — only mesh links exist. Check the
  `<lab>_vmN` function to see which NICs (`em0`, `vtnet0`, ...) it configures
  and whether it expects a shared LAN.
- `BSDRP-lab-bhyve.sh` verifies nothing about convergence: it prints the `cu`
  commands and leaves the inspection to you (or to `regression-test.sh`).

## Troubleshooting

- *"UEFI bootrom not found"*: `pkg install bhyve-firmware`, or pass `-B` to
  fall back to BIOS boot. The arm64 equivalent is *"arm64 bootrom not found"*
  (`pkg install u-boot-bhyve-arm64`).
- *"Unknown regression lab"* / *"needs exactly N VM(s)"*: the `-r` name or the
  `-n` count does not match `BSDRP/Files/usr/local/sbin/labconfig`; see the
  lab table above.
- *VM already running*: use `-s` to stop, or `-d` to wipe state.
- *Stale bridges/taps*: `-d` calls `destroy_all_if`, which removes any
  interface tagged with a `MESH_` or `LAN_` description.
- *Console shows nothing*: confirm you connected to the `B` end of the
  nmdm pair (`/dev/nmdm-BSDRP.<N>B`), not the `A` end.
