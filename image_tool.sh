#!/bin/sh
#
# Image manipulation tool for BSDRP 
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

# Uncomment for enable debug: 
#set -x

DEST_ROOT=/tmp/bsdrp_root
DEST_CFG=/tmp/bsdrp_cfg
DEST_DATA=/tmp/bsdrp_data
BSDRP_SRC=/usr/src/tools/tools/nanobsd/BSDRP

# Get options passed by user
getoption () {
	OPTION="$1"
    FILENAME="$2"
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
		#convert)
		#	convert
		#	;;
		help|h)
			usage
			;;
		*)
            if [ "${OPTION}" = "" ];
            then
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
#	echo "  - convert    : Convert ad0 to da0 and vice e versa"
	echo "  - help (h) [option]  : Display this help message"
	exit 0
}

# Check if image is mounted
check_is_mount () {
	# Verifing that destination mount points are mounted
	(mount | grep "${DEST_ROOT}"  > /dev/null 2>&1 )
	if [ ! $? -eq 0 ]
	then
		echo "It seem that ${DEST_ROOT} is not mounted"
		echo '"Use "image_tools mount" before'		
		exit 1
	fi

	(mount | grep "${DEST_CFG}"  > /dev/null 2>&1 )
	if [ ! $? -eq 0 ]
	then
		echo "It seem that ${DEST_CFG} is not mounted"
		echo '"Use "image_tools mount" before'		
		exit 1
	fi
	
	(mount | grep "${DEST_DATA}"  > /dev/null 2>&1 )
	if [ ! $? -eq 0 ]
	then
		echo "It seem that ${DEST_DATA} is not mounted"
	fi

}
# Convert function
convert_drive () {
	echo "mount -o ro /dev/${NEW_DRIVE}s3" > ${DEST_ROOT}/conf/default/etc/remount	
	echo "NANO_DRIVE=${NEW_DRIVE}" > ${DEST_ROOT}/etc/nanobsd.conf
	echo "/dev/${NEW_DRIVE}s1a / ufs ro 1 1" > ${DEST_ROOT}/etc/fstab
    echo "/dev/${NEW_DRIVE}s3 /cfg ufs rw,noauto 2 2" >> ${DEST_ROOT}/etc/fstab
	echo "Done!"
	echo "Don't forget to change the filename from ${NANO_DRIVE} to ${NEW_DRIVE} once image will be umounted"
	exit 0
}

# Convert Disk type (ad0 to da0, da0 to ad0) 
convert () {
	check_is_mount
	# Get original disk type (set the variable NANO_DRIVE)
	. ${DEST_ROOT}/etc/nanobsd.conf
	case "$NANO_DRIVE" in
		ad0)
			echo "ad0 detected, convert to da0:"
			NEW_DRIVE=da0
			convert_drive	
			exit 0
			;;
		da0)
			echo "da0 detected, convert to ad0:"
			NEW_DRIVE=ad0
			convert_drive
			exit 0
			;;
		*)
			echo "Unknown value: ${NANO_DRIVE}"
			exit 1
	esac
	
}
# update image
update_img () {
	check_is_mount

	# Verifing the presence of BSDRP Files folder:
	if [ ! -d ${BSDRP_SRC}/Files ]
	then
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
        if [ ! $? -eq 0 ]
        then
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
	qemu-img convert -c -f raw -O qcow2 ${FILENAME} ${FILENAME}.qcow2
  	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem during qemu-img convert"
		exit 1
	fi
	echo "Img convert successfully"
	echo "New image: ${FILENAME}.qcow2"
	exit 0
}

# Check if BSDRP image is allready mounted
check_notmounted () {
	# Verifing that destination mount point are free
	(mount | grep "${DEST_ROOT}"  > /dev/null 2>&1 )
	if [ $? -eq 0 ]
	then
		echo "It seem that ${DEST_ROOT} is allready mounted"
		echo '"Use "image_tools umount" before to use mount'		
		exit 1
	fi

	(mount | grep "${DEST_CFG}"  > /dev/null 2>&1 )
	if [ $? -eq 0 ]
	then
		echo "It seem that ${DEST_CFG} is allready mounted"
		echo '"Use "image_tools umount" before to use mount'		
		exit 1
	fi

	(mount | grep "${DEST_DATA}"  > /dev/null 2>&1 )
	if [ $? -eq 0 ]
	then
		echo "It seem that ${DEST_DATA} is allready mounted"
		echo '"Use "image_tools umount" before to use mount'		
		exit 1
	fi

}
# Mount image
mount_img () {

	check_notmounted
	check_img

	# Create the destination folders

	if [ ! -d ${DEST_ROOT} ]
	then
		mkdir ${DEST_ROOT}
	fi

	if [ ! -d ${DEST_CFG} ]
	then
		mkdir ${DEST_CFG}
	fi

	if [ ! -d ${DEST_DATA} ]
	then
		mkdir ${DEST_DATA}
	fi

	# Create RAM disk

	MD=`mdconfig -a -t vnode -f ${FILENAME} -x 63 -y 16`
	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem for creating memory disk."
		exit 1
	fi

	# Save MD name (for umount)
	echo "MD=$MD" > /tmp/bsdrp_image_tools.tmp
	
	mount /dev/${MD}s1a ${DEST_ROOT}
	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem for mounting root partition of the image."
		echo "Destroying Ram drive..."
		mdconfig -d -u $MD
		exit 1
	fi

	mount /dev/${MD}s3 ${DEST_CFG}
	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem for mounting cfg partition of the image."
		exit 1
	fi

	mount /dev/${MD}s4 ${DEST_DATA}
	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem for mounting data partition of the image."
	fi

	echo "Successful mount BSDRP image into:"
	echo " - root partition: ${DEST_ROOT}"
	echo " - cfg partition : ${DEST_CFG}"
	echo " - data partition : ${DEST_DATA}"
	
	exit 0	
}

# umount the image
umount_img () {

	check_is_mount

	umount ${DEST_ROOT}
	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem for umounting root partition of the image."
		echo "Still in use ?"
		exit 1
	fi

	umount ${DEST_CFG}
	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem for umounting cfg partition of the image."
		echo "Still in use ?"
		exit 1
	fi

	umount ${DEST_DATA}
	if [ ! $? -eq 0 ]
	then
		echo "Meet a problem for umounting data partition of the image."
		echo "Not a blocking problem"
	fi

	# Get the Memory Disk identifier:
	. /tmp/bsdrp_image_tools.tmp

	# Destroy memory disk:
	echo "Destroy ${MD}"
	mdconfig -d -u $MD
	echo "Successful umount BSDRP image"

	# cleanup
	rm /tmp/bsdrp_image_tools.tmp
	
	exit 0
}


### Main function ###

getoption $*

