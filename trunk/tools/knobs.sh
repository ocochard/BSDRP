#!/bin/sh
# A little script that generate file list of a "make installworld"
#   using all knobs in /usr/src/tools/build/options

# Exit if error
set -e

WORKING_DIR=/tmp/knob-list

# Function that delete destdir if exist
clean_destdir () {
	if [ -d ${WORKING_DIR}/$1 ]; then
    	chflags -R noschg ${WORKING_DIR}/$1
    	rm -rf ${WORKING_DIR}/$1
	fi
}

# TODO:
# - Check root ?
#

if [ ! -d /usr/obj/usr/src/ ]; then
	echo "You need to do a make buildworld (with an empty make.conf and src.conf) before"
	exit 1
fi
# Cleanup
if [ ! -d ${WORKING_DIR} ]; then
	mkdir ${WORKING_DIR}
fi

if [ -f ${WORKING_DIR}/WITHOUT.list ]; then
	rm ${WORKING_DIR}/WITHOUT.list
fi

# Put all WITHOUT in a file
(
cd /usr/src/tools/build/options/
for WITHOUT_KNOB in WITHOUT_* 
do
	echo $WITHOUT_KNOB >> ${WORKING_DIR}/WITHOUT.list
done;
)

# Generating the reference file if not allready exist

if [ ! -f ${WORKING_DIR}/WITH_ALL.list ]; then
	clean_destdir WITH_ALL
	mkdir ${WORKING_DIR}/WITH_ALL
	(cd /usr/src; make installworld DESTDIR=${WORKING_DIR}/WITH_ALL)
	(cd ${WORKING_DIR}/WITH_ALL; find . > ${WORKING_DIR}/WITH_ALL.list)
	clean_destdir WITH_ALL
fi

# Began the long installworld loop
for KNOB in $(cat ${WORKING_DIR}/WITHOUT.list)
do
	# This if can be remove (It's a rapid fix because I've udpated my script between 2 runs)	
	if [ ! -f ${WORKING_DIR}/${KNOB}.list ]; then
		clean_destdir $KNOB
		mkdir ${WORKING_DIR}/${KNOB}
		(cd /usr/src; make installworld ${KNOB}=YES DESTDIR=${WORKING_DIR}/${KNOB})
		(cd ${WORKING_DIR}/${KNOB}; find . > ${WORKING_DIR}/${KNOB}.list)
		clean_destdir $KNOB
	fi
	# Generate a more readable file list that show file removed:
	if ! diff -u ${WORKING_DIR}/WITH_ALL.list ${WORKING_DIR}/${KNOB}.list | grep -e '-./' > ${WORKING_DIR}/${KNOB}.txt; then
		echo "No difference detected: knobs related to a make buildworld, kernel or doesn' have effect yet" >> ${WORKING_DIR}/${KNOB}.txt	
	fi
done;

