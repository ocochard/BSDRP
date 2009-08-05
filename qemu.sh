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
# 3. Neither the name of the BSD Router Project/BSDRP nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
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

#Exit if not managed error encoutered
set -e

if [ $# -ne 1 ] ; then
	echo "usage: $0 BSDRP-image-filename"
	exit 0
fi

FILENAME=$1

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
		echo "Need to change FILENAME value: remove the last.bz2"
    fi

	if ! `file -b ${FILENAME} | grep -q "boot sector"  > /dev/null 2>&1`; then
		echo "ERROR: Not a BSDRP image??"
		exit 1
	fi
	
	
}
# To do list
# Check if we are under FreeBSD
# Check if qemu is installed
# Check if kqemu and ao is loaded
# Check if $1 is an amd64 or i386 image
# Creating admin bridge interface
create_interfaces () {
if ! `ifconfig | grep -q 10.0.0.254`; then
	echo "Creating admin bridge interface..."
	BRIDGE_NUMBER=`ifconfig bridge create`
	if ! `ifconfig ${BRIDGE_NUMBER} 10.0.0.254/24`; then
		echo "Can't set IP address on ${BRIDGE_NUMBER}"
		exit 1
	fi
else
	echo "Need to found the bridge number configured with 10.0.0.254"
fi
#SharedTAP interface for communicating with the host
echo creating tap interface
if ! `ifconfig | grep -q "10.0.0.1"`; then
    echo "Creating admin tap interface..."
    TAP_NUMBER=`ifconfig tap create`
    if ! `ifconfig ${TAP_NUMBER} 10.0.0.1/24`; then
        echo "Can't set IP address on ${TAP_NUMBER}"
        exit 1
    fi
else
    echo "Need to found the tap number configured with 10.0.0.254"
fi

# Link bridge with tap
ifconfig ${BRIDGE_NUMBER} addm ${TAP_NUMBER} up
ifconfig ${TAP_NUMBER} up
}

# Parse filename for detecting ARCH and console
parse_filename () {
	QEMU_ARCH=0
	if echo "${FILENAME}" | grep -q "amd64"; then
		QEMU_ARCH="qemu-system-x86_64"
		echo "filename guests a x86_64 image"
	fi
	if echo "${FILENAME}" | grep -q "i386"; then
        QEMU_ARCH="qemu"
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
# Main script

echo "BSD Router Project Qemu script"
check_system
check_user
check_image
parse_filename
create_interfaces
echo "Starting qemu..."
${QEMU_ARCH} -hda ${FILENAME} -net nic -net tap,ifname=tap0 -localtime -kernel-kqemu \
${QEMU_OUTPUT} -k fr
echo "...qemu stoped"
echo "Destroying Interfaces"
ifconfig ${TAP_NUMBER} destroy
ifconfig ${BRIDGE_NUMBER} destroy
