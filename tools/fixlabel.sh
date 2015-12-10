#!/bin/sh
# Fix label slice bug
# http://bsdrp.net
#
# Copyright (c) 2015, The BSDRP Development Team
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

# Variables loading
. /etc/nanobsd.conf
boot_dev=/dev/`glabel status | grep ${NANO_DRIVE}s1a \
			 | awk '{ s=$3; sub(/s[12]a$/, "", s); print s; }'`
LABEL=`cat /etc/nanobsd.conf | cut -d '/' -f 2`

swap() {

	echo -n "Active partition need to be partition 1, swaping it (Don't stop this fake-upgrade operation!)..."
    cat ${boot_dev}s2 | upgrade
	echo "ok"
	echo "Rebooting..."
    reboot
}

fixlabel() {
	tunefs -L ${LABEL}s2a ${boot_dev}s2
	tunefs -L ${LABEL}s3 ${boot_dev}s3
	newfs -b 4096 -f 512 -i 8192 -O1 -m 0 -L${LABEL}s4 ${boot_dev}s4
	/usr/local/sbin/config save
    config save
	echo "Done"
}

# Main function

echo "This tool will check if your system include the slice label bug"
echo "  (fresh instalation of BSDRP 1.57 only)"
echo "- If a partition swaping is needed, it will reboot automatically your system at the end."
echo "    and you had to restart this tool after the reboot for continuing"
echo "- Files in /data partition will be moved to the /cfg partition"
echo -n "Do you want to continue or abort ? (y/a): "
USER_CONFIRM=""
while [ "$USER_CONFIRM" != "y" -a "$USER_CONFIRM" != "a" ]; do
	read USER_CONFIRM <&1
done
[ "$USER_CONFIRM" = "a" ] && die "User aborded"

echo "Checking for bad slice label..."
ID=`glabel status | grep ${LABEL}s4 | awk '{ s=$3; sub(/s[12]a$/, "", s); print s; }' | cut -d 's' -f 2`
if [ ${ID} != "4" ]; then
        echo "Label number ${ID}, need to be number 3"
        echo "Buggy system detected, fixing it"
		mount /dev/ufs/${LABEL}s1a > /dev/null 2>&1 && fixlabel || swap
else
        echo "Everything is fine!"
fi
