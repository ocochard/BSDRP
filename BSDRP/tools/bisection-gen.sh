#!/bin/sh
#
# Bisection script for BSD Router Project 
# http://bsdrp.net
# 
# Purpose:
#  This script permit to build multiple image regarding a given list of svn revision number.
#  Coupled to an auto-bench script, this permit to found regression in -current code as example 
#

set -eu

if [ $# -ne 1 ]; then
	echo "$0 nanobsd-images-dir"
	exit 1
else
	IMAGES_DIR="$1"
fi

# An usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# Some little check

[ ! -d BSDRP ] && die "This script need to be executed from the main BSDRP dir"
[ ! -x make.sh ] && die "This script need to be executed from the main BSDRP dir"
[ ! -d ${IMAGES_DIR} ] && die "Can't found destination dir for storing images"

# List of SVN revision to build image for
# Compile but didn't boot: 239091 to 239093
SVN_REV_LIST='
255202
255488
256185
256842
257482
258080
258675
259551
260224
260720
261395
261991
262867
'

# Name of the BSDRP project
# TESTING project is a very small (should build fast)
PROJECT="TESTING"
CONSOLE="serial"
ARCH="amd64"

for SVN_REV in ${SVN_REV_LIST}; do
	echo -n "Building image matching revision ${SVN_REV}..."
	if [ -f ${IMAGES_DIR}/BSDRP-${SVN_REV}-upgrade-${ARCH}-${CONSOLE}.img ]; then
		echo "Already existing"
		continue
	elif [ -f ${IMAGES_DIR}/BSDRP-${SVN_REV}-upgrade-${ARCH}-${CONSOLE}.img.xz ]; then
		echo "Already existing"
		continue
	fi
	#Configuring SVN revision in $PROJECT/make.conf and in version
	sed -i "" -e "/SRC_REV=/s/.*/SRC_REV=${SVN_REV}/" $PROJECT/make.conf
	[ ! -d $PROJECT/Files/etc ] && mkdir -p $PROJECT/Files/etc
	echo ${SVN_REV} > $PROJECT/Files/etc/version
	set +e
	./make.sh -p TESTING -u -y -f -a ${ARCH} -c ${CONSOLE} > ${IMAGES_DIR}/bisec.log 2>&1
	set -e
	if [ ! -f /usr/obj/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}-full-${ARCH}-${CONSOLE}.img ]; then
			echo "Where are /usr/obj/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}-full-${ARCH}-${CONSOLE}.img ???"
			echo "Check error message in ${IMAGES_DIR}/bisec.log.${SVN_REV}"
			mv ${IMAGES_DIR}/bisec.log ${IMAGES_DIR}/bisec.log.${SVN_REV}
			continue
	fi
	mv /usr/obj/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}* ${IMAGES_DIR}
	echo "done"
done

echo "All images were put in ${IMAGES_DIR}"
