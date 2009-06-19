#!/bin/sh
# Experimental Make script for BSD Router Project

#############################################
############ Variables definition ###########
#############################################

# Uncomment for enable debug: 
#set -x

NANOBSD_DIR=/usr/src/tools/tools/nanobsd

#Compact flash database needed for NanoBSD ?
#cp $NANOBSD_DIR/FlashDevice.sub .

#TO DO: get actual pwd, and use it for NANOBSD variables
SYSTEM_REQUIRED='8.0-CURRENT'
SYSTEM_RELEASE=`uname -r`

# Progress Print level
PPLEVEL=3

#############################################
########### Function definition #############
#############################################

# Progress Print
#       Print $2 at level $1.
pprint() {
    if [ "$1" -le $PPLEVEL ]; then
        printf "%.${1}s %s\n" "#####" "$2"
    fi
}

check_current_dir() {
#### Check current dir

if [ "$NANOBSD_DIR/BSDRP" != `pwd` ]
then
	pprint 1 "You need to install source code of BSDRP in $NANOBSD_DIR/BSDRP"
	pprint 1 "Download BSDRP source with this command:"
	pprint 1 "cd /usr/src/tools/tools/nanobsd"
	pprint 1 "svn co https://bsdrp.svn.sourceforge.net/svnroot/bsdrp/trunk BSDRP"
	exit 1
fi
}

check_system() {
#### Check prerequisites

pprint 3 "Checking if FreeBSD-current sources are installed..."

if [ ! -f /usr/src/sys/sys/vimage.h  ]
then
	pprint 1 "BSDRP need up-to-date sources for FreeBSD-current"
	pprint 1 "And source file vimage.h (introduce in FreeBSD-current) not found"
	exit 1
fi

}

system_patch() {
###### Adding patch to NanoBSD if needed
if [ "$TARGET_ARCH" = "amd64"  ]
then
	pprint 3 "Checking in NanoBSD allready patched"
	grep -q 'amd64' $NANOBSD_DIR/nanobsd.sh
	if [ $? -eq 0 ] 
	then
		pprint 3 "NanoBSD allready patched"
	else
		pprint 3 "Patching NanoBSD with target amd64 support"
		patch $NANOBSD_DIR/nanobsd.sh nanobsd.patch
	fi
fi
}
#############################################
############ Main code ######################
#############################################

pprint 1 "Experimental (not working) BSDRP Make file"

check_current_dir
check_system

echo "BSDRP build script"
echo ""
echo "Enter target architecture ( i386 / amd64 ): "
while [ "$TARGET_ARCH" != "i386" -a "$TARGET_ARCH" != "amd64" ]
do
	read TARGET_ARCH <&1
done

echo "Enter default console ( vga / serial ): "
while [ "$INPUT_CONSOLE" != "vga" -a "$INPUT_CONSOLE" != "serial" ]
do
	read INPUT_CONSOLE <&1
done

system_patch

case $TARGET_ARCH in
	"amd64") echo "add amd64 custom";;
	"i386") echo "add i386 custom";;
esac

case $INPUT_CONSOLE in
	"vga") echo "add vga custom";;
	"serial") echo "add serial custom";;
esac
#sh $NANOBSD_DIR/nanobsd.sh -b -c BSDRP.nano
#sh ../nanobsd.sh -c BSDRP.nano
exit 0
