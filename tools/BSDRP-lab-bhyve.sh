#!/bin/sh
#
# Bhyve lab script for BSD Router Project
# https://bsdrp.net
#
# Copyright (c) 2013-2025, The BSDRP Development Team
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
arch=$(uname -p)
ADD_DISKS_NUMBER=0
ADD_DISKS_SIZE="8G"	# Additionnal disks size in GB
CORES=1
DEBUG=false
DISK_CTRL="virtio-blk"
FILE=""
LAN=0
MESHED=true
NCPUS=1
NUMBER_VM="1"
RAM="1G"
THREADS=1
SUDO=sudo
if [ "${arch}" = "amd64" ]; then
	UEFI=true
else
	UEFI=false
fi
VALE=false
VERBOSE=true
VNIC="virtio-net"
VM_NAME="BSDRP"
VNC=false
WRK_DIR="${HOME}/BSDRP-VMs"
VM_TEMPLATE=${WRK_DIR}/vm_template

### Constants ###
readonly MAC_PREFIX="58:9c:fc"           # MAC address prefix (locally administered)
readonly PCI_BUS_OFFSET=2                # Buses 0-1 reserved for hostbridge/lpc
readonly PCI_SLOTS_PER_BUS=8             # Number of PCI slots per bus
readonly VNC_BASE_PORT=5900              # Base TCP port for VNC servers
readonly DEBUG_BASE_PORT=9000            # Base TCP port for remote kgdb
readonly MAX_VMS=255                     # Maximum number of VMs supported

usage() {
	# $1: Cause of displaying usage
	[ $# -eq 1 ] && echo $1
	echo "Usage: $0 [-aBdeEhqsvV] -i FreeBSD-disk-image.img [-n vm-number] [-l LAN-number] [-c core] [-A number of additionnal disks] "
	echo " -a           Disable full-meshing"
	echo " -A           Number of additionnal disks"
	echo " -B           Disable UEFI boot mode (switch back to BIOS mode)"
	echo " -c           Number of core per VM (default: ${CORES})"
	echo " -d           Delete All VMs, including the template"
	echo " -D           Disk controller (default: ${DISK_CTRL}, can be ahci-hd|virtio-scsi|nvme)"
	echo " -g           Enable remote kgdb (host needs to be compiled with 'device bvmdebug')"
	echo " -h           Display this help"
	echo " -e           Emulate Intel e82545 (e1000) in place of virtIO NIC"
	echo " -i filename  FreeBSD file image"
	echo " -l X         Number of LAN common to all VM (default: ${LAN})"
	echo " -m X         RAM size (default: ${RAM})"
	echo " -n X         Number of VM full meshed (default: ${NUMBER_VM})"
	echo " -q           Quiet"
	echo " -s           Stop all VM"
	echo " -t           Number of threads per core (default: ${THREADS})"
	echo " -S           Additionnal disks size (default: ${ADD_DISKS_SIZE})"
	echo " -v           Add a graphic card and enable VNC"
	echo " -V           Use vale (netmap) switch in place of bridge+tap"
	echo " -w dirname   Working directory (default: ${WRK_DIR})"
	echo " This script needs to be executed with superuser privileges"
	echo ""
	exit 1
}

### Functions ####
# Error handling function - prints error message and exits
# Arguments:
#   $@: Error message to display
# Returns: exits with code 1
die() { echo -n "ERROR: " >&2; echo "$@" >&2; exit 1; }

# Validate that a parameter is a positive integer within optional range
# Arguments:
#   $1: Value to validate
#   $2: Parameter name (for error message)
#   $3: Minimum value (optional)
#   $4: Maximum value (optional)
# Returns: exits with error if validation fails
validate_number() {
	local value="$1"
	local param_name="$2"
	local min="${3:-}"
	local max="${4:-}"

	# Check if value is a positive integer
	case ${value} in
	''|*[!0-9]*)
		die "Invalid ${param_name}: must be a positive integer"
		;;
	esac

	# Check minimum bound
	if [ -n "${min}" ] && [ "${value}" -lt "${min}" ]; then
		die "Invalid ${param_name}: must be >= ${min}"
	fi

	# Check maximum bound
	if [ -n "${max}" ] && [ "${value}" -gt "${max}" ]; then
		die "Invalid ${param_name}: must be <= ${max}"
	fi
}

# Calculate PCI bus and slot from NIC number
# Arguments:
#   $1: NIC number (0-based)
# Outputs: Sets PCI_BUS and PCI_SLOT global variables
# Note: PCI buses 0-1 are reserved for hostbridge and LPC
calculate_pci_address() {
	local nic_num=$1
	PCI_BUS=$(( nic_num / PCI_SLOTS_PER_BUS + PCI_BUS_OFFSET ))
	PCI_SLOT=$(( nic_num % PCI_SLOTS_PER_BUS ))
}

# Format number as zero-padded 2-digit string for MAC address
# Arguments:
#   $1: Number to format (0-255)
# Returns: Zero-padded string via echo
format_mac_octet() {
	[ $1 -le 9 ] && echo "0$1" || echo "$1"
}

# Get driver name for NIC type and optionally display it
# Arguments:
#   $1: VNIC type (virtio-net|e1000|ptnet)
#   $2: If "display", prints the driver name prefix (optional)
# Returns: Driver name via echo
get_nic_driver() {
	local vnic_type=$1
	local display_mode="${2:-}"
	local driver=""

	case ${vnic_type} in
	virtio-net)
		driver="vtnet"
		;;
	e1000)
		driver="em"
		;;
	ptnet)
		driver="ptnet"
		;;
	*)
		driver="unknown"
		;;
	esac

	if [ "${display_mode}" = "display" ]; then
		echo -n "- ${driver}"
	else
		echo "${driver}"
	fi
}

# Cleanup function - removes temporary files
# Called automatically on exit, interrupt, or termination
# Arguments: none
# Returns: exits with stored exit code
cleanup_on_exit() {
	local exit_code=$?
	# Clean up temporary files if they exist
	[ -n "${TMPFILE:-}" ] && [ -f "${TMPFILE}" ] && rm -f "${TMPFILE}"
	[ -n "${TMPCONSOLE:-}" ] && [ -f "${TMPCONSOLE}" ] && rm -f "${TMPCONSOLE}"
	# Note: We don't destroy VMs on exit as they may be intentionally running
	exit ${exit_code}
}

# Check and load required FreeBSD kernel modules for bhyve operation
# Loads vmm, nmdm, and network tap modules as needed
# Arguments: none
# Returns: 0 on success, may exit on failure
check_bhyve_support () {
	# Check if bhyve vmm is loaded
	load_module vmm
	# Same for serial console nmdm
	load_module nmdm
	if ( ! ${VALE} ); then
		# Same for if_tap
		if [ -f /boot/kernel/if_tuntap.ko ]; then
			load_module if_tuntap
		else
			load_module if_tap
		fi
		# Enable net.link.tap.up_on_open
		${SUDO} sysctl net.link.tap.up_on_open=1 > /dev/null 2>&1 || echo "Warning: Can't enable net.link.tap.up_on_open"
	fi
}

# Load a FreeBSD kernel module if not already loaded
# Arguments:
#   $1: Name of the kernel module to load
# Returns: 0 if module loaded successfully, 1 on failure
load_module () {
	if ! kldstat -m $1 > /dev/null 2>&1; then
		echo "$1 module not loaded. Loading it..."
		${SUDO} kldload $1 && return 0 || return 1
	fi
}

# Detect and decompress disk image file to VM template
# Supports XZ, BZIP2, and raw disk formats
# Arguments: none (uses global FILE and VM_TEMPLATE variables)
# Returns: 0 on success, exits on error
uncompress_image () {
    [ -f ${FILE} ] || die "Can't find file ${FILE}"
	FILE_TYPE=$(file -b ${FILE} | cut -d ' ' -f 1)

	[ -f ${VM_TEMPLATE} ] && rm ${VM_TEMPLATE}

	case "${FILE_TYPE}" in
	"XZ")
		which xz > /dev/null 2>&1 || die "Need xz"
		xz --decompress --stdout ${FILE} > ${VM_TEMPLATE} || \
			die "Can't unxz image file"
		;;
	"BZIP")
		which bunzip2 > /dev/null 2>&1 || die "Need bunzip2"
		bunzip2 --decompress --stdout ${FILE} > ${VM_TEMPLATE} || \
			die "Can't bunzip2 image file"
		;;
	"DOS/MBR")
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

# Remove all VM disk images and clean up VM template
# Arguments: none
# Returns: 0 on success
erase_all_vm() {
	# We can display vm by looking in /dev/vmm
	# Search for VM disk image
	local VM_LIST=$(find ${WRK_DIR} -name "${VM_NAME}_*")
	local i=1
	for i in ${VM_LIST}; do
		( ${VERBOSE} ) && echo "Deleting VM $i..."
		local VM=$(basename $i)
		destroy_vm ${VM}
		rm $i || echo "can't erase vm $i"
	done
	[ -f ${VM_TEMPLATE} ] && rm ${VM_TEMPLATE}
	return 0
}

# Stop and destroy all running BSDRP VMs
# Arguments: none
# Returns: 0 on success
stop_all_vm() {
	if [ -e /dev/vmm ]; then
		local VM_LIST=$(find /dev/vmm -name "${VM_NAME}_*")
		for i in ${VM_LIST}; do
			destroy_vm $(basename $i)
		done
	fi
	return 0
}

# Destroy all network interfaces created for VM meshing
# Removes interfaces with MESH_ or LAN_ descriptions
# Arguments: none
# Returns: 0 on success
destroy_all_if() {
	IF_LIST=$(ifconfig -l)
	for i in ${IF_LIST}; do
		ifconfig $i | grep -q "description: MESH_\|description: LAN_" && \
			${SUDO} ifconfig $i destroy
	done
	return 0
}

# Destroy a specific bhyve virtual machine and cleanup resources
# Arguments:
#   $1: Name of the VM to destroy
# Returns: 0 on success
destroy_vm() {
	# Check if this VM exist by small query
	if is_running $1; then
		${SUDO} bhyvectl --vm=$1 --destroy || echo "Can't destroy VM $1"
		# BSDRP_1, extract all char after _
		# VM name is in form BSDRP_1, but console in form BSDRP.1B
		CONS=$(echo $1 | sed 's/_/./')
		${SUDO} pkill -f "cu -l /dev/nmdm-${CONS}B" || true
	fi
	return 0
}

# Check if a bhyve virtual machine is currently running
# Arguments:
#   $1: Name of the VM to check
# Returns: 0 if running, 1 if not running
is_running() {
	[ -e /dev/vmm/$1 ] && return 0 || return 1
}

# Find an available nmdm (null-modem) device for VM console
# Arguments:
#   $1: Starting VM number to check
# Returns: suffix string for available nmdm device
# Note: nmdm devices auto-create on access, so we avoid direct testing
get_free_nmdm () {
        TMPFILE=$(mktemp /tmp/nmdmlist.XXXXXX) || die "Can not create tmp file"
	find /dev/ -name 'nmdm-BSDRP.*A' > $TMPFILE
	# $1: VM number
	local i=$1
	while grep -q "/dev/nmdm-BSDRP.${i}A" $TMPFILE; do
		# This /dev/nmdm-BSDRP.$1A already exist, need to use another
		i=$(( i + 1 ))
	done
	rm $TMPFILE
	echo "-BSDRP.$i"
}

# Start a bhyve virtual machine with networking and console setup
# Arguments:
#   $1: VM number identifier
# Returns: continues in infinite loop for VM reboots
run_vm() {
	# Destroy previous if already exist

	# Need an infinite loop: This permit to do a reboot initated from the VM
	eval VM_FIRSTBOOT_$1=true
	while [ true ]; do
		# load a FreeBSD guest inside a bhyve virtual machine
		# BUT: If it's a reboot, DO NOT ask for a new NMDM_ID!
		eval "
		if (\${VM_FIRSTBOOT_$1}); then
			NMDM_ID=\$(get_free_nmdm \$1)
			VM_FIRSTBOOT_$1=false
		fi
		"
		if [ "${arch}" = "amd64" ]; then
			eval VM_LOAD_$1=\"${SUDO} bhyveload -S -m \${RAM} -d \${WRK_DIR}/\${VM_NAME}_$1 -c /dev/nmdm\${NMDM_ID}A \${VM_NAME}_$1\"
			eval \${VM_LOAD_$1}
		fi
		# c: Number of guest virtual CPUs
		# m: RAM
		# l: bootrom
		# A: Generate ACPI tables.  Required for FreeBSD/amd64 guests only
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
		# PCI 0:1 lpc (serial), x86 only
		# PCI 1:0 Hard drive
		# PCI 2:0 and next: Network NIC
		# PCI last:0 ptnetnetmap-memdev (if PTNET&VALE enabled)
		#   Note: It's not possible to have "hole" in PCI assignement
		VM_COMMON="${SUDO} bhyve -c cpus=${NCPUS},cores=${CORES},threads=${THREADS} -S -m ${RAM} -s 0:0,hostbridge"
		if [ "${arch}" = "amd64" ]; then
      VM_COMMON="${VM_COMMON} -A -H -P -s 0:1,lpc"
      if [ ${UEFI} = true ]; then
			  VM_BOOT="-l bootrom,/usr/local/share/uefi-firmware/BHYVE_UEFI.fd"
      fi
			eval VM_CONSOLE_$1=\"-l com1,/dev/nmdm\${NMDM_ID}A\"
		elif [ "${arch}" = "aarch64" ]; then
			VM_COMMON="${VM_COMMON} -o bootrom=/usr/local/share/u-boot/u-boot-bhyve-arm64/u-boot.bin"
			eval VM_CONSOLE_$1=\"-o console=/dev/nmdm\${NMDM_ID}A\"
		fi
		VM_BOOT=""
		VM_VNC=""
		# XXX Need to check if TCP port available
    if [ ${VNC} = true ]; then
		  VNC_PORT=$(( VNC_BASE_PORT + $1 ))
		  VM_VNC="-s 29,fbuf,tcp=0.0.0.0:${VNC_PORT},w=800,h=600"
    fi
		eval VM_DISK_$1=\"-s 1:0,\${DISK_CTRL},\${WRK_DIR}/\${VM_NAME}_$1\"
		if [ ${ADD_DISKS_NUMBER} -gt 0 ]; then
			for i in $(jot ${ADD_DISKS_NUMBER}); do
				if ! [ -f ${WRK_DIR}/${VM_NAME}_$1_add_$i ]; then
					truncate -S ${ADD_DISKS_SIZE} ${WRK_DIR}/${VM_NAME}_$1_add_$i
				fi
				eval VM_DISK_$1=\"\${VM_DISK_$1} -s 1:$i,ahci-hd,\${WRK_DIR}/\${VM_NAME}_$1_add_$i\"
			done
		fi

		if(${DEBUG}); then
			DEBUG_PORT=$(( DEBUG_BASE_PORT + $1 ))
			eval VM_DEBUG_$1=\"-g \${DEBUG_PORT}\"
		else
			eval VM_DEBUG_$1=\"\"
		fi
		# Store VM_$1_VMDM data for displaying it later
		echo "- VM $1 : ${SUDO} cu -l /dev/nmdm${NMDM_ID}B" >> ${TMPCONSOLE}

		# Check bhyve exit code, and if error: exit the infinite loop
		# 0  rebooted
		# 1  powered off
		# 2  halted
		# 3  triple fault
		# 4  exited due to an error

		set +e
		eval \${VM_COMMON} \${VM_BOOT} \${VM_VNC} \${VM_NET_$1} \${VM_DISK_$1} \${VM_CONSOLE_$1} \${VM_DEBUG_$1} ${VM_NAME}_$1
		if [ $? -ne 0 ]; then
			# Not a reboot, stop
			break
		fi
		set -e
	done
	set -e
	destroy_vm ${VM_NAME}_$1
}

create_interface() {
	# Check if already exist and if not, create new interface
	# $1: Interface description
	# $2: Interface type (bridge or tap)
	# $3: Name of the interface bridge to join (only for tap interface)
	# echo: The name of the interface created (bridgeX or tapY)

	[ $# -lt 2 ] && die "Bug when calling create_interface(): not enought argument"

	# Begin to search if interface already exist
	local IF_LIST=$(ifconfig -g $2)
	for i in ${IF_LIST}; do
		if ifconfig $i | grep -q "description: $1"; then
			echo $i
			return 0
		fi
	done
	IF=$(${SUDO} ifconfig $2 create)
	${SUDO} ifconfig ${IF} description $1 up || die "Can't set $1 on ${IF}"
	if [ $# -eq 3 ]; then
		${SUDO} ifconfig $3 addm ${IF} || die "Can't add ${IF} on bridge $3"
	fi
	echo ${IF}
	return 0
}

#### Main ####

# Install cleanup handler for temporary files
trap cleanup_on_exit EXIT INT TERM

[ $# -lt 1 ] && ! [ -f ${VM_TEMPLATE} ] && usage "ERROR: No argument given and no previous template to run"
if [ $(id -u) -ne 0 ]; then
  if [ $(${SUDO} id -u) -ne 0 ]; then
    die "ERROR: Could not use ${SUDO}"
  fi
fi

while getopts "aBc:dghD:ei:l:m:n:qt:svVw:A:S:" FLAG; do
    case "${FLAG}" in
	a)
		MESHED=false
		;;
	A)
		ADD_DISKS_NUMBER="$OPTARG"
		;;
	B)
		UEFI=false
		;;
	c)
		CORES="$OPTARG"
		;;
	d)
		erase_all_vm
		destroy_all_if
		exit 0
		;;
	D)
		DISK_CTRL="$OPTARG"
		;;
	e)
		VNIC="e1000"
		;;
	g)
		DEBUG=true
		;;
	h)
		usage
		;;
	i)
		FILE="$OPTARG"
        ;;
	l)
		LAN="$OPTARG"
		;;
	m)
		RAM="$OPTARG"
		;;
	n)
		NUMBER_VM="$OPTARG"
		;;
	q)
		VERBOSE=false
		;;
	s)
		stop_all_vm
		exit 0
		;;
	S)
		ADD_DISKS_SIZE="$OPTARG"
		;;
	t)
		THREADS="$OPTARG"
		;;
	v)
		VNC=true
		;;
	V)
		VALE=true
		;;
	w)
		WRK_DIR="$OPTARG"
		[ -d "${WRK_DIR}" ] || usage "ERROR: Working directory not found"
		VM_TEMPLATE="${WRK_DIR}/vm_template"
		;;
	*)
		break
        esac
done #while

shift $((OPTIND-1))

#( ${VALE} ) && VNIC="ptnet"

# Check user input
[ ! -f "${VM_TEMPLATE}" ] && [ -z "${FILE}" ] && usage "ERROR: No previous template \
	neither image filename given"

# Validate numeric parameters
validate_number "${NUMBER_VM}" "number of VMs (-n)" 1 255
validate_number "${LAN}" "number of LANs (-l)" 0 255
validate_number "${CORES}" "number of cores (-c)" 1
validate_number "${THREADS}" "number of threads (-t)" 1
validate_number "${ADD_DISKS_NUMBER}" "number of additional disks (-A)" 0
# If default number of VM and LAN, then create at least one LAN
[ ${NUMBER_VM} -eq 1 ] && [ ${LAN} -eq 0 ] && LAN=1

[ -d ${WRK_DIR} ] || mkdir -p ${WRK_DIR}

check_bhyve_support

# if input image given, need to prepare it
if [ -n "${FILE}" ]; then
	uncompress_image
fi

if [ ${UEFI} = true ]; then
	[ -f /usr/local/share/uefi-firmware/BHYVE_UEFI.fd ] || die "Missing bhyve-firmware package for UEFI"
fi

# Clean-up previous interfaces if existing
destroy_all_if

NCPUS=$(( CORES * THREADS ))

if ( ${VERBOSE} ); then
	echo "BSD Router Project (https://bsdrp.net) - bhyve full-meshed lab script"
	echo "Setting-up a virtual lab with $NUMBER_VM VM(s):"
	echo "- Working directory: ${WRK_DIR}"
	echo -n "- Each VM has a total of ${NCPUS} (${CORES} cores and ${THREADS} threads)"
	echo " and ${RAM} RAM"
	echo "- Emulated NIC: ${VNIC}"
	echo -n "- Boot mode: "
	[ ${UEFI} = true ] && echo "UEFI" || echo "BIOS"
	[ ${VNC} = true ] && echo "- Graphical/VNC enabled"
	echo -n "- Switch mode: "
	[ ${VALE} = true ] && echo "vale (netmap)" || echo "bridge + tap"
	echo "- $LAN LAN(s) between all VM"
	[ ${MESHED} = true ] && echo "- Full mesh Ethernet links between each VM"
fi

i=1

TMPCONSOLE=$(mktemp /tmp/console.XXXXXX)

# Enter the main loop for each VM
while [ $i -le $NUMBER_VM ]; do
	is_running ${VM_NAME}_$i && die "VM ${VM_NAME}_$i already runing"
	# Erase already existing VM disk only if:
	#   a image is given
	#   OR it didn't already exists
	# TO DO: Need to use UFS or ZFS snapshot in place of copying the full disk
	[ ! -f ${WRK_DIR}/${VM_NAME}_$i -o -n "${FILE}" ] && cp ${VM_TEMPLATE} ${WRK_DIR}/${VM_NAME}_$i
	# Network_config
	NIC_NUMBER=0
    if ( ${VERBOSE} ); then
		if ( ${DEBUG} ); then
			DEBUG_PORT=$(( DEBUG_BASE_PORT + i ))
			echo "VM $i (debugger port: ${DEBUG_PORT}) has the following NIC:"
		else
			echo "VM $i has the following NIC:"
		fi
	fi

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
				get_nic_driver "${VNIC}" "display"
				( ${VERBOSE} ) && echo "${NIC_NUMBER} connected to VM ${j}"
				# Calculate PCI address for this NIC
				calculate_pci_address ${NIC_NUMBER}
				# Format MAC address octets
				MAC_I=$(format_mac_octet $i)
				MAC_J=$(format_mac_octet $j)
				# We allways use "low number - high number" for identify cables
				if [ $i -le $j ]; then
					if (${VALE} ); then
						SW_CMD="vale${i}${j}:${VM_NAME}_$i"
					else
						BRIDGE_IF=$( create_interface MESH_${i}-${j} bridge )
						TAP_IF=$( create_interface MESH_${i}-${j}_${i} tap ${BRIDGE_IF} )
						SW_CMD=${TAP_IF}
					fi
					eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},\${VNIC},\
${SW_CMD},mac=${MAC_PREFIX}:\${MAC_I}:\${MAC_J}:\${MAC_I}\"

				else
					if (${VALE} ); then
						SW_CMD="vale${j}${i}:${VM_NAME}_$i"
					else
						BRIDGE_IF=$( create_interface MESH_${j}-${i} bridge )
						TAP_IF=$( create_interface MESH_${j}-${i}_${i} tap ${BRIDGE_IF} )
						SW_CMD=${TAP_IF}
					fi
					eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},\${VNIC},\
${SW_CMD},mac=${MAC_PREFIX}:\${MAC_J}:\${MAC_I}:\${MAC_I}\"
				fi
				NIC_NUMBER=$(( NIC_NUMBER + 1 ))
			fi
			j=$(( j + 1 ))
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
		# Format MAC address octets
		MAC_I=$(format_mac_octet $i)
		MAC_J=$(format_mac_octet $j)
		get_nic_driver "${VNIC}" "display"
		( ${VERBOSE} ) && echo "${NIC_NUMBER} connected to LAN number ${j}"
		# Calculate PCI address for this NIC
		calculate_pci_address ${NIC_NUMBER}
		if (${VALE} ); then
			SW_CMD="vale${j}:${VM_NAME}_$i"
		else
			BRIDGE_IF=$( create_interface LAN_${j} bridge )
			TAP_IF=$( create_interface LAN_${j}_${i} tap ${BRIDGE_IF} )
			SW_CMD=${TAP_IF}
		fi
		eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},\${VNIC},\
${SW_CMD},mac=${MAC_PREFIX}:\${MAC_J}:00:\${MAC_I}\"
        NIC_NUMBER=$(( NIC_NUMBER + 1 ))
        j=$(( j + 1 ))
	done # while [ $j -le $LAN ]

	#if (${VALE} ); then
		# PCI_SLOT must be between 0 and 7
		# Need to increase PCI_BUS number if slot is more than 7
	#	PCI_BUS=$(( NIC_NUMBER / 8 ))
	#	PCI_SLOT=$(( NIC_NUMBER - 8 * PCI_BUS ))
		# All PCI_BUS before 2 are already used
	#	PCI_BUS=$(( PCI_BUS + 2 ))
	#	eval VM_NET_${i}=\"\${VM_NET_${i}} -s \${PCI_BUS}:\${PCI_SLOT},ptnetmap-memdev\"
	#fi
	# Start VM
	run_vm $i &
	i=$(( i + 1 ))
done # Main loop: while [ $i -le $NUMBER_VM ]

i=1
# Enter tips main loop for each VM
if ( ${VERBOSE} ); then
	if ( $VNC ); then
		VNC_START=$(( VNC_BASE_PORT + 1 ))
		VNC_END=$(( VNC_BASE_PORT + NUMBER_VM ))
		echo "VM's VNC server TCP ports: ${VNC_START}-${VNC_END}"
	fi
	echo "To connect VM'serial console, you can use:"
	# run_vm was started in background
	# Then need to wait ${TMPCONSOLE} is full
	while [ $(wc -l < ${TMPCONSOLE}) -ne ${NUMBER_VM} ]; do
		sleep 1
	done
	cat ${TMPCONSOLE}
	rm ${TMPCONSOLE}
fi
