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

check_system () {
	if [ ! `uname -s | grep FreeBSD` ]; then
		echo "Error: This script was wrote for a FreeBSD"
		echo "You need to adapt it for other system"
		exit 1
	fi
	if ! pkg_info -q -E -x qemu; then
        echo "Error: qemu not found"
		echo "Install qemu: pkg_add -r qemu"
        exit 1
	fi

	if ! pkg_info -q -E -x kqemu; then
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
	if [ ! -f $1 ]; then
		echo "Can't found $1"
		exit 1
	fi

	if ! `file -b $1 | grep "boot sector"  > /dev/null 2>&1`; then
		echo "Not a BSDRP image (zipped?)"
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
if [ `ifconfig -l | grep bridge0` ]; then
	echo "Creating admin bridge interface..."
	IF_NUMBER=`ifconfig bridge create`
	if [ `ifconfig bridge${IF_NUMBER} 10.0.0.254/24` ]; then
		echo "Can't set IP adress on bridge${IF_NUMBER}"
		exit 1
	else
		ifconfig 
	fi
fi
#SharedTAP interface for communicating with the host
echo creating tap interface
ifconfig tap0 create
ifconfig tap0 10.0.0.254/24
}

# Main script
check_system
check_user
check_image $1
echo "Starting qemu with vga redirected to vnc :0"
echo "qemu-system-x86_64 -hda $1 -net nic -net tap,ifname=tap0 -localtime -kernel-kqemu \
-vnc :0 -k fr -usbdevice tablet"
