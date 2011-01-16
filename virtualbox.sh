#!/bin/sh
#
# VirtualBox lab script for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2009-2011, The BSDRP Development Team
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

# Global variable
WORKING_DIR="$HOME/.VirtualBox/HardDisks"
MAX_VM=9
LOG_FILE="BSDRP_lab.log"

# Check FreeBSD system pre-requise for starting virtualbox
check_system_freebsd () {
    if ! kldstat -m vboxdrv; then
        echo "vboxdrv module not loaded, loading it..."
        if kldload /boot/modules/vboxdrv.ko; then
            echo "ERROR: Can't load vboxdrv"
            exit 1
        fi
    fi

}

check_system_common () {
	
	echo "Checking if VirtualBox installed..." >> ${LOG_FILE}

	if [ ! -d $WORKING_DIR ]; then
    	echo "Don't find $WORKING_DIR"
    	echo "Is Virtualbox installed ?"
    	exit 1
	fi

    if ! `VBoxManage -v > /dev/null 2>&1`; then
        echo "ERROR: Is VirtualBox installed ?"
        exit 1
    fi
   	echo "Checking if socat installed..." >> ${LOG_FILE} 
    if ! `socat -V > /dev/null 2>&1`; then
        echo "WARNING: Is socat installed ?"
		echo "socat is mandatory for using the serial release"
        exit 1
    fi
	VBVERSION=`VBoxManage -v`
	VBVERSION_MAJ=`echo $VBVERSION|cut -d . -f 1`
	VBVERSION_MIN=`echo $VBVERSION|cut -d . -f 2`
	if [ $VBVERSION_MAJ -lt 3 ]; then
		echo "Error: Need Virtualbox 3.1 minimum"
		exit 1
	fi
	if [ $VBVERSION_MAJ -eq 3 -a $VBVERSION_MIN -lt 1 ]; then
        echo "Error: Need Virtualbox 3.1 minimum"
        exit 1
    fi

	if ! `VBoxHeadless | grep -q vrdp`; then
		if ! `VBoxHeadless | grep -q vnc`; then
			echo "No Virtualbox VRDP/VNC support detected:"
			echo "BSDRP vga images will not be supported (only serial)"
			echo "VRDP: Supported by Virtualbox closed source release"
			echo "VNC:  Supported by FreeBSD VirtualBox-OSE (if enabled during make config)"
			VBOX_VGA=false
		else
			VBOX_OUTPUT="vnc"
			VBOX_VGA=true
		fi
	else
		VBOX_OUTPUT="vrdp"
		VBOX_VGA=true
    fi

}

check_system_linux () {
	if ! `modprobe -a vboxdrv`; then
		echo "VirtualBox module not loaded ?"
	fi
}

# Check user
check_user () {
    if ! `groups | grep -q vboxusers`; then
        echo "Your users is not in the vboxusers group"
        exit 1
    fi

    #if [ ! $(whoami) = "root" ]; then
    #    echo "Disable the shared LAN"
    #        SHARED_WITH_HOST=false
    #fi  
}

# Check filename, and unzip it
check_image () {
    if [ ! -f ${FILENAME} ]; then
        echo "ERROR: Can't found the file ${FILENAME}"
        exit 1
    fi

    if echo ${FILENAME} | grep -q bz2  >> ${LOG_FILE} 2>&1; then
        echo "Bzip2 compressed image detected, unzip it..."
        bunzip2 -k ${FILENAME}
        # change FILENAME by removing the last.bz2"
        FILENAME=`echo ${FILENAME} | sed -e 's/.bz2//g'`
    elif echo ${FILENAME} | grep -q xz  >> ${LOG_FILE} 2>&1; then
        echo "xz compressed image detected, unzip it..."
        xz -dk ${FILENAME}
        # change FILENAME by removing the last.lzma"
        FILENAME=`echo ${FILENAME} | sed -e 's/.xz//g'`
	fi

    if ! `file -b ${FILENAME} | grep -q "boot sector"  >> ${LOG_FILE} 2>&1`; then
        echo "ERROR: Not a BSDRP image??"
        exit 1
    fi
    
}

# Create BSDRP template VM by converting BSDRP image disk into Virtualbox format and compress it
# This template is used only for the image disk
create_template_vm () {
	echo "Image file given… rebuilding BSDRP router template"
	echo "Check if BSDRP template VM exist..." >> ${LOG_FILE}
    if check_vm BSDRP_lab_template; then
		echo "Found: Deleting the template VM..."
        delete_vm BSDRP_lab_template
    fi

	echo "Convert BSDRP image disk to VDI..." >> ${LOG_FILE}
    VBoxManage convertfromraw ${FILENAME} ${WORKING_DIR}/BSDRP_lab_template.vdi >> ${LOG_FILE} 2>&1
	echo "Create BSDRP template VM..." >> ${LOG_FILE}
    VBoxManage createvm --name BSDRP_lab_template --ostype $VM_ARCH --register >> ${LOG_FILE} 2>&1
	echo "Add SATA controller to the VM..." >> ${LOG_FILE}
	VBoxManage storagectl BSDRP_lab_template --name "SATA Controller" --add sata --controller IntelAhci >> ${LOG_FILE} 2>&1
	echo "Add the VDI to the VM..." >> ${LOG_FILE}
	VBoxManage storageattach BSDRP_lab_template --storagectl "SATA Controller" \
    --port 0 --device 0 --type hdd \
    --medium $WORKING_DIR/BSDRP_lab_template.vdi >> ${LOG_FILE} 2>&1
	echo "Reduce Template VM requierement..." >> ${LOG_FILE}
    VBoxManage modifyvm BSDRP_lab_template --memory 16 --vram 1 >> ${LOG_FILE} 2>&1
	echo "Compress the VDI..." >> ${LOG_FILE}
    VBoxManage modifyvdi $WORKING_DIR/BSDRP_lab_template.vdi --compact >> ${LOG_FILE} 2>&1
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

# Create VM
# $1 : Name of the VM
create_vm () {
    if [ "$1" = "" ]; then
        echo "BUG: In function create_vm() that need a vm name"
        exit 1
    fi
    # Check if the vm allready exist
    if ! check_vm $1; then
		echo "Create VM $1..." >> ${LOG_FILE}
        VBoxManage createvm --name $1 --ostype $VM_ARCH --register >> ${LOG_FILE} 2>&1
        if [ -f $WORKING_DIR/$1.vdi ]; then
            rm $WORKING_DIR/$1.vdi
        fi
        VBoxManage clonehd $WORKING_DIR/BSDRP_lab_template.vdi $1.vdi >> ${LOG_FILE} 2>&1
		echo "Add SATA controller to the VM..." >> ${LOG_FILE}
    	VBoxManage storagectl $1 --name "SATA Controller" --add sata --controller IntelAhci >> ${LOG_FILE}
    	echo "Add the controller and disk to the VM..." >> ${LOG_FILE}
    	VBoxManage storageattach $1 --storagectl "SATA Controller" \
    	--port 0 --device 0 --type hdd \
    	--medium $1.vdi >> ${LOG_FILE} 2>&1
    else
        # if existing: Is running ?
        if `VBoxManage showvminfo $1 | grep -q "running"`; then
            VBoxManage controlvm $1 poweroff
            sleep 5
        fi
    fi
    VBoxManage modifyvm $1 --audio none --memory 92 --vram 1 --boot1 disk --floppy disabled >> ${LOG_FILE} 2>&1
    VBoxManage modifyvm $1 --biosbootmenu disabled >> ${LOG_FILE} 2>&1
    if ($SERIAL); then
        VBoxManage modifyvm $1 --uart1 0x3F8 4 --uartmode1 server $WORKING_DIR/$1.serial >> ${LOG_FILE} 2>&1
    fi
    
	#Delete all NIC
	local i=1
    while [ $i -le 8 ]; do
		VBoxManage modifyvm $1 --nic$i none >> ${LOG_FILE} 2>&1
        i=`expr $i + 1`
    done

	echo "VM $1 Created/Reseted" >> ${LOG_FILE}
}

# Parse filename for detecting ARCH and console
parse_filename () {
    VM_ARCH=0
    if echo "${FILENAME}" | grep -q "amd64"; then
        VM_ARCH="FreeBSD_64"
        echo "filename guest a x86-64 image"
    fi
    if echo "${FILENAME}" | grep -q "i386"; then
        VM_ARCH="FreeBSD"
        echo "filename guests a i386 image"
    fi
    if [ "$VM_ARCH" = "0" ]; then
        echo "WARNING: Can't guests arch of this image"
        echo "Will use as default i386"
        VM_ARCH="FreeBSD"
    fi
    VM_OUTPUT=0
    if echo "${FILENAME}" | grep -q "serial"; then
        SERIAL=true
        echo "filename guests a serial image"
    fi
    if echo "${FILENAME}" | grep -q "vga"; then
        SERIAL=false
        echo "filename guests a vga image"
		if ! $VBOX_VGA; then
		echo "You can't use BSDRP vga release with a Virtualbox that didn't support RDP or VNC"
		exit 1
		fi
    fi
    echo "VM_ARCH=$VM_ARCH" > ${WORKING_DIR}/image.info
    echo "SERIAL=$SERIAL" >> ${WORKING_DIR}/image.info

}

# This function generate the clones
clone_vm () {
    echo "Creating lab with $NUMBER_VM router(s):"
    echo "- $NUMBER_LAN LAN between all routers"
    echo "- Full mesh ethernet point-to-point link between each routers"
	if ($HOSTONLY_NIC); then
		echo "- One NIC connected to the shared LAN with the host"
	fi
    echo ""
    local i=1
    #Enter the main loop for each VM
    while [ $i -le $NUMBER_VM ]; do
        create_vm BSDRP_lab_R$i
        NIC_NUMBER=0
        echo "Router$i have the following NIC:"
        #Enter in the Cross-over (Point-to-Point) NIC loop
        #Now generate X x (X-1)/2 full meshed link
        local j=1
        while [ $j -le $NUMBER_VM ]; do
            if [ $i -ne $j ]; then
                echo "em${NIC_NUMBER} connected to Router${j}."
                NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
                if [ $i -le $j ]; then
                    VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} 82540EM --intnet${NIC_NUMBER} LAN${i}${j} --macaddress${NIC_NUMBER} AAAA00000${i}${i}${j} >> ${LOG_FILE} 2>&1
                else
                    VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} 82540EM --intnet${NIC_NUMBER} LAN${j}${i} --macaddress${NIC_NUMBER} AAAA00000${i}${j}${i} >> ${LOG_FILE} 2>&1
                fi
            fi
            j=`expr $j + 1` 
        done
        #Enter in the LAN NIC loop
        local j=1
        while [ $j -le $NUMBER_LAN ]; do
            echo "em${NIC_NUMBER} connected to LAN number ${j}."
            NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
            VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} 82540EM --intnet${NIC_NUMBER} LAN10${j} --macaddress${NIC_NUMBER} CCCC00000${j}0${i} >> ${LOG_FILE} 2>&1
            j=`expr $j + 1`
        done
		if ($HOSTONLY_NIC); then
			echo "em${NIC_NUMBER} connected to shared-with-host LAN."
			NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
			VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} hostonly --hostonlyadapter${NIC_NUMBER} ${HOSTONLY_NIC_NAME} --nictype${NIC_NUMBER} 82540EM --macaddress${NIC_NUMBER} 00bbbb00000${i} >> ${LOG_FILE} 2>&1
		fi
    i=`expr $i + 1`
    done
}

# Start each vm
start_vm () {
    local i=1
    #Enter the main loop for each VM
    while [ $i -le $NUMBER_VM ]; do
        # OSE version of VB doesn't support --vrdp option
		# Official OSE version of VB doesn't support --vnc option (need a patch)
		if ! ($SERIAL); then
        	nohup VBoxHeadless --${VBOX_OUTPUT} on --${VBOX_OUTPUT}port 590${i} --startvm BSDRP_lab_R$i >> ${LOG_FILE} 2>&1 &
		else
			nohup VBoxHeadless --startvm BSDRP_lab_R$i >> ${LOG_FILE} 2>&1 &
		fi
        sleep 2

		if ($HOSTONLY_NIC); then
        	echo "You need to configure an IP address in these range for communicating with the host:"
        	ifconfig ${HOSTONLY_NIC_NAME} | grep "inet"
    	fi

        if ($SERIAL); then
            socat -s UNIX-CONNECT:$WORKING_DIR/BSDRP_lab_R$i.serial TCP-LISTEN:800$i >> ${LOG_FILE} 2>&1 &
            echo "Connect to the router ${i} by TCP-connecting socat on port 800${i}"
        else
            echo "Connect to the router ${i} by ${VBOX_OUTPUT} client on port 800${i}"
        fi
        i=`expr $i + 1`
    done
	
	if ($SERIAL); then
		echo "Here is how to use a serial terminal software for connecting to the routers:"
		echo "1. Create a bridge between the socat port and a local PTY link"
		echo "   socat TCP-CONNECT:localhost:8001 PTY,link=/tmp/router1 &"
		echo "2. Open your serial terminal software using the local PTY link just created"
		echo "   Using screen:"
		echo "       screen /tmp/router1 9600"
		echo "   Or using tip (FreeBSD): "
		echo '       echo "router1:dv=/tmp/router1:br#9600:pa=none:" >> /etc/remote'
		echo "       tip router1"
		echo "Warning: Closing your session will close socat on both end"
	fi
}

# Delete VM
# $1: name of the VM
delete_vm () {
    if [ "$1" = "" ]; then
        echo "BUG: In delete_vm (), no argument given"
        exit 1
    fi
    echo "Delete VM: $1" >> ${LOG_FILE} 2>&1
    echo "step 1: Unlinking the disk controller..." >> ${LOG_FILE}
    VBoxManage storagectl $1 --name "SATA Controller" --remove >> ${LOG_FILE} 2>&1
    echo "step 2: Unregister the VDI..." >> ${LOG_FILE}
    VBoxManage unregistervm $1 --delete >> ${LOG_FILE} 2>&1
    echo "step 3: Delete the hard-drive image..." >> ${LOG_FILE}
    VBoxManage closemedium disk $WORKING_DIR/$1.vdi --delete >> ${LOG_FILE} 2>&1
}
delete_all_vm () {
    stop_all_vm
    local i=1
    #Enter the main loop for each VM
    while [ $i -le $MAX_VM ]; do
        if check_vm BSDRP_lab_R$i; then
            delete_vm BSDRP_lab_R$i 
        fi 
        i=`expr $i + 1`
    done
	if check_vm BSDRP_lab_template; then
            delete_vm BSDRP_lab_template
    fi
	echo "All VMs deleted"
	
}

# Stop All VM
stop_all_vm () {
    local i=1
    #Enter the main loop for each VM
    while [ $i -le $MAX_VM ]; do
        # Check if the vm allready exist
        if check_vm BSDRP_lab_R$i; then
            # if existing: Is running or in Guru meditation state ?
			echo "Testing state of BSDRP_lab_R$i..." >> ${LOG_FILE}
            if `VBoxManage showvminfo BSDRP_lab_R$i | grep -q "running"`; then
				echo "BSDRP_lab_R$i is in running state: Stopping it..." >> ${LOG_FILE}
				echo "BSDRP_lab_R$i is in running state: Stopping it..."
                VBoxManage controlvm BSDRP_lab_R$i poweroff >> ${LOG_FILE} 2>&1
                sleep 5
			elif `VBoxManage showvminfo BSDRP_lab_R$i | grep -q "meditation"`; then
				echo "BSDRP_lab_R$i is in Guru meditation state: Stopping it..." >> ${LOG_FILE}
				echo "BSDRP_lab_R$i is in Guru meditation state: Stopping it..."
				VBoxManage controlvm BSDRP_lab_R$i poweroff >> ${LOG_FILE} 2>&1
                sleep 5
            fi
        fi
        i=`expr $i + 1`
    done
}

# Get Virtualbox hostonly adapter informatiom
vbox_hostonly () {
	if ! `VBoxManage list hostonlyifs | grep "^Name:"  >> ${LOG_FILE} 2>&1`; then
        echo "ERROR: Not VBox hostonly NIC, you need to create one:"
		echo "VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.1.30 --netmask 255.255.255.0"
		echo "VBoxManage dhcpserver remove --ifname vboxnet0"
        exit 1
    fi

	HOSTONLY_NIC_NAME=`VBoxManage list hostonlyifs | grep "^Name:" | cut -d ':' -f 2 | sed 's/^[ \t]*//;s/[ \t]*$//'`
}

usage () {
        (
        echo "Usage: $0 [-hds] [-i BSDRP_image_file.img] [-n router-number] [-l LAN-number]"
        echo "  -i filename     BSDRP image file name (to be used the first time only)"
        echo "  -d delete       Delete all BSDRP VM and disks"
        echo "  -n X            Number of router (between 1 and 9) full meshed (default: 1)"
        echo "  -l Y            Number of LAN between 0 and 9 (default: 0)"
		echo "  -c              Enable internal NIC shared with host for each routers (default: Disable)"
        echo "  -h              Display this help"
        echo "  -s              Stop all VM"
        echo ""
        ) 1>&2
        exit 2
}

###############
# Main script #
###############

### Parse argument

set +e
args=`getopt i:dhcl:n:s $*`
if [ $? -ne 0 ] ; then
        usage
        exit 2
fi
set -e

HOSTONLY_NIC=false

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
                NUMBER_LAN=$2
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
        -s)
                stop_all_vm
				exit 0
                ;;
        --)
                shift
                break
        esac
done

if [ "$NUMBER_VM" != "" ]; then
    if [ $NUMBER_VM -lt 1 ]; then
        echo "Error: Use a minimal of 1 router in your lab."
        exit 1
    fi

    if [ $NUMBER_VM -gt $MAX_VM ]; then
        echo "ERROR: Use a maximum of $MAX_VM routers in your lab."
        exit 1
    fi
else
    NUMBER_VM=1
fi

if [ $NUMBER_VM -eq 1 ]; then
	# Impose shared-with-host NIC if only one router started
	HOSTONLY_NIC=true
fi

if [ "$NUMBER_LAN" != "" ]; then
    if [ $NUMBER_LAN -gt 9 ]; then
        echo "ERROR: Use a maximum of 9 LAN in your lab."
        exit 1
    fi
else
    NUMBER_LAN=0
fi

if [ "$FILENAME" = "" ]; then
	if ! check_vm BSDRP_lab_template; then
        echo "ERROR: No existing base disk lab detected."
        echo "You need to enter an image filename for creating the VM."
        exit 1
    fi
fi

if [ $# -gt 0 ] ; then
    echo "$0: Extraneous arguments supplied"
    usage
fi

if ($HOSTONLY_NIC); then
	vbox_hostonly
fi

echo "BSD Router Project: VirtualBox lab script"

echo "BSD Router Project: Virtualbox lab script, log file" > ${LOG_FILE}

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

if [ "$FILENAME" != "" ]; then
    check_image
    parse_filename
	create_template_vm
else
    if [ -f ${WORKING_DIR}/image.info ]; then 
        . ${WORKING_DIR}/image.info
    else
        echo "ERROR: You need to use the option -i filname for the first start"
        exit 1
    fi
fi

clone_vm
start_vm
