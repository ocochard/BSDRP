#!/bin/sh
#
# Bisection script for BSD Router Project
# https://bsdrp.net
#
# Purpose:
#  This script permit to build multiple image regarding a given list of svn revision number.
#  Coupled to an auto-bench script, this permit to found regression in -current code as example.
#  It can use a phabricator review ID too, and generate 2 images: Once with the patch and one without
#

set -eu

### Variables ###
IMAGES_DIR=""
PHABRID=""
# Name of the BSDRP project
# TESTING project is a very small (should build fast)
# Set PROJECT variable like this example:
# env ARCH=i386 tools/bisection-gen.sh
: ${PROJECT:=TESTING}
: ${CONSOLE:=serial}
: ${ARCH:=amd64}

# Enable TMPFS
TMPFS=true

if (${TMPFS}); then
	TMPOPT="-r"
	OBJDIR="/tmp/obj"
else
	TMPOPT=""
	OBJDIR="/usr/obj"
fi

### Functions ###

# An usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

usage() {
	echo "$0 nanobsd-images-dir [phabricator-id]"
	exit 0
}

# Build image
# $1 Revision number
# $2 file image extension (same as revision if empty)
build_project() {
	[ $# -lt 1 ] && die "BUG during build_project() call, missing argument"
	SVN_REV=$1
	FILENAME=$1
	[ $# -eq 2 ] && FILENAME=$2
	echo -n "Building image matching revision ${SVN_REV}..."
	if [ -f ${IMAGES_DIR}/BSDRP-${FILENAME}-upgrade-${ARCH}-${CONSOLE}.img ]; then
		echo "Already existing"
		return 0
	elif [ -f ${IMAGES_DIR}/BSDRP-${FILENAME}-upgrade-${ARCH}-${CONSOLE}.img.xz ]; then
		echo "Already existing"
		return 0
	fi
	#Configuring SVN revision in $PROJECT/make.conf and in version
	sed -i "" -e "/SRC_REV=/s/.*/SRC_REV=${SVN_REV}/" $PROJECT/make.conf
	[ ! -d $PROJECT/Files/etc ] && mkdir -p $PROJECT/Files/etc
	echo ${SVN_REV} > $PROJECT/Files/etc/version
	./make.sh -p ${PROJECT} -C -u -y -a ${ARCH} -c ${CONSOLE} ${TMPOPT} > ${IMAGES_DIR}/bisec.log 2>&1 && true
	if [ ! -f ${OBJDIR}/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}-full-${ARCH}-${CONSOLE}.img.xz ]; then
			echo "Where are ${OBJDIR}/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}-full-${ARCH}-${CONSOLE}.img.xz ?"
			echo "Check error message in ${IMAGES_DIR}/bisec.log.${SVN_REV}"
			for i in _.bw _.bk _.iw _.ik; do
				[ -f ${OBJDIR}/${PROJECT}.${ARCH}/$i ] && mv ${OBJDIR}/${PROJECT}.${ARCH}/$i ${IMAGES_DIR}/bisec.log.$i.${FILENAME}
			done
			mv ${IMAGES_DIR}/bisec.log ${IMAGES_DIR}/bisec.log.${FILENAME}
			return 0
	fi
	for i in full-${ARCH}-${CONSOLE}.img.xz upgrade-${ARCH}-${CONSOLE}.img.xz debug-${ARCH}.tar.xz ${ARCH}-${CONSOLE}.mtree.xz ; do
		mv ${OBJDIR}/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}-$i ${IMAGES_DIR}/BSDRP-${FILENAME}-$i
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

# Some little check

[ ! -d BSDRP ] && die "This script need to be executed from the main BSDRP dir"
[ ! -x make.sh ] && die "This script need to be executed from the main BSDRP dir"
[ ! -d ${IMAGES_DIR} ] && die "Can't found destination dir for storing images"

if [ -z "${PHABRID}" ]; then
	# List of SVN revision to build image for
	# For each image by week
	#  svnlite log | grep 'r.*|.*|.*(Sun'
	# 274745 to xxx
	# From Sunday 22 March, to each last commit of sundy of each week
	# and if build failed, take the last monday commit and if it failed again
	# take the last tusday commit
	#
	SVN_REV_LIST='
338437
338331
338074
337690
337363
336878
336617
336320
336114
335852
335610
335307
334933
334590
334260
333943
333587
333311
333092
332874
332518
332305
331869
331537
331146
330783
330419
329993
329535
329142
328863
328519
328223
327975
327684
	'
	for SVN_REV in ${SVN_REV_LIST}; do
		build_project ${SVN_REV}
	done
else
	cd ${PROJECT}/FreeBSD/src
	SVN_REV=$(svn up | tail -n 1 | grep revision | cut -d ' ' -f 3 | cut -d '.' -f 1)
	cd ../../..
	[ -z "${SVN_REV}" ] && die "Didn't found revision number"
	[ -f /tmp/bench-lab-patch.txt ] && rm /tmp/bench-lab-patch.txt
	fetch -o /tmp/bench-lab-patch.txt "https://reviews.freebsd.org/${PHABRID}?download=true" || die "Can't download Phabricator patch"
	grep -q 'DOCTYPE html' /tmp/bench-lab-patch.txt && die "Seems not a good patch (check /tmp/bench-lab-patch.txt)"
	build_project ${SVN_REV}
	[ -d ${PROJECT}/patches ] || mkdir ${PROJECT}/patches
	mv /tmp/bench-lab-patch.txt ${PROJECT}/patches/freebsd.${PHABRID}.patch
	build_project ${SVN_REV} ${SVN_REV}${PHABRID}
	rm ${PROJECT}/patches/freebsd.${PHABRID}.patch
fi


echo "All images were put in ${IMAGES_DIR}"
(${TMPFS}) && echo "Don't forgot to unmount ${OBJDIR}"
