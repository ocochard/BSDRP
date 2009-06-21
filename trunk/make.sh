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
	pprint 1 "Read HOW TO here:"
	pprint 1 "http://bsdrp.net/documentation/technical_docs"
	exit 1
fi

pprint 3 "Checking if ports sources are installed…"

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
	else
		pprint 3 "Patching NanoBSD with target amd64 support"
		patch $NANOBSD_DIR/nanobsd.sh nanobsd.patch
		rm /tmp/BSDRP.mnt
	fi

}
#############################################
############ Main code ######################
#############################################

pprint 1 "BSD Router Project image generator"

check_current_dir
check_system
check_clean

pprint 1 "BSDRP build script"
pprint 1 ""
pprint 1 "What type of target architecture ( i386 / amd64 ) ? "
while [ "$TARGET_ARCH" != "i386" -a "$TARGET_ARCH" != "amd64" ]
do
	read TARGET_ARCH <&1
done

pprint 1 "What type of default console ( vga / serial ) ? "
while [ "$INPUT_CONSOLE" != "vga" -a "$INPUT_CONSOLE" != "serial" ]
do
	read INPUT_CONSOLE <&1
done

pprint 1 "What type of storage media will be used ? "
pprint 1 "ad0 : For ATA hard drive, CF on IDE adapter, etc."
pprint 1 "da0 : For USB device."
while [ "$STORAGE_TYPE" != "ad0" -a "$STORAGE_TYPE" != "da0" ]
do
	read STORAGE_TYPE <&1
done

pprint 1 "Do you want to gzip the BSDRP image ( y / n ) ? "
pprint 1 "This will reduce the 600Mb image file to about 80Mb (usefull for network transfert)"
while [ "$GZIP_IMAGE" != "y" -a "$GZIP_IMAGE" != "n" ]
do
	read GZIP_IMAGE <&1
done
pprint 1 "If you had allready build an BSDRP image, you can skip the build process." 
pprint 1 "Do you want to SKIP build world and kernel ( y / n ) ? "

while [ "$SKIP_REBUILD" != "y" -a "$SKIP_REBUILD" != "n" ]
do
	read SKIP_REBUILD <&1
done

system_patch

# Copy the common nanobsd configuration file to /tmp
cp -v BSDRP.nano /tmp/BSDRP.nano

# And add the customized variable to the nanobsd configuration file
echo "############# Variable section (generated by make.sh) ###########" >> /tmp/BSDRP.nano
echo "# The drive name of the media at runtime" >> /tmp/BSDRP.nano
echo "NANO_DRIVE=$STORAGE_TYPE" >> /tmp/BSDRP.nano

echo "# Kernel config file to use" >> /tmp/BSDRP.nano

case $TARGET_ARCH in
	"amd64") echo "NANO_KERNEL=BSDRP-AMD64" >> /tmp/BSDRP.nano
		echo "NANO_ARCH=amd64"  >> /tmp/BSDRP.nano
		pprint 3 "Copying amd64 Kernel configuration file"
		cp -v BSDRP-AMD64 /usr/src/sys/amd64/conf
		;;
	"i386") echo "NANO_KERNEL=BSDRP-I386" >> /tmp/BSDRP.nano
		echo "NANO_ARCH=i386"  >> /tmp/BSDRP.nano
		pprint 3 "Copying amd64 Kernel configuration file"
		cp -v BSDRP-I386 /usr/src/sys/i386/conf
		;;
esac

echo "# Bootloader type"  >> /tmp/BSDRP.nano

case $INPUT_CONSOLE in
	"vga") echo "NANO_BOOTLOADER=\"boot/boot0\"" >> /tmp/BSDRP.nano 
;;
	"serial") echo "NANO_BOOTLOADER=\"boot/boot0sio\"" >> /tmp/BSDRP.nano
	echo "#Configure console port" >> /tmp/BSDRP.nano
	echo "customize_cmd cust_comconsole" >> /tmp/BSDRP.nano
;;
esac

echo "# Late customize commands."  >> /tmp/BSDRP.nano

case $GZIP_IMAGE in
	"y") echo "NANO_LATE_CUSTOMIZE=\"gzip -9n \${NANO_DISKIMGDIR}/\${NANO_IMGNAME}\"" >> /tmp/BSDRP.nano 
;;
	"n") echo "NANO_LATE_CUSTOMIZE=\"\"" >> /tmp/BSDRP.nano

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
	pprint 1 "NanoBSD build finish, BSDRP image file is here"
	pprint 1 "/usr/obj/nanobsd.BSDRP/BSDRP.img"
else
	pprint 1 "NanoBSD meet an error, check the log files here:"
	pprint 1 "/usr/obj/nanobsd.BSDRP/"	
	pprint 1 "An error during the buildworld stage can be caused by"
	pprint 1 "a bug in the FreeBSD-current code"	
	pprint 1 "try to re-sync your code" 
fi

exit 0
