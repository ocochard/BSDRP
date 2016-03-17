#!/bin/sh
#
# Bhyve lab script for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2013-2016, The BSDRP Development Team
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

### Global variables ###
WRK_DIR="/tmp/BSDRP"
VM_TEMPLATE=${WRK_DIR}/vm_template
VM_NAME="BSDRP"
CORE="1"
NUMBER_VM="1"
FILE=""
LAN=0
MESHED=true
RAM="256M"
VALE=false

usage() {
	# $1: Cause of displaying usage
	[ $# -eq 1 ] && echo $1
	echo "Usage: $0 [-adhps] -i FreeBSD-disk-image.img [-n vm-number] [-l LAN-number] -c [core]"
	echo " -a           Disable full-meshing"
	echo " -c           Number of core per VM (default ${CORE})"
	echo " -d           Delete All VMs, including the template"
	echo " -h           Display this help"
	echo " -i filename  FreeBSD file image"
	echo " -l X         Number of LAN common to all VM (default ${LAN})"
	echo " -m X         RAM size (default ${RAM})"
	echo " -n X         Number of VM full meshed (default ${NUMBER_VM})"
	echo " -p           Patch FreeBSD disk-image for serial output (useless with BSDRP images or FreBSD >= 10.1)"
	echo " -s           Stop all VM"
	echo " -V           Use vale (netmap) switch in place of bridge+tap"
	echo " -w dirname   Working directory (default ${WRK_DIR})"
	echo " This script needs to be executed with superuser privileges"
	echo ""
    exit 1
}

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
	if ( ! ${VALE} ); then
		# Same for if_tap
		load_module if_tap
		# Enable net.link.tap.up_on_open
		sysctl net.link.tap.up_on_open=1 > /dev/null 2>&1 || echo "Warning: Can't enable net.link.tap.up_on_open"
	fi
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
	"DOS/MBR boot sector")
		cp ${FILE} ${VM_TEMPLATE}
		return 0
		;;
	*)
		die "Didn't detect image format: ${FILE_TYPE}"
        ;;
	esac

	# Once unzip, we need to re-check the format
	if ! file -b ${VM_TEMPLATE} | grep -q "boot sector"; then
		die "Not a correct image format ?"
	fi	

	return 0

}

adapt_image_console () {
	# No more needed
	
	mkdir -p ${WRK_DIR}/mnt || die "Can't create ${WRK_DIR}/mnt"

	mount | grep -q "${WRK_DIR}/mnt"  && umount -f ${WRK_DIR}/mnt

	MD=`mdconfig -a ${VM_TEMPLATE}`
	fsck_ufs -y /dev/$MD"s1a" > /dev/null 2>&1 || die "Error regarding the FreeBSD image given"
	mount /dev/$MD"s1a" ${WRK_DIR}/mnt  || die "Can't mount the image"

	if ! grep -q 'console "/usr/libexec/getty std.9600"' ${WRK_DIR}/mnt/etc/ttys; then
		echo "Patching image file with a console bhyve compliant"
		cat >> ${WRK_DIR}/mnt/etc/ttys << EOF
console "/usr/libexec/getty std.9600"   vt100   on   secure
EOF
fi
	umount ${WRK_DIR}/mnt || "die can't unmount the disk image"
	mdconfig -du $MD || "die can't destroy md image"
}

erase_all_vm() {
	# We can display vm by looking in /dev/vmm
	# Search for VM disk image
	local VM_LIST=`find ${WRK_DIR} -name "${VM_NAME}_*"`
	local i=1
	for i in ${VM_LIST}; do
		echo "Deleting VM $i..."
		local VM=`basename $i`
		destroy_vm ${VM}
		rm $i || echo "can't erase vm $i"
	done
	[ -f ${VM_TEMPLATE} ] && rm ${VM_TEMPLATE}
	return 0
}

stop_all_vm() {
	if [ -e /dev/vmm ]; then
		local VM_LIST=`find /dev/vmm -name "${VM_NAME}_*"`
		for i in ${VM_LIST}; do
			destroy_vm `basename $i`
		done
	fi
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
	if [ -e /dev/vmm/$1 ]; then
		bhyvectl --vm=$1 --destroy || echo "Can't destroy VM $1"
	fi
	return 0
}

run_vm() {
	# $1: VM number
	# Destroy previous if allready exist
	destroy_vm ${VM_NAME}_$1
	# Need an infinite loop: This permit to do a reboot initated from the VM
	while [ 1 ]; do
		# load a FreeBSD guest inside a bhyve virtual machine
		eval VM_LOAD_$1=\"bhyveload -m \${RAM} -d \${WRK_DIR}/\${VM_NAME}_$1 -c /dev/nmdm$1A \${VM_NAME}_$1\"
		#eval echo DEBUG \${VM_LOAD_$1}
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
		# PCI 0:0 hostbridge
		# PCI 0:1 lpc (serial)
		# PCI 1:0 Hard drive
		# PCI 2:0 and next: Network NIC
		#   Note: It's not possible to have "hole" in PCI assignement
		VM_COMMON="bhyve -c ${CORE} -m ${RAM} -A -H -P -s 0:0,hostbridge -s 0:1,lpc"
		eval VM_CONSOLE_$1=\"-l com1,/dev/nmdm\$1A\"
		eval VM_DISK_$1=\"-s 1:0,virtio-blk,\${WRK_DIR}/\${VM_NAME}_$1\"
		#eval echo DEBUG \${VM_COMMON} \${VM_NET_$1} \${VM_DISK_$1} \${VM_CONSOLE_$1} \${VM_NAME}_$1
		eval \${VM_COMMON} \${VM_NET_$1} \${VM_DISK_$1} \${VM_CONSOLE_$1} ${VM_NAME}_$1
		# Check bhyve exit code, and if error: exit the infinite loop
		if [ $? -ne 0 ]; then
        	break
    	fi
		# Dirty fix for perventing bhyve bug that sometimes need input from console for unpausing
		echo >> /dev/nmdm$1B
	done
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

[ $# -lt 1 -a ! -f ${VM_TEMPLATE} ] && usage "ERROR: No argument given and no previous template to run"
[ `id -u` -ne 0 ] && usage "ERROR: not executed as root"

args=`getopt ac:dhi:l:m:n:sVw: $*`

set -- $args
for i; do
	case "$i"
	in
	-a)
		MESHED=false
		shift
		;;
	-c)
		CORE=$2
		shift
		shift
		;;
	-d)
		erase_all_vm
		destroy_all_if
		return 0
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
	-s)
		stop_all_vm
		return 0
		shift
		;;
	-V)
		VALE=true
		shift
		;;	
	-w)
		WRK_DIR=$2
		[ -d ${WRK_DIR} ] || usage "ERROR: Working directory not found"
		VM_TEMPLATE=${WRK_DIR}/vm_template
		shift
		shift
		;;
	--)
		shift
		break
        esac
done #for

# Check user input
[ ! -f ${VM_TEMPLATE} -a -z "${FILE}" ] && usage "ERROR: No previous template \
	neither image filename given"
# If default number of VM and LAN, then create at least one LAN
[ ${NUMBER_VM} -eq 1 -a ${LAN} -eq 0 ] && LAN=1

[ -d ${WRK_DIR} ] || mkdir -p ${WRK_DIR}

check_bhyve_support

# if input image given, need to prepare it
if [ -n "${FILE}" ]; then
	uncompress_image
fi

# Clean-up previous interfaces if existing
destroy_all_if

echo "BSD Router Project (http://bsdrp.net) - bhyve full-meshed lab script"
echo "Setting-up a virtual lab with $NUMBER_VM VM(s):"
echo "- Working directory: ${WRK_DIR}"
echo "- Each VM have ${CORE} core(s) and ${RAM} RAM"
echo -n "- Switch mode: "
( ${VALE} ) && echo "vale (netmap)" || echo "bridge + tap"
echo "- $LAN LAN(s) between all VM"
( ${MESHED} ) && echo "- Full mesh Ethernet links between each VM"

i=1                                                                   
# Enter the main loop for each VM                                            
while [ $i -le $NUMBER_VM ]; do
	# Erase already existing VM disk only if:
	#   a image is given
	#   OR it didn't already exists
	# TO DO: Need to use UFS or ZFS snapshot in place of copying the full disk
	[ ! -f ${WRK_DIR}/${VM_NAME}_$i -o -n "${FILE}" ] && cp ${VM_TEMPLATE} ${WRK_DIR}/${VM_NAME}_$i
	# Network_config
	NIC_NUMBER=0
    echo "VM $i have the following NIC:"

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
	if ( ${MESHED} ); then
		j=1
		while [ $j -le $NUMBER_VM ]; do
			# Skip if i = j
			if [ $i -ne $j ]; then
				echo "- vtnet${NIC_NUMBER} connected to VM ${j}."
				# PCI_SLOT must be between 0 and 7
				# Need to increase PCI_BUS number if slot is more than 7
		
				PCI_BUS=$(( ${NIC_NUMBER} / 8 ))
				PCI_SLOT=$(( ${NIC_NUMBER} - 8 * ${PCI_BUS} ))
				# All PCI_BUS before 2 are already used
				PCI_BUS=$(( ${PCI_BUS} + 2 ))
				# Need to manage correct mac address
				[ $i -le 9 ] && MAC_I="0$i" || MAC_I="$i"
				[ $j -le 9 ] && MAC_J="0$j" || MAC_J="$j"
				# We allways use "low number - high number" for identify cables
				if [ $i -le $j ]; then
					if (${VALE} ); then
						SW_CMD="vale${i}${j}:${VM_NAME}_$i"
					else
						BRIDGE_IF=$( create_interface MESH_${i}-${j} bridge )
						TAP_IF=$( create_interface MESH_${i}-${j}_${i} tap ${BRIDGE_IF} )
						SW_CMD=${TAP_IF}
					fi
					#eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},virtio-net,\
#${TAP_IF},mac=58:9c:fc:\${MAC_I}:\${MAC_J}:\${MAC_I}\"
					#eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},virtio-net,\
#vale${VALE}:${VM_NAME}_$i,mac=58:9c:fc:\${MAC_I}:\${MAC_J}:\${MAC_I}\"
					eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},virtio-net,\
${SW_CMD},mac=58:9c:fc:\${MAC_I}:\${MAC_J}:\${MAC_I}\"
				
				else
					if (${VALE} ); then
						SW_CMD="vale${j}${i}:${VM_NAME}_$i"
					else	
						BRIDGE_IF=$( create_interface MESH_${j}-${i} bridge )
						TAP_IF=$( create_interface MESH_${j}-${i}_${i} tap ${BRIDGE_IF} )
						SW_CMD=${TAP_IF}
					fi
					#eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},virtio-net,\
#${TAP_IF},mac=58:9c:fc:\${MAC_J}:\${MAC_I}:\${MAC_I}\"
					#eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},virtio-net,\
#vale${VALE}:${VM_NAME}_$i,mac=58:9c:fc:\${MAC_J}:\${MAC_I}:\${MAC_I}\"
					eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},virtio-net,\
${SW_CMD},mac=58:9c:fc:\${MAC_J}:\${MAC_I}:\${MAC_I}\"
				fi
				NIC_NUMBER=$(( ${NIC_NUMBER} + 1 ))
			fi
			j=$(( $j + 1 ))
		done # while [ $j -le $NUMBER_VM ] (
	fi # if $MESHED
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
		echo "- vtnet${NIC_NUMBER} connected to LAN number ${j}"
		# PCI_SLOT must be between 0 and 7
		# Need to increase PCI_BUS number if slot is more than 7
		PCI_BUS=$(( ${NIC_NUMBER} / 8 ))
		PCI_SLOT=$(( ${NIC_NUMBER} - 8 * ${PCI_BUS} ))
		# All PCI_BUS before 2 are already used
		PCI_BUS=$(( ${PCI_BUS} + 2 ))
		if (${VALE} ); then
			SW_CMD="vale${j}:${VM_NAME}_$i"
		else
			BRIDGE_IF=$( create_interface LAN_${j} bridge )
			TAP_IF=$( create_interface LAN_${j}_${i} tap ${BRIDGE_IF} )
			SW_CMD=${TAP_IF}
		fi
		eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},virtio-net,\
${SW_CMD},mac=58:9c:fc:\${MAC_J}:00:\${MAC_I}\"
        NIC_NUMBER=$(( ${NIC_NUMBER} + 1 ))
        j=$(( $j + 1 ))
	done # while [ $j -le $LAN ]

	# Start VM
	run_vm $i &
	i=$(( $i + 1 ))
done # Main loop: while [ $i -le $NUMBER_VM ]

i=1
# Enter tips main loop for each VM
echo "For connecting to VM'serial console, you can use:"
while [ $i -le $NUMBER_VM ]; do
	echo "- VM ${i} : cu -l /dev/nmdm${i}B"
	i=$(( $i + 1 ))
done
