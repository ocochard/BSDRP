---
name: bsdrp-release
description: Prepare a new BSDRP release - bump version, build images via `make release`, update CHANGES.md from the generated packages.list, and sync AUTHORS from the generated packages.license.list. Use when the user asks to prepare/cut a release (e.g. "prepare release 2.3", "cut a new release").
---

# BSDRP release preparation

This skill codifies the four steps required to ship a new BSDRP release.

## Inputs

Ask the user (only what is not obvious from context):
- **Target version** (e.g. `2.3`). Required.
- **Release date** for the CHANGES.md heading. Default to today (UTC) in
  `YYYY/MM/DD` format unless the user gives one.

## Step 1 - Bump the version

Overwrite `BSDRP/Files/etc/version` with the new version string followed by
a single newline. Nothing else - no comments, no leading `v`. Confirm by
reading the file back.

The current contents look like `2.1\n` or `n309368\n` (legacy hash style).
Always switch to the plain `X.Y\n` form for a release.

## Step 2 - Build the release images

Run `make release` from the repo root. This is the make target that
chains `all -> compress-images -> checksum-images` and produces (under
`/usr/local/poudriere/data/images/`):

- `BSDRP-<ver>-full-<arch>.img.xz`        (firmware image)
- `BSDRP-<ver>-upgrade-<arch>.img.xz`     (in-place upgrade image)
- `BSDRP-<ver>-<arch>.mtree.xz`           (file inventory)
- `BSDRP-<ver>-debug-<arch>.tar.xz`       (kernel debug symbols)
- `packages.list`                         (one line per shipped package)
- `packages.license.list`                 (per-package license inventory)

The build is long (often 30-90+ minutes on a cold tree). **Launch it via
the Bash tool with `run_in_background: true` and a generous timeout
(e.g. `timeout: 600000`)**, then wait for the task-notification - do not
poll, sleep, or re-launch on transient failures. If the build fails,
inspect the tail of the output file; common causes are stale source
trees (`make clean-src` then retry) or package build errors (look at
`/usr/local/poudriere/data/logs/bulk/.../`).

`packages.list` and `packages.license.list` are generated AT THE END of
the image build. **Do not try to read them before `make release`
completes** - they reflect the previous build if they exist at all.

## Step 3 - Update CHANGES.md

`CHANGES.md` at the repo root is the authoritative changelog.
Each release has its own `# Release X.Y (YYYY/MM/DD)` section at the
top of the file. Prepend the new section above the previous one.

### Build the new section by diffing

1. Find the previous release's `## Packages list` block (the very last
   section of the most recent release entry). The package list in the
   freshly generated `/usr/local/poudriere/data/images/packages.list` is
   the new ground truth.
2. `diff` the two lists. Each `<` / `>` pair where the package name
   matches is an **upgrade**; lines that appear only in `>` are
   **additions**; lines only in `<` are **removals**. A package whose
   name itself changed (e.g. `libyang2` -> `libyang3`) shows as one
   removal + one addition - call it out as a rename/major-version bump.
3. From these, write three subsections:
   - `## New features` - user-visible additions. Derive from
     `git log <previous-release-commit>..HEAD --oneline` and filter
     for feature-style commits (Add/Adding/Introduce/Ship). Cross-check
     with the package diff for newly-added ports.
   - `## Fixes` - bug-fix commits since the previous release (`fix:`,
     `Fix `).
   - `## Upgraded packages` - the version upgrades from the diff.
     Format: `* name: OLD -> NEW`. Group `vim` and `xxd` on one line
     when their versions move in lockstep (they come from the same port).

### Append the verbatim packages list

After the three subsections, add a `## Packages list` block that is the
verbatim contents of `/usr/local/poudriere/data/images/packages.list`
(every line starts with `* `).

### Optional: FreeBSD notable changes

For releases where the FreeBSD source bump brings significant
network-stack changes, add a `## FreeBSD notable network stack changes
introduced` block with subsections per area (CARP, PF/pfsync, IPFW, IPv6,
etc.). This is a curated highlight - it is NOT the full FreeBSD
changelog. Only fill this in if the user has visible changes worth
flagging; otherwise omit the block.

## Step 4 - Sync AUTHORS with packages.license.list

`AUTHORS` at the repo root ends with a `## Packages` section
(starts at the line `## Packages`, followed by a blank line, then one
`* name, license:X, URL` entry per package). This block must match
`/usr/local/poudriere/data/images/packages.license.list` line-for-line.

### Diff procedure

```sh
awk 'NR >= <first-package-line-number>' AUTHORS \
  | diff - /usr/local/poudriere/data/images/packages.license.list
```

The first-package-line-number is the line **after** `## Packages` plus the
following blank line - usually around line 24. Find it dynamically with
grep so the skill survives header edits.

Apply the diff to AUTHORS via Edit calls:
- Renamed package (e.g. `libyang2` -> `libyang3`): one Edit replacing the
  old line.
- Net new package: insert in alphabetical order.
- Removed package: delete the line.

### Skip noise

The `python` and `python3` meta-ports appear in `packages.license.list`
with empty `license:` fields and the same URL as `python311`. **Do not
add them to AUTHORS or CHANGES.md** - they are redundant with
`python311`. The user has flagged this preference; keep AUTHORS slim.

After editing, re-run the diff and confirm it is empty (modulo the
intentionally-skipped python meta-ports).

## Verification before declaring done

Print a one-line summary per artifact:
- `BSDRP/Files/etc/version` contents
- The four image filenames in `/usr/local/poudriere/data/images/`
  matching the new version (use `ls`).
- The first heading line of `CHANGES.md`.
- Result of the AUTHORS-vs-packages.license.list diff (should be empty
  or only the python meta-ports).

Do NOT commit, tag, or push - leave those to the user. The skill stops
at "ready to be committed".

## Tag naming convention (for reference)

When the user later asks for the tag command, the established
convention in this repo is:

- **Format**: `vX.Y` (lowercase `v` prefix, dotted version — verify
  with `git tag -l | sort -V | tail` before suggesting).
- **Annotated**: use `git tag -a` with a message matching prior
  releases — `Releasing version vX.Y` (check `git for-each-ref
  --format='%(subject)' refs/tags/v<prev>` to confirm the exact
  wording is still in use).
- **Push is separate**: `git push origin vX.Y` — `git push` alone
  does not push tags.

Do not run these commands as part of the skill — only surface them
if the user explicitly asks about tagging.

## SourceForge upload (for reference)

After the user commits and tags, the images and `CHANGES.md` are
published to SourceForge via `tools/release.sh upload`. The script
auto-detects the version from `BSDRP/Files/etc/version` and the arch
from `uname -p` (override with `-a <arch>` for cross-built images).
It uploads to `frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/
BSD_Router_Project/<ver>/<arch>/` via scp using SSH-key auth.

Set `DRY=echo` in the environment for a dry run that prints the scp
commands without executing them.

Do not run the upload as part of the skill — leave it to the user.
