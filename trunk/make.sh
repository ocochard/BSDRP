#!/bin/sh
#
# Make script for BSD Router Project 
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

#############################################
############ Variables definition ###########
#############################################

# Exit if error or variable undefined
set -eu

# Name of the product
NAME="BSDRP"

# CVSUP mirror
# sysutils/fastest_cvsup is very usefull
FREEBSD_CVSUP_HOST="cvsup3.fr.freebsd.org"

# Base (current) folder
BSDRP_ROOT=`pwd`

# Where the build configuration files used by nanobsd.sh live.
#NANO_CFG_BASE=${BSDRP_ROOT}/nanobsd

# Where the FreeBSD ports tree lives.
NANO_PORTS="${BSDRP_ROOT}/FreeBSD/ports"

# Where the FreeBSD source tree lives.
FREEBSD_SRC="${BSDRP_ROOT}/FreeBSD/src"

# Where the nanobsd tree lives
NANOBSD_DIR="${FREEBSD_SRC}/tools/tools/nanobsd"

# Product version (need to add SVN versio too)
VERSION=`cat ${BSDRP_ROOT}/Files/etc/version`

# Number of jobs
MAKE_JOBS=$(( 2 * $(sysctl -n kern.smp.cpus)))

# Progress Print level
PPLEVEL=3

#############################################
########### Function definition #############
#############################################

# Progress Print
#       Print $2 at level $1.
pprint() {
    if [ "$1" -le $PPLEVEL ]; then
        printf "%.${1}s %s\n" "#####" "$2"
    fi
}

# Update or install src if not installed
# TO DO: write a small fastest_csvusp 
update_src () {
	echo "Updating/Installing FreeBSD and ports source"
    if [ -z "${FREEBSD_CVSUP_HOST}" ]; then
        error "No sup host defined, please define FREEBSD_CVSUP_HOST and rerun"
    fi
    echo "Checking out tree from ${FREEBSD_CVSUP_HOST}..."
	if [ ! -d ${BSDRP_ROOT}/FreeBSD ]; then
    	mkdir -p ${BSDRP_ROOT}/FreeBSD
	fi

    SUPFILE=${BSDRP_ROOT}/FreeBSD/supfile
	PORTS_DATE="date=2012.03.30.00.00.00"
    cat <<EOF > $SUPFILE
*default host=${FREEBSD_CVSUP_HOST}
*default base=${BSDRP_ROOT}/FreeBSD/sup
*default prefix=${BSDRP_ROOT}/FreeBSD
*default release=cvs
*default delete use-rel-suffix
*default compress

src-all tag=RELENG_8_3
#ports-all date=${PORTS_DATE}
ports-base ${PORTS_DATE}
ports-benchmarks ${PORTS_DATE}
ports-devel ${PORTS_DATE}
ports-lang ${PORTS_DATE}
ports-net ${PORTS_DATE}
ports-net-mgmt ${PORTS_DATE}
ports-mail ${PORTS_DATE}
ports-sysutils ${PORTS_DATE}

EOF
	csup -L 1 $SUPFILE
    # Force a repatch because csup pulls pristine sources.
    : > $BSDRP_ROOT/FreeBSD/src-patches
    : > $BSDRP_ROOT/FreeBSD/ports-patches
    # Nuke the newly created files to avoid build errors, as
    # patch(1) will automatically append to the previously
    # non-existent file.
    for file in $(find ${BSDRP_ROOT}/FreeBSD/ -name '*.orig' -size 0); do
        rm -f "$(echo "$file" | sed -e 's/.orig//')"
    done
    : > $BSDRP_ROOT/FreeBSD/.pulled

	for patch in $(cd ${BSDRP_ROOT}/patches && ls freebsd.*.patch); do
    	if ! grep -q $patch ${BSDRP_ROOT}/FreeBSD/src-patches; then
        	echo "Applying patch $patch..."
        	(cd FreeBSD/src &&
         	patch -C -p0 < ${BSDRP_ROOT}/patches/$patch &&
         	patch -E -p0 -s < ${BSDRP_ROOT}/patches/$patch)
        	echo $patch >> ${BSDRP_ROOT}/FreeBSD/src-patches
    	fi
	done
	for patch in $(cd ${BSDRP_ROOT}/patches && ls ports.*.patch); do
    	if ! grep -q $patch ${BSDRP_ROOT}/FreeBSD/ports-patches; then
        	echo "Applying patch $patch..."
        	(cd FreeBSD/ports &&
         	patch -C -p0 < ${BSDRP_ROOT}/patches/$patch &&
         	patch -E -p0 -s < ${BSDRP_ROOT}/patches/$patch)
        	echo $patch >> ${BSDRP_ROOT}/FreeBSD/ports-patches
    	fi
	done

	# Overwite the nanobsd script
	cp ${BSDRP_ROOT}/tools/nanobsd.sh ${BSDRP_ROOT}/FreeBSD/src/tools/tools/nanobsd
	chmod +x ${BSDRP_ROOT}/FreeBSD/src/tools/tools/nanobsd

}

##### Check if previous NanoBSD make stop correctly by unoumt all tmp mount
# exit with 0 if no problem detected
# exit with 1 if problem detected, but clean it
# exit with 2 if problem detected and can't clean it
check_clean() {
	# Patch from Warner Losh (imp@)
	if ($MDMFS); then
		local OBJ_DIR=/tmp/obj/
	else
		local OBJ_DIR=/usr/obj/
	fi
	__a=`mount | grep ${OBJ_DIR} | awk '{print length($3), $3;}' | sort -rn | awk '{$1=""; print;}'`
	if [ -n "$__a" ]; then
		echo "unmounting $__a"
		umount $__a
	fi
}

usage () {
        (
        pprint 1 "Usage: $0 -bdhkurw [-c vga|serial] [-a i386|amd64]"
        pprint 1 "  -a      specify target architecture: i386 or amd64"
		pprint 1 "          if not specified, use local system arch (`uname -m`)"
		pprint 1 "          cambria (arm) and sparc64 targets are in work-in-progress state"	
        pprint 1 "  -b      suppress buildworld and buildkernel"
		pprint 1 "  -c      specify console type: vga (default) or serial"
		pprint 1 "  -d      generate image with debug feature enabled"
		pprint 1 "  -f      fast mode, skip: images compression and checksums"
		pprint 1 "  -h      display this help message"
		pprint 1 "  -k      suppress buildkernel"
		pprint 1 "  -u      update all src (freebsd and ports)"
		pprint 1 "  -r      use a memory disk as destination dir" 
		pprint 1 "  -w      suppress buildworld"
        ) 1>&2
        exit 2
}

#############################################
############ Main code ######################
#############################################

pprint 1 "BSD Router Project image build script"
pprint 1 ""

#Get argument

TARGET_ARCH=`uname -m`
MACHINE_ARCH=${TARGET_ARCH}

case "$TARGET_ARCH" in
	"amd64")
		NANO_KERNEL="${NAME}-AMD64"
		;;
	"i386")
		NANO_KERNEL="${NAME}-I386"
		;;
	"arm")
		NANO_KERNEL="${NAME}-CAMBRIA"
		;;
	"sparc64")
		NANO_KERNEL="${NAME}-SPARC64"
		;;
esac
DEBUG=false
SKIP_REBUILD=""
INPUT_CONSOLE="vga"
FAST=false
UPDATE_SRC=false
MDMFS=false
args=`getopt a:bc:dfhkurw $*`

set -- $args
for i
do
        case "$i"
        in
        -a)
                case "$2" in
				"amd64")
					if [ "${MACHINE_ARCH}" = "amd64" -o "${MACHINE_ARCH}" = "i386" ]; then
						TARGET_ARCH="amd64"
                    	NANO_KERNEL="${NAME}-AMD64"
					else
						pprint 1 "Cross compiling is not possible in your case: ${MACHINE_ARCH} => $2"
						exit 1
					fi
					;;
				"i386")
					if [ "${MACHINE_ARCH}" = "amd64" -o "${MACHINE_ARCH}" = "i386" ]; then
						TARGET_ARCH="i386"
                    	NANO_KERNEL="${NAME}-I386"
					else
                        pprint 1 "Cross compiling is not possible in your case: ${MACHINE_ARCH} => $2"
                        exit 1
                    fi
					;;
				"cambria")
					if [ "${MACHINE_ARCH}" = "arm" ]; then
						TARGET_ARCH="arm"
                    	TARGET_CPUTYPE=xscale; export TARGET_CPUTYPE
                    	TARGET_BIG_ENDIAN=true; export TARGET_BIG_ENDIAN
                    	NANO_KERNEL="${NAME}-CAMBRIA"
					else
                        pprint 1 "Cross compiling is not possible in your case: ${MACHINE_ARCH} => $2"
                        exit 1
                    fi
					;;
				"sparc64")
					if [ "${MACHINE_ARCH}" = "sparc64" ]; then
						TARGET_ARCH="sparc64"
                    	TARGET_CPUTYPE=sparc64; export TARGET_CPUTYPE
                    	TARGET_BIG_ENDIAN=true; export TARGET_BIG_ENDIAN
                    	NANO_KERNEL="${NAME}-SPARC64"
					else
                        pprint 1 "Cross compiling is not possible in your case: ${MACHINE_ARCH} => $2"
                        exit 1
                    fi
					;;

				*)
					pprint 1 "ERROR: Bad arch type"
					exit 1
				esac
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
                    INPUT_CONSOLE="vga"
                    ;;
                serial)
                    INPUT_CONSOLE="serial"
                    ;;
				*)
					pprint 1 "ERROR: Bad console type"
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
				MDMFS=true
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
# Cross compilation is not possible for the ports

# Cambria is not compatible with vga output
if [ "${NANO_KERNEL}" = "${NAME}-CAMBRIA" ] ; then
	if [ "${INPUT_CONSOLE}" = "vga" ] ; then
		pprint 1 "Gateworks Cambria platform didn't have vga board: Changing console to serial"
	fi
	INPUT_CONSOLE="serial"
fi

# Sparc64 is not compatible with vga output
if [ "${NANO_KERNEL}" = "${NAME}-SPARC64" ] ; then
    if [ "${INPUT_CONSOLE}" = "vga" ] ; then
        pprint 1 "Sparc64 platform didn't have vga board: Changing console to serial"
    fi
    INPUT_CONSOLE="serial"
fi


if [ `sysctl -n hw.usermem` -lt 2000000000 ]; then
	echo "WARNING: Not enough hw.usermem available, disable memory disk usage"
    MDMFS=false
fi

if ($MDMFS); then
	if mount | grep -q -e "^/dev/md[[:digit:]].*[[:space:]]/tmp/obj[[:space:]]"; then
    	echo "Existing mdmfs file system detected"
	else
		if [ ! -d /tmp/obj ]; then
			if ! mkdir /tmp/obj; then
				echo "ERROR: Cannot create /tmp/obj"
				exit 1
			fi
		fi
		if ! mdmfs -S -s 1500M md /tmp/obj; then
			echo "ERROR: Cannot create a 1.5G mdmfs on /tmp/obj"
			exit 1
		fi
	fi
	NANO_OBJ=/tmp/obj/${NAME}.${TARGET_ARCH}
else
	NANO_OBJ=/usr/obj/${NAME}.${TARGET_ARCH}
fi
if [ -n "${SKIP_REBUILD}" ]; then
	if [ ! -d ${NANO_OBJ} ]; then
		echo "ERROR: No previous object directory found, you can't skip some rebuild"
		exit 1
	fi
fi

check_clean

# If no source installed, force installing them
if [ ! -d ${BSDRP_ROOT}/FreeBSD/ports/net/quagga ]; then
	UPDATE_SRC=true
fi

pprint 1 "Will generate an ${NAME} image with theses values:"
pprint 1 "- Target architecture: ${TARGET_ARCH}"
pprint 1 "- Console : ${INPUT_CONSOLE}"
if ($UPDATE_SRC); then
	pprint 1 "- Source Updating/installing: YES"
else
	pprint 1 "- Source Updating/installing: NO"
fi
if [ -z "${SKIP_REBUILD}" ]; then
	pprint 1 "- Build the full world (take about 1 hour): YES"
else
	pprint 1 "- Build the full world (take about 1 hour): NO"
fi
if (${FAST}); then
	pprint 1 "- FAST mode (skip compression and checksumming): YES"
else
	pprint 1 "- FAST mode (skip compression and checksumming): NO"
fi

if ($MDMFS); then
	pprint 1 "- MDMFS: YES"
else
	pprint 1 "- MDMFS: NO"
fi
if ($DEBUG); then
    pprint 1 "- Debug image type: YES"
else
    pprint 1 "- Debug image type: NO"
fi

##### Generating the nanobsd configuration file ####

# Theses variables must be set on the begining
echo "# Name of this NanoBSD build.  (Used to construct workdir names)" > /tmp/${NAME}.nano
echo "NANO_NAME=${NAME}" >> /tmp/${NAME}.nano

echo "# Source tree directory" >> /tmp/${NAME}.nano
echo "NANO_SRC=\"${FREEBSD_SRC}\"" >> /tmp/${NAME}.nano

echo "# Where the port tree is" >> /tmp/${NAME}.nano
echo "NANO_PORTS=${NANO_PORTS}" >> /tmp/${NAME}.nano

echo "# Where nanobsd additional files live under the source tree" >> /tmp/${NAME}.nano

echo "NANO_TOOLS=\"${BSDRP_ROOT}\"" >> /tmp/${NAME}.nano
echo "NANO_OBJ=\"${NANO_OBJ}\"" >> /tmp/${NAME}.nano

# Copy the common nanobsd configuration file to /tmp
cat ${NAME}.nano >> /tmp/${NAME}.nano

# And add the customized variable to the nanobsd configuration file
echo "############# Variable section (generated by BSDRP make.sh) ###########" >> /tmp/${NAME}.nano

echo "# The default name for any image we create." >> /tmp/${NAME}.nano
echo "NANO_IMGNAME=\"${NAME}_${VERSION}_full_${TARGET_ARCH}_${INPUT_CONSOLE}.img\"" >> /tmp/${NAME}.nano

echo "# Kernel config file to use" >> /tmp/${NAME}.nano
echo "NANO_KERNEL=${NANO_KERNEL}" >> /tmp/${NAME}.nano

echo "# Parallel Make" >> /tmp/${NAME}.nano
# Special ARCH commands
# Note for modules names: They are relative to /usr/src/sys/modules
case ${TARGET_ARCH} in
	"i386") echo "NANO_PMAKE=\"make -j ${MAKE_JOBS}\"" >> /tmp/${NAME}.nano
	echo 'NANO_MODULES="acpi netgraph rc4 sppp if_ef if_tap if_carp if_bridge bridgestp if_lagg if_vlan if_gre ipfw ipdivert libalias dummynet pf pflog hifn padlock safe ubsec glxsb ispfw"' >> /tmp/${NAME}.nano
	;;
	"amd64") echo "NANO_PMAKE=\"make -j ${MAKE_JOBS}\"" >> /tmp/${NAME}.nano
	echo 'NANO_MODULES="ispfw netgraph rc4 sppp if_ef if_tap if_carp if_bridge bridgestp if_lagg if_vlan if_gre ipfw ipdivert libalias dummynet pf pflog hifn padlock safe ubsec ispfw"' >> /tmp/${NAME}.nano
	;;
	"arm") echo "NANO_PMAKE=\"make\"" >> /tmp/${NAME}.nano
	echo 'NANO_MODULES=""' >> /tmp/${NAME}.nano
	NANO_MAKEFS="makefs -B big \
    -o bsize=4096,fsize=512,density=8192,optimization=space"
	export NANO_MAKEFS
	;;
	"sparc64") echo "NANO_PMAKE=\"make -j ${MAKE_JOBS}\"" >> /tmp/${NAME}.nano
	echo 'NANO_MODULES="netgraph rc4 if_ef if_tap if_carp if_bridge bridgestp if_lagg if_vlan if_gre ipfw ipdivert libalias dummynet pf pflog"' >> /tmp/${NAME}.nano
	;;
esac

echo "# Bootloader type"  >> /tmp/${NAME}.nano

case ${INPUT_CONSOLE} in
	"dual") echo "NANO_BOOTLOADER=\"boot/boot0\"" >> /tmp/${NAME}.nano 
	echo "#Configure dual vga/serial console port" >> /tmp/${NAME}.nano
	echo "customize_cmd bsdrp_console_dual" >> /tmp/${NAME}.nano
;;

	"vga") echo "NANO_BOOTLOADER=\"boot/boot0\"" >> /tmp/${NAME}.nano 
	echo "#Configure vga only console port" >> /tmp/${NAME}.nano
	echo "customize_cmd bsdrp_console_vga" >> /tmp/${NAME}.nano
;;
	"serial") echo "NANO_BOOTLOADER=\"boot/boot0sio\"" >> /tmp/${NAME}.nano
	echo "#Configure serial console port" >> /tmp/${NAME}.nano
	echo "customize_cmd bsdrp_console_serial" >> /tmp/${NAME}.nano
;;
esac

# Export some variables for using them under nanobsd
export TARGET_ARCH

# Delete the destination dir
if [ -z "${SKIP_REBUILD}" ]; then
	if [ -d ${NANO_OBJ} ]; then
		pprint 1 "Existing working directory detected,"
		pprint 1 "but you asked for rebuild some parts (no -b, -w or -k option given)"
		pprint 1 "Do you want to continue ? (y/n)"
		USER_CONFIRM=""
        while [ "$USER_CONFIRM" != "y" -a "$USER_CONFIRM" != "n" ]; do
        	read USER_CONFIRM <&1
        done
        if [ "$USER_CONFIRM" = "n" ]; then
               exit 0     
        fi

		pprint 1 "Delete existing ${NANO_OBJ} directory"
		chflags -R noschg ${NANO_OBJ}
		rm -rf ${NANO_OBJ}
	fi
fi

#### Udpate or install source ####
if ($UPDATE_SRC); then
	pprint 1 "Update sources..."
	update_src
fi

pprint 3 "Copying ${TARGET_ARCH} Kernel configuration file"

cp ${BSDRP_ROOT}/kernels/${NANO_KERNEL} ${FREEBSD_SRC}/sys/${TARGET_ARCH}/conf/${NANO_KERNEL}

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
pprint 1 "Launching NanoBSD build process..."
cd ${NANOBSD_DIR}
sh ${NANOBSD_DIR}/nanobsd.sh ${SKIP_REBUILD} -c /tmp/${NAME}.nano

# Testing exit code of NanoBSD:
if [ $? -eq 0 ]; then
	pprint 1 "NanoBSD build seems finish successfully."
else
	pprint 1 "ERROR: NanoBSD meet an error, check the log files here:"
	pprint 1 "${NANO_OBJ}/"	
	pprint 1 "An error during the build world or kernel can be caused by"
	pprint 1 "a bug in the FreeBSD-current code"	
	pprint 1 "try to re-sync your code" 
	exit 1
fi

# The exit code on NanoBSD doesn't work for port compilation/installation
if [ ! -f ${NANO_OBJ}/_.disk.image ]; then
	pprint 1 "ERROR: NanoBSD meet an error (port installation/compilation ?)"
	exit 1
fi

if ($DEBUG);then
	FILENAME="${NAME}_${VERSION}_upgrade_${TARGET_ARCH}_${INPUT_CONSOLE}_DEBUG.img"
else
	FILENAME="${NAME}_${VERSION}_upgrade_${TARGET_ARCH}_${INPUT_CONSOLE}.img"
fi

#Remove old images if present
if [ -f ${NANO_OBJ}/${FILENAME} ]; then
	rm ${NANO_OBJ}/${FILENAME}
fi

if [ -f ${NANO_OBJ}/${FILENAME}.xz ]; then
	rm ${NANO_OBJ}/${FILENAME}.xz
fi

mv ${NANO_OBJ}/_.disk.image ${NANO_OBJ}/${FILENAME}

if ! $FAST; then
	pprint 1 "Compressing ${NAME} upgrade image..."
	xz -vf ${NANO_OBJ}/${FILENAME}
	pprint 1 "Generating checksum for ${NAME} upgrade image..."
	sha256 ${NANO_OBJ}/${FILENAME}.xz > ${NANO_OBJ}/${FILENAME}.sha256
	pprint 1 "${NAME} upgrade image file here:"
	pprint 1 "${NANO_OBJ}/${FILENAME}.xz"
else
	pprint 1 "Uncompressed ${NAME} upgrade image file here:"
	pprint 1 "${NANO_OBJ}/${FILENAME}"
fi

if ($DEBUG); then
	FILENAME="${NAME}_${VERSION}_full_${TARGET_ARCH}_${INPUT_CONSOLE}_DEBUG.img"
else
	FILENAME="${NAME}_${VERSION}_full_${TARGET_ARCH}_${INPUT_CONSOLE}.img"
fi

#Remove old images if present
if [ -f ${NANO_OBJ}/${FILENAME}.xz ]; then
    rm ${NANO_OBJ}/${FILENAME}.xz
fi

if ! $FAST; then
	pprint 1 "Compressing ${NAME} full image..." 
	xz -vf ${NANO_OBJ}/${FILENAME}
	pprint 1 "Generating checksum for ${NAME} full image..."
	sha256 ${NANO_OBJ}/${FILENAME}.xz > ${NANO_OBJ}/${FILENAME}.sha256
   	pprint 1 "Zipped ${NAME} full image file here:"
   	pprint 1 "${NANO_OBJ}/${FILENAME}.xz"
else
	pprint 1 "Unzipped ${NAME} full image file here:"
   	pprint 1 "${NANO_OBJ}/${FILENAME}"
fi

pprint 1 "Zipping and renaming mtree..."
if [ -f ${NANO_OBJ}/${FILENAME}.mtree.xz ]; then
	rm ${NANO_OBJ}/${FILENAME}.mtree.xz
fi
mv ${NANO_OBJ}/_.mtree ${NANO_OBJ}/${FILENAME}.mtree
xz -vf ${NANO_OBJ}/${FILENAME}.mtree
mv ${NANO_OBJ}/${FILENAME}.mtree.xz ${NANO_OBJ}/${NAME}_${VERSION}_${TARGET_ARCH}_${INPUT_CONSOLE}.mtree.xz

pprint 1 "Security reference mtree file here:"
pprint 1 "${NANO_OBJ}/${FILENAME}.mtree.xz"

if ($MDMFS); then
	pprint 1 "Remember, remember the ${NANO_OBJ} is a RAM disk"
fi
pprint 1 "Done !"
exit 0
