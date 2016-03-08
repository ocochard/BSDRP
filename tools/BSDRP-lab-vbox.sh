#!/bin/sh
#
# VirtualBox lab script for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2009-2015, The BSDRP Development Team
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

# Global variable
VM_TPL_NAME="BSDRP_lab_template"
LOG_FILE="${HOME}/BSDRP_lab.log"
DEFAULT_RAM="256"

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

check_system_common () {
	echo "Checking if VirtualBox installed..." >> ${LOG_FILE}

	`VBoxManage -v > /dev/null 2>&1` || die "[ERROR] Is VirtualBox installed ?"
	VBVERSION=`VBoxManage -v`
	VBVERSION_MAJ=`echo $VBVERSION|cut -d . -f 1`
	VBVERSION_MIN=`echo $VBVERSION|cut -d . -f 2`

	[ $VBVERSION_MAJ -lt 4 ] && die "[ERROR] Need Virtualbox 4.1 minimum"
	
	[ $VBVERSION_MAJ -eq 4 -a $VBVERSION_MIN -lt 1 ] &&
		die "[ERROR] Need Virtualbox 4.1 minimum"

	if ! `VBoxHeadless | grep -q vnc`; then
		if ! `VBoxHeadless | grep -q vrde`; then
			echo "No Virtualbox VRD/VNC support detected:"
			echo "BSDRP vga images will not be supported (only serial)"
			echo "VRDE: Supported by Virtualbox closed source release"
			echo "VNC:  Supported by FreeBSD VirtualBox-OSE (if enabled during make config)"
			VBOX_VGA=false
		else
			VBOX_OUTPUT="vrde"
			VBOX_VGA=true
		fi
	else
		VBOX_OUTPUT="vnc"
		VBOX_VGA=true
	fi

}

# Check filename given, and unzip it
check_image () {
	[ -f $1 ] || die "[ERROR] Can't found the file $1"

	if echo $1 | grep -q bz2  >> ${LOG_FILE} 2>&1; then
		echo "Bzip2 compressed image detected, unzip it..."
		which bunzip2 > /dev/null 2>&1 || \
			die "[ERROR] Need bunzip2 for bunzip the compressed image!"
		bunzip2 -fk $1 || die "[ERROR] Can't bunzip2 image file!"

		# change FILENAME by removing the last.bz2"
		FILENAME=`echo $1 | sed -e 's/.bz2//g'`
	elif echo $1 | grep -q xz  >> ${LOG_FILE} 2>&1; then
		echo "xz compressed image detected, unzip it..."
		which xz > /dev/null 2>&1 || \
			die "[ERROR] Need xz for unxz the compressed image!"
		xz -dkf ${FILENAME} || die "[ERROR] Can't unxz image file!"

		# change FILENAME by removing the last.lzma"
		FILENAME=`echo ${FILENAME} | sed -e 's/.xz//g'`
	fi

	file -b ${FILENAME} | grep -q "boot sector"  >> ${LOG_FILE} 2>&1 || \
		die "[ERROR] Not a BSDRP image??"
	
}

# Create BSDRP template VM by converting BSDRP image disk file (given in parameter) into Virtualbox format and compress it
# This template is used only for the image disk
create_template () {
	# Generate $VM_ARCH and $CONSOLE from the filename
	
	[ -z "$VM_ARCH" ] && parse_filename $1

	echo "Create BSDRP template VM..." >> ${LOG_FILE}
	VBoxManage createvm --name ${VM_TPL_NAME} --ostype $VM_ARCH \
		--register >> ${LOG_FILE} 2>&1 || die "[ERROR] Can't create template VM!"

	[ -z "$RAM" ] && RAM=${DEFAULT_RAM}

	# Enabling ICH9 chipset (support 36 NIC)
	VBoxManage modifyvm ${VM_TPL_NAME} --chipset ich9 --audio none \
		--memory $RAM --vram 9 --boot1 disk --floppy disabled \
		>> ${LOG_FILE} 2>&1 || die "[ERROR] Can't customize ${VM_TPL_NAME}"

	VBoxManage modifyvm ${VM_TPL_NAME} --biosbootmenu disabled \
		>> ${LOG_FILE} 2>&1 || die "[ERROR] Can't disable bootmenu for $1"

	echo "Add ATA controller to the VM..." >> ${LOG_FILE}
	VBoxManage storagectl ${VM_TPL_NAME} --name "ATA Controller" \
		--add ide --controller PIIX4 >> ${LOG_FILE} 2>&1 || \
		die "[ERROR] Can't add ATA controller to the VM!"

	echo "Convert BSDRP image disk to VDI..." >> ${LOG_FILE}
	VBoxManage convertfromraw "$1" \
		"${WORKING_DIR}/${VM_TPL_NAME}/${VM_TPL_NAME}.vdi" \
		>> ${LOG_FILE} 2>&1 || die "[ERROR] Can't convert BSDRP image disk!"

	echo "Add the VDI to the VM..." >> ${LOG_FILE}
	VBoxManage storageattach ${VM_TPL_NAME} --storagectl "ATA Controller" \
		--port 0 --device 0 --type hdd \
		--medium "${WORKING_DIR}/${VM_TPL_NAME}/${VM_TPL_NAME}.vdi" \
		>> ${LOG_FILE} 2>&1 || die "[ERROR] Can't add VDI to the VM!"

	VBoxManage modifyvm ${VM_TPL_NAME} --uart1 0x3F8 4 \
		--uartmode1 server /tmp/${VM_TPL_NAME}.serial \
		>> ${LOG_FILE} 2>&1 || \
		die "[ERROR] Can't configure serial port for ${VM_TPL_NAME}"

	echo "Compress the VDI..." >> ${LOG_FILE}
	VBoxManage modifyvdi "${WORKING_DIR}/${VM_TPL_NAME}/${VM_TPL_NAME}.vdi" \
		--compact >> ${LOG_FILE} 2>&1 || \
		die "[ERROR] Can't compres the VDI!"

	# Enable pagefusion (avoid duplicate RAM use between all routers)
	# pagefusion works only on 64bit host & guest with VT-X/AMD-V
	if [ "$VM_ARCH" = "FreeBSD_64" ]; then
		if [ "$MACHINE_TYPE" = "amd64" -o "$MACHINE_TYPE" = "x86_64" ]; then
			VBoxManage modifyvm ${VM_TPL_NAME} --pagefusion on \
				>> ${LOG_FILE} 2>&1 || \
				echo "[WARNING] Can't enable pagefusion"
		fi
	fi

	#Save CONSOLE type to extradata
	($SERIAL) && VBoxManage setextradata ${VM_TPL_NAME} Console Serial || \
		 VBoxManage setextradata ${VM_TPL_NAME} Console VGA

	echo "Take a snapshot (will be the base for linked-vm)..."  >> ${LOG_FILE} 2>&1
	VBoxManage snapshot ${VM_TPL_NAME} take SNAPSHOT \
		--description  "Snapshot used for linked clone" \
		>> ${LOG_FILE} 2>&1 || die "[ERROR] Can't take a snapshot"
}

# Check if VM allready exist
# Return 0 (true) if exist
# Returen 1 (false) if doesn't exist
check_vm () {
	echo "Check if $1 exist..." >> ${LOG_FILE}
   if `VBoxManage showvminfo $1 > /dev/null 2>&1`; then
	   echo "Found it..." >> ${LOG_FILE}
	   return 0 # true
   else
	   echo "Didn't found it..." >> ${LOG_FILE}
	   return 1 # false
   fi
}

# Clone VM
# $1 : Name of the VM
clone_vm () {
	[ "$1" = "" ] && die "[BUG] In function clone_vm() that need a vm name"

# Check if the vm allready exist
if ! check_vm $1; then
	echo "Clone VM $1..." >> ${LOG_FILE}
	VBoxManage clonevm ${VM_TPL_NAME} --name $1 --snapshot SNAPSHOT \
		--options link --register >> ${LOG_FILE} 2>&1 || \
		die "[ERROR] Can't clone $1"
	VBoxManage modifyvm $1 --uartmode1 server /tmp/$1.serial \
		>> ${LOG_FILE} 2>&1 || \
		die "[ERROR] Can't configure serial port for $1"
	echo "VM $1 cloned" >> ${LOG_FILE}
else
	# if existing: Is running ?
	if `VBoxManage showvminfo $1 | grep -q "running"`; then
		VBoxManage controlvm $1 poweroff ||
			echo "[ERROR] Can't poweroff running $1"
	fi
	delete_all_nic $1
fi
}

delete_all_nic () { 
	#Delete all NIC
	local NIC_LIST=""
	NIC_lIST=`VBoxManage showvminfo $1 | grep MAC | cut -d ' ' -f 2 | cut -d ':' -f 1`
	for i in ${NIC_LIST}; do
		VBoxManage modifyvm $1 --nic$i none >> ${LOG_FILE} 2>&1 || \
			echo "[WARNING] Can't unconfigure NIC $i"
	done
}

# Parse filename for detecting ARCH and console
parse_filename () {
	if echo "$1" | grep -q "amd64"; then
		VM_ARCH="FreeBSD_64"
		echo "x86-64 image"
	fi
	
	if echo "$1" | grep -q "i386"; then
		VM_ARCH="FreeBSD"
		echo "i386 image"
	fi
	[ "$VM_ARCH" = "0" ] && die "[ERROR] Can't deduce arch type from filename"
 
	# SERIAL can bÃe allready set from CLI options 
	if [ -z ${SERIAL} ]; then  
		if echo "$1" | grep -q "serial"; then
			SERIAL=true
			echo "serial image"
		fi
		if echo "$1" | grep -q "vga"; then
			SERIAL=false
			echo "vga image"
			if ! $VBOX_VGA; then
				die "[ERROR] You can't use BSDRP vga release with a Virtualbox that didn't support RDP or VNC"
			fi
		fi
	fi

}

# This function generate the clones
build_lab () {
	echo "Setting-up a lab with $NUMBER_VM router(s):"
	echo "- $LAN LAN between all routers"
	echo "- Full mesh Ethernet links between each routers"
	if ($HOSTONLY_NIC); then
		echo "- One NIC connected to the shared LAN with the host"
	fi
	if ($VIRTIO); then
		echo "- Virtio interfaces enabled"
		NIC_TYPE="virtio"
		DRIVER_TYPE="vtnet"
	else
		NIC_TYPE="82540EM"
		DRIVER_TYPE="em"
	fi
	[ -n "$RAM" ] && echo "- RAM: $RAM MB each"
	
	echo ""
	local i=1
	#Enter the main loop for each VM
	while [ $i -le $NUMBER_VM ]; do
		clone_vm BSDRP_lab_R$i

		if [ -n "$RAM" ]; then
			#Configure RAM
			VBoxManage modifyvm BSDRP_lab_R$i --memory $RAM \
				>> ${LOG_FILE} 2>&1 || \
				die "[ERROR] Can't change RAM for BSDRP_lab_R$i"
		fi

		NIC_NUMBER=0
		echo "Router$i have the following NIC:"
		#Enter in the Cross-over (Point-to-Point) NIC loop
		#Now generate X x (X-1)/2 full meshed link
		local j=1
		while [ $j -le $NUMBER_VM ]; do
			if [ $i -ne $j ]; then
				echo "${DRIVER_TYPE}${NIC_NUMBER} connected to Router${j}."
				NIC_NUMBER=$(( ${NIC_NUMBER} + 1 ))
				if [ $i -le $j ]; then
					#Need to manage correct mac address
					[ $i -le 9 ] && MAC_I="0$i" || MAC_I="$i"
					[ $j -le 9 ] && MAC_J="0$i" || MAC_J="$i"
					VBoxManage modifyvm BSDRP_lab_R$i \
						--nic${NIC_NUMBER} intnet \
						--nictype${NIC_NUMBER} ${NIC_TYPE} \
						--intnet${NIC_NUMBER} LAN${i}${j} \
						--macaddress${NIC_NUMBER} AAAA00${MAC_I}${MAC_I}${MAC_J} \
						--nicpromisc${NIC_NUMBER} allow-vms \
						>> ${LOG_FILE} 2>&1 || \
						die "[ERROR] Can't add NIC ${NIC_NUMBER} (full mesh) to VM $i"
				else
					VBoxManage modifyvm BSDRP_lab_R$i \
						--nic${NIC_NUMBER} intnet \
						--nictype${NIC_NUMBER} ${NIC_TYPE} \
						--intnet${NIC_NUMBER} LAN${j}${i} \
						--macaddress${NIC_NUMBER} AAAA00000${i}${j}${i} \
						--nicpromisc${NIC_NUMBER} allow-vms \
						>> ${LOG_FILE} 2>&1 || \
						die "[ERROR] Can't add NIC ${NIC_NUMBER} (full mesh) to VM $i"
				fi
			fi
			j=$(( $j + 1 ))
		done
		#Enter in the LAN NIC loop
		local j=1
		while [ $j -le $LAN ]; do
			#Need to manage correct mac address
			[ $i -le 9 ] && MAC_I="0$i" || MAC_I="$i"
			[ $j -le 9 ] && MAC_J="0$i" || MAC_J="$i"

			echo "${DRIVER_TYPE}${NIC_NUMBER} connected to LAN number ${j}."
			NIC_NUMBER=$(( ${NIC_NUMBER} + 1 ))
			VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet \
				--nictype${NIC_NUMBER} ${NIC_TYPE} \
				--intnet${NIC_NUMBER} LAN10${j} \
				--macaddress${NIC_NUMBER} CCCC0000${MAC_J}${MAC_I} \
				--nicpromisc${NIC_NUMBER} allow-vms \
				>> ${LOG_FILE} 2>&1 || \
				die "[ERROR] Can't add NIC ${NIC_NUMBER} (LAN) to VM $i"
			j=$(( $j + 1 ))
		done
		if ($HOSTONLY_NIC); then
			#Need to manage correct mac address
			[ $i -le 9 ] && MAC_I="0$i" || MAC_I="$i"
			
			echo "${DRIVER_TYPE}${NIC_NUMBER} connected to shared-with-host LAN."
			NIC_NUMBER=$(( ${NIC_NUMBER} + 1 ))
			VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} hostonly \
				--hostonlyadapter${NIC_NUMBER} ${HOSTONLY_NIC_NAME} \
				--nictype${NIC_NUMBER} ${NIC_TYPE} \
				--macaddress${NIC_NUMBER} 00bbbb0000${MAC_I} \
				--nicpromisc${NIC_NUMBER} allow-vms >> ${LOG_FILE} 2>&1 || \
				die "[ERROR] Can't add NIC ${NIC_NUMBER} (Host only) to VM $i"
		fi
		i=$(( $i + 1 ))
	done
}

# Start each vm
start_lab () {
	local i=1
	echo "Start the lab..."

	# if console mode is not forced: need to look in extrada for getting console type
	if [ -z ${SERIAL} ]; then
		VBoxManage getextradata ${VM_TPL_NAME} Console | grep -q Serial \
			&& SERIAL=true || SERIAL=false
	fi
	#Enter the main loop for each VM
	while [ $i -le $NUMBER_VM ]; do
		if ! ($SERIAL); then
			[ $i -le 9 ] && VNC_PORT="0$i" || VNC_PORT="$i"
			if [ "${VBOX_OUTPUT}" = "vnc" ]; then
				nohup VBoxHeadless --vnc --${VBOX_OUTPUT}port 59${VNC_PORT} --startvm BSDRP_lab_R$i >> ${LOG_FILE} 2>&1 &
			else
				# --vrdeport seems to have disappeared from VBoxHeadless (at least on 4.3.36)
				# use VBoxManage modifyvm instead and start with config
				VBoxManage modifyvm BSDRP_lab_R$i --${VBOX_OUTPUT}port 59${VNC_PORT} || \
					die "[ERROR] Can't set ${VBOX_OUTPUT}port to 59${VNC_PORT} for VM $i"
				nohup VBoxHeadless --${VBOX_OUTPUT} on --startvm BSDRP_lab_R$i >> ${LOG_FILE} 2>&1 &
			fi
		else
			nohup VBoxHeadless --startvm BSDRP_lab_R$i >> ${LOG_FILE} 2>&1 &
		fi
		sleep 2

		if ($SERIAL); then
			echo "Connect to router ${i}: socat unix-connect:/tmp/BSDRP_lab_R${i}.serial stdio,raw,echo=0,icanon=0"
		else
			echo "Connect to router ${i}: connect a ${VBOX_OUTPUT} client on port 590${i}"
		fi
		i=$(( $i + 1 ))
	done

	if ($HOSTONLY_NIC); then
		echo "You need to configure an IP address in these range for communicating with the host:"
		/sbin/ifconfig ${HOSTONLY_NIC_NAME} | grep "inet"
	fi
}

# Delete VM
# $1: name of the VM
delete_vm () {
	[ "$1" = "" ] && die "BUG: In delete_vm (), no argument given"

	echo "Delete VM $1" >> ${LOG_FILE} 2>&1
   	echo "Delete VM $1" 
	VBoxManage unregistervm $1 --delete >> ${LOG_FILE} 2>&1 || \
		die "[ERROR] Can't delete VM $1, Check ${LOG_FILE}."

	#Some times, templates is deletet, but there is some file that was not deletet
	if ! check_vm $1; then
		if [ -d "${WORKING_DIR}/$1" ]; then
			echo "[WARNING] Force deleting directory for $1"
			rm -rf "${WORKING_DIR}/$1"
		fi
	fi

}
delete_all_vm () {
	stop_all_vm
	local LIST_VM=""
	LIST_VM=`VBoxManage list vms | grep BSDRP_lab_R | cut -d "\"" -f 2`
	#Enter the main loop for each cloned VM
	for i in ${LIST_VM}; do
		check_vm $i && delete_vm $i
	done
	#And, at last, delete the template
	check_vm ${VM_TPL_NAME} && delete_vm ${VM_TPL_NAME}
	echo "All VMs deleted"
}

# Stop All VM
stop_all_vm () {
	local LIST_RUNNING_VM=""
	LIST_RUNNING_VM=`VBoxManage list runningvms | grep BSDRP_lab | cut -d "\"" -f 2`
	#Enter the main loop for each VM
	for i in ${LIST_RUNNING_VM}; do
		echo "Stopping $i..."
		VBoxManage controlvm $i poweroff >> ${LOG_FILE} 2>&1 || \
			echo "[WARNING] Can't poweroff $i"
	done
}

# Get Virtualbox hostonly adapter informatiom
vbox_hostonly () {
	if ! `VBoxManage list hostonlyifs | grep "^Name:"  >> ${LOG_FILE} 2>&1`; then
		echo "ERROR: Not VBox hostonly NIC, you need to create one:"
		echo "VBoxManage hostonlyif create"
		echo "VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0"
		echo "VBoxManage dhcpserver remove --ifname vboxnet0"
		exit 1
	fi

	HOSTONLY_NIC_NAME=`VBoxManage list hostonlyifs | grep "^Name:" | cut -d ':' -f 2 | sed 's/^[ \t]*//;s/[ \t]*$//' | head -n 1`
}

usage () {
	(
	echo "Usage: $0 [-hdsv] [-a i386|amd64] [-i BSDRP_image_file.img] [-n router-number] [-l LAN-number] [-o serial|vga]"
	echo "  -a ARCH    Force architecture: i386 or amd"
	echo "             This disable automatic arch/console detection from the filename"
	echo "             You should use -o with -a"
	echo "  -c         Enable internal NIC shared with host for each routers (default: Disable)"
	echo "  -d         Delete all BSDRP VM and disks"
	echo "  -i filename BSDRP image file name (to be used the first time only)"
	echo "  -h         Display this help"
	echo "  -l Y       Number of LAN between 0 and 9 (default: 0)"
	echo "  -m         RAM (in MB) for each VM (default: ${DEFAULT_RAM})"
	echo "  -n X       Number of router (between 1 and 9) full meshed (default: 1)"
	echo "  -o CONS    Force console:vga (default if -a) or serial" 
	echo "  -s         Stop all VM"
	echo "  -v         Enable virtio drivers"
	echo ""
	) 1>&2
	exit 2
}

###############
# Main script #
###############

### Parse argument

args=`getopt a:i:dhcl:m:n:o:sv $*`
[ $? -ne 0 ] && usage

NUMBER_VM=""
HOSTONLY_NIC=false
VIRTIO=false
LAN=""
FILENAME=""
RAM=""
SERIAL=""
VM_ARCH=""

echo "BSD Router Project (http://bsdrp.net) - VirtualBox lab script"

echo "BSD Router Project (http://bsdrp.net) - Virtualbox lab script, log file" > ${LOG_FILE}

OS_DETECTED=`uname -s`
MACHINE_TYPE=`uname -m`

check_system_common

case "$OS_DETECTED" in
	"FreeBSD")
		kldstat -m vboxdrv > /dev/null 2>&1 || \
			echo "[WARNING] vboxdrv module not loaded ?"
		break
		;;
	"Linux")
		grep -q vboxdrv /proc/modules || \
			echo "[WARNING] VirtualBox module not loaded ?"
		break
		;;
	*)
		echo "ERROR: This script doesn't support $OS_DETECTED"
		exit 1
		;;
esac

WORKING_DIR=`VBoxManage list systemproperties | grep "Default machine folder" | cut -d ":" -f 2 | tr -s " " | sed '1s/^.//'`
MAX_NIC=`VBoxManage list systemproperties | grep "Maximum ICH9 Network Adapter count" | cut -d ":" -f 2 | tr -s " " | sed '1s/^.//'`
# A full mesh network consume, on each machine, N-1 VNIC
MAX_VM=$(( $MAX_NIC + 1 ))

set -- $args
for i do
	case "$i" in
		-a)
			if [ "$2" = "i386" ]; then
				VM_ARCH="FreeBSD"
			elif [ "$2" = "amd64" ]; then
				VM_ARCH="FreeBSD_64"
			else
				echo "INPUT ERROR: Bad ARCH name"
				usage
			fi
			shift
			shift
			;;
		-n)
			NUMBER_VM=$2
			shift
			shift
			;;
		-c)
			HOSTONLY_NIC=true
			shift
			;;
		-d)
			delete_all_vm
			exit 0
			;;
		-l)
			LAN=$2
			shift
			shift
			;;
		-h)
			usage
			;;
		-i)
			FILENAME="$2"
			echo "Filename given, delete existing lab"
			delete_all_vm
			shift
			shift
			;;
		-m)
			RAM="$2"
			shift
			shift
			;;
		-o)
			if [ "$2" = "vga" ]; then
				SERIAL=false
			elif [ "$2" = "serial" ]; then
				SERIAL=true
			else
				echo "INPUT ERROR: Bad OUTPUT name"
				usage
			fi
			shift
			shift
			;;
		-s)
			stop_all_vm
			exit 0
			;;
		-v)
			VIRTIO=true
			shift
			;;
		--)
			shift
			break
	esac
done

id ${USER} | grep -q vboxusers || \
	die "[WARNING] Your user is not in the vboxusers group"

if [ "$NUMBER_VM" != "" ]; then
	[ $NUMBER_VM -lt 1 ] && die "[ERROR] Use a minimal of 1 router in your lab."
	[ $NUMBER_VM -gt $MAX_VM ] && \
		die "[ERROR] Use a maximum of $MAX_VM routers in your lab (Vbox don't support more than $MAX_NIC VNIC to a VM."
else
	NUMBER_VM=1
fi

if [ $NUMBER_VM -eq 1 ]; then
	# Impose shared-with-host NIC if only one router started
	HOSTONLY_NIC=true
fi

if [ "$LAN" != "" ]; then
	[ $LAN -gt $MAX_NIC ] && \
		die "[ERROR] Use a maximum of $MAX_VM routers in your lab (Vbox don't support more than $MAX_NIC VNIC to a VM."
else
	LAN=0
fi

if [ $# -gt 0 ] ; then
	echo "$0: Extraneous arguments supplied"
	usage
fi

($HOSTONLY_NIC) && vbox_hostonly

#Count the number of available NIC

($HOSTONLY_NIC) && TOTAL_NIC=1 || TOTAL_NIC=0
TOTAL_NIC=$(( $TOTAL_NIC + $LAN )) || true
TOTAL_NIC=$(( $TOTAL_NIC + $NUMBER_VM - 1 )) || true
[ $TOTAL_NIC -gt $MAX_NIC ] && die "[ERROR] you can't have more than $MAX_NIC VNIC by VM"

if ! check_vm ${VM_TPL_NAME}; then
	if [ "$FILENAME" != "" ]; then
		check_image ${FILENAME}
		#Note: check_image will change the $FILENAME variable...
		create_template ${FILENAME}
	else
		die "[ERROR] You need to enter an image filename for creating the VM."
	fi
fi

build_lab
start_lab
