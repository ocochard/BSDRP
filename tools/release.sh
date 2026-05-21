#!/bin/sh
#
# BSDRP release management script
# Handles image upload to SourceForge and generates documentation
#
# Purpose:
#   - Uploads BSDRP images to SourceForge file hosting
#   - Generates DokuWiki-formatted download tables
#   - Manages release artifacts and checksums
#
# Dependencies:
#   - Package lists from poudriere: packages.list, packages.license.list
#   - BSDRP version from BSDRP/Files/etc/version
#   - SCP access to SourceForge project
#
# Note: SourceForge download mirrors may have slow propagation

set -eu
# Error handling function - prints error message and exits
# Arguments:
#   $@: Error message to display
# Returns: exits with code 1
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# General variables
: ${DRY:=""}
poudriere_imgdir="/usr/local/poudriere/data/images"

# Display usage information and available commands
# Arguments: none
# Returns: exits with code 0
usage () {
	echo "$0 [-a <arch>] [ upload | dokuwiki ]"
	echo " - upload: Upload all images to SourceForge"
	echo " - dokuwiki: Generate dokuwiki table of images"
	echo " - -a <arch>: target arch (default: \$(uname -p)); use to upload cross-built images"
	exit 0
}

# Upload BSDRP images and changelog to SourceForge
# Arguments:
#   $1: Version string (e.g., 2.0, nightly/2012-09-05)
#   $2: Architecture (amd64, aarch64, etc.)
# Returns: exits with code 0
upload(){
  local ver=$1
  local arch=$2
	${DRY} scp CHANGES.md cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/${ver}
			${DRY} scp ${file_list} cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/${ver}/${arch}
	exit 0
}

# Generate DokuWiki-formatted download table for website
# Arguments:
#   $1: Version string for SourceForge URL path
#   $2: Architecture (currently unused, iterates all architectures)
# Returns: exits with code 0, outputs wiki markup to stdout
dokuwiki(){
	local ver=$1
  local arch=$2
  URL="https://sourceforge.net/projects/bsdrp/files/BSD_Router_Project/${ver}"
  ARCHS='
amd64
aarch64
'
	FAMILIES='
full
upgrade
mtree
debug
	'
	for family in ${FAMILIES}; do
    # family = purpose
		echo "^ Arch ^ Purpose ^ File ^ Checksum ^"
      for arch in ${ARCHS}; do
				echo -n "| ${arch}"
 				echo -n "| ${family}"
        # Filename format differs by family:
        #   full / upgrade / debug: BSDRP-${ver}-${family}-${arch}.<ext>
        #   mtree:                  BSDRP-${ver}-${arch}.mtree.xz  (no family in name)
        case ${family} in
          full|upgrade) file=BSDRP-${ver}-${family}-${arch}.img.xz ;;
          debug)        file=BSDRP-${ver}-${family}-${arch}.tar.xz ;;
          mtree)        file=BSDRP-${ver}-${arch}.mtree.xz ;;
        esac
			  echo -n " | [[$URL/${arch}/${file}/download|${file}]]"
 			  echo " | [[$URL/${arch}/${file}.sha256/download|sha256]] |"
     done # for arch
	  done # for type
	exit 0
}

# Main part

arch=$(uname -p)
while getopts "a:h" opt; do
  case "${opt}" in
    a) arch=${OPTARG} ;;
    h|*) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
	echo " Missing argument"
	usage
fi

# Whitelist subcommand before dispatching by name
case "$1" in
  upload|dokuwiki) cmd=$1 ;;
  *) echo "Unknown command: $1"; usage ;;
esac

if [ -r BSDRP/Files/etc/version ]; then
  version=$(cat BSDRP/Files/etc/version)
else
  die "No BSDRP/Files/etc/version (run from the repo root)"
fi

# dokuwiki is a pure formatter - no files / confirm needed
if [ "${cmd}" = "dokuwiki" ]; then
  ${cmd} "${version}" "${arch}"
fi

# upload path: locate artifacts, show them, confirm, then go.
# Two globs needed because mtree files lack the -<family>- segment:
#   BSDRP-${ver}-full-${arch}.img.xz       (full / upgrade / debug)
#   BSDRP-${ver}-${arch}.mtree.xz          (mtree, no family in name)
file_list=$(ls \
  ${poudriere_imgdir}/BSDRP-${version}-*-${arch}.* \
  ${poudriere_imgdir}/BSDRP-${version}-${arch}.* \
  2>/dev/null || true)

if [ -z "${file_list}" ]; then
  die "no files found matching ${poudriere_imgdir}/BSDRP-${version}-*${arch}.*"
fi

echo "Detected files to be uploaded to ${version}/${arch}:"
echo "${file_list}" | sed 's/^/  /'
echo
echo "Do you confirm? [y/n]"

input=""
while [ "${input}" != "y" ] && [ "${input}" != "n" ]; do
  read -r input
done
if [ "${input}" = "y" ]; then
  ${cmd} "${version}" "${arch}"
else
  exit 1
fi
