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
236884
238516
238573
238851
238763
238770
238987
238990
239774
240232
240233
241610
241909
241913
241955
241923
242014
242082
242160
242161
242311
242336
242361
242386
242395
242401
242402
242404
242413
242434
242462
242463
242623
242624
243443
244323
244585
244900
245423
246146
246482
246520
246710
246792
247463
247916
248267
248584
248830
248944
248975
249022
249052
249094
249163
249330
249506
249908
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
