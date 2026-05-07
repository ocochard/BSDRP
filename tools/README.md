# BSDRP lab tools

This directory contains scripts for spinning up BSDRP test labs on top of
several hypervisors:

- `BSDRP-lab-bhyve.sh` — bhyve (FreeBSD native hypervisor)
- `BSDRP-lab-qemu.sh` — QEMU
- `BSDRP-lab-vbox.sh` / `.ps1` / `.vbs` — VirtualBox (shell, PowerShell, VBScript)

This README documents `BSDRP-lab-bhyve.sh`.

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

To use your own cloud-init payload, edit the generated files under
`${WRK_DIR}/cloudinit/<lab>_vm<N>/` and rebuild the image with `makefs`,
or replicate the small block in `build_vm_disk_cloudinit_args()` in the
script.

### Troubleshooting

- *"Missing bhyve-firmware package for UEFI"*: install `pkg install
  bhyve-firmware`, or pass `-B` to fall back to BIOS boot.
- *VM already running*: use `-s` to stop, or `-d` to wipe state.
- *Stale bridges/taps*: `-d` calls `destroy_all_if`, which removes any
  interface tagged with a `MESH_` or `LAN_` description.
- *Console shows nothing*: confirm you connected to the `B` end of the
  nmdm pair (`/dev/nmdm-BSDRP.<N>B`), not the `A` end.
