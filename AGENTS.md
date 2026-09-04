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

`tools/README.md` is the reference for everything under `tools/`. Read it, and
the target script's header comment, before running or modifying anything there
— this section is only a map, and a map goes stale.

- **`tools/regression-test.sh <image> <lab>`** is the automated feature
  regression driver: it launches the lab and then asserts on it over the
  serial consoles. This is what "run the regression test" means. Assertions
  currently exist for the `full` lab only; needs `expect` on the host.
- `tools/BSDRP-lab-bhyve.sh -r <lab>` only launches a lab (bhyve topology +
  cloud-init disks that run `labconfig` in each VM). It asserts nothing.
- `tools/ci-qemu-test.sh` is the CI boot smoke test: it proves the image
  reaches userland, and exercises no networking or routing.
- Per-lab VM counts live in `BSDRP/Files/usr/local/sbin/labconfig` (one
  `<lab>_vm<N>` function per VM) and are duplicated in `regression-test.sh`'s
  `lab_vm_count()` — changing a lab means updating both.

## Development Notes

- The build system requires root privileges and uses poudriere for package building
- FreeBSD and ports sources are automatically synchronized from git repositories
- Images support both BIOS and UEFI boot with GPT partitioning
- Custom kernel configurations are in `BSDRP/kernels/` (these are standalone configs, NOT `include GENERIC`, so every desired kernel option must be listed explicitly)
- Patches for FreeBSD and ports are in `BSDRP/patches/`

### Kernel modules

- The list of kernel modules built and shipped on the image is controlled by `MODULES_OVERRIDE` in `poudriere.etc/poudriere.d/BSDRPj-src.conf.common`. Only modules listed there are built — defaults from `sys/modules` are not included.
- Module entries use the path under `sys/modules/` (e.g. `geom/geom_mirror`, `usb/cdce`), not just the module name.
- A reference FreeBSD source tree is unpacked under `obj/FreeBSD/sys/` after the first build — use it to look up GENERIC configs (`obj/FreeBSD/sys/<arch>/conf/GENERIC`), available module paths (`obj/FreeBSD/sys/modules/...`), and module dependencies (`MODULE_DEPEND` / `MODULE_VERSION` calls in the module's `.c` files).
- To check if a feature is compiled into the kernel vs available only as a module: grep the BSDRP kernel config in `BSDRP/kernels/<arch>` for the `options` symbol (e.g. `GEOM_MIRROR`). If it's not there but the module exists under `sys/modules/`, it's module-only and must be added to `MODULES_OVERRIDE` to be shipped.
