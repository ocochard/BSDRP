#!/bin/sh
#
# BSDRP review image generation script
# Builds comparison images for FreeBSD Phabricator reviews
#
# Purpose:
#   Creates two TESTING project images for patch comparison:
#   1. Reference image without the review patch
#   2. Patched image with the review applied
#
# Workflow:
#   - Downloads patch from FreeBSD Phabricator review system
#   - Builds baseline image from current sources
#   - Applies patch and builds modified image
#   - Stores both images for testing and comparison
#
# Arguments:
#   -r REVIEW-ID: FreeBSD Phabricator review identifier (e.g., D12345)
#
# Returns: 0 on success, exits on build failure

set -eu
REVIEW=""

# Update source for TESTING (re-using update script)
# Check for unwanted patches (git status | remove?)
# make directory and build reference and patched images

# Display usage information and command line help
# Arguments: none
# Returns: exits with code 0
usage () {
	echo "Usage: $0 -r REVIEW-ID"
	exit 0
}

### Main function ###

[ $# -lt 1 ] && usage

while getopts "r:" FLAG; do
	case "${FLAG}" in
	r)
		REVIEW="$OPTARG"
		;;
	*)
		break
	esac
done

shift $((OPTIND-1))

[ -z "${REVIEW}" ] && usage

# Start by downloading patchs and check it before launching build
fetch -o freebsd.${REVIEW}.patch https://reviews.freebsd.org/${REVIEW}?download=true

mkdir /root/images/${REVIEW}
git clean -fd TESTING/patches/
tools/update-svn.sh TESTING
REV=$(grep -E '^SRC_REV=' TESTING/make.conf | cut -d '"' -f 2)
echo "r${REV}" > TESTING/Files/etc/version
./make.sh -c serial -p TESTING -u
mv workdir/TESTING.amd64/BSDRP-r${REV}-* /root/images/${REVIEW}
mv freebsd.${REVIEW}.patch TESTING/patches/
echo "r${REV}${REVIEW}" > TESTING/Files/etc/version
./make.sh -c serial -p TESTING -u
mv workdir/TESTING.amd64/BSDRP-r${REV}${REVIEW}-* /root/images/${REVIEW}

