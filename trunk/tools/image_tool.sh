#!/bin/sh
#
# Image manipulation tool for BSDRP 
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

set -e

DEST_ROOT=/tmp/bsdrp_root
DEST_CFG=/tmp/bsdrp_cfg
DEST_DATA=/tmp/bsdrp_data
DEST_LIST="$DEST_ROOT $DEST_CFG $DEST_DATA"
BSDRP_SRC=..

# Get options passed by user
getoption () {
	if [ $# -lt 1 ]; then
        	usage
	else
		OPTION="$1"
	fi
	if [ $# -eq 2 ];then
		FILENAME="$2"
	fi

	set -u
   	case "$OPTION" in
		mount)
        	mount_img
       		;;
        umount)
		umount_img 
		;;
	update)
		update_img
		;;
	qemu)
		convert_2qemu
		;;
	help|h)
		usage
		;;
	*)
       		if [ ! -n ${OPTION} ]; then
       			echo "missing option"
        	else    
            		echo "illegal option: $OPTION"
        	fi
        	usage
            	;;
        esac
}

# Display help
usage () {
	echo "BSD Router Project image manipulation tool"

# value $0 is the name of the called script
	echo "Usage: $0 option"
	echo "  - mount <filename>  : Mount BSDRP image"
	echo "  - umount   : umount BSDRP image"
	echo "  - update   : Copy some of the BSDRP source Files/ to mounted root"
	echo "  - qemu <filename>   : Convert BSDRP image to compressed qcow2 (qemu) format (not mandatory for using it with qemu)"
	echo "  - help (h) [option]  : Display this help message"
	exit 0
}

# Check if image is mounted
# $1: mount point to check
# Return 0 if yes, 1 if not
is_mounted () {
	if df $1  > /dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

are_mounted () {
	for MOUNT in $DEST_LIST; do
		if [ -d $MOUNT ];then
			is_mounted $MOUNT
		fi
	done
}

# update image
update_img () {
	if ! are_mounted; then
		echo "ERROR: image not mounted"
		exit 1
	fi

	# Verifing the presence of BSDRP Files folder:
	if [ ! -d ${BSDRP_SRC}/Files ]; then
		echo "Don't found ${BSDRP_SRC}/Files !"
		exit 1
	fi
	
	# Copying all Files (and create dir) 
	# execpt:
	# .svn and /usr/local/etc (because need special permission for quagga)
	# boot/ (because line are added to this file in serial or dual mode)
	(
	cd ${BSDRP_SRC}/Files
	find . -print | grep -Ev '/(CVS|\.svn|etc|boot)' | cpio -dumpv ${DEST_ROOT}/
	)
	(
	cd ${BSDRP_SRC}/Files/etc
	find . -print | grep -Ev '/(CVS|\.svn)' | cpio -dumpv ${DEST_ROOT}/etc/
	)

}
# Check validity of image file
check_img () {
	if [ "${FILENAME}" = "" ];
	then
		echo "Missing filename"
		usage
	fi
	# Checking if file exist
        if [ ! -f ${FILENAME} ]
		then
                echo "Can't found ${FILENAME}"
                exit 1
        fi
        # Checking file type
        (file -b ${FILENAME} | grep "boot sector"  > /dev/null 2>&1 )
        if [ ! $? -eq 0 ]; then
                echo "Not a BSDRP image file detected"
                echo "If your BSDRP image is zipped, unzip it before to use
 with this tools"
                exit 1
        fi
	
}

# Convert to qcow2 format
convert_2qemu () {
	check_img
	if [ ! -f /usr/local/bin/qemu-img ]
	then
		echo "Don't found qemu-img: Is qemu installed ?"
		exit 1
	fi
	# Checking if file exist
    if [ ! -f ${FILENAME} ]
    then
        echo "Can't found ${FILENAME}"
        exit 1
    fi

	# Checking if destination file exist
    if [ -f ${FILENAME}.qcow2 ]
    then
        echo "Destination file allready exist."
		echo "Move existing file to .old"
		mv ${FILENAME}.qcow2 ${FILENAME}.qcow2.old
    fi


	echo "Converting image…"
	if ! qemu-img convert -c -f raw -O qcow2 ${FILENAME} ${FILENAME}.qcow2; then
		echo "Meet a problem during qemu-img convert"
		exit 1
	fi
	echo "Img convert successfully"
	echo "New image: ${FILENAME}.qcow2"
	exit 0
}

# Mount image
mount_img () {

	if are_mounted; then
		echo "Some of them are allready mounted"
		exit 1
	fi
	check_img

	# Create RAM disk

	MD=`mdconfig -a -t vnode -f ${FILENAME}`
	if [ ! $? -eq 0 ]; then
		echo "Meet a problem for creating memory disk."
		exit 1
	fi

	# Save MD name (for umount)
	echo "MD=$MD" > /tmp/bsdrp_image_tool.tmp
	if [ -e /dev/${MD}s1a ]; then
		mkdir ${DEST_ROOT}
		if ! mount /dev/${MD}s1a ${DEST_ROOT}; then
			echo "ERROR Meet a problem for mounting root partition of the image."
			echo "Destroying Ram drive..."
			mdconfig -d -u $MD
			rm /tmp/bsdrp_image_tool.tmp
			exit 1
		fi
	else
		echo "ERROR: no /dev/${MD}s1a partition"
		mdconfig -d -u $MD
		rm /tmp/bsdrp_image_tool.tmp
		exit 1
	fi

	if [ -e /dev/${MD}s3 ]; then
		mkdir ${DEST_CFG}
		if ! mount /dev/${MD}s3 ${DEST_CFG}; then
			echo "ERROR: Meet a problem for mounting cfg partition of the image."
		fi
	fi

	if [ -e /dev/${MD}s4 ]; then
		mkdir ${DEST_DATA}
		if mount /dev/${MD}s4 ${DEST_DATA}; then
			echo "Meet a problem for mounting data partition of the image."
		fi
	fi

	echo "Successful mount BSDRP image into:"
	echo " - root partition: ${DEST_ROOT}"
	echo " - cfg partition : ${DEST_CFG}"
	echo " - data partition : ${DEST_DATA}"
	
	exit 0	
}

# umount the image
umount_img () {

	if ! are_mounted; then
		echo "ERROR: They are not mounted"
		exit 1
	fi

	for DEST_MOUNT in $DEST_LIST; do
		if [ -d ${DEST_MOUNT} ]; then
			if ! umount ${DEST_MOUNT}; then
				echo "ERROR: Meet a problem for umounting $DEST_MOUNT."
			else
				rm -rf ${DEST_MOUNT}
			fi
		fi
	done

	# Get the Memory Disk identifier:
	. /tmp/bsdrp_image_tool.tmp

	# Destroy memory disk:
	echo "Destroy ${MD}"
	
	if ! mdconfig -d -u $MD; then
		echo "ERROR: Can't destroy md $MD"
	fi
	echo "Successful umount BSDRP image"

	# cleanup
	rm /tmp/bsdrp_image_tool.tmp
	
	exit 0
}


### Main function ###

getoption $*

