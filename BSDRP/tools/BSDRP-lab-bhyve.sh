#!/bin/sh
#
# Bhyve lab script for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2013, The BSDRP Development Team
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

set -eu

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "ERROR: " >&2; echo "$@" >&2; exit 1; }

# Check FreeBSD system pre-requise for starting virtualbox
check_system_freebsd () {
    if ! kldstat -m vmm > /dev/null 2>&1; then
        echo "[WARNING] bhyve vmm module not loaded ?"
    fi
}

usage() {
    echo "Usage: $0 BSDRP-serial-image"
    exit 1
}

adapt_guest_console () {
	[ ! -f $1  ] && die "No image file" 
	MNT=/mnt

	echo "Force unmounting $MNT"
	echo ""
	if mount | grep -q '/mnt'; then
		umount -f $MNT
	fi

	MD=`mdconfig -a $1`
	fsck_ufs -y /dev/$MD"s1a" || die "Error regarding the BSDRP image given"
	mount /dev/$MD"s1a" $MNT  || die "Can't mount the BSDRP image"

	echo "Enabling the required console"
	echo ""

if ! grep -q 'console "/usr/libexec/getty std.9600"' $MNT/etc/ttys; then
	echo "Patching the BSDRP image console for bhyve compliant"
	cat >> $MNT/etc/ttys << EOF
console "/usr/libexec/getty std.9600"   vt100   on   secure
EOF
fi
	umount $MNT || "die can't unmount the BSDRP image"
	mdconfig -du $MD || "die can't destroy md image"
}

run_guest () {
	bhyvectl --vm=BSDRP --destroy && echo "destroying previous guest" || echo "no previous guest"
	bhyveload -m 256M -d $1 BSDRP || echo "Can't load the guest"
	#/usr/sbin/bhyve -c 2 -m 512M -AI -H -P -g 0 -s 0:0,hostbridge -s 1:0,virtio-net,tap0 -s 2:0,virtio-blk,BSDRP-1.41-full-amd64-serial.img -S 31,uart,stdio BSDRP
	bhyve -c 1 -m 256M -AI -H -P       \
                -s 0:0,hostbridge       \
                -s 2:0,virtio-blk,${1}   \
                -S 31,uart,stdio          \
                BSDRP || "echo can't start the guest"
	bhyvectl --vm=BSDRP --destroy && echo "destroying guest" || die "can't destroy guest"
}

[ $# -lt 1 ] && usage

check_system_freebsd
adapt_guest_console $1
run_guest $1

