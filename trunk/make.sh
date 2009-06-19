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

check_system() {
#### Check prerequisites
if [ $SYSTEM_RELEASE != $SYSTEM_REQUIRED ]
then
        pprint 1 "BSDRP need an up-to-date FreeBSD $SYSTEM_REQUIRED"
	pprint 1 "And you have a $SYSTEM_RELEASE"
	exit 1
fi

pprint 3 "Checking if FreeBSD sources are installed..."
if [ -d "$NANOBSD_DIR" ]
then
	pprint 3 "NanoBSD detected (sources installed)"
else
	pprint 1 "NanoBSD directory ($NANOBSD_DIR) not found"
	pprint 1 "Did you installed FreeBSD sources ?"
	exit
fi

}

system_patch() {
###### Adding patch to NanoBSD if needed
pprint 3 "Checking in NanoBSD allready patched"
if !grep -q amd64 $NANOBSD_DIR/nanobsd fic1 && [ $TARGET_ARCH = "amd64" ]
then
	pprint 3 "Patching NanoBSD with target amd64 support"	
	patch $NANOBSD_DIR/nanobsd nanobsd.patch
fi
}
#############################################
########### Main code ######################
############################################

pprint 1 "Experimental (not working) BSDRP Make file"

check_system

echo "BSDRP build script"
echo ""
echo "Enter target architecture (i386/amd64): "
while [ $TARGET_ARCH != "i386" ]
do
	read TARGET_ARCH <&1
done

echo "Enter default console (vga/serial): "
while ( INPUT_CONSOLE="vga" || "serial" )
do
	read INPUT_CONSOLE <&1
done

system_patch

#sh $NANOBSD_DIR/nanobsd.sh -b -c BSDRP.nano
#sh ../nanobsd.sh -c BSDRP.nano
exit 0
