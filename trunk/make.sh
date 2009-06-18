#!/bin/sh
# Make script for BSD Router Project

# Uncomment for enable debug: 
#set -x

NANOBSD_DIR=/usr/src/tools/tools/nanobsd

#Flash database to copy
#TO DO: get actual pwd, and use it for NANOBSD variables

#TO DO: Check that we are under FreeBSD current

echo "BSDRP make script"
echo ""
echo "Enter architecture (i386/amd64): "
while INPUT_ARCH="i386" || "amd64"
do
	read INPUT_ARCH <&1
done

echo "Enter console type (vga/serial): "
while INPUT_CONSOLE="vga" || "serial"
do
	read INPUT_CONSOLE <&1
done
echo "Enter word:"
read word <&1
echo "$line $word"


#sh $NANOBSD_DIR/nanobsd.sh -b -c BSDRP.nano
#sh ../nanobsd.sh -c BSDRP.nano
