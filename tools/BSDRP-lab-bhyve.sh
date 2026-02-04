#!/bin/sh
#
# Bhyve lab script for BSD Router Project
# https://bsdrp.net
#
# Copyright (c) 2013-2026, The BSDRP Development Team
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

### PCI Address Allocation Scheme ###
#
# bhyve VMs use PCI devices for all virtual hardware. The script assigns
# PCI addresses dynamically based on the number and type of devices.
#
# Fixed PCI Assignments:
#   Bus 0, Slot 0: hostbridge (required for all VMs)
#   Bus 0, Slot 1: LPC bridge for serial console (amd64 only)
#   Bus 1, Slot 0: Primary disk controller (virtio-blk/ahci-hd/nvme)
#   Bus 1, Slot 1+: Additional disk controllers (if -A option used)
#   Slot 29:       Framebuffer device for VNC (if -v option used)
#
# Dynamic NIC Assignments:
#   NICs are assigned starting from Bus 2, Slot 0
#   With 8 slots per bus, addressing is:
#     NIC 0-7:   Bus 2, Slots 0-7
#     NIC 8-15:  Bus 3, Slots 0-7
#     NIC 16-23: Bus 4, Slots 0-7
#     etc.
#
# Formula: For NIC number N:
#   PCI_BUS  = (N / 8) + 2
#   PCI_SLOT = N % 8
#
# Example: VM with 3 meshed connections + 2 LANs = 5 NICs total
#   NIC 0: Bus 2, Slot 0 (mesh to VM 2)
#   NIC 1: Bus 2, Slot 1 (mesh to VM 3)
#   NIC 2: Bus 2, Slot 2 (mesh to VM 4)
#   NIC 3: Bus 2, Slot 3 (LAN 1)
#   NIC 4: Bus 2, Slot 4 (LAN 2)

### MAC Address Format ###
#
# All VMs use locally administered MAC addresses with a common prefix
# to avoid conflicts with physical hardware.
#
# MAC Address Format: 58:9c:fc:XX:YY:ZZ
#
# Prefix: 58:9c:fc (bit 1 of first octet = 1, marking locally administered)
#
# For Mesh Network Links (point-to-point between two VMs):
#   XX = Lower VM number (zero-padded to 2 digits)
#   YY = Higher VM number (zero-padded to 2 digits)
#   ZZ = Current VM number (zero-padded to 2 digits)
#
#   Example: Link between VM 1 and VM 3
#     VM 1 interface: 58:9c:fc:01:03:01
#     VM 3 interface: 58:9c:fc:01:03:03
#
# For LAN Links (shared broadcast domain):
#   XX = LAN number (zero-padded to 2 digits)
#   YY = 00 (fixed, identifies LAN vs mesh)
#   ZZ = Current VM number (zero-padded to 2 digits)
#
#   Example: VM 5 connected to LAN 2
#     VM 5 interface: 58:9c:fc:02:00:05
#
# This scheme ensures:
#   - All MAC addresses are unique
#   - Mesh link partners can be identified from MAC
#   - LAN membership can be identified from MAC
#   - No conflicts across up to 255 VMs and 255 LANs

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
  echo " -r lab       Regression tests, labconfig familly to use"
  echo "              Generate a cloudinit disk, instructing to run labconfig"
  echo "              Example, with 'full', will run labconfig full_vm1 for the first VM,"
  echo "              then labconfig full_vm2 for the second VM, etc."
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
  rm -rf ${WRK_DIR}
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

# Load FreeBSD bootloader for amd64 architecture
# Arguments:
#   $1: VM number
#   $2: NMDM device ID
# Returns: 0 on success
# Note: Only needed for amd64 BIOS mode; UEFI and ARM64 use firmware
load_vm_bootloader() {
	local vm_num=$1
	local nmdm_id=$2

	if [ "${arch}" = "amd64" ]; then
		${SUDO} bhyveload -S -m ${RAM} \
			-d ${WRK_DIR}/${VM_NAME}_${vm_num} \
			-c /dev/nmdm${nmdm_id}A \
			${VM_NAME}_${vm_num}
	fi
}

# Build console arguments for bhyve based on architecture
# Arguments:
#   $1: VM number
#   $2: NMDM device ID
# Returns: console argument string via echo
build_vm_console_args() {
	local vm_num=$1
	local nmdm_id=$2

	if [ "${arch}" = "amd64" ]; then
		echo "-l com1,/dev/nmdm${nmdm_id}A"
	elif [ "${arch}" = "aarch64" ]; then
		echo "-o console=/dev/nmdm${nmdm_id}A"
	fi
}

# Build disk arguments for bhyve (primary + additional disks)
# Arguments:
#   $1: VM number
# Returns: disk argument string via echo
build_vm_disk_args() {
	local vm_num=$1
	local disk_args="-s 1:0,${DISK_CTRL},${WRK_DIR}/${VM_NAME}_${vm_num}"

	# Add additional disks if configured
	if [ ${ADD_DISKS_NUMBER} -gt 0 ]; then
		local i
		for i in $(jot ${ADD_DISKS_NUMBER}); do
			# Create disk file if it doesn't exist
			if ! [ -f ${WRK_DIR}/${VM_NAME}_${vm_num}_add_${i} ]; then
				truncate -S ${ADD_DISKS_SIZE} ${WRK_DIR}/${VM_NAME}_${vm_num}_add_${i}
			fi
			disk_args="${disk_args} -s 1:${i},ahci-hd,${WRK_DIR}/${VM_NAME}_${vm_num}_add_${i}"
		done
	fi

	echo "${disk_args}"
}

# Build cloud-init disk argument
# Arguments:
#   $1: Lab name and vm name compliant to labconfig arg (ex: full_vm1)
build_vm_disk_cloudinit_args() {
  local lab=$1
  local cloudinit_args=""
  if [ -n "${REG_LAB}" ]; then
    mkdir -p ${WRK_DIR}/cloudinit/${lab}
    cat > ${WRK_DIR}/cloudinit/${lab}/meta-data <<EOF
#cloud-config
hostname: ${lab}.lab.bsdrp.net
EOF
    cat > ${WRK_DIR}/cloudinit/${lab}/user-data <<EOF
#cloud-config
runcmd:
  - /usr/local/sbin/labconfig ${lab}
EOF
    # Generate a 64MB VFAT image from the directory
    makefs -t msdos \
      -o "volume_label=cidata" \
      -o fat_type=12 \
      -s 2m \
      ${WRK_DIR}/cloudinit/${lab}.img ${WRK_DIR}/cloudinit/${lab} > /dev/null

    cloudinit_args="-s 1:7,virtio-blk,${WRK_DIR}/cloudinit/${lab}.img"
  fi
  echo "${cloudinit_args}"
}

# Build debug arguments for bhyve (remote gdb support)
# Arguments:
#   $1: VM number
# Returns: debug argument string via echo (empty if debug disabled)
build_vm_debug_args() {
	local vm_num=$1

	if [ "${DEBUG}" = "true" ]; then
		local debug_port=$(( DEBUG_BASE_PORT + vm_num ))
		echo "-g ${debug_port}"
	else
		echo ""
	fi
}

# Build VNC framebuffer arguments for bhyve
# Arguments:
#   $1: VM number
# Returns: VNC argument string via echo (empty if VNC disabled)
build_vm_vnc_args() {
	local vm_num=$1

	if [ ${VNC} = true ]; then
		local vnc_port=$(( VNC_BASE_PORT + vm_num ))
		echo "-s 29,fbuf,tcp=0.0.0.0:${vnc_port},w=800,h=600"
	else
		echo ""
	fi
}

# Start a bhyve virtual machine with networking and console setup
# Arguments:
#   $1: VM number identifier
# Returns: continues in infinite loop for VM reboots
run_vm() {
	local vm_num=$1
	local firstboot=true
	local nmdm_id=""

	# Infinite loop to support VM reboots initiated from within the guest
	while true; do
		# On first boot only, allocate a unique nmdm device for console
		# Reuse the same device on subsequent reboots
		if [ "${firstboot}" = "true" ]; then
			nmdm_id=$(get_free_nmdm ${vm_num})
			firstboot=false
		fi

		# Load bootloader (amd64 BIOS mode only)
		load_vm_bootloader ${vm_num} "${nmdm_id}"

		# Build base bhyve command with CPU/RAM configuration
		# bhyve options:
		#   -c: CPU topology (cores, threads)
		#   -S: Wire guest memory (prevent swapping)
		#   -m: RAM size
		#   -A: Generate ACPI tables (amd64 only)
		#   -H: Yield CPU on HLT instruction (power saving)
		#   -P: Pin vCPUs to host CPUs (performance)
		local vm_cmd="${SUDO} bhyve -c cpus=${NCPUS},cores=${CORES},threads=${THREADS} -S -m ${RAM} -s 0:0,hostbridge"

		# Add architecture-specific options
		local vm_boot=""
		if [ "${arch}" = "amd64" ]; then
			vm_cmd="${vm_cmd} -A -H -P -s 0:1,lpc"
			# Use UEFI firmware if enabled, otherwise BIOS (bhyveload above)
			if [ ${UEFI} = true ]; then
				vm_boot="-l bootrom,/usr/local/share/uefi-firmware/BHYVE_UEFI.fd"
			fi
		elif [ "${arch}" = "aarch64" ]; then
			vm_cmd="${vm_cmd} -o bootrom=/usr/local/share/u-boot/u-boot-bhyve-arm64/u-boot.bin"
		fi

		# Build component argument strings using helper functions
		local vm_console=$(build_vm_console_args ${vm_num} "${nmdm_id}")
		local vm_disk=$(build_vm_disk_args ${vm_num})
    local vm_disk_cloudinit=$(build_vm_disk_cloudinit_args ${REG_LAB}_vm${vm_num})
		local vm_debug=$(build_vm_debug_args ${vm_num})
		local vm_vnc=$(build_vm_vnc_args ${vm_num})

		# Get network configuration from dynamic variable VM_NET_$vm_num
		# This must use eval because each VM (running in parallel) has its own
		# network configuration built in the main loop
		local vm_net=""
		eval "vm_net=\"\${VM_NET_${vm_num}}\""

		# Store console connection command for user display
		echo "- VM ${vm_num} : ${SUDO} cu -l /dev/nmdm${nmdm_id}B" >> ${TMPCONSOLE}

		# Execute bhyve with all configured options
		# Exit codes: 0=reboot, 1=poweroff, 2=halt, 3=triple-fault, 4=error
		set +e
		${vm_cmd} ${vm_boot} ${vm_vnc} ${vm_net} ${vm_disk} ${vm_disk_cloudinit} ${vm_console} ${vm_debug} ${VM_NAME}_${vm_num}
		local exit_code=$?
		set -e

		# Break loop if VM powered off or encountered error (not a reboot)
		if [ ${exit_code} -ne 0 ]; then
			break
		fi
	done

	# Cleanup VM resources
	destroy_vm ${VM_NAME}_${vm_num}
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

while getopts "aBc:dghD:ei:l:m:n:qr:t:svVw:A:S:" FLAG; do
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
  r)
    REG_LAB="$OPTARG"
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
  [ -n "${REG_LAB}" ] && echo "- Regression test lab: ${REG_LAB}"
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
	# === Network Configuration ===
	# Build bhyve NIC arguments for this VM
	# Each VM gets assigned NIC_NUMBER sequential NICs (mesh + LAN)
	NIC_NUMBER=0
    if ( ${VERBOSE} ); then
		if ( ${DEBUG} ); then
			DEBUG_PORT=$(( DEBUG_BASE_PORT + i ))
			echo "VM $i (debugger port: ${DEBUG_PORT}) has the following NIC:"
		else
			echo "VM $i has the following NIC:"
		fi
	fi

	# === Mesh Network Topology ===
	# Generate full mesh: each VM connects point-to-point to every other VM
	# For N VMs, creates N*(N-1)/2 total links
	#
	# Example with 3 VMs:
	#        VM1                            VM2
	#    (TAP1-2_1) ---- BRIDGE1-2 ---- (TAP1-2_2)
	#    (TAP1-3_1)                     (TAP2-3_2)
	#            \                        /
	#         BRIDGE1-3              BRIDGE2-3
	#              \                   /
	#           (TAP1-3_3)       (TAP2-3_3)
	#                        VM3
	#
	# Initialize network args string for this VM (using eval for parallel execution)
	# VM_NET_1, VM_NET_2, etc. are built here and read in run_vm()
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
				# Format MAC address octets (zero-padded)
				MAC_I=$(format_mac_octet $i)
				MAC_J=$(format_mac_octet $j)

				# Cable naming: always use "lower-higher" (e.g., link 1-3, not 3-1)
				# This ensures both VMs on a link reference the same bridge/vale switch
				# Without this, VM1-VM3 link would create both BRIDGE1-3 and BRIDGE3-1
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
