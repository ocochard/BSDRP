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
# An usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

[ ! -d BSDRP ] && die "This script need to be executed from the main BSDRP dir"
[ ! -x make.sh ] && die "This script need to be executed from the main BSDRP dir"

# List of SVN revision to build image for
SVN_REV_LIST='
244900
247463
249330
'

# Name of the BSDRP project
# TESTING project is a very small (should build fast)
PROJECT="TESTING"
CONSOLE="serial"
ARCH="amd64"

for SVN_REV in ${SVN_REV_LIST}; do
	echo "Building image matching revsion ${SVN_REV}..."
	#Configuring SVN revision in $PROJECT/make.conf and in version
	sed -i "" -e "/SRC_REV=/s/.*/SRC_REV=${SVN_REV}/" $PROJECT/make.conf
	echo ${SVN_REV} > $PROJECT/Files/etc/version
	set +e
	./make.sh -p TESTING -u -y -f -a ${ARCH} -c ${CONSOLE} > /dev/null 2>&1
	set -e
	if [ ! -f /usr/obj/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}-full-${ARCH}-${CONSOLE}.img ]; then
			die "Where are /usr/obj/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}-full-${ARCH}-${CONSOLE}.img ???"
	fi
	mv /usr/obj/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}* /tmp
done

echo "All images put in /tmp"
