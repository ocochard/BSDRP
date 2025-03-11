#!/bin/sh
#
# Qemu/kvm lab test script for BSD Router Project
# https://bsdrp.net
#
# Copyright (c) 2009-2025, The BSDRP Development Team
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

### Variables

HOST_OS=$(uname -s)
HOST_ARCH=$(uname -m)
NIC_MODEL=virtio-net-pci
NIC_NAME=vtnet
FILENAME=""
NUMBER_VM=1
NUMBER_LAN=0
RAM=1024

### Functions
die() {
    echo -n "EXIT: " >&2
    echo "$@" >&2
    exit 1
}

check_image() {
    local file=$1
    if [ ! -f ${file} ]; then
        die "ERROR: Can't found the file ${file}"
    fi

    if file -b ${file} | grep -q "XZ compressed data"; then
		  echo "Compressed image detected, uncompress it..."
		  xz -dfk ${file}
		  file=$(echo ${file} | sed -e 's/.xz//g')
    fi

    if ! file -b ${file} | grep -q "boot sector"; then
        die "ERROR: Not a BSDRP disk image (missing "boot sector" identifier)"
    fi
    FILENAME=${file}
}

search_boot_loaders() {
    local arch=$1
    local bootloader=""

    # List of possible paths based on OS and installation method
    local paths="
        /opt/homebrew/Cellar/qemu/*/share/qemu/edk2-${arch}-code.fd
        /Applications/UTM.app/Contents/Resources/qemu/edk2-${arch}-code.fd
        /usr/local/share/qemu/edk2-${arch}-code.fd
        /usr/share/qemu/edk2-${arch}-code.fd
    "

    # Try each path
    for path in ${paths}; do
        # Use ls to handle wildcards, suppress errors
        for found in $(ls $path 2>/dev/null); do
            if [ -f "$found" ]; then
                bootloader="$found"
                echo "$bootloader"
                return 0
            fi
        done
    done

    if [ -z "$bootloader" ]; then
        die "WARNING: Could not find ${arch} UEFI firmware file"
    fi
}

# Parse filename for detecting ARCH
parse_filename () {
    local file=$1
    QEMU_ARCH=""


    # Need to map disk image ARCH and local ARCH
    # load as read-only because on FreeBSD the UEFI firmwares are not writable and qemu by default check if it is writable
    if echo "${file}" | grep -q "amd64"; then
        bootloader=$(search_boot_loaders x86_64)
        if [ "${HOST_OS}" = "Darwin" ] && [ "${HOST_ARCH}" = "x86_64" ]; then
            ACCEL="hvf"
        else
            ACCEL="tcg"
        fi
        # XXX $ACCEL not used here ?
        QEMU_ARCH="qemu-system-x86_64 --machine pc -cpu qemu64 -drive if=pflash,readonly=on,format=raw,file=${bootloader}"
    elif echo "${file}" | grep -q "i386"; then
        bootloader=$(search_boot_loaders i386)
        QEMU_ARCH="qemu-system-i386 --machine pc -cpu qemu32 -drive if=pflash,readonly=on,format=raw,file=${bootloader}"
    elif echo "${file}" | grep -q "aarch64"; then
        bootloader=$(search_boot_loaders aarch64)
        # hvf: Apple hypervisor
        if [ "${HOST_OS}" = "Darwin" ] && [ "${HOST_ARCH}" = "arm64" ]; then
            ACCEL="accel=hvf -cpu host"
        else
            ACCEL="accel=tcg -cpu neoverse-n1"
        fi
        QEMU_ARCH="qemu-system-aarch64 --machine virt,${ACCEL} -drive if=pflash,readonly=on,format=raw,file=${bootloader}"
        echo "filename guests an ARM 64 image"
    fi

    if [ -z "$QEMU_ARCH" ]; then
        # XXX Need to be optimized (avoid duplicate)
        echo "WARNING: Can't guests the CPU architecture of this image from the filename"
        echo "Defaulting to x86_64"
        bootloader=$(search_boot_loaders x86_64)
        QEMU_ARCH="qemu-system-x86_64 --machine pc -cpu qemu64 -drive if=pflash,readonly=on,format=raw,file=${bootloader}"
    fi

    QEMU_OUTPUT="-display none -serial mon:stdio" # Only valid if one VM started
    SERIAL=true
    echo "filename guests a serial image"
    echo "Will use standard console as input/output"
    echo "Guest VM configured without vga card"
}

start_lab_vm () {
    echo "Starting a lab with $NUMBER_VM routers:"
    echo "- 1 shared LAN between all routers and the host"
    echo "- $NUMBER_LAN LAN between all routers"
    echo "- Full mesh ethernet point-to-point link between each routers"
    echo ""
    i=1
    #Enter the main loop for each VM
    while [ $i -le ${NUMBER_VM} ]; do
        echo "Router$i have the folllowing NIC:"
        QEMU_NAME="-name Router${i}"
        NIC_NUMBER=0
        echo "${NIC_NAME}${NIC_NUMBER} connected to shared with host LAN, configure dhclient on this."
        NIC_NUMBER=$(( NIC_NUMBER + 1 ))
        QEMU_ADMIN_NIC="-netdev user,id=hostnet${i} -device ${NIC_MODEL},netdev=hostnet${i},mac=AA:AA:00:00:00:0${i}"
        SNAPSHOT=""
        QEMU_PP_NIC=""
        QEMU_LAN_NIC=""
        QEMU_OUTPUT="-display none -serial mon:stdio"
        if [ ${NUMBER_VM} -gt 1 ]; then
            # Enable snapshot if more than 1 VM
            SNAPSHOT="-snapshot"
            # Generate full-mesh links between all VMs
            # Now generate X x (X-1)/2 full meshed link
            j=1
            while [ $j -le ${NUMBER_VM} ]; do
                if [ $i -ne $j ]; then
                    echo "${NIC_NAME}${NIC_NUMBER} connected to Router${j}."
                    NIC_NUMBER=$(( NIC_NUMBER + 1 ))
                    if [ $i -le $j ]; then
                        QEMU_PP_NIC="${QEMU_PP_NIC} -device ${NIC_MODEL},netdev=pp${i}${i}${j},mac=AA:AA:00:00:0${i}:${i}${j} -netdev dgram,id=pp${i}${i}${j},local.type=inet,local.host=localhost,local.port=20${i}${j},remote.type=inet,remote.host=localhost,remote.port=20${j}${i}"
                    else
                        QEMU_PP_NIC="${QEMU_PP_NIC} -device ${NIC_MODEL},netdev=pp${i}${j}${i},mac=AA:AA:00:00:0${i}:${j}${i} -netdev dgram,id=pp${i}${j}${i},local.type=inet,local.host=localhost,local.port=20${i}${j},remote.type=inet,remote.host=localhost,remote.port=20${j}${i}"
                    fi
                fi
                j=$(( j + 1 ))
            done
            #Enter in the LAN NIC loop
            j=1
            while [ $j -le ${NUMBER_LAN} ]; do
                echo "${NIC_NAME}${NIC_NUMBER} connected to LAN number ${j}."
                NIC_NUMBER=$(( ${NIC_NUMBER} + 1 ))
                if [ ${HOST_OS} = "Darwin" ]; then
                    # Need root, because vmnet-host will create a bridge interface
                    QEMU_LAN_NIC="${QEMU_LAN_NIC} -device ${NIC_MODEL},netdev=l${i}${j},mac=CC:CC:00:00:0${j}:0${i} -netdev vmnet-host,id=l${i}${j},net-uuid=84930000-0000-0000-0000-000000000d0${j}"
                else
                    QEMU_LAN_NIC="${QEMU_LAN_NIC} -device ${NIC_MODEL},netdev=l${i}${j},mac=CC:CC:00:00:0${j}:0${i} -netdev socket,id=l${i}${j},mcast=230.0.0.1:200${j},localaddr=127.0.0.1"
                fi
                j=$(( j + 1 ))
            done
            if [ ${SERIAL} = true ]; then
                QEMU_OUTPUT="-display none -serial telnet::800${i},server,nowait -serial mon:telnet::900${i},server,nowait -daemonize"
                echo "Connect to the console port of router ${i} by telneting to localhost on port 800${i}"
                echo "qemu-monitor is on port 900${i} for this router (Ctrl-A + c)"
            fi
        fi # if NUMBER_VM > 1
        # XXX bug on FreeBSD: in snapshot mode only (IE: multiple VMs)the EFI firmware goes in shell mode and need to manually enter "FS0:\EFI\BOOT\BOOTX64.EFI" to continue booting
        ${QEMU_ARCH} -m ${RAM} ${SNAPSHOT} -drive if=virtio,file=${FILENAME},format=raw,media=disk ${QEMU_OUTPUT} ${QEMU_NAME} ${QEMU_ADMIN_NIC} ${QEMU_PP_NIC} ${QEMU_LAN_NIC} -pidfile /tmp/BSDRP-$i.pid
        i=$(( i + 1 ))
    done

}

usage () {
        (
        echo "Usage: $0 [-shv] -i BSDRP-full.img [-n router-number] [-l LAN-number]"
        echo "  -i filename     BSDRP file image path"
        echo "  -n X            Number of VM to start, they will be full meshed (default: 1)"
        echo "  -l Y            Number of shared LAN between VM (default: 0)"
        echo "  -h              Display this help"
        echo "  -v              Display verbose output"
        echo ""
        echo "Note: If more than 1 VM, the qemu process are started in snapshot mode,"
        echo "this mean that all modifications to disks are lose after quitting the lab"
        ) 1>&2
        exit 2
}

################
# Main section #
################

### Parse argument

if [ $? -ne 0 ] ; then
        usage
        exit 2
fi

while getopts "i:hl:n:" arg; do
    case "$arg" in
    h)  usage 0 ;;
    n)  NUMBER_VM="$OPTARG" ;;
    l)  NUMBER_LAN="$OPTARG" ;;
    i)  FILENAME="$OPTARG" ;;
    v)  set -x ;;
    *)  usage 1 ;;
esac
done
shift $(( OPTIND - 1 ))

echo "BSD Router Project: Qemu lab script"

if ! which qemu-system-x86_64; then
    die "qemu not found, need to install qemu and edk2 (qemu EFI firmwares)"
fi

if [ ${HOST_OS} = "Darwin" ] && [ ${NUMBER_LAN} -gt 0 ]; then
    if [ ${USER} != "root" ]; then
        die "Need to be run as root to use shared LAN (MacOS needs to create a vmnet bridge interface"
    fi
fi

check_image ${FILENAME}
parse_filename ${FILENAME}

echo "Starting $NUMBER_VM BSDRP VM full meshed"
start_lab_vm
