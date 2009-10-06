#!/bin/sh
#
# VirtualBox lab and start script for BSD Router Project
#
# Copyright (c) 2009, The BSDRP Development Team
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
WORKING_DIR="/tmp/$USER/BSDRP-lab"
MAX_VM=9

if [ ! -d $WORKING_DIR ]; then
    mkdir -p $WORKING_DIR
fi
# Check system pre-requise for starting virtualbox

check_system_freebsd () {
    if ! `pkg_info -q -E -x virtualbox  > /dev/null 2>&1`; then
        echo "ERROR: Virtualbox not installed ?"
        echo "Install qemu with: pkg_add -r virtualbox"
        exit 1
    fi

    if ! `mount | grep -q ^procfs`; then
        echo "procfs not mounted, mounting it..."
        if mount -t procfs proc /proc; then
            echo "ERROR: Can't mount /proc"
            exit 1
        fi
    fi

    if ! kldstat -m vboxdrv; then
        echo "vboxdrv module not loaded, loading it..."
        if kldload /boot/modules/vboxdrv.ko; then
            echo "ERROR: Can't load vboxdrv"
            exit 1
        fi
    fi

}

check_system_linux () {
    if ! `VBoxManage -v > /dev/null 2>&1`; then
        echo "ERROR: Is VirtualBox installed ?"
        exit 1
    fi
    
    if ! `socat -V > /dev/null 2>&1`; then
        echo "ERROR: Is socat installed ?"
        exit 1
    fi
}

# Check user
check_user () {
    if ! `groups | grep -q vboxusers`; then
        echo "Your users is not in the vboxusers group"
        exit 1
    fi

    if [ ! $(whoami) = "root" ]; then
        echo "Disable the shared LAN"
            SHARED_WITH_HOST=false
    fi  
}

# Check filename, and unzip it
check_image () {
    if [ ! -f ${FILENAME} ]; then
        echo "ERROR: Can't found the file ${FILENAME}"
        exit 1
    fi

    if `file -b ${FILENAME} | grep -q "bzip2 compressed data"  > /dev/null 2>&1`; then
        echo "Bzipped image detected, unzip it..."
        bunzip2 -k ${FILENAME}
        # change FILENAME by removing the last.bz2"
        FILENAME=`echo ${FILENAME} | sed -e 's/.bz2//g'`
    fi

    if ! `file -b ${FILENAME} | grep -q "boot sector"  > /dev/null 2>&1`; then
        echo "ERROR: Not a BSDRP image??"
        exit 1
    fi
    
}

# Convert image into Virtualbox format and copy it to working dir

convert_image () {
    if [ -f ${WORKING_DIR}/BSDRP_lab.vdi ]; then
        mv ${WORKING_DIR}/BSDRP_lab.vdi ${WORKING_DIR}/BSDRP_lab.vdi.bak
    fi
    VBoxManage convertfromraw ${FILENAME} ${WORKING_DIR}/BSDRP_lab.vdi > /dev/null 2>&1
    # Now compress the image
    VBoxManage createvm --name BSDRP_lab_tempo --ostype $VM_ARCH --register > /dev/null 2>&1
    VBoxManage modifyvm BSDRP_lab_tempo --memory 16 --vram 1 --hda $WORKING_DIR/BSDRP_lab.vdi > /dev/null 2>&1
    VBoxManage modifyvdi $WORKING_DIR/BSDRP_lab.vdi --compact > /dev/null 2>&1
    VBoxManage modifyvm BSDRP_lab_tempo --hda none > /dev/null 2>&1
    VBoxManage unregisterimage disk $WORKING_DIR/BSDRP_lab.vdi > /dev/null 2>&1
    VBoxManage unregistervm BSDRP_lab_tempo --delete > /dev/null 2>&1
}

# Check if VM allready exist

check_vm () {
   if `VBoxManage showvminfo $1 > /dev/null 2>&1`; then
        return 1 # false
   else
        return 0 # true
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
    if check_vm $1; then
        VBoxManage createvm --name $1 --ostype $VM_ARCH --register
        if [ -f $WORKING_DIR/$1.vdi ]; then
            rm $WORKING_DIR/$1.vdi
        fi
        VBoxManage clonehd $WORKING_DIR/BSDRP_lab.vdi $1.vdi
        VBoxManage modifyvm $1 --hda $1.vdi
    else
        # if existing: Is running ?
        if `VBoxManage showvminfo $1 | grep -q "running"`; then
            VBoxManage controlvm $1 poweroff
            sleep 5
        fi
    fi
    VBoxManage modifyvm $1 --audio none --memory 92 --vram 1 --boot1 disk --floppy disabled
    VBoxManage modifyvm $1 --biosbootmenu disabled 
    if ($SERIAL); then
        VBoxManage modifyvm $1 --uart1 0x3F8 4 --uartmode1 server $WORKING_DIR/$1.serial
    else
        VBoxManage modifyvm $1 --vrdp on --vrdpauthtype null --vrdpport 330$1
    fi
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
        echo "Will start a RDP server on :0 for input/output"
        echo "DEBUG: BSDRP bug with no serial port"
    fi
    echo "VM_ARCH=$VM_ARCH" > ${WORKING_DIR}/image.info
    echo "SERIAL=$SERIAL" >> ${WORKING_DIR}/image.info

}

# This function generate the clones
clone_vm () {
    echo "Creating lab with $NUMBER_VM routers:"
    echo "- $NUMBER_LAN LAN between all routers"
    echo "- Full mesh ethernet point-to-point link between each routers"
    echo ""
    i=1
    #Enter the main loop for each VM
    while [ $i -le $NUMBER_VM ]; do
        create_vm BSDRP_lab_R$i
        NIC_NUMBER=0
        echo "Router$i have the folllowing NIC:"
        #Enter in the Cross-over (Point-to-Point) NIC loop
        #Now generate X x (X-1)/2 full meshed link
        j=1
        while [ $j -le $NUMBER_VM ]; do
            if [ $i -ne $j ]; then
                echo "em${NIC_NUMBER} connected to Router${j}."
                NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
                if [ $i -le $j ]; then
                    VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} 82540EM --intnet${NIC_NUMBER} LAN${i}${j} --macaddress${NIC_NUMBER} AAAA00000${i}${i}${j}
                else
                    VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} 82540EM --intnet${NIC_NUMBER} LAN${j}${i} --macaddress${NIC_NUMBER} AAAA00000${i}${j}${i}
                fi
            fi
            j=`expr $j + 1` 
        done
        #Enter in the LAN NIC loop
        j=1
        while [ $j -le $NUMBER_LAN ]; do
            echo "em${NIC_NUMBER} connected to LAN number ${j}."
            NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
            VBoxManage modifyvm BSDRP_lab_R$i --nic${NIC_NUMBER} intnet --nictype${NIC_NUMBER} 82540EM --intnet${NIC_NUMBER} LAN10${j} --macaddress${NIC_NUMBER} CCCC00000${j}0${i}
            j=`expr $j + 1`
        done
    i=`expr $i + 1`
    done
}

# Start each vm
start_vm () {
    i=1
    #Enter the main loop for each VM
    while [ $i -le $NUMBER_VM ]; do
        # OSE version of VB doesn't support --vrdp option
        if ($OSE); then
            VBoxHeadless --startvm BSDRP_lab_R$i &
        else
            VBoxHeadless --vrdp config --startvm BSDRP_lab_R$i &
        fi
        sleep 2
        if ($SERIAL); then
            socat UNIX-CONNECT:$WORKING_DIR/BSDRP_lab_R$i.serial TCP-LISTEN:800$i &
            echo "Connect to the router ${i} by telneting to localhost on port 800${i}"
        else
            echo "Connect to the router ${i} by RDP client on port 330${i}"
        fi
        i=`expr $i + 1`
    done
}

delete_all_vm () {
    stop_all_vm
    i=1
    #Enter the main loop for each VM
    while [ $i -le $MAX_VM ]; do
        if check_vm BSDRP_lab_R1; then
            VBoxManage unregistervm BSDRP_lab_R$i --delete
        fi 
        i=`expr $i + 1`
    done

}

# Stop All VM
stop_all_vm () {
    i=1
    #Enter the main loop for each VM
    while [ $i -le $MAX_VM ]; do
        # Check if the vm allready exist
        if ! check_vm BSDRP_lab_R$i; then
            # if existing: Is running ?
            if `VBoxManage showvminfo BSDRP_lab_R$i | grep -q "running"`; then
                VBoxManage controlvm BSDRP_lab_R$i poweroff
                sleep 5
            fi
        fi
        i=`expr $i + 1`
    done
}

usage () {
        (
        echo "Usage: $0 [-hds] -i BSDRP-full.img [-n router-number] [-l LAN-number]"
        echo "  -i filename     BSDRP image file name (to be used the first time only)"
        echo "  -d delete       Delete all BSDRP VM and disks"
        echo "  -n X            Number of router (between 2 and 9) full meshed"
        echo "  -l Y            Number of LAN between 0 and 9"
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
args=`getopt i:dhl:n:s $*`
if [ $? -ne 0 ] ; then
        usage
        exit 2
fi
set -e

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
        -d)
                delete_all_vm
                shift
                shift
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
                shift
                shift
                ;;
        --)
                shift
                break
        esac
done

if [ "$NUMBER_VM" != "" ]; then
    if [ $NUMBER_VM -lt 1 ]; then
        echo "Error: Use a minimal of 2 routers in your lab."
        exit 1
    fi

    if [ $NUMBER_VM -ge $MAX_VM ]; then
        echo "ERROR: Use a maximum of $MAX_VM routers in your lab."
        exit 1
    fi
else
    echo "ERROR: Missing -n number-router"
    usage
fi

if [ "$NUMBER_LAN" != "" ]; then
    if [ $NUMBER_LAN -ge 9 ]; then
        echo "ERROR: Use a maximum of 9 LAN in your lab."
        exit 1
    fi
else
    NUMBER_LAN=0
fi

if [ "$FILENAME" = "" ]; then
    if [ ! -f ${WORKING_DIR}/BSDRP_lab.vdi ]; then
        echo "ERROR: No existing base disk lab detected."
        echo "You need to enter an image filename for creating the VM."
        exit 1
    fi
fi

if [ $# -gt 0 ] ; then
    echo "$0: Extraneous arguments supplied"
    usage
fi

echo "BSD Router Project VirtualBox lab script"

OS_DETECTED=`uname -s`

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

if VBoxManage -v | grep -q "OSE"; then
    OSE=true
else
    OSE=false
fi

check_user

if [ "$FILENAME" != "" ]; then
    check_image
    parse_filename
    convert_image
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
