# AGENTS.md

This file provides guidance to Agent when working with code in this repository.

## Project Overview

BSD Router Project (BSDRP) is a FreeBSD-based router distribution that creates specialized network appliance firmware. The project uses poudriere-image to build both BIOS and UEFI-compatible disk images with networking software like FRRouting, Bird, ExaBGP, OpenVPN, and strongSwan.

## Companion repo: `~/bsdrp-website`

The public documentation site at `bsdrp.net` lives in a separate repo at
`~/bsdrp-website` (github.com/ocochard/bsdrp-website). It is an
mkdocs-material site whose source of truth is the markdown under
`docs/`.

**Many changes here have a documentation side**: a software version
bump, a new lab/example, a new build option, or a behavior change in
the user-facing tooling typically warrants matching edits in the
website repo (release notes, version mentions on the homepage, new
pages under `docs/documentation/examples/`). When a session in this
repo makes such a change, also open `~/bsdrp-website`, make the
matching doc edits, run `mkdocs build --strict` there, and commit +
push the two repos independently. They are not coupled by a submodule;
they have separate lifecycles, just related ones.

The website repo's `AGENTS.md` has its own copyediting and convention
notes; read it before editing markdown there.

## Architecture

The build system has three main phases:
1. **Builder jail creation**: Creates a reduced FreeBSD jail (BSDRPj) with compilation tools
2. **Package building**: Builds packages from ports tree using the builder jail
3. **Image generation**: Creates nanobsd-like UEFI/BIOS compatible firmware images

### Key directories:
- `BSDRP/`: Main project files including nano configuration, kernel configs, patches, and file overlays
- `EINE/`: Easy Internet vpN Extender sub-project for large-scale network appliance deployment
- `poudriere.etc/`: Poudriere configuration files for jail and package building
- `tools/`: Lab scripts for testing in bhyve, QEMU, VirtualBox environments
- `obj/`: Build artifacts and object files

### Configuration files:
- `Makefile.vars`: FreeBSD and ports tree git hashes and repository URLs
- `poudriere.etc/poudriere.d/`: Contains jail source config, package lists, and build options
- `BSDRP/Files/`: File overlay structure that gets copied to final image

## Build Commands

### Basic building:
```bash
make                    # Build images (default target)
make help              # Show all available targets
```

### Development workflow:
```bash
make upstream-sync     # Fetch latest FreeBSD and ports sources, update Makefile.vars
make clean-src         # Clean source trees (needed when FreeBSD obj tree prevents upgrade)
make clean-packages    # Clean all existing packages
make clean-jail        # Clean builder jail and obj directories
make clean-all         # Clean everything
```

### Release preparation:
```bash
make release          # Build, compress, and generate checksums of images
make compress-images  # Compress generated files
make checksum-images  # Compute checksums of generated files
```

### Rebuild triggers (important):

The Makefile is dependency-driven via stamp files in `obj/` — you almost never need to manually delete stamps or run `clean-*` targets. Just run `make`:

- **Editing `poudriere.etc/poudriere.d/BSDRPj-src.conf.common`** (e.g. changing `MODULES_OVERRIDE`, `WITHOUT_*`): the `build-builder-jail` target depends on this file, so `make` re-runs the jail/kernel build automatically on mtime change.
- **Editing `Makefile.vars`** (bumping `FreeBSD_hash` or `ports_hash`): the `update-src-${repo}` recipe compares the configured hash against the actual checked-out hash and, if different, cleans + checks out the new hash. This cascades through `patch-src-*` → `patch-sources` → `build-builder-jail`, triggering a full rebuild.
- **Editing a BSDRP kernel config** (`BSDRP/kernels/<arch>`): the `${kernel}` target copies it into the FreeBSD source tree, which feeds into `patch-sources` → jail rebuild.
- **`make upstream-sync`** runs `sed` to update the hashes in `Makefile.vars`, so the next `make` picks up new sources via the mechanism above.

Use `clean-jail` / `clean-src` / `clean-all` only when something is genuinely wrong (corrupted obj tree, stuck patches) — not as a default precaution.

## Requirements

- FreeBSD 15.0 or higher
- poudriere installed
- git
- Root access (uses sudo when not running as root)

## Testing Tools

The `tools/` directory contains lab scripts for testing built images:
- `BSDRP-lab-bhyve.sh`: Test with bhyve hypervisor (supports regression-test labs via `-r`)
- `BSDRP-lab-qemu.sh`: Test with QEMU
- `BSDRP-lab-vbox.*`: Test with VirtualBox (shell, PowerShell, VBS variants)
- `ci-qemu-test.sh`: Single-VM boot smoke test for CI (mounts the image's s3 cfg partition, drops an `rc.conf.local` that prints "Hello world" then powers off, runs under QEMU with a 300s timeout, greps the serial log). It does NOT exercise networking or routing features — it only proves the image POSTs and reaches userland.
- `validate-image.sh`: Image validation

### Regression-test labs (bhyve + cloud-init + labconfig)

The full feature regression workflow is driven by three pieces working together:

1. **`tools/BSDRP-lab-bhyve.sh -r <lab>`** orchestrates the host side: extracts the image, creates N per-VM disks under `~/BSDRP-VMs/`, builds a full-mesh bridge/tap topology with deterministic MACs (`58:9c:fc:<i>:<j>:<self>` for mesh links, `58:9c:fc:<lan>:00:<self>` for LANs), and for each VM N generates a cloud-init VFAT disk (label `cidata`) containing a `user-data` with `runcmd: /usr/local/sbin/labconfig <lab>_vm${N}`. The cidata disk is attached at PCI slot `1:7`.
2. **`BSDRP/Files/usr/local/sbin/labconfig`** is the in-VM configurator shipped on the image. It is a flat shell script of functions named `<lab>_vm<N>` (e.g. `full_vm1`, `frr_vm3`). Each function uses `sysrc` to write the appropriate `rc.conf` for that VM's role, restarts services, and runs `/usr/local/sbin/config save` to persist to nanobsd's `/cfg`. Invoked as `labconfig <lab>_vm<N>` — the `$1` argument is called as a function name.
3. **cloud-init inside the BSDRP image** reads the cidata disk on first boot and runs the `runcmd` line.

**Available lab families and their VM counts** (grep `^<name>_vm.* () {` in `labconfig`):
- `full` (5), `frr` (7), `bgp` (7), `vpn` (5), `mlvpn` (6), `mlppp` (6), `ecmp` (6), `fairshape` (5), `jailpf` (5), `pimsm` (4), `vrrp` (4)
- Single-VM jails-based: `bird_jails`, `frr_jails`, `graphpath`

**Running a regression lab** (example: full, 5 VMs):
```bash
sudo tools/BSDRP-lab-bhyve.sh -d    # stop running VMs, wipe ~/BSDRP-VMs, tear down bridges/taps
sudo tools/BSDRP-lab-bhyve.sh -i BSDRP-<version>-full-amd64.img.xz -n 5 -r full
```

`-d` already destroys running VMs (via `erase_all_vm` → `destroy_vm` → `bhyvectl --destroy`) before erasing the disks, so there is no need to run `-s` first. Use `-s` only when you want to stop VMs but keep the disks for a later resume.

**Important gotchas:**
- `-n` MUST match the lab's defined VM count — extra VMs get no labconfig function and fail; missing VMs leave the topology incomplete.
- cloud-init `runcmd` only fires on **first boot**. To re-run the same lab, run `-d` (wipes disks) before re-launching, otherwise the existing `/cfg` keeps the old config and labconfig is not re-executed.
- When `-n > 1`, `-l` (LAN count) defaults to 0 — only mesh links exist. Check the specific `<lab>_vmN` function in `labconfig` to see which NICs (`em0`/`vtnet0` etc.) it configures and whether it expects a shared LAN.
- The script does NOT automatically verify lab convergence — after launch it prints `cu -l /dev/nmdm-BSDRP.NB` commands and the operator manually connects to each VM's serial console to inspect routing tables / SAs / VRRP state / etc.

## Development Notes

- The build system requires root privileges and uses poudriere for package building
- FreeBSD and ports sources are automatically synchronized from git repositories
- Images support both BIOS and UEFI boot with GPT partitioning
- Custom kernel configurations are in `BSDRP/kernels/` (these are standalone configs, NOT `include GENERIC`, so every desired kernel option must be listed explicitly)
- Patches for FreeBSD and ports are in `BSDRP/patches/`
- The EINE sub-project has its own build process using `./make.sh -p EINE`

### Kernel modules

- The list of kernel modules built and shipped on the image is controlled by `MODULES_OVERRIDE` in `poudriere.etc/poudriere.d/BSDRPj-src.conf.common`. Only modules listed there are built — defaults from `sys/modules` are not included.
- Module entries use the path under `sys/modules/` (e.g. `geom/geom_mirror`, `usb/cdce`), not just the module name.
- A reference FreeBSD source tree is unpacked under `obj/FreeBSD/sys/` after the first build — use it to look up GENERIC configs (`obj/FreeBSD/sys/<arch>/conf/GENERIC`), available module paths (`obj/FreeBSD/sys/modules/...`), and module dependencies (`MODULE_DEPEND` / `MODULE_VERSION` calls in the module's `.c` files).
- To check if a feature is compiled into the kernel vs available only as a module: grep the BSDRP kernel config in `BSDRP/kernels/<arch>` for the `options` symbol (e.g. `GEOM_MIRROR`). If it's not there but the module exists under `sys/modules/`, it's module-only and must be added to `MODULES_OVERRIDE` to be shipped.
