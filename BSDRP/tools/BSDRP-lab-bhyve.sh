#!/bin/sh
#
# Bhyve lab script for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2013-2014, The BSDRP Development Team
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

usage() {
	# $1: Cause of displaying usage
	[ $# -eq 1 ] && echo $1
	echo "Usage: $0 [-hv] -i FreeBSD-disk-image.img [-n router-number] [-l LAN-number]"
	echo " -d           Destroy VM"
	echo " -h           Display this help"
	echo " -i filename  FreeBSD file image"
	echo " -l X         Number of LAN common to all VM (between 0 and 9)"
	echo " -m X         RAM in Mb (default 256)"
	echo " -n X         Number of routers (between 2 and 9) full meshed (default 1)"
	echo " This script needs to be executed with superuser privileges"
	echo ""
    exit 1
}

### Global variables ###
WRK_DIR="/tmp/BSDRP"
VM_TEMPLATE=${WRK_DIR}/vm_template
VM_NAME="BSDRP"
NUMBER_VM="1"
FILE=""
LAN=0
RAM="256M"

### Functions ####
# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "ERROR: " >&2; echo "$@" >&2; exit 1; }

# Check FreeBSD system pre-requise for starting bhyve
check_bhyve_support () {
	# Check if processor support bhyve
	grep -q 'Features.*POPCNT' /var/run/dmesg.boot || die \
		"Your CPU does not support POPCNT."

	# Check if bhyve vmm is loaded
	load_module vmm
	# Same for serial console nmdm
	load_module nmdm
}

load_module () {
	# $1 : Module name
	if ! kldstat -m $1 > /dev/null 2>&1; then
		echo "$1 module not loaded. Loading it..."
		kldload $1|| die "can't load $1"
	fi
}

# Check filename given, and unzip it
# Common with vbox/quemu script
uncompress_image () {
    [ -f ${FILE} ] || die "Can't find file ${FILE}"
	FILE_TYPE=`file -b ${FILE} | cut -d ';' -f 1`

	[ -f ${VM_TEMPLATE} ] && rm ${VM_TEMPLATE}

	case "${FILE_TYPE}" in
	"XZ compressed data")
		which xz > /dev/null 2>&1 || die "Need xz"
		xz --decompress --stdout ${FILE} > ${VM_TEMPLATE} || \
			die "Can't unxz image file"
		;;
	"BZIP compressed data")
		which bunzip2 > /dev/null 2>&1 || die "Need bunzip2"
		bunzip2 --decompress --stdout ${FILE} > ${VM_TEMPLATE} || \
			die "Can't bunzip2 image file"
		;;
	"x86 boot sector")
		cp ${FILE} ${VM_TEMPLATE}
		return 0
		;;
	*)
		die "Didn't detect image format: ${FILE_TYPE}"
        ;;
	esac

	# Once unzip, we need to re-check the format
	FILE_TYPE=`file -b ${VM_TEMPLATE} | cut -d ';' -f 1`
	[ "${FILE_TYPE}" == "x86 boot sector" ] || \
		die "Didn't detect image format:  ${FILE_TYPE}"

	return 0

}

adapt_image_console () {
	
	mkdir -p ${WRK_DIR}/mnt || die "Can't create ${WRK_DIR}/mnt"

	mount | grep -q "${WRK_DIR}/mnt"  && umount -f ${WRK_DIR}/mnt

	MD=`mdconfig -a ${VM_TEMPLATE}`
	fsck_ufs -y /dev/$MD"s1a" > /dev/null 2>&1 || die "Error regarding the image given"
	mount /dev/$MD"s1a" ${WRK_DIR}/mnt  || die "Can't mount the image"

	if ! grep -q 'console "/usr/libexec/getty std.9600"' ${WRK_DIR}/mnt/etc/ttys; then
		echo "Patching image file with a console bhyve compliant"
		cat >> ${WRK_DIR}/mnt/etc/ttys << EOF
console "/usr/libexec/getty std.9600"   vt100   on   secure
EOF
fi
	umount ${WRK_DIR}/mnt || "die can't unmount the BSDRP image"
	mdconfig -du $MD || "die can't destroy md image"
}

destroy_all_vm() {
	echo "TO DO: get an ls of number of VM disk"
	NUMBER_VM=`find ${WRK_DIR} -name "${VM_NAME}_*" | wc -l`
#	local i=1
#	while [ $i -le $NUMBER_VM ]; do
#		bhyvectl --vm=${VM_NAME}_$1 --destroy && echo "destroying guest" \
#			&& rm ${WRK_DIR}/${VM_NAME}_$1 \
#			|| echo "can't destroy vm ${VM_NAME}_$1"
#	done
	return 0
}

destroy_all_if() {
	IF_LIST=`ifconfig -l`
	for i in ${IF_LIST}; do
		ifconfig $i | grep -q "description: MESH_\|description: LAN_" && \
			ifconfig $i destroy
	done
	return 0
}

destroy_vm() {
	# $1: VM name
	# Check if this VM exist by small query
	if bhyvectl --vm=$1 --get-vmcs-vpid  > /dev/null 2>&1; then
		bhyvectl --vm=$1 --destroy || die "Can't destroy VM $1"
	fi
	return 0
}

run_vm() {
	# $1: VM number
	# Destroy previous is allready exist
	destroy_vm ${VM_NAME}_$1
	# load a FreeBSD guest inside a bhyve virtual machine
	eval VM_LOAD_$1=\"bhyveload -m \${RAM} -d \${WRK_DIR}/\${VM_NAME}_$1 -c /dev/nmdm$1A \${VM_NAME}_$1\"
	eval \${VM_LOAD_$1}
	# c: Number of guest virtual CPUs
	# m: RAM
	# A: Generate ACPI tables.  Required for FreeBSD/amd64 guests
	# I: Allow devices behind the LPC PCI-ISA bridge to be configured.
	#     The only supported devices are the TTY-class devices, com1
	#     and com2.
	# H: Yield the virtual CPU thread when a HLT instruction is detected.
	#    If this option is not specified, virtual CPUs will use 100% of a
	#    host CPU
	# P: Force guest virtual CPUs to be pinned to host CPUs
	# s: Configure a virtual PCI slot and function.
	# S: Configure legacy ISA slot and function 
	VM_COMMON="bhyve -c 1 -m ${RAM} -AI -H -P -s 0,hostbridge"
	eval VM_CONSOLE_$1=\"-l com1,/dev/nmdm\$1A\"
	eval VM_DISK_$1=\"-s 3,virtio-blk,\${WRK_DIR}/\${VM_NAME}_$1\"
	eval \${VM_COMMON} \${VM_NET_$1} \${VM_DISK_$1} \${VM_CONSOLE_$1} \
		\${VM_NAME}_$1
	echo "start a cu -l /dev/nmdm$1B for connecting VM ${VM_NAME}_$1's serial console"
	
}

create_interface() {
	# Check if already exist and if not, create new interface
	# $1: Interface description
	# $2: Interface type (bridge or tap)
	# $3: Name of the interface bridge to join (only for tap interface)
	# echo: The name of the interface created (bridgeX or tapY)
	
	[ $# -lt 2 ] && die "Bug when calling create_interface(): not enought argument"
	
	# Begin to search if interface already exist
	local IF_LIST=`ifconfig -g $2`
	for i in ${IF_LIST}; do
		if ifconfig $i | grep -q "description: $1"; then
			echo $i
			return 0
		fi
	done
	IF=`ifconfig $2 create`
	ifconfig ${IF} description $1 up || die "Can't set $1 on ${IF}"
	if [ $# -eq 3 ]; then
		ifconfig $3 addm ${IF} || die "Can't add ${IF} on bridge $3"
	fi
	echo ${IF}
	return 0
}

#### Main ####

[ $# -lt 1 ] && usage "ERROR: No argument given"
[ `id -u` -ne 0 ] && usage "ERROR: not executed as root"

args=`getopt i:dhcl:m:n:sv $*`

set -- $args
for i; do
	case "$i"
	in
	-d)
		destroy_all_vm
		destroy_all_if
		exit
		shift
		;;
	-h)
		usage
		shift
		;;
	-i)
		FILE=$2
        shift
        shift
        ;;
	-l)
		LAN=$2
		shift
		shift
		;;
	-m)
		RAM=$2
		shift
		shift
		;;
	-n)
		NUMBER_VM=$2
		shift
		shift
		;;
	--)
		shift
		break
        esac
done #for

[ ! -f ${VM_TEMPLATE} -a -z ${FILE} ] && usage "ERROR: No previous template \
	neither image filename given"
[ -z ${NUMBER_VM} ] && usage "ERROR: No VM number given"

check_bhyve_support

# if input image given, need to prepare it
if [ -n "${FILE}" ]; then
	uncompress_image
	adapt_image_console
fi

# Clean-up previous interfaces if existing
destroy_all_if

i=1                                                                   
# Enter the main loop for each VM                                            
while [ $i -le $NUMBER_VM ]; do
	# Clone VM disk
	cp ${VM_TEMPLATE} ${WRK_DIR}/${VM_NAME}_$i
	# Network_config
	NIC_NUMBER=0
    echo "VM ${VM_NAME}_$i have the following NIC:"

	# Entering the Meshed NIC loop NIC loop
	# Now generate X (X-1)/2 full meshed link
	# if we have 3 VMs:
	#        VM1                            VM2
	#    (TUN-BR1-2_1) -- BRIDGE1-2 -- (TUN-BR1-2_2)
	#    (TUN-BR1-3_1)                 (TUN-BR2-3_3)
	#            \                        /
	#         BRIDGE1-3              BRIDGE2-3
	#              \                   /
	#           (TUN-BR1-3_3)   (TUN-BR2-3_3)
	#                        VM3
	#     
	eval VM_NET_${i}=\"\"
	j=1
	while [ $j -le $NUMBER_VM ]; do
		# Skip if i = j
		if [ $i -ne $j ]; then
			echo "vtnet${NIC_NUMBER} connected to VM ${VM_NAME}_${j}."
			NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
			# Need to manage correct mac address
			[ $i -le 9 ] && MAC_I="0$i" || MAC_I="$i"
			[ $j -le 9 ] && MAC_J="0$j" || MAC_J="$j"
			# We allways use "low number - high number"
			if [ $i -le $j ]; then
				BRIDGE_IF=$( create_interface MESH_${i}-${j} bridge )
				TAP_IF=$( create_interface MESH_${i}-${j}_${i} tap ${BRIDGE_IF} )
				eval VM_NET_${i}=\"\${VM_NET_${i}} -s 2:\${NIC_NUMBER},virtio-net,\
${TAP_IF},mac=58:9c:fc:\${MAC_I}:\${MAC_J}:\${MAC_I}\"
			else
				BRIDGE_IF=$( create_interface MESH_${j}-${i} bridge )
				TAP_IF=$( create_interface MESH_${j}-${i}_${i} tap ${BRIDGE_IF} )
				eval VM_NET_${i}=\"\${VM_NET_${i}} -s 2:\${NIC_NUMBER},virtio-net,\
${TAP_IF},mac=58:9c:fc:\${MAC_J}:\${MAC_I}:\${MAC_I}\"
            fi
        fi
        j=`expr $j + 1`
	done # while [ $j -le $NUMBER_VM ] (
    j=1
	# Entering in the LAN NIC loop
	#    VM1         VM2        VM3
	# (LAN_1_1)   (LAN_1_1)  (LAN_1_3)
	#     |           |          |
	#    -------LAN_1-------------
	#
    while [ $j -le $LAN ]; do
		# Need to manage correct mac address
        [ $i -le 9 ] && MAC_I="0$i" || MAC_I="$i"
        [ $j -le 9 ] && MAC_J="0$i" || MAC_J="$i"
        echo "vtnet${NIC_NUMBER} connected to LAN number ${j}."
        NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
		BRIDGE_IF=$( create_interface LAN_${j} bridge )
		TAP_IF=$( create_interface LAN_${j}_${i} tap ${BRIDGE_IF} ) 
		eval VM_NET_${i}=\"\${VM_NET_${i}} -s 2:\${NIC_NUMBER},virtio-net,\
${TAP_IF},mac=58:9c:fc:\${MAC_J}:00:\${MAC_I}\"
           j=`expr $j + 1`
	done # while [ $j -le $LAN ]

	# Start VM
	run_vm $i
	i=`expr $i + 1`
done # Main loop: while [ $i -le $NUMBER_VM ]
#destroy_vm

