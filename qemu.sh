#!/bin/sh
#
# Qemu test script for BSD Router Project
#
# Copyright (c) 2009-2010, The BSDRP Development Team
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

check_user () {
    if [ ! $(whoami) = "root" ]; then
		NOT_ROOT=true
		echo "Info: Starting this script as a simple user have some limitation"
        if ($SHARED_WITH_HOST); then
            echo "Warning: You need to be root for creating the shared LAN interfaces with the hosts"
            echo "Shared LAN disabled"
            SHARED_WITH_HOST=false
        fi
    fi  
}

check_system () {
    if ! `uname -s | grep -q FreeBSD`; then
        echo "Error: This script was wrote for a FreeBSD only"
        echo "You need to adapt it for other system"
        exit 1
    fi
    if ! `pkg_info -q -E -x qemu  > /dev/null 2>&1`; then
        echo "Error: qemu not found"
        echo "Install qemu with: pkg_add -r qemu"
        exit 1
    fi

    if ! `pkg_info -q -E -x kqemu  > /dev/null 2>&1`; then
        echo "Warning: kqemu not found"
        echo "kqemu is not mandatory, but improve a lot the speed"
        echo "Install kqemu with: pkg_add -r kqemu"
    fi

    if ! kldstat -m kqemu; then
		if $NOT_ROOT; then
			echo "Warning: kqemu module not loaded"
			echo "You need to be root for loading this module"
		else
        	echo "Loading kqemu"
        	if kldload kqemu; then
            	echo "Can't load kqemu"
        	fi
		fi
    fi
    if ! kldstat -m aio; then
		if $NOT_ROOT; then
			echo "Error: aio module not loaded (mandatory for qemu)"
			echo "You need to be root for loading this module"
		else
        	echo "Loading aio"
        	if kldload aio; then
            	echo "Can't load aio"
        	fi
		fi
    fi

}

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

# Creating interfaces
create_interfaces_shared () {
    if ! `ifconfig | grep -q 10.0.0.254`; then
        echo "Creating admin bridge interface..."
        BRIDGE_IF=`ifconfig bridge create`
        if ! `ifconfig ${BRIDGE_IF} 10.0.0.254/24`; then
            echo "Can't set IP address on ${BRIDGE_IF}"
            exit 1
        fi
    else
        # Need to check if it's a bridge interface that is allready configured with 10.0.0.254"
        DETECTED_NIC=`ifconfig -l`
        for NIC in $DETECTED_NIC
        do
           if `ifconfig $NIC | /usr/bin/grep -q 10.0.0.254`; then 
                if `echo $NIC | /usr/bin/grep -q bridge`; then
                    BRIDGE_IF="$NIC"
                else
                    echo "ERROR: Interface $NIC is allready configured with 10.0.0.254"
                    echo "I cant' configure this IP on interface $BRIDGE_IF"
                    exit 1
                fi
            fi 
        done

    fi
    #Shared TAP interface for communicating with the host
    echo "Creating admin tap interface..."
    TAP_IF=`ifconfig tap create`

    # Link bridge with tap
    ifconfig ${BRIDGE_IF} addm ${TAP_IF} up
    ifconfig ${TAP_IF} up
    QEMU_NIC="-net nic -net tap,ifname=${TAP_IF}"
}

# Creating interfaces for lAB mode
create_interfaces_lab () {
    if ! `ifconfig | grep -q 10.0.0.254`; then
        echo "Creating admin bridge interface..."
        BRIDGE_IF=`ifconfig bridge create`
        if ! `ifconfig ${BRIDGE_IF} 10.0.0.254/24`; then
            echo "Can't set IP address on ${BRIDGE_IF}"
            exit 1
        fi
    else
        echo "Need to found the bridge number configured with 10.0.0.254"
        exit 1
    fi
    #Shared TAP interface for communicating with the host
    echo "Creating the $NUMBER_VM tap interfaces that be shared with host"
    i=1
    while [ $i -le $NUMBER_VM ]; do
        echo "Creating admin tap interface..."
        eval TAP_IF_${i}=`ifconfig tap create`

        # Link bridge with tap
        TAP_IF="TAP_IF_$i"
        TAP_IF=`eval echo $"${TAP_IF}"`
        ifconfig ${BRIDGE_IF} addm ${TAP_IF} up
        ifconfig ${TAP_IF} up
        i=`expr $i + 1`
    done
}

# Delete all admin interfaces create for lab mode
delete_interface_lab () {
    i=1
    while [ $i -le $NUMBER_VM ]; do
        TAP_IF="TAP_IF_$i"
        TAP_IF=`eval echo $"${TAP_IF}"`
        ifconfig ${TAP_IF} destroy
        i=`expr $i + 1`
    done
    ifconfig ${BRIDGE_IF} destroy

} 
# Parse filename for detecting ARCH and console
parse_filename () {
    QEMU_ARCH=0
    if echo "${FILENAME}" | grep -q "amd64"; then
        QEMU_ARCH="qemu-system-x86_64 -m 96"
        echo "filename guest a x86-64 image"
    fi
    if echo "${FILENAME}" | grep -q "i386"; then
        QEMU_ARCH="qemu -m 96"
        echo "filename guests a i386 image"
    fi
    if [ "$QEMU_ARCH" = "0" ]; then
        echo "WARNING: Can't guests arch of this image"
        echo "Will use as default i386"
        QEMU_ARCH="qemu"
    fi
    QEMU_OUTPUT=0
    if echo "${FILENAME}" | grep -q "serial"; then
        QEMU_OUTPUT="-nographic -vga none"
        SERIAL=true
        echo "filename guests a serial image"
        echo "Will use standard console as input/output"
        echo "Guest VM configured without vga card"
    fi
    if echo "${FILENAME}" | grep -q "vga"; then
        QEMU_OUTPUT="-vnc :0 -serial none"
        SERIAL=false
        echo "filename guests a vga image"
        echo "Will start a VNC server on :0 for input/output"
        echo "Guest VM configured without serial port"
    fi
    if [ "$QEMU_OUTPUT" = "0" ]; then
        echo "WARNING: Can't suppose default console of this image"
        echo "Will start a VNC server on :0 for input/output"
        SERIAL=false
        QEMU_OUTPUT="-vnc :0"
    fi

}

start_lab_vm () {
    echo "Starting a lab with $NUMBER_VM routers:"
    echo "- 1 shared LAN between all routers and the host"
    echo "- $NUMBER_LAN LAN between all routers"
    echo "- Full mesh ethernet point-to-point link between each routers"
    echo ""
    i=1
    #Enter the main loop for each VM
    while [ $i -le $NUMBER_VM ]; do
        echo "Router$i have the folllowing NIC:"
        TAP_IF="TAP_IF_$i"
        TAP_IF=`eval echo $"${TAP_IF}"`
        QEMU_NAME="-name Router${i}"
        if ($SHARED_WITH_HOST); then
            NIC_NUMBER=0
            echo "ed${NIC_NUMBER} connected to shared with host LAN, configure IP 10.0.0.${i}/8 on this."
            NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
            QEMU_ADMIN_NIC="-net nic,macaddr=AA:AA:00:00:00:0${i},vlan=0 -net tap,vlan=0,ifname=${TAP_IF}"
        else
            QEMU_ADMIN_NIC=""
            NIC_NUMBER=0
        fi
        #Enter in the Cross-over (Point-to-Point) NIC loop
        #Now generate X x (X-1)/2 full meshed link
        j=1
        QEMU_PP_NIC=""
        while [ $j -le $NUMBER_VM ]; do
            if [ $i -ne $j ]; then
                echo "ed${NIC_NUMBER} connected to Router${j}."
                NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
                if [ $i -le $j ]; then
                    QEMU_PP_NIC="${QEMU_PP_NIC} -net nic,macaddr=AA:AA:00:00:0${i}:${i}${j},vlan=${i}${j} -net socket,mcast=230.0.0.1:100${i}${j},vlan=${i}${j}"
                else
                    QEMU_PP_NIC="${QEMU_PP_NIC} -net nic,macaddr=AA:AA:00:00:0${i}:${j}${i},vlan=${j}${i} -net socket,mcast=230.0.0.1:100${j}${i},vlan=${j}${i}"
                fi
            fi
            j=`expr $j + 1` 
        done
        #Enter in the LAN NIC loop
        j=1
        QEMU_LAN_NIC=""
        while [ $j -le $NUMBER_LAN ]; do
            echo "ed${NIC_NUMBER} connected to LAN number ${j}."
            NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
            QEMU_LAN_NIC="${QEMU_LAN_NIC} -net nic,macaddr=CC:CC:00:00:0${j}:0${i},vlan=10${j} -net socket,mcast=230.0.0.1:1000${j},vlan=10${j}"
            j=`expr $j + 1`
        done
        if ($SERIAL); then
            QEMU_OUTPUT="-nographic -vga none -serial telnet::800${i},server,nowait"
            echo "Connect to the router ${i} by telneting to localhost on port 800${i}"
        else
            QEMU_OUTPUT="-vnc :${i}"
            echo "Connect to the router ${i} by VNC client on display ${i}"
        fi
        ${QEMU_ARCH} -enable-kqemu -snapshot -hda ${FILENAME} ${QEMU_OUTPUT} ${QEMU_NAME} ${QEMU_ADMIN_NIC} ${QEMU_PP_NIC} ${QEMU_LAN_NIC} -pidfile /tmp/BSDRP-$i.pid -daemonize
        i=`expr $i + 1`
    done

    #Now wait for each qemu process end before continue
    i=1
    while [ $i -le $NUMBER_VM ]; do
        while (ps -p `cat /tmp/BSDRP-$i.pid` > /dev/null)
        do
            sleep 1
        done
        i=`expr $i + 1`
    done
    
}

usage () {
        (
        echo "Usage: $0 [-s] -i BSDRP-full.img [-n router-number] [-l LAN-number]"
        echo "  -i filename     BSDRP file image path"
        echo "  -n X            Lab mode: start X routers (between 2 and 9) full meshed"
        echo "  -l Y            Number of LAN between 0 and 9 (in lab mode only)"
        echo "  -s              Enable a shared LAN with Qemu host"
        echo "  -h              Display this help"
        echo ""
        echo "Note: In lab mode, the qemu process are started in snapshot mode,"
        echo "this mean that all modifications to disks are lose after quitting the lab"
        echo "Script need to be started with root if you want a shared LAN with the Qemu host"
        echo "WARNING: Multicast traffic is not possible between Qemu guest!!"
        ) 1>&2
        exit 2
}

###############
# Main script #
###############

### Parse argument

set +e
args=`getopt i:hl:n:s $*`
if [ $? -ne 0 ] ; then
        usage
        exit 2
fi
set -e

set -- $args
LAB_MODE=false
SHARED_WITH_HOST=false
for i
do
        case "$i" 
        in
        -n)
                LAB_MODE=true
                NUMBER_VM=$2
                shift
                shift
                ;;
        -l)
                NUMBER_LAN=$2
                shift
                shift
                ;;
        -s)
                SHARED_WITH_HOST=true
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

    if [ $NUMBER_VM -ge 9 ]; then
        echo "Error: Use a maximum of 9 routers in your lab."
        exit 1
    fi
fi

if [ "$NUMBER_LAN" != "" ]; then
    if [ $NUMBER_LAN -ge 9 ]; then
        echo "Error: Use a maximum of 9 LAN in your lab."
        exit 1
    fi
else
    NUMBER_LAN=0
fi

if [ "$FILENAME" = "" ]; then
    usage
fi
if [ $# -gt 0 ] ; then
    echo "$0: Extraneous arguments supplied"
    usage
fi

echo "BSD Router Project Qemu script"
check_user
check_system
check_image
parse_filename

QEMU_NIC="-net nic -net user"

if ($SHARED_WITH_HOST); then
    if ($LAB_MODE); then
        create_interfaces_lab
    else
        create_interfaces_shared
    fi
fi

if ($LAB_MODE); then
    echo "Starting qemu in lab mode..."
    echo "With $NUMBER_VM BSDRP VM full meshed"
    start_lab_vm    
else
    echo "Starting qemu..."
    ${QEMU_ARCH} -hda ${FILENAME} ${QEMU_NIC} -localtime \
    ${QEMU_OUTPUT} -k fr
fi
echo "...qemu stoped"
if ($SHARED_WITH_HOST); then
    echo "Destroying shared Interfaces..."
    if ($LAB_MODE); then
        delete_interface_lab
    else
        ifconfig ${TAP_IF} destroy
        ifconfig ${BRIDGE_IF} destroy
    fi
fi

