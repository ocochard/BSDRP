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
	echo "$0 [ upload | dokuwiki ]"
	echo " - upload: Upload all images to SourceForge"
	echo " - dokuwiki: Generate dokuwiki table of images"
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
  FILE_LIST=$(ls ${poudriere_imgdir}/BSDRP-${ver}-*-${arch}.*)
			${DRY} scp ${FILE_LIST} cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/${ver}/${arch}
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
        # xxx mtree and tar
        case ${family} in
          full|upgrade) ext=".img.xz" ;;
          mtree) ext=".mtree.xz";;
          debug) ext=".tar.xz";;
        esac
        file=BSDRP-${ver}-${family}-${arch}${ext}
			  echo -n " | [[$URL/${arch}/${file}/download|${file}]]"
 			  echo " | [[$URL/${arch}/${file}.sha256/download|sha256]] |"
     done # for arch
	  done # for type
	exit 0
}

# Main part

if [ $# -lt 1 ]; then
	echo " Missing argument"
	usage
fi

if [ -r BSDRP/Files/etc/version ]; then
  version=$(cat BSDRP/Files/etc/version)
else
  die "No BSDRP/Files/etc/version"
fi

arch=$(uname -p)

if [ "$1" = "upload" -a $# -eq 1 ]; then
  echo "Missing destination directory, examples:"
  echo "- nightly/2012-09-05"
  echo "- 2.0"
  echo
  usage
fi


if [ "$1" = "dokuwiki" -a $# -eq 1 ]; then
  echo "Missing destination directory, examples:"
  echo "- nightly/2012-09-05"
  echo "- 2.0"
  echo
  usage
fi

$1 ${version} ${arch}
