#!/bin/sh
#
# Qemu test script for BSD Router Project
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

#Uncomment for debug
#set -x

check_system () {
	if ! `uname -s | grep -q FreeBSD`; then
		echo "Error: This script was wrote for a FreeBSD"
		echo "You need to adapt it for other system"
		exit 1
	fi
	if ! `pkg_info -q -E -x qemu  > /dev/null 2>&1`; then
        echo "Error: qemu not found"
		echo "Install qemu: pkg_add -r qemu"
        exit 1
	fi

	if ! `pkg_info -q -E -x kqemu  > /dev/null 2>&1`; then
        echo "Warning: kqemu not found"
		echo "kqemu is not mandatory, but improve a lot the speed"
	fi

	if ! kldstat -m kqemu; then
		echo "Loading kqemu"
		if kldload kqemu; then
			echo "Can't load kqemu"
		fi
	fi
	if ! kldstat -m aio; then
        echo "Loading aio"
        if kldload aio; then
            echo "Can't load aio"
        fi
    fi

}

check_user () {
	if [ ! $(whoami) = "root" ]; then
		echo "You need to be root"
		exit 1
	fi	
}

check_image () {
	if [ ! -f ${FILENAME} ]; then
		echo "ERROR: Can't found the file ${FILENAME}"
		exit 1
	fi

    if `file -b ${FILENAME} | grep -q "bzip2 compressed data"  > /dev/null 2>&1`; then
        echo "Bzipped image detected, unzip it..."
		bunzip2 -k ${FILENAME}
		# change FILENAME by removing the last.bz2"
		FILENAME=`echo ${FILENAME} | sed -e 's/.bz2//g'`
    fi

	if ! `file -b ${FILENAME} | grep -q "boot sector"  > /dev/null 2>&1`; then
		echo "ERROR: Not a BSDRP image??"
		exit 1
	fi
	
	
}

# Creating interfaces
create_interfaces () {
	if ! `ifconfig | grep -q 10.0.0.254`; then
		echo "Creating admin bridge interface..."
		BRIDGE_IF=`ifconfig bridge create`
		if ! `ifconfig ${BRIDGE_IF} 10.0.0.254/24`; then
			echo "Can't set IP address on ${BRIDGE_IF}"
			exit 1
		fi
	else
		echo "Need to found the bridge number configured with 10.0.0.254"
	fi
	#Shared TAP interface for communicating with the host
   	echo "Creating admin tap interface..."
   	TAP_IF=`ifconfig tap create`

	# Link bridge with tap
	ifconfig ${BRIDGE_IF} addm ${TAP_IF} up
	ifconfig ${TAP_IF} up
}

# Creating interfaces for lAB mode
create_interfaces_lab () {
	if ! `ifconfig | grep -q 10.0.0.254`; then
		echo "Creating admin bridge interface..."
		BRIDGE_IF=`ifconfig bridge create`
		if ! `ifconfig ${BRIDGE_IF} 10.0.0.254/24`; then
			echo "Can't set IP address on ${BRIDGE_IF}"
			exit 1
		fi
	else
		echo "Need to found the bridge number configured with 10.0.0.254"
		exit 1
	fi
	#Shared TAP interface for communicating with the host
	echo "creating the 4 tap interfaces"
	i=1
	while [ $i -le 4 ]; do
    	echo "Creating admin tap interface..."
    	eval TAP_IF_${i}=`ifconfig tap create`

		# Link bridge with tap
		TAP_IF="TAP_IF_$i"
		TAP_IF=`eval echo $"${TAP_IF}"`
		ifconfig ${BRIDGE_IF} addm ${TAP_IF} up
		ifconfig ${TAP_IF} up
	i=`expr $i + 1`
	done
}

# Delete all admin interfaces create for lab mode
delete_interface_lab () {
	i=1
	while [ $i -le 4 ]; do
		TAP_IF="TAP_IF_$i"
		TAP_IF=`eval echo $"${TAP_IF}"`
    	ifconfig ${TAP_IF} destroy
    		i=`expr $i + 1`
	done
	ifconfig ${BRIDGE_IF} destroy

} 
# Parse filename for detecting ARCH and console
parse_filename () {
	QEMU_ARCH=0
	if echo "${FILENAME}" | grep -q "amd64"; then
		#QEMU_ARCH="qemu-system-x86_64 -m 256 -no-kqemu"
		QEMU_ARCH="qemu-system-x86_64 -m 256"
		echo "filename guests a x86_64 image"
		echo "Warning: Disable kqemu for using with the 64 bit image, because there is a bug running FreeBSD 7.2 as guest with kqemu"
		echo "Will remove this limitation when this bug will be fixed"
	fi
	if echo "${FILENAME}" | grep -q "i386"; then
        QEMU_ARCH="qemu -kernel-kqemu"
		echo "filename guests a i386 image"
    fi
	if [ "$QEMU_ARCH" = "0" ]; then
		echo "WARNING: Can't guests arch of this image"
		echo "Will use as default i386"
		QEMU_ARCH="qemu"
	fi
	QEMU_OUTPUT=0
	if echo "${FILENAME}" | grep -q "serial"; then
        QEMU_OUTPUT="-nographic"
        echo "filename guests a serial image"
		echo "Will use standard console as input/output"
    fi
    if echo "${FILENAME}" | grep -q "vga"; then
        QEMU_OUTPUT="-vnc :0"
		echo "filename guests a vga image"
        echo "Will start a VNC server on :0 for input/output"
    fi
    if [ "$QEMU_OUTPUT" = "0" ]; then
        echo "WARNING: Can't suppose default console of this image"
		echo "Will start a VNC server on :0 for input/output"
        QEMU_OUTPUT="-vnc :0"
    fi

}

usage () {
        (
        echo "Usage: $0 [-lh] -i BSDRP-full.img"
        echo "  -l      lab mode: start 4 qemu processs"
		echo "  -h      display this help"
		echo "  -i      specify BSDRP image name"
		echo ""
		echo "Note: In lab mode, the qemu process are started in snapshot mode,"
		echo "this mean that all write to BSDRP disks are not write into the image"
        ) 1>&2
        exit 2
}

###############
# Main script #
###############

### Parse argument

set +e
args=`getopt i:hl $*`
if [ $? -ne 0 ] ; then
        usage
        exit 2
fi
set -e

set -- $args
LAB_MODE=false
FILENAME=""
for i
do
        case "$i" 
        in
        -l)
                LAB_MODE=true
                shift
                ;;
        -h)
                usage
                ;;
		-i)
				FILENAME="$2"
				shift
				shift
				;;
		--)
                shift
                break
        esac
done
if [ "$FILENAME" = "" ]; then
	usage
fi
if [ $# -gt 0 ] ; then
    echo "$0: Extraneous arguments supplied"
    usage
fi

echo "BSD Router Project Qemu script"
check_system
check_user
check_image
parse_filename

if ($LAB_MODE); then
	create_interfaces_lab
else
	create_interfaces
fi

if ($LAB_MODE); then
	echo "Starting qemu in lab mode..."
else
	echo "Starting qemu..."
	${QEMU_ARCH} -hda ${FILENAME} -net nic -net tap,ifname=tap0 -localtime \
	${QEMU_OUTPUT} -k fr
fi
echo "...qemu stoped"
echo "Destroying Interfaces"
if ($LAB_MODE); then
	delete_interface_lab
else
	ifconfig ${TAP_IF} destroy
	ifconfig ${BRIDGE_IF} destroy
fi
