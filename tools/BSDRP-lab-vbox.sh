#!/bin/sh
#
# VirtualBox lab script for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2009-2012, The BSDRP Development Team
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

#Uncomment for debug
#set -x

set -eu

# Global variable
VM_TPL_NAME="BSDRP_lab_template"
LOG_FILE="${HOME}/BSDRP_lab.log"

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# Check FreeBSD system pre-requise for starting virtualbox
check_system_freebsd () {
    if ! kldstat -m vboxdrv > /dev/null 2>&1; then
        echo "[WARNING] vboxdrv module not loaded ?"
    fi
}

check_system_common () {
	echo "Checking if VirtualBox installed..." >> ${LOG_FILE}

    if ! `VBoxManage -v > /dev/null 2>&1`; then
        die "[ERROR] Is VirtualBox installed ?"
    fi
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

check_system_linux () {
	if ! `grep -q vboxdrv /proc/modules`; then
		echo "[WARNING] VirtualBox module not loaded ?"
	fi
}

# Check user
check_user () {
    if ! `id ${USER} | grep -q vboxusers`; then
        die "[WARNING] Your user is not in the vboxusers group"
    fi
}

# Check filename given, and unzip it
check_image () {
    [ -f $1 ] || die "[ERROR] Can't found the file $1"

    if echo $1 | grep -q bz2  >> ${LOG_FILE} 2>&1; then
        echo "Bzip2 compressed image detected, unzip it..."
		if ! which bunzip2 > /dev/null 2>&1; then
			die "[ERROR] Need bunzip2 for bunzip the compressed image!"
		fi
        bunzip2 -fk $1 || die "[ERROR] Can't bunzip2 image file!"

        # change FILENAME by removing the last.bz2"
        FILENAME=`echo $1 | sed -e 's/.bz2//g'`
    elif echo $1 | grep -q xz  >> ${LOG_FILE} 2>&1; then
        echo "xz compressed image detected, unzip it..."
		if ! which xz > /dev/null 2>&1; then
            die "[ERROR] Need xz for unxz the compressed image!"
        fi
        xz -dkf ${FILENAME} || die "[ERROR] Can't unxz image file!"

        # change FILENAME by removing the last.lzma"
        FILENAME=`echo ${FILENAME} | sed -e 's/.xz//g'`
	fi

    if ! `file -b ${FILENAME} | grep -q "boot sector"  >> ${LOG_FILE} 2>&1`; then
        die "[ERROR] Not a BSDRP image??"
    fi
	
}

# Create BSDRP template VM by converting BSDRP image disk file (given in parameter) into Virtualbox format and compress it
# This template is used only for the image disk
create_template () {
	echo "Image file given... rebuilding BSDRP router template and deleting all routers"
	echo "Check if BSDRP template VM exist..." >> ${LOG_FILE}
    if check_vm ${VM_TPL_NAME}; then
		echo "Found: Deleting all BSDRP routers VM..."
        delete_all_vm
    fi

	# Generate $VM_ARCH and $CONSOLE from the filename	
	parse_filename $1

	echo "Create BSDRP template VM..." >> ${LOG_FILE}
    if ! VBoxManage createvm --name ${VM_TPL_NAME} --ostype $VM_ARCH --register >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't create template VM!"
	fi

	if [ -z "$RAM" ]; then
		RAM=192
	fi

	# Enabling ICH9 chipset (support 36 NIC)
    if ! VBoxManage modifyvm ${VM_TPL_NAME} --chipset ich9 --audio none --memory $RAM --vram 8 --boot1 disk --floppy disabled >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't customize ${VM_TPL_NAME}"
	fi

    if ! VBoxManage modifyvm ${VM_TPL_NAME} --biosbootmenu disabled >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't disable bootmenu for $1"
	fi

	echo "Add ATA controller to the VM..." >> ${LOG_FILE}
	if ! VBoxManage storagectl ${VM_TPL_NAME} --name "ATA Controller" --add ide --controller PIIX4 >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't add ATA controller to the VM!"
	fi

	echo "Convert BSDRP image disk to VDI..." >> ${LOG_FILE}
    if ! VBoxManage convertfromraw "$1" "${WORKING_DIR}/${VM_TPL_NAME}/${VM_TPL_NAME}.vdi" >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't convert BSDRP image disk!"
	fi

	echo "Add the VDI to the VM..." >> ${LOG_FILE}
	if ! VBoxManage storageattach ${VM_TPL_NAME} --storagectl "ATA Controller" \
    --port 0 --device 0 --type hdd \
    --medium "${WORKING_DIR}/${VM_TPL_NAME}/${VM_TPL_NAME}.vdi" >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't add VDI to the VM!"
	fi

    if ! VBoxManage modifyvm ${VM_TPL_NAME} --uart1 0x3F8 4 --uartmode1 server /tmp/${VM_TPL_NAME}.serial >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't configure serial port for ${VM_TPL_NAME}"
	fi

	echo "Compress the VDI..." >> ${LOG_FILE}
    if ! VBoxManage modifyvdi "${WORKING_DIR}/${VM_TPL_NAME}/${VM_TPL_NAME}.vdi" --compact >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't compres the VDI!"
	fi
	# Enable pagefusion (avoid duplicate RAM use between all routers)
	if [ "$VM_ARCH" = "FreeBSD_64" ]; then
		if ! VBoxManage modifyvm ${VM_TPL_NAME} --pagefusion on >> ${LOG_FILE} 2>&1; then
			echo "[WARNING] Can't enable pagefusion"
		fi
	fi

	#Save CONSOLE type to extradata
	if ($SERIAL); then
		VBoxManage setextradata ${VM_TPL_NAME} Console Serial
	else
		 VBoxManage setextradata ${VM_TPL_NAME} Console VGA
	fi

	echo "Take a snapshot (will be the base for linked-vm)..."  >> ${LOG_FILE} 2>&1
	if ! VBoxManage snapshot ${VM_TPL_NAME} take SNAPSHOT --description  "Snapshot used for linked clone" >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't take a snapshot"
	fi
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
        if ! VBoxManage clonevm ${VM_TPL_NAME} --name $1 --snapshot SNAPSHOT --options link --register >> ${LOG_FILE} 2>&1; then
			die "[ERROR] Can't clone $1"
		fi
		if ! VBoxManage modifyvm $1 --uartmode1 server /tmp/$1.serial >> ${LOG_FILE} 2>&1; then
			die "[ERROR] Can't configure serial port for $1"
		fi
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
		if ! VBoxManage modifyvm $1 --nic$i none >> ${LOG_FILE} 2>&1; then
			echo "[WARNING] Can't unconfigure NIC $i"
		fi
    done
}

# Parse filename for detecting ARCH and console
parse_filename () {
    VM_ARCH=0
    if echo "$1" | grep -q "amd64"; then
        VM_ARCH="FreeBSD_64"
        echo "x86-64 image"
		
    fi
    if echo "$1" | grep -q "i386"; then
        VM_ARCH="FreeBSD"
        echo "i386 image"
    fi
    [ "$VM_ARCH" = "0" ] && die "[ERROR] Can't deduce arch type from filename"
    
	VM_OUTPUT=0
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
    echo ""
    local i=1
    #Enter the main loop for each VM
    while [ $i -le $NUMBER_VM ]; do
        clone_vm BSDRP_lab_R$i

		if [ -n "$RAM" ]; then
			#Configure RAM
			if ! VBoxManage modifyvm BSDRP_lab_R$i --memory $RAM >> ${LOG_FILE} 2>&1; then
        		die "[ERROR] Can't change RAM for BSDRP_lab_R$i"
    		fi
		fi

        NIC_NUMBER=0
        echo "Router$i have the following NIC:"
        #Enter in the Cross-over (Point-to-Point) NIC loop
        #Now generate X x (X-1)/2 full meshed link
        local j=1
        while [ $j -le $NUMBER_VM ]; do
            if [ $i -ne $j ]; then
                echo "${DRIVER_TYPE}${NIC_NUMBER} connected to Router${j}."
                NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
                if [ $i -le $j ]; then
					#Need to manage correct mac address
					if [ $i -le 9 ]; then
						MAC_I="0$i"
					else
						MAC_I="$i"
					fi
					if [ $j -le 9 ]; then
						MAC_J="0$i"
					else
						MAC_J="$i"
					fi
                    if ! VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} ${NIC_TYPE} --intnet${NIC_NUMBER} LAN${i}${j} --macaddress${NIC_NUMBER} AAAA00${MAC_I}${MAC_I}${MAC_J} --nicpromisc${NIC_NUMBER} allow-vms >> ${LOG_FILE} 2>&1; then
						die "[ERROR] Can't add NIC ${NIC_NUMBER} (full mesh) to VM $i"
					fi
                else
                    if ! VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} ${NIC_TYPE} --intnet${NIC_NUMBER} LAN${j}${i} --macaddress${NIC_NUMBER} AAAA00000${i}${j}${i} --nicpromisc${NIC_NUMBER} allow-vms >> ${LOG_FILE} 2>&1; then
						die "[ERROR] Can't add NIC ${NIC_NUMBER} (full mesh) to VM $i"
					fi
                fi
            fi
            j=`expr $j + 1` 
        done
        #Enter in the LAN NIC loop
        local j=1
        while [ $j -le $LAN ]; do
			#Need to manage correct mac address
			if [ $i -le 9 ]; then
				MAC_I="0$i"
			else
				MAC_I="$i"
			fi
			if [ $j -le 9 ]; then
				MAC_J="0$i"
			else
				MAC_J="$i"
			fi
            echo "${DRIVER_TYPE}${NIC_NUMBER} connected to LAN number ${j}."
            NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
            if ! VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} ${NIC_TYPE} --intnet${NIC_NUMBER} LAN10${j} --macaddress${NIC_NUMBER} CCCC0000${MAC_J}${MAC_I} --nicpromisc${NIC_NUMBER} allow-vms >> ${LOG_FILE} 2>&1; then
				die "[ERROR] Can't add NIC ${NIC_NUMBER} (LAN) to VM $i"
			fi
            j=`expr $j + 1`
        done
		if ($HOSTONLY_NIC); then
			#Need to manage correct mac address
			if [ $i -le 9 ]; then
				MAC_I="0$i"
			else
				MAC_I="$i"
			fi
			echo "${DRIVER_TYPE}${NIC_NUMBER} connected to shared-with-host LAN."
			NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
			if ! VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} hostonly --hostonlyadapter${NIC_NUMBER} ${HOSTONLY_NIC_NAME} --nictype${NIC_NUMBER} ${NIC_TYPE} --macaddress${NIC_NUMBER} 00bbbb0000${MAC_I} --nicpromisc${NIC_NUMBER} allow-vms >> ${LOG_FILE} 2>&1; then
				die "[ERROR] Can't add NIC ${NIC_NUMBER} (Host only) to VM $i"
			fi
		fi
    i=`expr $i + 1`
    done
}

# Start each vm
start_lab () {
    local i=1
	echo "Start the lab..."
	# Need to look in extrada for getting console type
	if VBoxManage getextradata ${VM_TPL_NAME} Console | grep -q Serial; then
		SERIAL=true
	else
		SERIAL=false
	fi
    #Enter the main loop for each VM
    while [ $i -le $NUMBER_VM ]; do
		if ! ($SERIAL); then
			if [ $i -le 9 ]; then
				VNC_PORT="0$i"
			else
				VNC_PORT="$i"
			fi
			if [ "${VBOX_OUTPUT}" = "vnc" ]; then
        		nohup VBoxHeadless --vnc --${VBOX_OUTPUT}port 59${VNC_PORT} --startvm BSDRP_lab_R$i >> ${LOG_FILE} 2>&1 &
			else
				nohup VBoxHeadless --${VBOX_OUTPUT} on --${VBOX_OUTPUT}port 59${VNC_PORT} --startvm BSDRP_lab_R$i >> ${LOG_FILE} 2>&1 &
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
        i=`expr $i + 1`
    done

	if ($HOSTONLY_NIC); then
		echo "You need to configure an IP address in these range for communicating with the host:"
		/sbin/ifconfig ${HOSTONLY_NIC_NAME} | grep "inet"
    fi
}

# Delete VM
# $1: name of the VM
delete_vm () {
    if [ "$1" = "" ]; then
        echo "BUG: In delete_vm (), no argument given"
        exit 1
    fi
    echo "Delete VM $1" >> ${LOG_FILE} 2>&1
   	echo "Delete VM $1" 
    if ! VBoxManage unregistervm $1 --delete >> ${LOG_FILE} 2>&1; then
		die "[ERROR] Can't delete VM $1, Check ${LOG_FILE}."
	fi

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
		if ! VBoxManage controlvm $i poweroff >> ${LOG_FILE} 2>&1; then
			echo "[WARNING] Can't poweroff $i"
		fi
    done
}

# Get Virtualbox hostonly adapter informatiom
vbox_hostonly () {
	if ! `VBoxManage list hostonlyifs | grep "^Name:"  >> ${LOG_FILE} 2>&1`; then
        echo "ERROR: Not VBox hostonly NIC, you need to create one:"
		echo "VBoxManage hostonlyif create"
		echo "VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.1.30 --netmask 255.255.255.0"
		echo "VBoxManage dhcpserver remove --ifname vboxnet0"
        exit 1
    fi

	HOSTONLY_NIC_NAME=`VBoxManage list hostonlyifs | grep "^Name:" | cut -d ':' -f 2 | sed 's/^[ \t]*//;s/[ \t]*$//'`
}

usage () {
        (
        echo "Usage: $0 [-hdsv] [-i BSDRP_image_file.img] [-n router-number] [-l LAN-number]"
        echo "  -i filename     BSDRP image file name (to be used the first time only)"
        echo "  -d              Delete all BSDRP VM and disks"
        echo "  -n X            Number of router (between 1 and 9) full meshed (default: 1)"
        echo "  -l Y            Number of LAN between 0 and 9 (default: 0)"
		echo "  -m              RAM (in MB) for each VM (default: 192)"
		echo "  -c              Enable internal NIC shared with host for each routers (default: Disable)"
        echo "  -h              Display this help"
        echo "  -s              Stop all VM"
		echo "  -v              Enable virtio drivers"
        echo ""
        ) 1>&2
        exit 2
}

###############
# Main script #
###############

### Parse argument

#set +e
args=`getopt i:dhcl:m:n:sv $*`
if [ $? -ne 0 ] ; then
        usage
        exit 2
fi
#set -e

NUMBER_VM=""
HOSTONLY_NIC=false
VIRTIO=false
LAN=""
FILENAME=""
RAM=""

echo "BSD Router Project (http://bsdrp.net) - VirtualBox lab script"

echo "BSD Router Project (http://bsdrp.net) - Virtualbox lab script, log file" > ${LOG_FILE}

OS_DETECTED=`uname -s`

check_system_common

case "$OS_DETECTED" in
    "FreeBSD")
        check_system_freebsd
        break
        ;;
    "Linux")
        check_system_linux
        break
        ;;
    *)
        echo "ERROR: This script doesn't support $OS_DETECTED"
        exit 1
        ;;
esac

check_user

WORKING_DIR=`VBoxManage list systemproperties | grep "Default machine folder" | cut -d ":" -f 2 | tr -s " " | sed '1s/^.//'`
MAX_NIC=`VBoxManage list systemproperties | grep "Maximum ICH9 Network Adapter count" | cut -d ":" -f 2 | tr -s " " | sed '1s/^.//'`
# A full mesh network consume, on each machine, N-1 VNIC
MAX_VM=`expr $MAX_NIC + 1`

set -- $args
for i
do
        case "$i" 
        in
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
                shift
                shift
                ;;
		-m)
				RAM="$2"
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

if [ "$NUMBER_VM" != "" ]; then
    if [ $NUMBER_VM -lt 1 ]; then
        die "[ERROR] Use a minimal of 1 router in your lab."
    fi

    if [ $NUMBER_VM -gt $MAX_VM ]; then
        die "[ERROR] Use a maximum of $MAX_VM routers in your lab (Vbox don't support more than $MAX_NIC VNIC to a VM."
    fi
else
    NUMBER_VM=1
fi

if [ $NUMBER_VM -eq 1 ]; then
	# Impose shared-with-host NIC if only one router started
	HOSTONLY_NIC=true
fi

if [ "$LAN" != "" ]; then
    if [ $LAN -gt $MAX_NIC ]; then
		die "[ERROR] Use a maximum of $MAX_VM routers in your lab (Vbox don't support more than $MAX_NIC VNIC to a VM."
    fi
else
    LAN=0
fi

if [ $# -gt 0 ] ; then
    echo "$0: Extraneous arguments supplied"
    usage
fi

if ($HOSTONLY_NIC); then
	vbox_hostonly
fi

#Count the number of available NIC

if ($HOSTONLY_NIC); then
	TOTAL_NIC=1
else
	TOTAL_NIC=0
fi
TOTAL_NIC=`expr $TOTAL_NIC + $LAN` || true
TOTAL_NIC=`expr $TOTAL_NIC + $NUMBER_VM - 1` || true
if [ $TOTAL_NIC -gt $MAX_NIC ]; then
	die "[ERROR] you can't have more than $MAX_NIC VNIC by VM"
fi

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
