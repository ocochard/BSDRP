#!/bin/sh
#
# BSD Router Project: Modified version of nanobsd
#
# Copyright (c) 2005 Poul-Henning Kamp.
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
#

set -e

#######################################################################
#
# Setup default values for all controlling variables.
# These values can be overridden from the config file(s)
#
#######################################################################

# Name of this NanoBSD build.  (Used to construct workdir names)
NANO_NAME=full

# Source tree directory
NANO_SRC=/usr/src

# Where nanobsd additional files live under the source tree
NANO_TOOLS=tools/tools/nanobsd

# Where cust_pkg() finds packages to install
NANO_PACKAGE_DIR=${NANO_SRC}/${NANO_TOOLS}/Pkg
NANO_PACKAGE_LIST="*"

# Object tree directory
# default is subdir of /usr/obj
#NANO_OBJ=""

# The directory to put the final images
# default is ${NANO_OBJ}
#NANO_DISKIMGDIR=""

# Parallel Make
NANO_PMAKE="make -j 3"

# The default name for any image we create.
NANO_IMGNAME="_.disk.full"

# Options to put in make.conf during buildworld only
CONF_BUILD=' '

# Options to put in make.conf during installworld only
CONF_INSTALL=' '

# Options to put in make.conf during both build- & installworld.
CONF_WORLD=' '

# Kernel config file to use
NANO_KERNEL=GENERIC

# Kernel modules to build; default is none
NANO_MODULES=

# Customize commands.
NANO_CUSTOMIZE=""

# Late customize commands.
NANO_LATE_CUSTOMIZE=""

# Newfs paramters to use
NANO_NEWFS="-b 4096 -f 512 -i 8192 -O1 -U"

# The drive name of the media at runtime
NANO_DRIVE=ad0

# Target media size in 512 bytes sectors
NANO_MEDIASIZE=1500000

# Number of code images on media (1 or 2)
NANO_IMAGES=2

# 0 -> Leave second image all zeroes so it compresses better.
# 1 -> Initialize second image with a copy of the first
NANO_INIT_IMG2=1

# Size of code file system in 512 bytes sectors
# If zero, size will be as large as possible.
NANO_CODESIZE=0

# Size of configuration file system in 512 bytes sectors
# Cannot be zero.
NANO_CONFSIZE=2048

# Size of data file system in 512 bytes sectors
# If zero: no partition configured.
# If negative: max size possible
NANO_DATASIZE=0

# Size of the /etc ramdisk in 512 bytes sectors
NANO_RAM_ETCSIZE=10240

# Size of the /tmp+/var ramdisk in 512 bytes sectors
NANO_RAM_TMPVARSIZE=10240

# Media geometry, only relevant if bios doesn't understand LBA.
NANO_SECTS=63
NANO_HEADS=16

# boot0 flags/options and configuration
NANO_BOOT0CFG="-o packet -s 1 -m 3"
NANO_BOOTLOADER="boot/boot0sio"

# boot2 flags/options
# default force serial console
NANO_BOOT2CFG="-h"

# Backing type of md(4) device
# Can be "file" or "swap"
NANO_MD_BACKING="file"

# for swap type md(4) backing, write out the mbr only
NANO_IMAGE_MBRONLY=true

# Progress Print level
PPLEVEL=3

# Set NANO_LABEL to non-blank to form the basis for using /dev/ufs/label
# in preference to /dev/${NANO_DRIVE}
# Root partition will be ${NANO_LABEL}s{1,2}
# /cfg partition will be ${NANO_LABEL}s3
# /data partition will be ${NANO_LABEL}s4
NANO_LABEL=""

#######################################################################
# Architecture to build.  Corresponds to TARGET_ARCH in a buildworld.
# Unfortunately, there's no way to set TARGET at this time, and it
# conflates the two, so architectures where TARGET != TARGET_ARCH do
# not work.  This defaults to the arch of the current machine.

NANO_ARCH=`uname -p`

# Directory to populate /cfg from
NANO_CFGDIR=""

# Directory to populate /data from
NANO_DATADIR=""

#######################################################################
#
# The functions which do the real work.
# Can be overridden from the config file(s)
#
#######################################################################

nano_cleanup() {
   if [ $? -ne 0 ]; then
       echo "Error encountered.  Check for errors in last log file." 1>&2
    fi
    exit $?
}

clean_build ( ) (
	pprint 2 "Clean and create object directory (${MAKEOBJDIRPREFIX})"

	if ! rm -rf ${MAKEOBJDIRPREFIX} > /dev/null 2>&1 ; then
		chflags -R noschg ${MAKEOBJDIRPREFIX}
		rm -r ${MAKEOBJDIRPREFIX}
	fi
	mkdir -p ${MAKEOBJDIRPREFIX}
	printenv > ${MAKEOBJDIRPREFIX}/_.env
)

make_conf_build ( ) (
	pprint 2 "Construct build make.conf ($NANO_MAKE_CONF_BUILD)"

	echo "${CONF_WORLD}" > ${NANO_MAKE_CONF_BUILD}
	echo "${CONF_BUILD}" >> ${NANO_MAKE_CONF_BUILD}
	echo "SRCCONF=/dev/null" >> ${NANO_MAKE_CONF_BUILD}
)

build_world ( ) (
	pprint 2 "run buildworld"
	pprint 3 "log: ${MAKEOBJDIRPREFIX}/_.bw"

	cd ${NANO_SRC}
	env TARGET_ARCH=${NANO_ARCH} ${NANO_PMAKE} \
		__MAKE_CONF=${NANO_MAKE_CONF_BUILD} buildworld \
		> ${MAKEOBJDIRPREFIX}/_.bw 2>&1
)

build_kernel ( ) (
	pprint 2 "build kernel ($NANO_KERNEL)"
	pprint 3 "log: ${MAKEOBJDIRPREFIX}/_.bk"

	(
	if [ -f ${NANO_KERNEL} ] ; then
		kernconfdir=$(realpath $(dirname ${NANO_KERNEL}))
		kernconf=$(basename ${NANO_KERNEL})
	else
		kernconf=${NANO_KERNEL}
	fi

	cd ${NANO_SRC};
	# unset these just in case to avoid compiler complaints
	# when cross-building
	unset TARGET_CPUTYPE
	unset TARGET_BIG_ENDIAN
	# Note: We intentionally build all modules, not only the ones in
	# NANO_MODULES so the built world can be reused by multiple images.
	env TARGET_ARCH=${NANO_ARCH} ${NANO_PMAKE} buildkernel \
		__MAKE_CONF=${NANO_MAKE_CONF_BUILD} \
		${kernconfdir:+"KERNCONFDIR="}${kernconfdir} \
		KERNCONF=${kernconf}
	) > ${MAKEOBJDIRPREFIX}/_.bk 2>&1
)

clean_world ( ) (
	if [ "${NANO_OBJ}" != "${MAKEOBJDIRPREFIX}" ]; then
		pprint 2 "Clean and create object directory (${NANO_OBJ})"
		if ! rm -rf ${NANO_OBJ} > /dev/null 2>&1 ; then
			chflags -R noschg ${NANO_OBJ}
			rm -r ${NANO_OBJ}
		fi
		mkdir -p ${NANO_OBJ} ${NANO_WORLDDIR}
		printenv > ${NANO_OBJ}/_.env
	else
		pprint 2 "Clean and create world directory (${NANO_WORLDDIR})"
		if ! rm -rf ${NANO_WORLDDIR}/ > /dev/null 2>&1 ; then
			chflags -R noschg ${NANO_WORLDDIR}
			rm -rf ${NANO_WORLDDIR}
		fi
		mkdir -p ${NANO_WORLDDIR}
	fi
)

make_conf_install ( ) (
	pprint 2 "Construct install make.conf ($NANO_MAKE_CONF_INSTALL)"

	echo "${CONF_WORLD}" > ${NANO_MAKE_CONF_INSTALL}
	echo "${CONF_INSTALL}" >> ${NANO_MAKE_CONF_INSTALL}
	echo "SRCCONF=/dev/null" >> ${NANO_MAKE_CONF_INSTALL}
)

install_world ( ) (
	pprint 2 "installworld"
	pprint 3 "log: ${NANO_OBJ}/_.iw"

	cd ${NANO_SRC}
	env TARGET_ARCH=${NANO_ARCH} \
	${NANO_PMAKE} __MAKE_CONF=${NANO_MAKE_CONF_INSTALL} installworld \
		DESTDIR=${NANO_WORLDDIR} \
		> ${NANO_OBJ}/_.iw 2>&1
	chflags -R noschg ${NANO_WORLDDIR}
)

install_etc ( ) (

	pprint 2 "install /etc"
	pprint 3 "log: ${NANO_OBJ}/_.etc"

	cd ${NANO_SRC}
	env TARGET_ARCH=${NANO_ARCH} \
	${NANO_PMAKE} __MAKE_CONF=${NANO_MAKE_CONF_INSTALL} distribution \
		DESTDIR=${NANO_WORLDDIR} \
		> ${NANO_OBJ}/_.etc 2>&1
	# make.conf doesn't get created by default, but some ports need it
	# so they can spam it.
	cp /dev/null ${NANO_WORLDDIR}/etc/make.conf
)

install_kernel ( ) (
	pprint 2 "install kernel ($NANO_KERNEL)"
	pprint 3 "log: ${NANO_OBJ}/_.ik"

	(
	if [ -f ${NANO_KERNEL} ] ; then
		kernconfdir=$(realpath $(dirname ${NANO_KERNEL}))
		kernconf=$(basename ${NANO_KERNEL})
	else
		kernconf=${NANO_KERNEL}
	fi

	cd ${NANO_SRC}
	env TARGET_ARCH=${NANO_ARCH} ${NANO_PMAKE} installkernel \
		DESTDIR=${NANO_WORLDDIR} \
		__MAKE_CONF=${NANO_MAKE_CONF_INSTALL} \
		${kernconfdir:+"KERNCONFDIR="}${kernconfdir} \
		KERNCONF=${kernconf} \
		MODULES_OVERRIDE="${NANO_MODULES}"
	) > ${NANO_OBJ}/_.ik 2>&1
)

run_customize() (

	pprint 2 "run customize scripts"
	for c in $NANO_CUSTOMIZE
	do
		pprint 2 "customize \"$c\""
		pprint 3 "log: ${NANO_OBJ}/_.cust.$c"
		pprint 4 "`type $c`"
		( set -x ; $c ) > ${NANO_OBJ}/_.cust.$c 2>&1
	done
)

run_late_customize() (

	pprint 2 "run late customize scripts"
	for c in $NANO_LATE_CUSTOMIZE
	do
		pprint 2 "late customize \"$c\""
		pprint 3 "log: ${NANO_OBJ}/_.late_cust.$c"
		pprint 4 "`type $c`"
		( set -x ; $c ) > ${NANO_OBJ}/_.late_cust.$c 2>&1
	done
)

setup_nanobsd ( ) (
	pprint 2 "configure nanobsd setup"
	pprint 3 "log: ${NANO_OBJ}/_.dl"

	(
	cd ${NANO_WORLDDIR}

	# Move /usr/local/etc to /etc/local so that the /cfg stuff
	# can stomp on it.  Otherwise packages like ipsec-tools which
	# have hardcoded paths under ${prefix}/etc are not tweakable.
	if [ -d usr/local/etc ] ; then
		(
		mkdir -p etc/local
		cd usr/local/etc
		find . -print | cpio -dumpl ../../../etc/local
		cd ..
		rm -rf etc
		ln -s ../../etc/local etc
		)
	fi

	for d in var etc
	do
		# link /$d under /conf
		# we use hard links so we have them both places.
		# the files in /$d will be hidden by the mount.
		# XXX: configure /$d ramdisk size
		mkdir -p conf/base/$d conf/default/$d
		find $d -print | cpio -dumpl conf/base/
	done

	echo "$NANO_RAM_ETCSIZE" > conf/base/etc/md_size
	echo "$NANO_RAM_TMPVARSIZE" > conf/base/var/md_size

	# pick up config files from the special partition
	echo "mount -o ro /dev/${NANO_DRIVE}s3" > conf/default/etc/remount

	# Put /tmp on the /var ramdisk (could be symlink already)
	rmdir tmp || true
	rm tmp || true
	ln -s var/tmp tmp

	) > ${NANO_OBJ}/_.dl 2>&1
)

setup_nanobsd_etc ( ) (
	pprint 2 "configure nanobsd /etc"

	(
	cd ${NANO_WORLDDIR}

	# create diskless marker file
	touch etc/diskless

	# Make root filesystem R/O by default
	echo "root_rw_mount=NO" >> etc/defaults/rc.conf

	# save config file for scripts
	echo "NANO_DRIVE=${NANO_DRIVE}" > etc/nanobsd.conf

	echo "/dev/${NANO_DRIVE}s1a / ufs ro 1 1" > etc/fstab
	echo "/dev/${NANO_DRIVE}s3 /cfg ufs rw,noauto 2 2" >> etc/fstab
	mkdir -p cfg
	)
)

prune_usr() (

	# Remove all empty directories in /usr 
	find ${NANO_WORLDDIR}/usr -type d -depth -not -name aout -print |
		while read d
		do
			rmdir $d > /dev/null 2>&1 || true 
		done
)

newfs_part ( ) (
	local dev mnt lbl
	dev=$1
	mnt=$2
	lbl=$3
	echo newfs ${NANO_NEWFS} ${NANO_LABEL:+-L${NANO_LABEL}${lbl}} ${dev}
	newfs ${NANO_NEWFS} ${NANO_LABEL:+-L${NANO_LABEL}${lbl}} ${dev}
	mount -o async ${dev} ${mnt}
)

populate_slice ( ) (
	local dev dir mnt lbl
	dev=$1
	dir=$2
	mnt=$3
	lbl=$4
	test -z $2 && dir=${NANO_WORLDDIR}/var/empty
	test -d $dir || dir=${NANO_WORLDDIR}/var/empty
	echo "Creating ${dev} with ${dir} (mounting on ${mnt})"
	newfs_part $dev $mnt $lbl
	cd ${dir}
	find . -print | grep -Ev '/(CVS|\.svn)' | cpio -dumpv ${mnt}
	df -i ${mnt}
	umount ${mnt}
)

populate_cfg_slice ( ) (
	populate_slice "$1" "$2" "$3" "$4"
)

populate_data_slice ( ) (
	populate_slice "$1" "$2" "$3" "$4"
)

generate_mtree ( ) (
	local md mnt
	md=$1
	mnt=$2
	mount ${md} ${mnt}
    echo "Generating mtree..."
    echo "./etc" > ${NANO_OBJ}/mtree-exclude
    echo "./var" >> ${NANO_OBJ}/mtree-exclude
    echo "./tmp" >> ${NANO_OBJ}/mtree-exclude
    echo "./dev" >> ${NANO_OBJ}/mtree-exclude
    ( cd ${mnt} && mtree -x -ic -k flags,gid,mode,nlink,size,link,uid,sha256digest -X ${NANO_OBJ}/mtree-exclude ) > ${NANO_OBJ}/_.mtree

    ( cd ${mnt} && du -k ) > ${NANO_OBJ}/_.du
    umount ${mnt}
)

create_i386_diskimage ( ) (
	pprint 2 "build diskimage"
	pprint 3 "log: ${NANO_OBJ}/_.di"

	(
	echo $NANO_MEDIASIZE $NANO_IMAGES \
		$NANO_SECTS $NANO_HEADS \
		$NANO_CODESIZE $NANO_CONFSIZE $NANO_DATASIZE |
	awk '
	{
		printf "# %s\n", $0

		# size of cylinder in sectors
		cs = $3 * $4

		# number of full cylinders on media
		cyl = int ($1 / cs)

		# output fdisk geometry spec, truncate cyls to 1023
		if (cyl <= 1023)
			print "g c" cyl " h" $4 " s" $3
		else
			print "g c" 1023 " h" $4 " s" $3

		if ($7 > 0) { 
			# size of data partition in full cylinders
			dsl = int (($7 + cs - 1) / cs)
		} else {
			dsl = 0;
		}

		# size of config partition in full cylinders
		csl = int (($6 + cs - 1) / cs)

		if ($5 == 0) {
			# size of image partition(s) in full cylinders
			isl = int ((cyl - dsl - csl) / $2)
		} else {
			isl = int (($5 + cs - 1) / cs)
		}

		# First image partition start at second track
		print "p 1 165 " $3, isl * cs - $3
		c = isl * cs;

		# Second image partition (if any) also starts offset one 
		# track to keep them identical.
		if ($2 > 1) {
			print "p 2 165 " $3 + c, isl * cs - $3
			c += isl * cs;
		}

		# Config partition starts at cylinder boundary.
		print "p 3 165 " c, csl * cs
		c += csl * cs

		# Data partition (if any) starts at cylinder boundary.
		if ($7 > 0) {
			print "p 4 165 " c, dsl * cs
		} else if ($7 < 0 && $1 > c) {
			print "p 4 165 " c, $1 - c
		} else if ($1 < c) {
			print "Disk space overcommitted by", \
			    c - $1, "sectors" > "/dev/stderr"
			exit 2
		}

		# Force slice 1 to be marked active. This is necessary
		# for booting the image from a USB device to work.
		print "a 1"
	}
	' > ${NANO_OBJ}/_.fdisk

	IMG=${NANO_DISKIMGDIR}/${NANO_IMGNAME}
	MNT=${NANO_OBJ}/_.mnt
	mkdir -p ${MNT}

	if [ "${NANO_MD_BACKING}" = "swap" ] ; then
		MD=`mdconfig -a -t swap -s ${NANO_MEDIASIZE} -x ${NANO_SECTS} \
			-y ${NANO_HEADS}`
	else
		echo "Creating md backing file..."
		rm -f ${IMG}
		dd if=/dev/zero of=${IMG} seek=${NANO_MEDIASIZE} count=0
		MD=`mdconfig -a -t vnode -f ${IMG} -x ${NANO_SECTS} \
			-y ${NANO_HEADS}`
	fi

	trap "echo 'Running exit trap code' ; df -i ${MNT} ; umount ${MNT} || true ; mdconfig -d -u $MD" 1 2 15 EXIT

	fdisk -i -f ${NANO_OBJ}/_.fdisk ${MD}
	fdisk ${MD}
	# XXX: params
	# XXX: pick up cached boot* files, they may not be in image anymore.
	boot0cfg -B -b ${NANO_WORLDDIR}/${NANO_BOOTLOADER} ${NANO_BOOT0CFG} ${MD}
	bsdlabel -w -B -b ${NANO_WORLDDIR}/boot/boot ${MD}s1
	bsdlabel ${MD}s1

	# Create first image
	populate_slice /dev/${MD}s1a ${NANO_WORLDDIR} ${MNT} "s1a"

	generate_mtree /dev/${MD}s1a ${MNT}

	if [ $NANO_IMAGES -gt 1 -a $NANO_INIT_IMG2 -gt 0 ] ; then
		# Duplicate to second image (if present)
		echo "Duplicating to second image..."
		dd if=/dev/${MD}s1 of=/dev/${MD}s2 bs=64k
		mount /dev/${MD}s2a ${MNT}
		for f in ${MNT}/etc/fstab ${MNT}/conf/base/etc/fstab
		do
			sed -i "" "s=${NANO_DRIVE}s1=${NANO_DRIVE}s2=g" $f
		done
		umount ${MNT}
		# Override the label from the first partition so we
		# don't confuse glabel with duplicates.
		if [ ! -z ${NANO_LABEL} ]; then
			tunefs -L ${NANO_LABEL}"s2a" /dev/${MD}s2a
		fi
	fi
	
	# Create Config slice
	populate_cfg_slice /dev/${MD}s3 "${NANO_CFGDIR}" ${MNT} "s3"

	# Create Data slice, if any.
	if [ $NANO_DATASIZE -ne 0 ] ; then
		populate_data_slice /dev/${MD}s4 "${NANO_DATADIR}" ${MNT} "s4"
	fi

	if [ "${NANO_MD_BACKING}" = "swap" ] ; then
		if [ ${NANO_IMAGE_MBRONLY} ]; then
			echo "Writing out _.disk.mbr..."
			dd if=/dev/${MD} of=${NANO_DISKIMGDIR}/_.disk.mbr bs=512 count=1
		else
			echo "Writing out ${NANO_IMGNAME}..."
			dd if=/dev/${MD} of=${IMG} bs=64k
		fi
	fi

	if ${do_copyout_partition} ; then
		echo "Writing out _.disk.image..."
		dd if=/dev/${MD}s1 of=${NANO_DISKIMGDIR}/_.disk.image bs=64k
	fi
	mdconfig -d -u $MD

	trap - 1 2 15 EXIT
	trap "nano_cleanup" EXIT

	) > ${NANO_OBJ}/_.di 2>&1
)

# i386 and amd64 are identical for disk images
create_amd64_diskimage ( ) (
	create_i386_diskimage
)

# This function need to be adapted to the new nanobsd !!
create_arm_diskimage()
{
    pprint 2 "build diskimage"
    pprint 3 "log: ${MAKEOBJDIRPREFIX}/_.di"

    (
    echo "NANO_MEDIASIZE:   $NANO_MEDIASIZE"
    echo "NANO_IMAGES:  $NANO_IMAGES"
    echo "NANO_SECTS:   $NANO_SECTS"
    echo "NANO_HEADS:   $NANO_HEADS"
    echo "NANO_CODESIZE:    $NANO_CODESIZE"
    echo "NANO_CONFSIZE:    $NANO_CONFSIZE"
    echo "NANO_DATASIZE:    $NANO_DATASIZE"

    echo $NANO_MEDIASIZE $NANO_IMAGES \
        $NANO_SECTS $NANO_HEADS \
        $NANO_CODESIZE $NANO_CONFSIZE $NANO_DATASIZE |
    awk '
    {
        printf "# %s\n", $0

        # size of cylinder in sectors
        cs = $3 * $4

        # number of full cylinders on media
        cyl = int ($1 / cs)

        # output fdisk geometry spec, truncate cyls to 1023
        if (cyl <= 1023)
            print "g c" cyl " h" $4 " s" $3
        else
            print "g c" 1023 " h" $4 " s" $3
if ($7 > 0) {
            # size of data partition in full cylinders
            dsl = int (($7 + cs - 1) / cs)
        } else {
            dsl = 0;
        }

        # size of config partition in full cylinders
        csl = int (($6 + cs - 1) / cs)

        if ($5 == 0) {
            # size of image partition(s) in full cylinders
            isl = int ((cyl - dsl - csl) / $2)
        } else {
            isl = int (($5 + cs - 1) / cs)
        }

        # First image partition start at second track
        print "p 1 165 " $3, isl * cs - $3
        c = isl * cs;

        # Second image partition (if any) also starts offset one 
        # track to keep them identical.
        if ($2 > 1) {
            print "p 2 165 " $3 + c, isl * cs - $3
            c += isl * cs;
        }

        # Config partition starts at cylinder boundary.
        print "p 3 165 " c, csl * cs
        c += csl * cs
		
		# Data partition (if any) starts at cylinder boundary.
        if ($7 > 0) {
            print "p 4 165 " c, dsl * cs
        } else if ($7 < 0 && $1 > c) {
            print "p 4 165 " c, $1 - c
        } else if ($1 < c) {
            print "Disk space overcommitted by", \
                c - $1, "sectors" > "/dev/stderr"
            exit 2
        }

        # Force slice 1 to be marked active. This is necessary
        # for booting the image from a USB device to work.
        print "a 1"
    }
    ' > ${NANO_OBJ}/_.fdisk

    IMG=${NANO_DISKIMGDIR}/${NANO_IMGNAME}
    BS=${NANO_SECTS}b

    if [ "${NANO_MD_BACKING}" = "swap" ] ; then
        MD=`mdconfig -a -t swap -s ${NANO_MEDIASIZE} -x ${NANO_SECTS} \
            -y ${NANO_HEADS}`
    else
        echo ""; echo "Creating md backing file ${IMG} ..."
        _c=`expr ${NANO_MEDIASIZE} / ${NANO_SECTS}`
        pprint 2 "dd if=/dev/zero of=${IMG} bs=${BS} count=${_c}"
        dd if=/dev/zero of=${IMG} bs=${BS} count=${_c}
        pprint 2 "mdconfig -a -t vnode -f ${IMG} -x ${NANO_SECTS} -y ${NANO_HEADS}"
        MD=`mdconfig -a -t vnode -f ${IMG} -x ${NANO_SECTS} \
            -y ${NANO_HEADS}`
    fi
	
	trap "mdconfig -d -u $MD" 1 2 15 EXIT

    echo ""; echo "Write partition table ..."
    FDISK=${NANO_OBJ}/_.fdisk
    pprint 2 "fdisk -i -f ${FDISK} ${MD}"
    fdisk -i -f ${FDISK} ${MD}
    pprint 2 "fdisk ${MD}"
    fdisk ${MD}

    # Create first image
    IMG1=${NANO_DISKIMGDIR}/_.disk.image1
    echo ""; echo "Create first image ${IMG1} ..."
    SIZE=`awk '/^p 1/ { print $5 "b" }' ${FDISK}`
    pprint 2 "${NANO_MAKEFS} -s ${SIZE} ${IMG1} ${NANO_WORLDDIR}"
	# TO DO: glabel patch !!!!
    ${NANO_MAKEFS} -s ${SIZE} ${IMG1} ${NANO_WORLDDIR}
    pprint 2 "dd if=${IMG1} of=/dev/${MD}s1 bs=${BS}"
    dd if=${IMG1} of=/dev/${MD}s1 bs=${BS}
	tunefs -L ${NANO_GLABEL_SYS}s1a /dev/${MD}s1

	generate_mtree /dev/${MD}s1a ${MNT}

    if [ $NANO_IMAGES -gt 1 -a $NANO_INIT_IMG2 -gt 0 ] ; then
        IMG2=${NANO_DISKIMGDIR}/_.disk.image2
        echo ""; echo "Create second image ${IMG2}..."
        for f in ${NANO_WORLDDIR}/etc/fstab ${NANO_WORLDDIR}/conf/base/etc/fstab
        do
            sed -i "" "s/${NANO_DRIVE}s1/${NANO_DRIVE}s2/g" $f
        done

        SIZE=`awk '/^p 2/ { print $5 "b" }' ${FDISK}`
        pprint 2 "${NANO_MAKEFS} -s ${SIZE} ${IMG2} ${NANO_WORLDDIR}"
        ${NANO_MAKEFS} -s ${SIZE} ${IMG2} ${NANO_WORLDDIR}
        pprint 2 "dd if=${IMG2} of=/dev/${MD}s2 bs=${BS}"
        dd if=${IMG2} of=/dev/${MD}s2 bs=${BS}
		tunefs -L ${NANO_GLABEL_SYS}s2a /dev/${MD}s1
    fi

	# Create Config slice
    CFG=${NANO_DISKIMGDIR}/_.disk.cfg
    echo ""; echo "Creating config partition ${CFG}..."
    SIZE=`awk '/^p 3/ { print $5 "b" }' ${FDISK}`
    # XXX: fill from where ?
    pprint 2 "${NANO_MAKEFS} -s ${SIZE} ${CFG} ${NANO_CFGDIR}"
	# NEED TO SET THE LABEL !!!!!
    ${NANO_MAKEFS} -s ${SIZE} ${CFG} ${NANO_CFGDIR}
    pprint 2 "dd if=${CFG} of=/dev/${MD}s3 bs=${BS}"
    dd if=${CFG} of=/dev/${MD}s3 bs=${BS}
	tunefs -L ${NANO_GLABEL_SYS}s3 /dev/${MD}s3
    pprint 2 "rm ${CFG}"
    rm ${CFG}; CFG=         # NB: disable printing below

    # Create Data slice, if any.
    if [ $NANO_DATASIZE -gt 0 ] ; then
        DATA=${NANO_DISKIMGDIR}/_.disk.data
        echo ""; echo "Creating data partition ${DATA}..."
        SIZE=`awk '/^p 4/ { print $5 "b" }' ${FDISK}`
        # XXX: fill from where ?
        pprint 2 "${NANO_MAKEFS} -s ${SIZE} ${DATA} /var/empty"
		# NEED TO SET THE LABEL !!!
        ${NANO_MAKEFS} -s ${SIZE} ${DATA} /var/empty
        pprint 2 "dd if=${DATA} of=/dev/${MD}s4 bs=${BS}"
        dd if=${DATA} of=/dev/${MD}s4 bs=${BS}
		tunefs -L ${NANO_GLABEL_DATA} /dev/${MD}s4
        pprint 2 "rm ${DATA}"
        rm ${DATA}; DATA=   # NB: disable printing below
    fi

    if [ "${NANO_MD_BACKING}" = "swap" ] ; then
        echo "Writing out _.disk.full..."
        dd if=/dev/${MD} of=${IMG} bs=${BS}
    fi

	echo ""
    echo "Completed images in:"
    echo ""
    echo "Full disk:         ${IMG}"
    echo "Primary partition: ${IMG1}"
    test "${IMG2}" && echo "2ndary partition:  ${IMG2}"
    test "${CFG}" &&  echo "/cfg partition:    ${CFG}"
    test "${DATA}" && echo "/data partition:   ${DATA}"
    echo ""
    echo "Use dd if=<file> of=/dev/<somewhere> bs=${BS} to transfer an"
    echo "image to bootable media /dev/<somewhere>."
    ) > ${MAKEOBJDIRPREFIX}/_.di 2>&1
}

# Need to adapt NANO_LABEL variable with the old use ! 
create_sparc64_diskimage ( ) (
    pprint 2 "build diskimage"
    pprint 3 "log: ${NANO_OBJ}/_.di"
   # Using sparc bootloader
   NANO_BOOTLOADER="boot/boot1"

    (
    IMG=${NANO_DISKIMGDIR}/${NANO_IMGNAME}
    MNT=${NANO_OBJ}/_.mnt
    mkdir -p ${MNT}

    if [ "${NANO_MD_BACKING}" = "swap" ] ; then
        MD=`mdconfig -a -t swap -s ${NANO_MEDIASIZE} -x ${NANO_SECTS} \
            -y ${NANO_HEADS}`
    else
        echo "Creating md backing file..."
        dd if=/dev/zero of=${IMG} bs=${NANO_SECTS}b \
            count=`expr ${NANO_MEDIASIZE} / ${NANO_SECTS}`
        MD=`mdconfig -a -t vnode -f ${IMG} -x ${NANO_SECTS} \
            -y ${NANO_HEADS}`
    fi

    trap "echo 'Running exit trap code' ; df -i ${MNT} ; umount ${MNT} || true ; mdconfig -d -u $MD" 1 2 15 EXIT
   # Create initial bootable label:
   echo "Creating initial empty but bootable sunlabel..."
   sunlabel -w -B ${MD} auto
   
   # Extracting label prototype in cylinder unit
   sunlabel -c ${MD} > ${NANO_OBJ}/_.sunlabel

   # Generate partition on the prototype file
   # Need to calc the NANO_CODESIZE and the media size that is smaller than given (why??)
   # Warning, from sunlabel man page  : "partitions in the Sun OpenBoot PROM
    # must always start at a cylinder boundary (for whatever geometry emulation
    # has been chosen)."
   if [ ${NANO_CODESIZE} = 0 ]; then
       #MESURED_MEDIASIZE=`grep "sectors/unit" ${NANO_OBJ}/_.sunlabel | cut -d' ' -f 2`
   MESURED_MEDIASIZE_CYL=`grep "text" ${NANO_OBJ}/_.sunlabel| cut -d' ' -f 4`
   SEC_PER_CYL=`grep "sectors/cylinder" ${NANO_OBJ}/_.sunlabel | cut -d' ' -f 2`
   NANO_CONFSIZE_CYL=`expr $NANO_CONFSIZE / $SEC_PER_CYL`
   NANO_DATASIZE_CYL=`expr $NANO_DATASIZE / $SEC_PER_CYL`
   NANO_CODESIZE_CYL=`expr \( $MESURED_MEDIASIZE_CYL - $NANO_CONFSIZE_CYL - $NANO_DATASIZE_CYL \) / 2`
   fi  
   echo "a: ${NANO_CODESIZE_CYL} 0" >> ${NANO_OBJ}/_.sunlabel
   echo "d: ${NANO_CODESIZE_CYL} *" >> ${NANO_OBJ}/_.sunlabel
   echo "e: ${NANO_CONFSIZE_CYL} *" >> ${NANO_OBJ}/_.sunlabel
   echo "f: ${NANO_DATASIZE_CYL} *" >> ${NANO_OBJ}/_.sunlabel

   # Apply the label prototype file to the md disk
   sunlabel -c -R ${MD} ${NANO_OBJ}/_.sunlabel

	# Create first image
    populate_slice /dev/${MD}a ${NANO_WORLDDIR} ${MNT} "s1a"

	generate_mtree /dev/${MD}a ${MNT}

    if [ $NANO_IMAGES -gt 1 -a $NANO_INIT_IMG2 -gt 0 ] ; then
        # Duplicate to second image (if present)
        echo "Duplicating to second image..."
        dd if=/dev/${MD}a of=/dev/${MD}d bs=64k
        mount /dev/${MD}d ${MNT}
        for f in ${MNT}/etc/fstab ${MNT}/conf/base/etc/fstab
        do
            sed -i "" "s/${NANO_DRIVE}a/${NANO_DRIVE}d/g" $f
        done
        umount ${MNT}
		# Override the label from the first partition so we
        # don't confuse glabel with duplicates.
        if [ ! -z ${NANO_LABEL} ]; then
            tunefs -L ${NANO_LABEL}"s2a" /dev/${MD}d
        fi

    fi

	# Create Config slice
    populate_cfg_slice /dev/${MD}e "${NANO_CFGDIR}" ${MNT} "s3"

    # Create Data slice, if any.
    if [ $NANO_DATASIZE -ne 0 ] ; then
        populate_data_slice /dev/${MD}f "${NANO_DATADIR}" ${MNT} "s4"
    fi

	if [ "${NANO_MD_BACKING}" = "swap" ] ; then
        if [ ${NANO_IMAGE_MBRONLY} ]; then
            echo "Writing out _.disk.mbr..."
            dd if=/dev/${MD} of=${NANO_DISKIMGDIR}/_.disk.mbr bs=512 count=1
        else
            echo "Writing out ${NANO_IMGNAME}..."
            dd if=/dev/${MD} of=${IMG} bs=64k
        fi
    fi

	if [ "${NANO_MD_BACKING}" = "swap" ] ; then
        if [ ${NANO_IMAGE_MBRONLY} ]; then
            echo "Writing out _.disk.mbr..."
            dd if=/dev/${MD} of=${NANO_DISKIMGDIR}/_.disk.mbr bs=512 count=1
        else
            echo "Writing out ${NANO_IMGNAME}..."
            dd if=/dev/${MD} of=${IMG} bs=64k
        fi
    fi

    if ${do_copyout_partition} ; then
        echo "Writing out _.disk.image..."
        dd if=/dev/${MD}a of=${NANO_DISKIMGDIR}/_.disk.image bs=64k
    fi
    mdconfig -d -u $MD

    trap - 1 2 15 EXIT
	trap "nano_cleanup" EXIT

    ) > ${NANO_OBJ}/_.di 2>&1
)

last_orders () (
	# Redefine this function with any last orders you may have
	# after the build completed, for instance to copy the finished
	# image to a more convenient place:
	# cp ${NANO_DISKIMGDIR}/_.disk.image /home/ftp/pub/nanobsd.disk
)

#######################################################################
#
# Optional convenience functions.
#
#######################################################################

#######################################################################
# Common Flash device geometries
#

FlashDevice () {
	if [ -d ${NANO_TOOLS} ] ; then
		. ${NANO_TOOLS}/FlashDevice.sub
	else
		. ${NANO_SRC}/${NANO_TOOLS}/FlashDevice.sub
	fi
	sub_FlashDevice $1 $2
}

#######################################################################
# USB device geometries
#
# Usage:
#	UsbDevice Generic 1000	# a generic flash key sold as having 1GB
#
# This function will set NANO_MEDIASIZE, NANO_HEADS and NANO_SECTS for you.
#
# Note that the capacity of a flash key is usually advertised in MB or
# GB, *not* MiB/GiB. As such, the precise number of cylinders available
# for C/H/S geometry may vary depending on the actual flash geometry.
#
# The following generic device layouts are understood:
#  generic           An alias for generic-hdd.
#  generic-hdd       255H 63S/T xxxxC with no MBR restrictions.
#  generic-fdd       64H 32S/T xxxxC with no MBR restrictions.
#
# The generic-hdd device is preferred for flash devices larger than 1GB.
#

UsbDevice () {
	a1=`echo $1 | tr '[:upper:]' '[:lower:]'`
	case $a1 in
	generic-fdd)
		NANO_HEADS=64
		NANO_SECTS=32
		NANO_MEDIASIZE=$(( $2 * 1000 * 1000 / 512 ))
		;;
	generic|generic-hdd)
		NANO_HEADS=255
		NANO_SECTS=63
		NANO_MEDIASIZE=$(( $2 * 1000 * 1000 / 512 ))
		;;
	*)
		echo "Unknown USB flash device"
		exit 2
		;;
	esac
}

#######################################################################
# Setup serial console

cust_comconsole () (
	# Enable getty on console
	sed -i "" -e /tty[du]0/s/off/on/ ${NANO_WORLDDIR}/etc/ttys

	# Disable getty on syscons devices
	sed -i "" -e '/^ttyv[0-8]/s/	on/	off/' ${NANO_WORLDDIR}/etc/ttys

	# Tell loader to use serial console early.
	echo "${NANO_BOOT2CFG}" > ${NANO_WORLDDIR}/boot.config
)

#######################################################################
# Allow root login via ssh

cust_allow_ssh_root () (
	sed -i "" -e '/PermitRootLogin/s/.*/PermitRootLogin yes/' \
	    ${NANO_WORLDDIR}/etc/ssh/sshd_config
)

#######################################################################
# Install the stuff under ./Files

cust_install_files () (
	cd ${NANO_TOOLS}/Files
	find . -print | grep -Ev '/(CVS|\.svn)' | cpio -Ldumpv ${NANO_WORLDDIR}
)

#######################################################################
# Install packages from ${NANO_PACKAGE_DIR}

cust_pkg () (

	# If the package directory doesn't exist, we're done.
	if [ ! -d ${NANO_PACKAGE_DIR} ]; then
		echo "DONE 0 packages"
		return 0
	fi

	# Copy packages into chroot
	mkdir -p ${NANO_WORLDDIR}/Pkg
	(
		cd ${NANO_PACKAGE_DIR}
		find ${NANO_PACKAGE_LIST} -print |
		    cpio -Ldumpv ${NANO_WORLDDIR}/Pkg
	)

	# Count & report how many we have to install
	todo=`ls ${NANO_WORLDDIR}/Pkg | wc -l`
	echo "=== TODO: $todo"
	ls ${NANO_WORLDDIR}/Pkg
	echo "==="
	while true
	do
		# Record how many we have now
		have=`ls ${NANO_WORLDDIR}/var/db/pkg | wc -l`

		# Attempt to install more packages
		# ...but no more than 200 at a time due to pkg_add's internal
		# limitations.
		chroot ${NANO_WORLDDIR} sh -c \
			'ls Pkg/*tbz | xargs -n 200 pkg_add -F' || true

		# See what that got us
		now=`ls ${NANO_WORLDDIR}/var/db/pkg | wc -l`
		echo "=== NOW $now"
		ls ${NANO_WORLDDIR}/var/db/pkg
		echo "==="


		if [ $now -eq $todo ] ; then
			echo "DONE $now packages"
			break
		elif [ $now -eq $have ] ; then
			echo "FAILED: Nothing happened on this pass"
			exit 2
		fi
	done
	rm -rf ${NANO_WORLDDIR}/Pkg
)

#######################################################################
# Convenience function:
# 	Register all args as customize function.

customize_cmd () {
	NANO_CUSTOMIZE="$NANO_CUSTOMIZE $*"
}

#######################################################################
# Convenience function:
# 	Register all args as late customize function to run just before
#	image creation.

late_customize_cmd () {
	NANO_LATE_CUSTOMIZE="$NANO_LATE_CUSTOMIZE $*"
}

#######################################################################
#
# All set up to go...
#
#######################################################################

# Progress Print
#	Print $2 at level $1.
pprint() {
    if [ "$1" -le $PPLEVEL ]; then
	runtime=$(( `date +%s` - $NANO_STARTTIME ))
	printf "%s %.${1}s %s\n" "`date -u -r $runtime +%H:%M:%S`" "#####" "$2" 1>&3
    fi
}

usage () {
	(
	echo "Usage: $0 [-bfiknqvw] [-c config_file]"
	echo "	-b	suppress builds (both kernel and world)"
	echo "	-f	suppress code slice extraction"
	echo "	-i	suppress disk image build"
	echo "	-k	suppress buildkernel"
	echo "	-n	add -DNO_CLEAN to buildworld, buildkernel, etc"
	echo "	-q	make output quieter"
	echo "	-v	make output more verbose"
	echo "	-w	suppress buildworld"
	echo "	-c	specify config file"
	) 1>&2
	exit 2
}

#######################################################################
# Parse arguments

do_clean=true
do_kernel=true
do_world=true
do_image=true
do_copyout_partition=true

set +e
args=`getopt bc:fhiknqvw $*`
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
	-b)
		do_world=false
		do_kernel=false
		shift
		;;
	-k)
		do_kernel=false
		shift
		;;
	-c)
		. "$2"
		shift
		shift
		;;
	-f)
		do_copyout_partition=false
		shift
		;;
	-h)
		usage
		;;
	-i)
		do_image=false
		shift
		;;
	-n)
		do_clean=false
		shift
		;;
	-q)
		PPLEVEL=$(($PPLEVEL - 1))
		shift
		;;
	-v)
		PPLEVEL=$(($PPLEVEL + 1))
		shift
		;;
	-w)
		do_world=false
		shift
		;;
	--)
		shift
		break
	esac
done

if [ $# -gt 0 ] ; then
	echo "$0: Extraneous arguments supplied"
	usage
fi
trap "nano_cleanup" EXIT

#######################################################################
# Setup and Export Internal variables
#
test -n "${NANO_OBJ}" || NANO_OBJ=/usr/obj/nanobsd.${NANO_NAME}/
test -n "${MAKEOBJDIRPREFIX}" || MAKEOBJDIRPREFIX=${NANO_OBJ}
test -n "${NANO_DISKIMGDIR}" || NANO_DISKIMGDIR=${NANO_OBJ}

NANO_WORLDDIR=${NANO_OBJ}/_.w
NANO_MAKE_CONF_BUILD=${MAKEOBJDIRPREFIX}/make.conf.build
NANO_MAKE_CONF_INSTALL=${NANO_OBJ}/make.conf.install

if [ -d ${NANO_TOOLS} ] ; then
	true
elif [ -d ${NANO_SRC}/${NANO_TOOLS} ] ; then
	NANO_TOOLS=${NANO_SRC}/${NANO_TOOLS}
else
	echo "NANO_TOOLS directory does not exist" 1>&2
	exit 1
fi

if $do_clean ; then
	true
else
	NANO_PMAKE="${NANO_PMAKE} -DNO_CLEAN"
fi

# Override user's NANO_DRIVE if they specified a NANO_LABEL
if [ ! -z "${NANO_LABEL}" ]; then
	NANO_DRIVE=ufs/${NANO_LABEL}
fi

export MAKEOBJDIRPREFIX

export NANO_ARCH
export NANO_CFGDIR
export NANO_CODESIZE
export NANO_CONFSIZE
export NANO_CUSTOMIZE
export NANO_DATASIZE
export NANO_DATADIR
export NANO_DRIVE
export NANO_HEADS
export NANO_IMAGES
export NANO_IMGNAME
export NANO_MAKE_CONF_BUILD
export NANO_MAKE_CONF_INSTALL
export NANO_MEDIASIZE
export NANO_NAME
export NANO_NEWFS
export NANO_OBJ
export NANO_PMAKE
export NANO_SECTS
export NANO_SRC
export NANO_TOOLS
export NANO_WORLDDIR
export NANO_BOOT0CFG
export NANO_BOOTLOADER
export NANO_LABEL

#######################################################################
# And then it is as simple as that...

# File descriptor 3 is used for logging output, see pprint
exec 3>&1

NANO_STARTTIME=`date +%s`
pprint 1 "NanoBSD image ${NANO_NAME} build starting"

if $do_world ; then
	if $do_clean ; then
		clean_build
	else
		pprint 2 "Using existing build tree (as instructed)"
	fi
	make_conf_build
	build_world
else
	pprint 2 "Skipping buildworld (as instructed)"
fi

if $do_kernel ; then
	if ! $do_world ; then
		make_conf_build
	fi
	build_kernel
else
	pprint 2 "Skipping buildkernel (as instructed)"
fi

clean_world
make_conf_install
install_world
install_etc
setup_nanobsd_etc
install_kernel

run_customize
setup_nanobsd
prune_usr
run_late_customize
if $do_image ; then
	create_${NANO_ARCH}_diskimage
else
	pprint 2 "Skipping image build (as instructed)"
fi
last_orders

pprint 1 "NanoBSD image ${NANO_NAME} completed"
