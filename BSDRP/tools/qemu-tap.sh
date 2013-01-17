#!/bin/sh
#
# Qemu lab and start script for BSD Router Project
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

# Note: this script use bridged TAP interface between guest
# This script was creat when Qemu interfaces didn't support multicast traffic (and prevent to use carp for example).
# New script (A lot more simpler) using Qemu internal interface can he found here:
# http://bsdrp.svn.sourceforge.net/viewvc/bsdrp/trunk/qemu.sh

#Uncomment for debug
#set -x

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
		echo "Loading kqemu"
		if kldload kqemu; then
			echo "Can't load kqemu"
		fi
	fi
	if ! kldstat -m aio; then
        echo "Loading aio"
        if kldload aio; then
            echo "Can't load aio"
        fi
    fi

}

check_user () {
	if [ ! $(whoami) = "root" ]; then
        if ($LAB_MODE); then
            echo "Error: You need to be root for using the Lab Mode (create TAP and bridge interface)"
            exit 1 
        fi
        if ($SHARED_WITH_HOST); then
		    echo "Warning: You need to be root for creating the shared LAN interfaces with the hosts"
            echo "Disable the shared LAN"
            SHARED_WITH_HOST=false
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

# Creating TAP and bridged interfaces
create_interfaces () {
    #Create Bridged interface that will be shared with guest 
    if ($SHARED_WITH_HOST); then
        echo "Creating the $ROUTERS tap interfaces that be shared with host"
	    if ! `ifconfig | grep -q 10.0.0.254`; then
		    echo "Creating admin bridge interface..."
		    BRIDGE_SHARED_IF=`ifconfig bridge create`
            echo "Set IP address 10.0.0.254/24 to the bridge interface"
		    if ! `ifconfig ${BRIDGE_SHARED_IF} 10.0.0.254/24`; then
			    echo "Can't set IP address on ${BRIDGE_SHARED_IF}"
			    exit 1
		    fi
	    else
		    echo "Need to found the bridge number allready configured with 10.0.0.254"
		    exit 1
	    fi
    fi
    #Create Bridged interfaces that will be used for each LAN
    i=1
    while [ $i -le $LAN ];do
        eval BRIDGE_LAN_IF_${i}=`ifconfig bridge create`
        i=`expr $i + 1` 
    done
    # Main loop for each router
    i=1
    while [ $i -le $ROUTERS ]; do
        echo "Router $i network links matrix:"
        NIC_NUMBER=0
        #Create the shared with host bridged interface
        #Qemu cmd line is stored in variable QEMU_SHARED_IF_router-number
        if ($SHARED_WITH_HOST); then
            eval TAP_SHARED_IF_${i}=`ifconfig tap create`
		    # Link bridge with tap
		    TAP_SHARED_IF="TAP_SHARED_IF_$i"
		    TAP_SHARED_IF=`eval echo $"${TAP_SHARED_IF}"`
            ifconfig ${TAP_SHARED_IF} up
		    ifconfig ${BRIDGE_SHARED_IF} addm ${TAP_SHARED_IF} up
            echo "em${NIC_NUMBER} connected to the shared with host LAN, configure IP 10.0.0.${i}/24 on this NIC."
            NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
            TEMPO="-net nic,macaddr=AA:AA:00:00:00:0${i},vlan=0 -net tap,vlan=0,ifname=${TAP_SHARED_IF}"
		    eval QEMU_SHARED_IF_${i}=`echo '${TEMPO}'`
        else
            eval QEMU_SHARED_IF_${i}=""
        fi  
        # Enter in Full meshed Point-to-Point link loop
        # Full meshed "Point-to-Point" Loop interface creation
        # This loop create 2 TAPs bridged together for each links
        # Name convention:
        # BRIDGE_PP_IF_XY , for example BRIDGE_PP_IF_12 for link between router 1 and 2
        # TAP_PP_IF_XY_X, for example TAP_PP_IF_12_1 for link on router 1 used for link between router 1 and 2
        # TAP_PP_IF_XY_Y, for example TAP_PP_IF_12_2 for link on router 2 used for link between router 1 and 2
        eval QEMU_PP_IF_$i=""
        j=1 
        while [ $j -le $ROUTERS ]; do
            if [ $i -ne $j ]; then
                echo "em${NIC_NUMBER} connected to router ${j}."
                NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
                QEMU_PP="QEMU_PP_IF_$i"
                QEMU_PP=`eval echo $"${QEMU_PP}"`
                if [ $i -le $j ]; then
                    eval BRIDGE_PP_IF_${i}${j}=`ifconfig bridge create`
                    eval TAP_PP_IF_${i}${j}_${i}=`ifconfig tap create`
                    TAP_PP_IF="TAP_PP_IF_${i}${j}_${i}"
                    TAP_PP_IF=`eval echo $"${TAP_PP_IF}"`
                    BRIDGE_PP_IF="BRIDGE_PP_IF_${i}${j}"
                    BRIDGE_PP_IF=`eval echo $"${BRIDGE_PP_IF}"`
                    ifconfig ${TAP_PP_IF} up
                    ifconfig ${BRIDGE_PP_IF} addm ${TAP_PP_IF} up
                    TEMPO="${QEMU_PP} -net nic,macaddr=AA:AA:00:00:0${i}:${i}${j},vlan=${i}${j} -net tap,vlan=${i}${j},ifname=${TAP_PP_IF}"
                    eval QEMU_PP_IF_$i=`echo '${TEMPO}'`
                else
                    eval TAP_PP_IF_${j}${i}_${i}=`ifconfig tap create`
                    TAP_PP_IF="TAP_PP_IF_${j}${i}_${i}"
                    TAP_PP_IF=`eval echo $"${TAP_PP_IF}"`
                    BRIDGE_PP_IF="BRIDGE_PP_IF_${j}${i}"
                    BRIDGE_PP_IF=`eval echo $"${BRIDGE_PP_IF}"`
                    ifconfig ${TAP_PP_IF} up
                    ifconfig ${BRIDGE_PP_IF} addm ${TAP_PP_IF} up
                    TEMPO="${QEMU_PP} -net nic,macaddr=AA:AA:00:00:0${i}:${j}${i},vlan=${j}${i} -net tap,vlan=${j}${i},ifname=${TAP_PP_IF}"
                    eval QEMU_PP_IF_$i=`echo '${TEMPO}'`
                fi
            fi
            j=`expr $j + 1` 
        done
        # Enter in LAN interface loop
        # Convention name
        # BRIDGE_LAN_IF_Y (with Y lan number, X router number)
        # TAP_LAN_IF_Y_XY_
        eval QEMU_LAN_IF_$i=""
        j=1 
        while [ $j -le $LAN ]; do
            echo "em${NIC_NUMBER} connected to LAN ${j}."
            NIC_NUMBER=`expr ${NIC_NUMBER} + 1`
            eval TAP_LAN_IF_${j}_${i}=`ifconfig tap create`
            TAP_LAN_IF="TAP_LAN_IF_${j}_${i}"
            TAP_LAN_IF=`eval echo $"${TAP_LAN_IF}"`
            BRIDGE_LAN_IF="BRIDGE_LAN_IF_${j}"
            BRIDGE_LAN_IF=`eval echo $"${BRIDGE_LAN_IF}"`
            ifconfig ${TAP_LAN_IF} up
            ifconfig ${BRIDGE_LAN_IF} addm ${TAP_LAN_IF} up
            QEMU_LAN="QEMU_LAN_IF_$i"
            QEMU_LAN=`eval echo$"${QEMU_LAN}"`
            TEMPO="${QEMU_LAN} -net nic,macaddr=CC:CC:00:00:0${j}:0${i},vlan=10${j} -net tap,vlan=10${j},ifname=${TAP_LAN_IF}"
            eval QEMU_LAN_IF_$i=`echo '${TEMPO}'`
            j=`expr $j + 1` 
        done
        i=`expr $i + 1`
    done
}

# Delete all admin interfaces create for lab mode
delete_interfaces () {
    # Delete shared with host bridge and TAP
    if ($SHARED_WITH_HOST); then
	    ifconfig ${BRIDGE_SHARED_IF} destroy
    fi
    #Delete Bridged interfaces that will be used for each LAN
    i=1
    while [ $i -le $LAN ];do
        BRIDGE_LAN="BRIDGE_LAN_IF_$i"
		BRIDGE_LAN=`eval echo $"${BRIDGE_LAN}"`
    	ifconfig ${BRIDGE_LAN} destroy
        i=`expr $i + 1` 
    done
    # Main loop for each router
    i=1
    while [ $i -le $ROUTERS ]; do
        # Delele the shared with host bridged interface
        if ($SHARED_WITH_HOST); then
		    TAP_SHARED_IF="TAP_SHARED_IF_$i"
		    TAP_SHARED_IF=`eval echo $"${TAP_SHARED_IF}"`
            ifconfig ${TAP_SHARED_IF} destroy
        fi  
        # Delete all Point-to-Point link loop
        j=1 
        while [ $j -le $ROUTERS ]; do
            if [ $i -ne $j ]; then
                if [ $i -le $j ]; then
                    TAP_PP_IF="TAP_PP_IF_${i}${j}_${i}"
                    TAP_PP_IF=`eval echo $"${TAP_PP_IF}"`
                    ifconfig ${TAP_PP_IF} destroy
                else
                    TAP_PP_IF="TAP_PP_IF_${j}${i}_${i}"
                    TAP_PP_IF=`eval echo $"${TAP_PP_IF}"`
                    ifconfig ${TAP_PP_IF} destroy
                    BRIDGE_PP_IF="BRIDGE_PP_IF_${j}${i}"
                    BRIDGE_PP_IF=`eval echo $"${BRIDGE_PP_IF}"`
                    ifconfig ${BRIDGE_PP_IF} destroy
                fi
            fi
            j=`expr $j + 1` 
        done
        # Delete all TAP LAN interface loop
        j=1 
        while [ $j -le $LAN ]; do
            TAP_LAN_IF="TAP_LAN_IF_${j}_${i}"
            TAP_LAN_IF=`eval echo $"${TAP_LAN_IF}"`
            ifconfig ${TAP_LAN_IF} destroy
            j=`expr $j + 1` 
        done
        i=`expr $i + 1`
    done

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
    fi
    if echo "${FILENAME}" | grep -q "vga"; then
        QEMU_OUTPUT="-vnc :0 -serial none"
		SERIAL=false
		echo "filename guests a vga image"
        echo "Will start a VNC server on :0 for input/output"
        echo "DEBUG: BSDRP bug with no serial port"
    fi
    if [ "$QEMU_OUTPUT" = "0" ]; then
        echo "WARNING: Can't suppose default console of this image"
		echo "Will start a VNC server on :0 for input/output"
		SERIAL=false
        QEMU_OUTPUT="-vnc :0"
    fi
}

start_lab_vm () {
	i=1
    #Enter the main loop for each VM
	while [ $i -le $ROUTERS ]; do
        #Enter in the LAN NIC loop
        if ($SERIAL); then
            QEMU_OUTPUT="-nographic -vga none -serial telnet::800${i},server,nowait"
            echo "Connect to the router ${i} by telneting to localhost on port 800${i}"
        else
            QEMU_OUTPUT="-vnc :${i}"
            echo "Connect to the router ${i} by VNC client on display ${i}"
        fi
        QEMU_SHARED="QEMU_SHARED_IF_$i"
        QEMU_SHARED=`eval echo $"${QEMU_SHARED}"`
		QEMU_LAN="QEMU_LAN_IF_$i"
        QEMU_LAN=`eval echo $"${QEMU_LAN}"`
        QEMU_PP="QEMU_PP_IF_$i"
        QEMU_PP=`eval echo $"${QEMU_PP}"`

        ${QEMU_ARCH} -snapshot -hda ${FILENAME} ${QEMU_OUTPUT} ${QEMU_NAME} ${QEMU_SHARED} ${QEMU_PP} ${QEMU_LAN} -pidfile /tmp/BSDRP-$i.pid -daemonize
    	i=`expr $i + 1`
	done

    #Now wait for each qemu process end before continue
    i=1
	while [ $i -le $ROUTERS ]; do
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
ROUTERS=1
for i
do
        case "$i" 
        in
        -n)
                LAB_MODE=true
				ROUTERS=$2
                shift
                shift
                ;;
        -l)
                LAN=$2
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
if ($LAB_MODE); then
    if [ "$ROUTERS" != "" ]; then
	    if [ $ROUTERS -lt 1 ]; then
		    echo "Error: Use a minimal of 2 routers in your lab."
		    exit 1
	    fi

	    if [ $ROUTERS -ge 9 ]; then
		    echo "Error: Use a maximum of 9 routers in your lab."
		    exit 1
	    fi
    fi

    if [ "$LAN" != "" ]; then
        if [ $LAN -ge 9 ]; then
            echo "Error: Use a maximum of 9 LAN in your lab."
            exit 1
        fi
    else
        LAN=0
    fi
else
    SHARED_WITH_HOST=true
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

if ($LAB_MODE); then
    echo "Starting a lab with $ROUTERS routers:"
    if ($SHARED_WITH_HOST); then
        echo "- A LAN between all routers and the host"
    fi
	echo "- $LAN LAN(s) between all routers"
    echo "- Full mesh ethernet links between each routers"
	echo ""
fi

create_interfaces

if ($LAB_MODE); then
	start_lab_vm	
else
	echo "Starting qemu..."
    echo "BUG HERE: need to replace hard-coded tap0 with variable"
	${QEMU_ARCH} -hda ${FILENAME} -net nic -net tap,ifname=tap0 -localtime \
	${QEMU_OUTPUT} -k fr
fi
echo "...qemu stoped"

delete_interfaces

