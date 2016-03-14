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

[ ! -d BSDRP ] && die "This script need to be executed from the main BSDRP dir"
[ ! -x make.sh ] && die "This script need to be executed from the main BSDRP dir"
[ ! -d ${IMAGES_DIR} ] && die "Can't found destination dir for storing images"

# List of SVN revision to build image for
# For each image by week
#  svnlite log | grep 'r.*|.*|.*(Sun'
# 274745 to xxx
# From Sunday 22 March, to each last commit of sundy of each week
# and if build failed, take the last monday commit and if it failed again
# take the last tusday commit
# Failed:
#  278414
#  279508
#  279795
#  280126
# 283498
#  283502
# 284140
# 284392
# 284683
#  284701
# 290562
#  290622
# 290883
# 
SVN_REV_LIST='
276669
277034
277350
277717
278038
278477
278826
279189
279554
279828
280156
280357
280829
281121
281470
281752
282042
282369
282739
283035
283593
283841
284168
284739
284916
285173
285433
285702
285903
286213
286556
286833
287083
287314
287525
287767
288046
288311
288671
289159
289550
289951
290245
290665
290914
291164
291461
291909
292177
292519
292788
293120
293643
294235
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
			for i in _.bw _.bk _.iw _.ik; do
				[ -f /usr/obj/${PROJECT}.${ARCH}/$i ] && mv /usr/obj/${PROJECT}.${ARCH}/$i ${IMAGES_DIR}/bisec.log.$i.${SVN_REV}
			done
			mv ${IMAGES_DIR}/bisec.log ${IMAGES_DIR}/bisec.log.${SVN_REV}
			continue
	fi
	mv /usr/obj/${PROJECT}.${ARCH}/BSDRP-${SVN_REV}* ${IMAGES_DIR}
	echo "done"
done

echo "All images were put in ${IMAGES_DIR}"
