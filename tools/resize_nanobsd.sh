#!/bin/sh
# Resizing nanobsd partition for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2016, The BSDRP Development Team
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

set -eu

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

swap() {
	echo -n "Active partition need to be partition 1, swaping it (Don't stop this fake-upgrade operation!)..."
    cat /dev/${boot_dev}s2 | upgrade
	echo "ok"
	echo "Rebooting..."
    reboot
}

resize() {
	# Need to check if already resized
	echo -n "Checking partition size..."
	partition_size=`gpart show -p ${boot_dev} | grep ${boot_dev}s1 | tr -s ' ' | cut -d ' ' -f 3`
	[ -z "${partition_size}" ] && die "Can't read the primary partition size"
	if [ ${partition_size} -ge 963837 ]; then
		echo "compliant"
		return 0
	else
		echo "Too small"
		return 1
	fi
	echo -n "Resizing partition..."
    gpart delete -i 4 ${boot_dev}
    gpart delete -i 3 ${boot_dev}
    gpart delete -i 2 ${boot_dev}
    gpart resize -i 1 -s 963837 ${boot_dev}
    gpart commit ${boot_dev}s1
    gpart add -t freebsd -i 2 -s 963837 ${boot_dev}
    gpart add -t freebsd -i 3 -s 32193 ${boot_dev}
    gpart add -t freebsd -i 4 ${boot_dev}
    newfs -b 4096 -f 512 -i 8192 -U -L BSDRPs3 /dev/${boot_dev}s3
    newfs -b 4096 -f 512 -i 8192 -U -L BSDRPs4 /dev/${boot_dev}s4
    config save
	echo "Done"
	return 0
}

# Main function

echo "This tool will check if your system is compliant to an upgrade to BSDRP 1.60"
echo "- If a partition swaping is needed, it will reboot automatically your system at the end"
echo "  You need to restart this tool after the reboot for continuing"
echo "- All files stored in /data partition will be destroyed!"
echo -n "Do you want to continue or abort ? (y/a): "
USER_CONFIRM=""
while [ "$USER_CONFIRM" != "y" -a "$USER_CONFIRM" != "a" ]; do
	read USER_CONFIRM <&1
done
[ "$USER_CONFIRM" = "a" ] && die "User aborded"

# Need to check total disk space
echo -n "Checking disk size..."
boot_dev=`glabel status | grep BSDRPs1 | awk '{ print $3; }'\  | cut -d s -f 1`
[ -z "${boot_dev}" ] && die "Can't detect the physical disk where BSDRP is installed"
disk_size=`gpart show ${boot_dev} | grep MBR | tr -s ' ' | cut -d ' ' -f 3`
[ -z "${disk_size}" ] && die "Can't read the disk size"

# 2 000 000 sector at 512B
[ ${disk_size} -lt 1999999 ] && die "Your disk is too small for allowing an upgrade to BSDRP 1.60 (1GB minimum)"

echo "compliant"
#echo "Checking BSDRP minimum version..."
#grep -q 1.51 /etc/version || die "You need to upgrade your BSDRP to version 1.51 first"
#echo "compliant"
mount /dev/ufs/BSDRPs1a > /dev/null 2>&1 && resize || swap

echo "Your system is ready for being upgraded to BSDRP 1.60"
return 0
