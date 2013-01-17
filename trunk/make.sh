#!/bin/sh
#
# Make script for BSD Router Project 
# http://bsdrp.net
#
# Copyright (c) 2009-2013, The BSDRP Development Team 
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#	 notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#	 notice, this list of conditions and the following disclaimer in the
#	 documentation and/or other materials provided with the distribution.
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

#############################################
############ Variables definition ###########
#############################################

# Exit if error or variable undefined
set -eu

#############################################
########### Function definition #############
#############################################

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# Update or install src if not installed
# TO DO: write a small fastest_csvusp 
update_src () {
	echo "Updating/Installing FreeBSD and ports source"
	
	if [ ! -d ${PROJECT_DIR}/FreeBSD/src/.svn ]; then
		echo "Checking out source..."
		mkdir -p ${PROJECT_DIR}/FreeBSD/src || die "Can't create ${PROJECT_DIR}/FreeBSD/src"
		svn co svn://${SVN_SRC_PATH} ${PROJECT_DIR}/FreeBSD/src -r ${SRC_REV} || die "Can't check out sources"
	else
		echo "Cleaning local patches to source..."
		#cleaning local patced source
		svn revert -R ${PROJECT_DIR}/FreeBSD/src
		echo "Updating sources..."
		svn update ${PROJECT_DIR}/FreeBSD/src -r ${SRC_REV} || die "Can't update FreeBSD src"
	fi
	if [ ! -d ${PROJECT_DIR}/FreeBSD/ports/.svn ]; then
		echo "Checking out ports source..."
		mkdir -p ${PROJECT_DIR}/FreeBSD/ports || die "Can't create ${PROJECT_DIR}/FreeBSD/ports"
		svn co svn://${SVN_PORTS_PATH} ${PROJECT_DIR}/FreeBSD/ports -r ${PORTS_REV} || die "Can't check out ports sources"
	else
		#cleaning local patched ports sources
		echo "Cleaning local patches to ports..."
		svn revert -R ${PROJECT_DIR}/FreeBSD/ports
		echo "Updating ports sources..."
		svn update ${PROJECT_DIR}/FreeBSD/ports -r ${PORTS_REV} || die "Can't update ports sources"
	fi
}

#patch the source tree
patch_src() {
	: > ${PROJECT_DIR}/FreeBSD/src-patches
	: > ${PROJECT_DIR}/FreeBSD/ports-patches
	: > ${PROJECT_DIR}/FreeBSD/ports-added
	# Nuke the newly created files to avoid build errors, as
	# patch(1) will automatically append to the previously
	# non-existent file.
	( cd FreeBSD/src &&
	svn status --no-ignore | grep -e ^\? -e ^I | awk '{print $2}' | xargs -r rm -r)
	( cd FreeBSD/ports
	svn status --no-ignore | grep -e ^\? -e ^I | awk '{print $2}' | xargs -r rm -r)
	: > ${PROJECT_DIR}/FreeBSD/.pulled

	for patch in $(cd ${PROJECT_DIR}/patches && ls freebsd.*.patch); do
		if ! grep -q $patch ${PROJECT_DIR}/FreeBSD/src-patches; then
			echo "Applying patch $patch..."
			(cd FreeBSD/src &&
			patch -C -p0 < ${PROJECT_DIR}/patches/$patch &&
			patch -E -p0 -s < ${PROJECT_DIR}/patches/$patch)
			echo $patch >> ${PROJECT_DIR}/FreeBSD/src-patches
		fi
	done
	for patch in $(cd ${PROJECT_DIR}/patches && ls ports.*.patch); do
		if ! grep -q $patch ${PROJECT_DIR}/FreeBSD/ports-patches; then
			echo "Applying patch $patch..."
			(cd FreeBSD/ports &&
			patch -C -p0 < ${PROJECT_DIR}/patches/$patch &&
			patch -E -p0 -s < ${PROJECT_DIR}/patches/$patch)
			echo $patch >> ${PROJECT_DIR}/FreeBSD/ports-patches
		fi
	done

	# Overwite the nanobsd script
	cp ${PROJECT_DIR}/nanobsd.sh ${PROJECT_DIR}/FreeBSD/src/tools/tools/nanobsd
	chmod +x ${PROJECT_DIR}/FreeBSD/src/tools/tools/nanobsd

}

#Add new ports in shar format
add_new_ports() {
	for ports in $(cd ${PROJECT_DIR}/patches && ls ports.*.shar); do
		if ! grep -q $ports ${PROJECT_DIR}/FreeBSD/ports-added; then
			echo "Adding port $ports..."
			(cd FreeBSD/ports &&
			sh ${PROJECT_DIR}/patches/$ports)
			echo $ports >> ${PROJECT_DIR}/FreeBSD/ports-added
		fi
	done
}

##### Check if previous NanoBSD make stop correctly by unoumt all tmp mount
# exit with 0 if no problem detected
# exit with 1 if problem detected, but clean it
# exit with 2 if problem detected and can't clean it
check_clean() {
	# Patch from Warner Losh (imp@)
	__a=`mount | grep $1 | awk '{print length($3), $3;}' | sort -rn | awk '{$1=""; print;}'`
	if [ -n "$__a" ]; then
		echo "unmounting $__a"
		umount $__a
	fi
}

usage () {
	(
		echo "Usage: $0 -bdhkuryw [-a ARCH] [-c vga|serial] [-p PROJECT]"
		echo 1 " -a   specify target architecture:"
		echo "      i386, i386_xenpv, i386_xenhvm, amd64 or amd64_xenhvm"
		echo "      if not specified, use local system arch (`uname -p`)"
		echo "      cambria (arm) and sparc64 targets are in work-in-progress state"	
		echo " -b   suppress buildworld and buildkernel"
		echo " -c   specify console type: vga (default) or serial"
		echo " -d   generate image with debug feature enabled"
		echo " -f   fast mode, skip: images compression and checksums"
		echo " -h   display this help message"
		echo " -k   suppress buildkernel"
		echo " -p   project name to build"
		echo " -u   update all src (freebsd and ports)"
		echo " -r   use a memory disk as destination dir" 
		echo " -y   Answer yes to all confirmation"
		echo " -w   suppress buildworld"
	) 1>&2
	exit 2
}

#############################################
############ Main code ######################
#############################################

echo "BSD Router Project image build script"
echo ""

#Get argument

SCRIPT=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT`
ALWAYS_YES=false
LOCAL_ARCH=`uname -p`
PROJECT="BSDRP"
TARGET_ARCH=${LOCAL_ARCH}
NANO_KERNEL=${TARGET_ARCH}
DEBUG=false
SKIP_REBUILD=""
INPUT_CONSOLE="-vga"
FAST=false
UPDATE_SRC=false
TMPFS=false
args=`getopt a:bc:dfhkpuryw $*`

set -- $args
for i
do
		case "$i" in
		-a)
			NANO_KERNEL=$2
			shift
			shift
			;;
		-b)
			SKIP_REBUILD="-b -n"
			shift
			;;
		-c)
			case "$2" in
			vga)
				INPUT_CONSOLE="-vga"
				;;
			serial)
				INPUT_CONSOLE="-serial"
				;;
			*)
				echo "ERROR: Bad console type"
				exit 1
			esac
			shift
			shift
			;;
		-d)
			DEBUG=true
			shift
			;;
		-f)
			FAST=true
			shift
			;;
		-h)
			usage
			;;
		-k)
			SKIP_REBUILD="-k -n"
			shift
			;;
		-u)
			UPDATE_SRC=true
			shift
			;;
		-r)
			TMPFS=true
			shift
			;;
		-t)
			PROJECT=$2
			shift
			;;
		-y)
			ALWAYS_YES=true
			shift
			;;
		-w)
			SKIP_REBUILD="-w -n"
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

# Number of jobs
MAKE_JOBS=$(( 2 * $(sysctl -n kern.smp.cpus)))

# Checking TARGET folder
[ -d ${SCRIPT_DIR}/${PROJECT} ] || die "Can't found target ${PROJECT}"

PROJECT_DIR="${SCRIPT_DIR}/${PROJECT}"

# Loading the project variables
. ${SCRIPT_DIR}/${PROJECT}/make.conf

# project version
VERSION=`cat ${PROJECT_DIR}/Files/etc/version`

echo "PROJECT_DIR: ${PROJECT_DIR}"

# Checking target ARCH

[ -f ${PROJECT_DIR}/kernels/${NANO_KERNEL} ] || die "Can't found kernels/${NANO_KERNEL}"
			case "${NANO_KERNEL}" in
			"amd64" | "amd64_xenhvm" )
				if [ "${LOCAL_ARCH}" = "amd64" -o "${LOCAL_ARCH}" = "i386" ]; then
					TARGET_ARCH="amd64"
				else
					echo "Cross compiling is not possible in your case: ${LOCAL_ARCH} => ${NANO_KERNEL}"
					exit 1
				fi
				;;
			"i386" | "i386_xenpv" | "i386_xenhvm")
				if [ "${LOCAL_ARCH}" = "amd64" -o "${LOCAL_ARCH}" = "i386" ]; then
					TARGET_ARCH="i386"
				else
					echo "Cross compiling is not possible in your case: ${LOCAL_ARCH} => ${NANO_KERNEL}"
					exit 1
				fi
				;;
			"cambria")
				if [ "${LOCAL_ARCH}" = "arm" ]; then
					TARGET_ARCH="arm"
					TARGET_CPUTYPE=xscale; export TARGET_CPUTYPE
					TARGET_BIG_ENDIAN=true; export TARGET_BIG_ENDIAN
				else
					echo "Cross compiling is not possible in your case: ${LOCAL_ARCH} => ${NANO_KERNEL}"
					exit 1
				fi
				;;
			"sparc64")
				if [ "${LOCAL_ARCH}" = "sparc64" ]; then
					TARGET_ARCH="sparc64"
					TARGET_CPUTYPE=sparc64; export TARGET_CPUTYPE
					TARGET_BIG_ENDIAN=true; export TARGET_BIG_ENDIAN
				else
					echo "Cross compiling is not possible in your case: ${LOCAL_ARCH} => ${NANO_KERNEL}"
					exit 1
				fi
				;;
			*)
				echo "ERROR: Bad arch type"
				exit 1
			esac
	
# Cross compilation is not possible for the ports

# Cambria is not compatible with vga output
if [ "${TARGET_ARCH}" = "arm" ] ; then
	if [ "${INPUT_CONSOLE}" = "-vga" ] ; then
		echo "Gateworks Cambria platform didn't have vga board: Changing console to serial"
	fi
	INPUT_CONSOLE="-serial"
fi

# Sparc64 is console agnostic
if [ "${TARGET_ARCH}" = "sparc64" ] ; then
	INPUT_CONSOLE=""
fi

if [ `sysctl -n hw.usermem` -lt 2000000000 ]; then
	echo "WARNING: Not enough hw.usermem available, disable memory disk usage"
	TMPFS=false
fi

if ($TMPFS); then
	if mount | grep -q -e "^tmpfs[[:space:]].*/tmp/obj[[:space:]]"; then
		echo "Existing tmpfs file system detected"
	else
		if [ ! -d /tmp/obj ]; then
			mkdir /tmp/obj || die "ERROR: Cannot create /tmp/obj"
		fi
		mount -t tmpfs tmpfs /tmp/obj/ || die "ERROR: Cannot create a tmpfs on /tmp/obj"
	fi
	NANO_OBJ=/tmp/obj/${NAME}.${NANO_KERNEL}
else
	NANO_OBJ=/usr/obj/${NAME}.${NANO_KERNEL}
fi
if [ -n "${SKIP_REBUILD}" ]; then
	if [ ! -d ${NANO_OBJ} ]; then
		echo "ERROR: No previous object directory found, you can't skip some rebuild"
		exit 1
	fi
fi

check_clean ${NANO_OBJ}

# If no source installed, force installing them
[ -d ${PROJECT_DIR}/FreeBSD/ports/.svn ] || UPDATE_SRC=true

echo "Will generate an ${NAME} image with theses values:"
echo "- Target architecture: ${NANO_KERNEL}"
if [ -n "${INPUT_CONSOLE}" ]; then
	echo "- Console : ${INPUT_CONSOLE}"
fi
if ($UPDATE_SRC); then
	echo "- Source Updating/installing: YES"
else
	echo "- Source Updating/installing: NO"
fi
if [ -z "${SKIP_REBUILD}" ]; then
	echo "- Build the full world (take about 1 hour): YES"
else
	echo "- Build the full world (take about 1 hour): NO"
fi
if (${FAST}); then
	echo "- FAST mode (skip compression and checksumming): YES"
else
	echo "- FAST mode (skip compression and checksumming): NO"
fi

if ($TMPFS); then
	echo "- TMPFS: YES"
else
	echo "- TMPFS: NO"
fi
if ($DEBUG); then
	echo "- Debug image type: YES"
else
	echo "- Debug image type: NO"
fi

##### Generating the nanobsd configuration file ####

# Theses variables must be set on the begining
echo "# Name of this NanoBSD build.  (Used to construct workdir names)" > /tmp/${NAME}.nano
echo "NANO_NAME=${NAME}" >> /tmp/${NAME}.nano

echo "# Source tree directory" >> /tmp/${NAME}.nano
echo "NANO_SRC=\"${FREEBSD_SRC}\"" >> /tmp/${NAME}.nano

echo "# Where the port tree is" >> /tmp/${NAME}.nano
echo "NANO_PORTS=\"${NANO_PORTS}\"" >> /tmp/${NAME}.nano

echo "# Where nanobsd additional files live under the source tree" >> /tmp/${NAME}.nano

echo "NANO_TOOLS=\"${PROJECT_DIR}\"" >> /tmp/${NAME}.nano
echo "NANO_OBJ=\"${NANO_OBJ}\"" >> /tmp/${NAME}.nano

# Copy the common nanobsd configuration file to /tmp
cat ${PROJECT_DIR}/${NAME}.nano >> /tmp/${NAME}.nano

# And add the customized variable to the nanobsd configuration file
echo "############# Variable section (generated by BSDRP make.sh) ###########" >> /tmp/${NAME}.nano

echo "# The default name for any image we create." >> /tmp/${NAME}.nano
echo "NANO_IMGNAME=\"${NAME}-${VERSION}-full-${NANO_KERNEL}${INPUT_CONSOLE}.img\"" >> /tmp/${NAME}.nano
echo "# Kernel config file to use" >> /tmp/${NAME}.nano
echo "NANO_KERNEL=${NANO_KERNEL}" >> /tmp/${NAME}.nano

echo "# Parallel Make" >> /tmp/${NAME}.nano
# Special ARCH commands
# Note for modules names: They are relative to /usr/src/sys/modules
echo "NANO_PMAKE=\"make -j ${MAKE_JOBS}\"" >> /tmp/${NAME}.nano
eval echo NANO_MODULES=\\\"\${NANO_MODULES_${NANO_KERNEL}}\\\" >> /tmp/${NAME}.nano
case ${NANO_KERNEL} in
	"cambria") 
		NANO_MAKEFS="makefs -B big \
		-o bsize=4096,fsize=512,density=8192,optimization=space"
		export NANO_MAKEFS
		;;
	"i386_xenpv" | "i386_xenhvm" | "amd64_xenhvm" | "amd64_xenpv" )
		#echo "add_port \"lang/python27\" \"-DNOPORTDATA\"" >> /tmp/${NAME}.nano
		#echo "add_port \"sysutils/xen-tools\"" >> /tmp/${NAME}.nano
		echo "#Configure xen console port" >> /tmp/${NAME}.nano
        echo "customize_cmd bsdrp_console_xen" >> /tmp/${NAME}.nano
		;;
esac

echo "# Bootloader type"  >> /tmp/${NAME}.nano

case ${INPUT_CONSOLE} in
	"-vga") echo "NANO_BOOTLOADER=\"boot/boot0\"" >> /tmp/${NAME}.nano 
		echo "#Configure dual vga/serial console port" >> /tmp/${NAME}.nano
		echo "customize_cmd bsdrp_console_dual" >> /tmp/${NAME}.nano
		;;
	"-serial") echo "NANO_BOOTLOADER=\"boot/boot0sio\"" >> /tmp/${NAME}.nano
		echo "#Configure serial console port" >> /tmp/${NAME}.nano
		echo "customize_cmd bsdrp_console_serial" >> /tmp/${NAME}.nano
		;;
esac

# Delete the destination dir
if [ -z "${SKIP_REBUILD}" ]; then
	if [ -d ${NANO_OBJ} ]; then
		echo "Existing working directory detected (${NANO_OBJ}),"
		echo "but you asked for rebuild some parts (no -b, -w or -k option given)"
		echo "Do you want to continue ? (y/n)"
		if ! ${ALWAYS_YES}; then
			USER_CONFIRM=""
			while [ "$USER_CONFIRM" != "y" -a "$USER_CONFIRM" != "n" ]; do
				read USER_CONFIRM <&1
			done
			[ "$USER_CONFIRM" = "n" ] && exit 0
		fi
		echo "Delete existing ${NANO_OBJ} directory"
		chflags -R noschg ${NANO_OBJ}
		rm -rf ${NANO_OBJ}
	fi
fi

#### Udpate or install source ####
if ($UPDATE_SRC); then
	echo "Update sources..."
	update_src
	echo "Patch sources..."
	patch_src
	echo "Add ports..."
	add_new_ports
fi

# Export some variables for using them under nanobsd
# Somes ports needs the correct uname -r output
REV=`grep -m 1 REVISION= ${FREEBSD_SRC}/sys/conf/newvers.sh | cut -f2 -d '"'`
BRA=`grep -m 1 BRANCH=	${FREEBSD_SRC}/sys/conf/newvers.sh | cut -f2 -d '"'`
export FBSD_DST_RELEASE="${REV}-${BRA}"
export FBSD_DST_OSVERSION=$(awk '/\#define.*__FreeBSD_version/ { print $3 }' "${FREEBSD_SRC}/sys/sys/param.h")
export TARGET_ARCH

echo "Copying ${NANO_KERNEL} Kernel configuration file"

cp ${PROJECT_DIR}/kernels/${NANO_KERNEL} ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/

# The xen_hvm kernel include the standard kernel, need to copy it too
case ${NANO_KERNEL} in
	"amd64_xenhvm")
		cp ${PROJECT_DIR}/kernels/amd64 ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/
		;;
	"i386_xenhvm")
		cp ${PROJECT_DIR}/kernels/i386 ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/
        ;;	
esac

# Debug mode: add debug features to the kernel:
if ($DEBUG); then
	echo "makeoptions	DEBUG=-g" >> ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/${NANO_KERNEL}
	echo "options	KDB" >> ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/${NANO_KERNEL}
	echo "options	KDB_TRACE" >> ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/${NANO_KERNEL}
	echo "options	DDB" >> ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/${NANO_KERNEL}
	# Debug mode: compile gdb
	sed -i "" '/WITHOUT_GDB/d' /tmp/${NAME}.nano
fi

# Start nanobsd using the BSDRP configuration file
echo "Launching NanoBSD build process..."
cd ${NANOBSD_DIR}
sh ${NANOBSD_DIR}/nanobsd.sh ${SKIP_REBUILD} -c /tmp/${NAME}.nano

# Testing exit code of NanoBSD:
if [ $? -eq 0 ]; then
	echo "NanoBSD build seems finish successfully."
else
	echo "ERROR: NanoBSD meet an error, check the log files here:"
	echo "${NANO_OBJ}/"
	echo "An error during the build world or kernel can be caused by"
	echo "a bug in the FreeBSD-current code"	
	echo "try to re-sync your code" 
	exit 1
fi

# The exit code on NanoBSD doesn't work for port compilation/installation
if [ ! -f ${NANO_OBJ}/_.disk.image ]; then
	echo "ERROR: NanoBSD meet an error (port installation/compilation ?)"
	exit 1
fi

# We start by renaming/xzing the upgrade image
if ($DEBUG);then
	FILENAME="${NAME}-${VERSION}-upgrade-${NANO_KERNEL}${INPUT_CONSOLE}-DEBUG.img"
else
	FILENAME="${NAME}-${VERSION}-upgrade-${NANO_KERNEL}${INPUT_CONSOLE}.img"
fi

#Remove old upgrade images if present
[ -f ${NANO_OBJ}/${FILENAME} ] && rm ${NANO_OBJ}/${FILENAME}
[ -f ${NANO_OBJ}/${FILENAME}.xz ] && rm ${NANO_OBJ}/${FILENAME}.xz

mv ${NANO_OBJ}/_.disk.image ${NANO_OBJ}/${FILENAME}

if ! $FAST; then
	if echo ${NANO_KERNEL} | grep -q xenpv -; then
		mv ${NANO_OBJ}/${FILENAME} ${NANO_OBJ}/${NAME}-${VERSION}-upgrade-${NANO_KERNEL}.img
        FILENAME="${NAME}-${VERSION}-upgrade-${NANO_KERNEL}.img"
	fi
	echo "Compressing ${NAME} upgrade image..."
	xz -vf ${NANO_OBJ}/${FILENAME}
	echo "Generating checksum for ${NAME} upgrade image..."
	sha256 ${NANO_OBJ}/${FILENAME}.xz > ${NANO_OBJ}/${FILENAME}.sha256
	echo "${NAME} upgrade image file here:"
	echo "${NANO_OBJ}/${FILENAME}.xz"
else
	echo "Uncompressed ${NAME} upgrade image file here:"
	echo "${NANO_OBJ}/${FILENAME}"
fi

# Now renamning/xzing the full image
if ($DEBUG); then
	FILENAME="${NAME}-${VERSION}-full-${NANO_KERNEL}${INPUT_CONSOLE}-DEBUG.img"
else
	FILENAME="${NAME}-${VERSION}-full-${NANO_KERNEL}${INPUT_CONSOLE}.img"
fi

#Remove old images if present
[ -f ${NANO_OBJ}/${FILENAME}.xz ] && rm ${NANO_OBJ}/${FILENAME}.xz
if ! $FAST; then
	if echo ${NANO_KERNEL} | grep -q xenpv -; then
		mv ${NANO_OBJ}/${FILENAME} ${NANO_OBJ}/${NAME}-${VERSION}-full-${NANO_KERNEL}.img
		FILENAME="${NAME}-${VERSION}-full-${NANO_KERNEL}"
		[ -f ${NANO_OBJ}/${FILENAME}.tar.xz ] && rm ${NANO_OBJ}/${FILENAME}.tar.xz
    	echo "Generate the XEN PV archive..."
		cat <<EOF > ${NANO_OBJ}/${FILENAME}.conf
name = "${NAME}-${NANO_KERNEL}"
memory = 196
disk = [ 'file:${FILENAME}.img,hda,w']
vif = [' ']
kernel = "${FILENAME}.kernel.gz"
extra = ",vfs.root.mountfrom=ufs:/ufs/BSDRPs1a"
EOF
		cp ${NANO_OBJ}/_.w/boot/kernel/kernel.gz ${NANO_OBJ}/${NAME}-${NANO_KERNEL}.kernel.gz
		tar cvfJ ${NANO_OBJ}/${FILENAME}.tar.xz \
			-C ${NANO_OBJ} \
			${FILENAME}.conf \
			${FILENAME}.img	\
			${NAME}-${NANO_KERNEL}.kernel.gz
		rm ${NANO_OBJ}/${FILENAME}.conf
		rm ${NANO_OBJ}/${FILENAME}.img
		rm ${NANO_OBJ}/${NAME}-${NANO_KERNEL}.kernel.gz
		echo "Generating checksum for ${NAME} Xen archive..."
        sha256 ${NANO_OBJ}/${FILENAME}.tar.xz > ${NANO_OBJ}/${FILENAME}.sha256
		echo "${NANO_OBJ}/${FILENAME}.tar.xz include:"
		echo "- XEN example configuration file: ${FILENAME}.conf"
		echo "- The disk image: ${FILENAME}.img"
		echo "- The extracted kernel: ${NANO_KERNEL}.kernel.gz"
		mv ${NANO_OBJ}/_.mtree ${NANO_OBJ}/${NAME}-${VERSION}-${NANO_KERNEL}.mtree
		FILENAME="${NAME}-${VERSION}-${NANO_KERNEL}"
	else	
		echo "Compressing ${NAME} full image..." 
		xz -vf ${NANO_OBJ}/${FILENAME}
		echo "Generating checksum for ${NAME} full image..."
		sha256 ${NANO_OBJ}/${FILENAME}.xz > ${NANO_OBJ}/${FILENAME}.sha256
		echo "Zipped ${NAME} full image file here:"
		echo "${NANO_OBJ}/${FILENAME}.xz"
		mv ${NANO_OBJ}/_.mtree ${NANO_OBJ}/${NAME}-${VERSION}-${NANO_KERNEL}${INPUT_CONSOLE}.mtree
		FILENAME="${NAME}-${VERSION}-${NANO_KERNEL}${INPUT_CONSOLE}"
	fi
	echo "Zipping and renaming mtree..."
	[ -f ${NANO_OBJ}/${FILENAME}.mtree.xz ] && rm ${NANO_OBJ}/${FILENAME}.mtree.xz
	xz -vf ${NANO_OBJ}/${FILENAME}.mtree
	echo "HIDS reference file here:"
    echo "${NANO_OBJ}/${FILENAME}.mtree.xz"
else
	echo "Unzipped ${NAME} full image file here:"
	echo "${NANO_OBJ}/${FILENAME}"
	echo "Unzipped HIDS reference file here:"
	echo "${NANO_OBJ}/_.mtree"
fi

if ($TMPFS); then
	echo "Remember, remember the ${NANO_OBJ} is a tmpfs volume"
fi
echo "Done !"
exit 0
