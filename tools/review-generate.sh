#!/bin/sh
# Generate images from a review DXXXX number:
# 2 images using the TESTING (current with minimum patches applied)
# one without the DXXX patchs and another with the patch

set -eu
REVIEW=""

# Update source for TESTING (re-using update script)
# Check for unwanted patches (git status | remove?)
# make directory and build reference and patched images

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

