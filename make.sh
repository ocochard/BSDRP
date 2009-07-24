#!/bin/sh
#
# Make script for BSD Router Project 
#
# Copyright (c) 2009, The BSDRP Development Team 
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

#############################################
############ Variables definition ###########
#############################################

# Uncomment for enable debug: 
#set -x

# Exit if error
#set -e

FREEBSD_SRC=/usr/src/
NANOBSD_DIR=/usr/src/tools/tools/nanobsd

#Compact flash database needed for NanoBSD ?
#cp $NANOBSD_DIR/FlashDevice.sub .

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

if [ "${NANOBSD_DIR}/BSDRP" != `pwd` ]
then
	pprint 1 "You need to install BSDRP source code in ${NANOBSD_DIR}/BSDRP"
	exit 1
fi
}

check_system() {
#### Check prerequisites

pprint 3 "Checking if FreeBSD-current sources are installed..."
SRC_VERSION=0
grep -q 'REVISION="8.0"' ${FREEBSD_SRC}/sys/conf/newvers.sh
if [ $? -eq 0 ]
then
	SRC_VERSION="8.0"
fi
grep -q 'REVISION="7.2"' ${FREEBSD_SRC}/sys/conf/newvers.sh
if [ $? -eq 0 ]
then
    SRC_VERSION="7.2"
fi

if [ ${SRC_VERSION} = 0 ]
then
	pprint 1 "BSDRP need FreeBSD 8.0-current or 7.2 sources"
	pprint 1 "And source file vimage.h (introduce in FreeBSD-current) not found"
	pprint 1 "Read HOW TO here:"
	pprint 1 "http://bsdrp.net/documentation/technical_docs"
	exit 1
fi

pprint 3 "Will generate a BSDRP image based on FreeBSD ${SRC_VERSION}"
pprint 3 "Checking if ports sources are installed..."

if [ ! -d /usr/ports/net/quagga ]
then
	pprint 1 "BSDRP need up-to-date FreeBSD ports sources tree"
	pprint 1 "And it seems that you didn't install the ports source tree"
        pprint 1 "Read HOW TO here:"
        pprint 1 "http://bsdrp.net/documentation/technical_docs"
	exit 1
fi
}

system_patch() {
###### Adding patch to NanoBSD 

# Adding BSDRP label patch to NanoBSD
# NanoBSD image use fixed boot disk: ad0, da0, etc...
# This is a big limitation for a "generic" image that can be installed
# on a USB (da0) or on an hard drive (ad0).
# If FreeBSD 7.2 source code detected, download latest nanobsd.sh script

if [ ${SRC_VERSION} = "7.2" ]
then
	if [ ! -f ../nanobsd.bak.7_2 ]
	then
		pprint 3 "Downloading new nanobsd.sh script"
		(
		cd ..
		mv nanobsd.sh nanobsd.bak.7_2
		fetch -o nanobsd.sh "http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/src/tools/tools/nanobsd/nanobsd.sh?rev=1.28.2.4"
		if [ ! $? -eq 0 ]
		then
			mv nanobsd.bak.7_2 nanobsd.sh
			pprint 3 "Error for downloading latest nanobsd.sh script"
			exit 1
		fi
		)
	fi
fi
pprint 3 "Checking in NanoBSD allready glabel patched"
grep -q 'GLABEL' ${NANOBSD_DIR}/nanobsd.sh
if [ $? -eq 0 ] 
then
	pprint 3 "NanoBSD allready glabel patched"
else
	pprint 3 "Patching NanoBSD with glabel support"
	patch ${NANOBSD_DIR}/nanobsd.sh nanobsd.glabel.patch
fi

# Adding amd64 support to NanoBSD:
if [ "$TARGET_ARCH" = "amd64"  ]
then
	pprint 3 "Checking in NanoBSD allready amd64 patched"
	grep -q 'amd64' ${NANOBSD_DIR}/nanobsd.sh
	if [ $? -eq 0 ] 
	then
		pprint 3 "NanoBSD allready amd64 patched"
	else
		pprint 3 "Patching NanoBSD with amd64 support"
		patch ${NANOBSD_DIR}/nanobsd.sh nanobsd.amd64.patch
	fi
fi

# Adding another cool patch that fix a lot's of problem
# http://www.freebsd.org/cgi/query-pr.cgi?pr=136889
pprint 3 "Checking in NanoBSD allready PR-136889 patched"
grep -q 'NANO_BOOT2CFG' ${NANOBSD_DIR}/nanobsd.sh
if [ $? -eq 0 ] 
then
	pprint 3 "NanoBSD allready PR-136889 patched"
else
	pprint 3 "Patching NanoBSD with some fixes (PR-136889)"
	patch ${NANOBSD_DIR}/nanobsd.sh nanobsd.pr-136889.patch
fi

}

check_clean() {
##### Check if previous NanoBSD make stop correctly by unoumt all tmp mount
# Need to optimize this code
mount > /tmp/BSDRP.mnt
grep -q 'BSDRP' /tmp/BSDRP.mnt
if [ $? -eq 0 ] 
then
	pprint 1 "Unmounted NanoBSD works directory found"
	pprint 1 "This can create a bug that delete all your /usr/src directory"
	pprint 1 "Unmount manually theses mount points"
	rm /tmp/BSDRP.mnt
	exit 1
fi
rm /tmp/BSDRP.mnt

}

# Ask some questions to the user
get_user_input () {

pprint 1 "Type of BSDRP image to generate ( full / upgrade ) ? "
pprint 1 " - full : Image of the complete disk, to be used for installation"
pprint 1 " - upgrade : Image for the upgrade tool only"
while [ "$IMG_TYPE" != "full" -a "$IMG_TYPE" != "upgrade" ]
do
	read IMG_TYPE <&1
done

pprint 1 "Target architecture ( i386 / amd64 ) ? "
while [ "$TARGET_ARCH" != "i386" -a "$TARGET_ARCH" != "amd64" ]
do
	read TARGET_ARCH <&1
done

# This variable is needed earlier for generating the BSDRP nano config file
export TARGET_ARCH

pprint 1 "Console type for boot message:"
pprint 1 " - vga : vga only"
pprint 1 " - dual : vga and serial (BUGGY and serial port mandatory!)"
pprint 1 " - serial : serial only"
while [ "$INPUT_CONSOLE" != "vga" -a "$INPUT_CONSOLE" != "serial" -a "$INPUT_CONSOLE" != "dual" ]
do
	read INPUT_CONSOLE <&1
done

#pprint 1 "Storage media ? "
#pprint 1 "ad0 : For ATA hard drive, CF on IDE adapter, etc."
#pprint 1 "da0 : For USB device."
#while [ "$STORAGE_TYPE" != "ad0" -a "$STORAGE_TYPE" != "da0" ]
#do
#	read STORAGE_TYPE <&1
#done

if [ "$IMG_TYPE" = "full" ]
then
	pprint 1 "Zip the BSDRP image ( y / n ) ? "
	pprint 1 "Reduce the 600Mb image file to about 70Mb"
	while [ "$ZIP_IMAGE" != "y" -a "$ZIP_IMAGE" != "n" ]
	do
		read ZIP_IMAGE <&1
	done
fi

pprint 1 "If you had allready build an BSDRP image, you can skip the build process." 
pprint 1 "Do you want to SKIP build world and kernel ( y / n ) ? "

while [ "$SKIP_REBUILD" != "y" -a "$SKIP_REBUILD" != "n" ]
do
	read SKIP_REBUILD <&1
done

}
#############################################
############ Main code ######################
#############################################

pprint 1 "BSD Router Project image build script"
pprint 1 ""

check_current_dir
check_system
check_clean

get_user_input

system_patch

# Copy the common nanobsd configuration file to /tmp
cp -v BSDRP.nano /tmp/BSDRP.nano

# And add the customized variable to the nanobsd configuration file
echo "############# Variable section (generated by BSDRP make.sh) ###########" >> /tmp/BSDRP.nano

echo "# The default name for any image we create." >> /tmp/BSDRP.nano
echo "NANO_IMGNAME=\"BSDRP-full-${TARGET_ARCH}-${INPUT_CONSOLE}.img\"" >> /tmp/BSDRP.nano
echo "# The drive name of the media at runtime" >> /tmp/BSDRP.nano
#echo "NANO_DRIVE=$STORAGE_TYPE" >> /tmp/BSDRP.nano

echo "# Kernel config file to use" >> /tmp/BSDRP.nano

case $TARGET_ARCH in
	"amd64") echo "NANO_KERNEL=BSDRP-AMD64" >> /tmp/BSDRP.nano
		echo "NANO_ARCH=amd64"  >> /tmp/BSDRP.nano
		pprint 3 "Copying ${TARGET_ARCH} Kernel configuration file"
		case ${SRC_VERSION} in
		"8.0")
			cp -v BSDRP-AMD64.8_0 /usr/src/sys/amd64/conf/BSDRP-AMD64
			;;
		"7.2")
			cp -v BSDRP-AMD64.7_2 /usr/src/sys/amd64/conf/BSDRP-AMD64
			;;
		esac
		;;
	"i386") echo "NANO_KERNEL=BSDRP-I386" >> /tmp/BSDRP.nano
		echo "NANO_ARCH=i386"  >> /tmp/BSDRP.nano
		pprint 3 "Copying ${TARGET_ARCH} Kernel configuration file"
		case ${SRC_VERSION} in
		"8.0")
			cp -v BSDRP-I386.8_0 /usr/src/sys/i386/conf/BSDRP-I386
			;;
		"7.2")
			cp -v BSDRP-I386.7_2 /usr/src/sys/i386/conf/BSDRP-I386
			;;
		esac
		;;
esac

echo "# Bootloader type"  >> /tmp/BSDRP.nano

case $INPUT_CONSOLE in
	"dual") echo "NANO_BOOTLOADER=\"boot/boot0\"" >> /tmp/BSDRP.nano 
	echo "#Configure dual vga/serial console port" >> /tmp/BSDRP.nano
	echo "customize_cmd bsdrp_console_dual" >> /tmp/BSDRP.nano
;;

	"vga") echo "NANO_BOOTLOADER=\"boot/boot0\"" >> /tmp/BSDRP.nano 
	echo "#Configure vga only console port" >> /tmp/BSDRP.nano
	echo "customize_cmd bsdrp_console_vga" >> /tmp/BSDRP.nano
;;
	"serial") echo "NANO_BOOTLOADER=\"boot/boot0sio\"" >> /tmp/BSDRP.nano
	echo "#Configure serial console port" >> /tmp/BSDRP.nano
	echo "customize_cmd bsdrp_console_serial" >> /tmp/BSDRP.nano
;;
esac

# Start nanobsd using the BSDRP configuration file
pprint 1 "Launching NanoBSD build process..."
if [ "$SKIP_REBUILD" = "y" ]
then
	sh ../nanobsd.sh -b -c /tmp/BSDRP.nano
else
	sh ../nanobsd.sh -c /tmp/BSDRP.nano
fi

# Testing exit code of NanoBSD:

if [ $? -eq 0 ] 
then
	pprint 1 "NanoBSD build finish successfully."
else
	pprint 1 "NanoBSD meet an error, check the log files here:"
	pprint 1 "/usr/obj/nanobsd.BSDRP/"	
	pprint 1 "An error during the buildworld or buildkernel stage can be caused by"
	pprint 1 "a bug in the FreeBSD-current code"	
	pprint 1 "try to re-sync your code" 
	exit 1
fi


if [ "$IMG_TYPE" = "upgrade" ]
then
	pprint 1 "Zipping the BSDRP upgrade image..." 
	mv /usr/obj/nanobsd.BSDRP/_.disk.image /usr/obj/nanoBSDRP/BSDRP-upgrade-${TARGET_ARCH}-${INPUT_CONSOLE}.img
	bzip2 -9v /usr/obj/nanobsd.BSDRP/BSDRP-upgrade-${TARGET_ARCH}-${INPUT_CONSOLE}.img
        pprint 1 "You will found the zipped BSDRP upgrade image file here:"
        pprint 1 "/usr/obj/nanobsd.BSDRP/BSDRP-upgrade-${TARGET_ARCH}-${INPUT_CONSOLE}.img.bz2"
else
	if [ "$ZIP_IMAGE" = "y" ] 
	then
		pprint 1 "Zipping the BSDRP full image..." 
		bzip2 -9v /usr/obj/nanobsd.BSDRP/BSDRP-full-${TARGET_ARCH}-${INPUT_CONSOLE}.img
        	pprint 1 "You will found the zipped BSDRP full image file here:"
        	pprint 1 "/usr/obj/nanobsd.BSDRP/BSDRP-${TARGET_ARCH}-${INPUT_CONSOLE}.img.bz2"
	else
		pprint 1 "You will found the BSDRP full image file here:"
        	pprint 1 "/usr/obj/nanobsd.BSDRP/BSDRP-full-${TARGET_ARCH}-${INPUT_CONSOLE}.img"
	fi
fi

exit 0
