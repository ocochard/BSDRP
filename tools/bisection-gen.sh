#!/bin/sh
#
# Bisection script for BSD Router Project
# https://bsdrp.net
#
# Purpose:
#  Builds one BSDRP image per FreeBSD source git hash in a list.
#  Coupled to an auto-bench script, this permits finding a regression in
#  FreeBSD -current code, for example.
#  It can use a Phabricator review ID too, generating 2 images: one with the
#  patch applied and one without.
#
#  The build is driven by the top-level Makefile: the FreeBSD hash to build is
#  written into Makefile.vars (FreeBSD_hash), then `make MACHINE_ARCH=$ARCH
#  release` produces the compressed images under poudriere's images dir.
#

set -eu

### Variables ###
IMAGES_DIR=""
PHABRID=""
: ${ARCH:=amd64}

# Where the top-level Makefile drops compressed images:
# ${BASEFS}/data/images/BSDRP-${VERSION}-<flavour>-${ARCH}.<ext>
BASEFS="$(grep '^BASEFS=' /usr/local/etc/poudriere.conf | cut -d '=' -f 2)"
[ -z "${BASEFS}" ] && BASEFS="/usr/local/poudriere"
POUDRIERE_IMAGES_DIR="${BASEFS}/data/images"

### Functions ###

# Error handling function - prints error message and exits
# Arguments:
#   $@: Error message to display
# Returns: exits with code 1
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# Display usage information and command line help
# Arguments: none
# Returns: exits with code 0
usage() {
	echo "$0 images-dir [phabricator-id]"
	echo "  env vars: ARCH (default amd64)"
	exit 0
}

# Build BSDRP image for a specific FreeBSD source git hash
# Arguments:
#   $1: FreeBSD source git hash to build
#   $2: File image suffix (optional, defaults to the hash)
# Returns: 0 on success (or already-built/build-failed, logged), exits on setup error
build_project() {
	[ $# -lt 1 ] && die "BUG during build_project() call, missing argument"
	SRC_HASH=$1
	FILENAME=$1
	[ $# -eq 2 ] && FILENAME=$2
	echo -n "Building image matching FreeBSD hash ${SRC_HASH}..."
	if [ -f ${IMAGES_DIR}/BSDRP-${FILENAME}-full-${ARCH}.img.xz ]; then
		echo "Already existing"
		return 0
	fi
	# Pin the FreeBSD source hash the Makefile checks out. The update-src-FreeBSD
	# recipe compares this against the checked-out tree and re-checks-out on change.
	sed -i "" -e "/^FreeBSD_hash?*=/s|.*|FreeBSD_hash?=${SRC_HASH}|" Makefile.vars
	make MACHINE_ARCH=${ARCH} release > ${IMAGES_DIR}/bisec.log 2>&1 && true
	# The image name embeds VERSION (from BSDRP/Files/etc/version), not the hash,
	# so glob the freshly produced full image.
	BUILT_IMG=$(ls -t ${POUDRIERE_IMAGES_DIR}/BSDRP-*-full-${ARCH}.img.xz 2>/dev/null | head -n 1)
	if [ -z "${BUILT_IMG}" ] || [ ! -f "${BUILT_IMG}" ]; then
		echo "failed"
		echo "No full image produced in ${POUDRIERE_IMAGES_DIR} for hash ${SRC_HASH}"
		echo "Check error messages in ${IMAGES_DIR}/bisec.log.${FILENAME}"
		mv ${IMAGES_DIR}/bisec.log ${IMAGES_DIR}/bisec.log.${FILENAME}
		return 0
	fi
	# Rename each produced flavour to carry the bisection FILENAME suffix.
	VERSION=$(cat BSDRP/Files/etc/version)
	for flavour in full-${ARCH}.img.xz upgrade-${ARCH}.img.xz debug-${ARCH}.tar.xz ${ARCH}.mtree.xz; do
		src="${POUDRIERE_IMAGES_DIR}/BSDRP-${VERSION}-${flavour}"
		[ -f "${src}" ] && mv "${src}" "${IMAGES_DIR}/BSDRP-${FILENAME}-${flavour}"
	done

	echo "done"
	return 0
}

### Main ###
if [ $# -lt 1 ]; then
	usage
fi

IMAGES_DIR="$1"
[ $# -eq 2 ] && PHABRID="$2"

# Some little checks
[ ! -d BSDRP ] && die "This script needs to be executed from the main BSDRP dir"
[ ! -f Makefile.vars ] && die "This script needs to be executed from the main BSDRP dir"
[ ! -d ${IMAGES_DIR} ] && die "Can't find destination dir for storing images"

if [ -z "${PHABRID}" ]; then
	# List of FreeBSD source git hashes to build an image for.
	# Populate with the hashes spanning the regression window, e.g. from
	#   git -C obj/FreeBSD/src log --oneline <good>..<bad>
	SRC_HASH_LIST='
	'
	[ -z "$(echo ${SRC_HASH_LIST})" ] && die "SRC_HASH_LIST is empty: edit the script and add FreeBSD git hashes to bisect"
	for SRC_HASH in ${SRC_HASH_LIST}; do
		build_project ${SRC_HASH}
	done
else
	# Build the current pinned hash twice: once clean, once with the Phabricator patch.
	SRC_HASH=$(grep '^FreeBSD_hash?*=' Makefile.vars | cut -d '=' -f 2)
	[ -z "${SRC_HASH}" ] && die "Didn't find FreeBSD_hash in Makefile.vars"
	[ -f /tmp/bench-lab-patch.txt ] && rm /tmp/bench-lab-patch.txt
	fetch -o /tmp/bench-lab-patch.txt "https://reviews.freebsd.org/${PHABRID}?download=true" || die "Can't download Phabricator patch"
	grep -q 'DOCTYPE html' /tmp/bench-lab-patch.txt && die "Seems not a good patch (check /tmp/bench-lab-patch.txt)"
	build_project ${SRC_HASH}
	mv /tmp/bench-lab-patch.txt BSDRP/patches/freebsd.${PHABRID}.patch
	build_project ${SRC_HASH} ${SRC_HASH}${PHABRID}
	rm BSDRP/patches/freebsd.${PHABRID}.patch
fi


echo "All images were put in ${IMAGES_DIR}"
