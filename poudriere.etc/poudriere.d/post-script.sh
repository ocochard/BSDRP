#!/bin/sh
#
# Not all WITHOUT_ options are correctly use during image generation

# XXX Need to build /usr/src/tools/tools/netrate/netblast&netreceive

# XXX Need to extract debug symbols first
TO_REMOVE='
usr/sbin/config
usr/lib/debug
usr/sbin/bsdconfig
usr/share/bsdconfig
usr/share/bhyve
usr/share/examples
usr/share/flua
usr/share/doc
usr/share/man/man3
usr/share/man/man3lua
usr/share/man/man9
usr/share/mk
usr/share/openssl
usr/include
usr/share/misc/magic.mgc
usr/share/misc/termcap.db
usr/local/include
'

if [ -z "${WORLDDIR}" ]; then
	echo "ERROR: Empty variable WORLDDIR"
	exit 1
fi

#for i in ${TO_REMOVE}; do
#	if [ -e ${WORLDDIR}/$i ]; then
#		rm -rf ${WORLDDIR}/$i
#	fi
#done

# Kill all .a's that are installed with TOOLCHAIN (remove 33MB)
#find ${WORLDDIR} -type f -name \*.a | xargs rm
