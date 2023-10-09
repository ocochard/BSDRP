#!/bin/sh
#
# Not all WITHOUT_ options are correctly applied during image generation

# XXX Need to build /usr/src/tools/tools/netrate/netblast&netreceive

# If port related, it is recommanded to add list of file in the pkg.conf file
# That will avoid installing files during packages installation
TO_REMOVE='
/usr/local/sbin/pkg-static
usr/include
usr/local/include
'

if [ -z "${WORLDDIR}" ]; then
	echo "ERROR: Empty variable WORLDDIR"
	exit 1
fi

for i in ${TO_REMOVE}; do
	if [ -e ${WORLDDIR}/$i ]; then
		rm -rf ${WORLDDIR}/$i
	fi
done
