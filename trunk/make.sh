#!/bin/sh
#
# Make script for BSD Router Project 
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

#############################################
############ Variables definition ###########
#############################################

# Uncomment for enable debug: 
#set -x

# Exit if error
set -e

# Force check variable definition
#set -u

FREEBSD_SRC=/usr/src
NANOBSD_DIR=/usr/src/tools/tools/nanobsd
NAME="BSDRP"
VERSION=`cat ${NANOBSD_DIR}/${NAME}/Files/etc/${NAME}.version`

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

#### Check current dir
check_current_dir() {
	if [ "${NANOBSD_DIR}/${NAME}" != `pwd` ]; then
		pprint 1 "You need to install ${NAME} source code in ${NANOBSD_DIR}/${NAME}"
		exit 1
	fi
}

#### Check prerequisites
check_system() {
	pprint 3 "Checking if FreeBSD sources are installed..."
	SRC_VERSION=0
	if ! [ -f ${FREEBSD_SRC}/sys/conf/newvers.sh ]; then
		pprint 1 "ERROR: Can't found FreeBSD sources!"
		exit 1
	fi
	
	if `grep -q 'REVISION="8.2"' ${FREEBSD_SRC}/sys/conf/newvers.sh`; then
		SRC_VERSION="8.2"
	fi

	#if `grep -q 'REVISION="7.4"' ${FREEBSD_SRC}/sys/conf/newvers.sh`; then
    # 	SRC_VERSION="7.4"
	#fi

	if [ ${SRC_VERSION} = 0 ]; then
		pprint 1 "ERROR: ${NAME} need FreeBSD 8.2 or 7.4 sources"
		pprint 1 "Read BSDRP HOW TO here:"
		pprint 1 "http://bsdrp.net/documentation/technical_docs"
		exit 1
	fi
	pprint 3 "Will generate a ${NAME} image based on FreeBSD ${SRC_VERSION}"
	pprint 3 "Checking if ports sources are installed..."

	if [ ! -d /usr/ports/net/quagga ]; then
		pprint 1 "ERROR: ${NAME} need up-to-date FreeBSD ports sources tree"
		pprint 1 "And it seems that you didn't install the ports source tree"
        pprint 1 "Read BSDRP HOW TO here:"
        pprint 1 "http://bsdrp.net/documentation/technical_docs"
		exit 1
	fi
}

###### Adding patch to NanoBSD
nanobsd_patches() {
	# Using up-to-date nanobsd script and patch it
	if [ `sha256 -q ../nanobsd.sh` != "bf2bfaf68faa060ef60dd4e896e4b994c9ac374a58714962b79d1a8e7068a0f4" ]; then
		pprint 3 "Download up-to-date nanobsd release"
		if ! mv ../nanobsd.sh ../nanobsd.original.bak; then	
			pprint 3 "ERROR: Can't backup original nanobsd.sh script"
		fi
		if ! fetch -o ../nanobsd.sh "http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/src/tools/tools/nanobsd/nanobsd.sh?rev=1.70"; then
				mv ../nanobsd.original.bak ../nanobsd.sh
				pprint 3 "ERROR: Can't download up-to-date nanobsd.sh script"
				exit 1
		fi

		# Adding another cool patch that fix a lot's of problem
		# http://www.freebsd.org/cgi/query-pr.cgi?pr=136889
		pprint 3 "Patching NanoBSD with some fixes (PR-136889)"
		patch ${NANOBSD_DIR}/nanobsd.sh patches/nanobsd.pr-136889.patch

		# Patching mtree generation mode for be usable as security audit reference
       	pprint 3 "Patching NanoBSD with mtree support"
       	patch ${NANOBSD_DIR}/nanobsd.sh patches/nanobsd.mtree.patch

		# Adding arm support to NanoBSD
       	pprint 3 "Patching NanoBSD with arm support"
       	patch ${NANOBSD_DIR}/nanobsd.sh patches/nanobsd.arm.patch

		# Adding sparc64 support to NanoBSD
       	pprint 3 "Patching NanoBSD with sparc64 support"
       	patch ${NANOBSD_DIR}/nanobsd.sh patches/nanobsd.sparc64.patch

	fi

}

#### Port patches

ports_patches()
{
	pprint 2 "patching ports..."
	#pprint 3 "net/mcast-tools (missing pre-requiered in makefile)"
	#if ! `grep -q 'automake' /usr/ports/net/mcast-tools/Makefile`; then
	#	patch /usr/ports/net/mcast-tools/Makefile patches/mcast-tools/Makefile.diff
	#fi

}

##### Check if previous NanoBSD make stop correctly by unoumt all tmp mount
# exit with 0 if no problem detected
# exit with 1 if problem detected, but clean it
# exit with 2 if problem detected and can't clean it
check_clean() {
	# Patch from Warner Losh (imp@)
	__a=`mount | grep /usr/obj/ | awk '{print length($3), $3;}' | sort -rn | awk '{$1=""; print;}`
	if [ -n "$__a" ]; then
		echo "unmounting $__a"
		umount $__a
	fi
}

usage () {
        (
        pprint 1 "Usage: $0 -bkwzdh [-c vga|serial] [-a i386|amd64]"
        pprint 1 "  -c      specify console type: vga (default) or serial"
        pprint 1 "  -a      specify target architecture: i386 or amd64"
		pprint 1 "          if not specified, use local system arch (`uname -m`)"
		pprint 1 "          cambria (arm) and sparc64 targets are in work-in-progress state"	
        pprint 1 "  -b      suppress buildworld and buildkernel"
		pprint 1 "  -k      suppress buildkernel"
		pprint 1 "  -w      suppress buildworld"
        pprint 1 "  -f      fast mode, skip: images compression and checksums"
        pprint 1 "  -d      Enable debug"
		pprint 1 "  -h      Display this help message"
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
DEBUG=""
SKIP_REBUILD=""
INPUT_CONSOLE="vga"
FAST="n"

args=`getopt c:a:fbdhkw $*`

set -- $args
DELETE_ALL=true
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
        -b)
                SKIP_REBUILD="-b"
				DELETE_ALL=false
                shift
                ;;
		-k)
                SKIP_REBUILD="-k"
				DELETE_ALL=false
                shift
                ;;
		-w)
                SKIP_REBUILD="-w"
				DELETE_ALL=false
                shift
                ;;

        -d)
                DEBUG="-x"
                shift
                ;;
		-f)
				FAST="y"
				shift
				;;
        -h)
                usage
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

NANOBSD_OBJ=/usr/obj/nanobsd.${NAME}.${TARGET_ARCH}

check_current_dir
check_system
check_clean

pprint 1 "Will generate an ${NAME} image with theses values:"
pprint 1 "- Target architecture: ${TARGET_ARCH}"
pprint 1 "- Console : ${INPUT_CONSOLE}"
if [ "${SKIP_REBUILD}" = "" ]; then
	pprint 1 "- Build the full world (take about 2 hours): YES"
else
	pprint 1 "- Build the full world (take about 2 hours): NO"
fi
if [ "${FAST}" = "y" ]; then
	pprint 1 "- FAST mode (skip compression and checksumming): YES"
else
	pprint 1 "- FAST mode (skip compression and checksumming): NO"
fi

nanobsd_patches
#kernel_patches
ports_patches

# Copy the common nanobsd configuration file to /tmp
cp ${NAME}.nano /tmp/${NAME}.nano

# And add the customized variable to the nanobsd configuration file
echo "############# Variable section (generated by BSDRP make.sh) ###########" >> /tmp/${NAME}.nano

echo "# The default name for any image we create." >> /tmp/${NAME}.nano
echo "NANO_IMGNAME=\"${NAME}_${VERSION}_full_${TARGET_ARCH}_${INPUT_CONSOLE}.img\"" >> /tmp/${NAME}.nano

echo "# Kernel config file to use" >> /tmp/${NAME}.nano
echo "NANO_KERNEL=${NANO_KERNEL}" >> /tmp/${NAME}.nano

pprint 3 "Copying ${TARGET_ARCH} Kernel configuration file"

cp kernels/${NANO_KERNEL}.${SRC_VERSION} /usr/src/sys/${TARGET_ARCH}/conf/${NANO_KERNEL}

echo "# Parallel Make" >> /tmp/${NAME}.nano
# Special ARCH commands
case ${TARGET_ARCH} in
	"i386") echo 'NANO_PMAKE="make -j 3"' >> /tmp/${NAME}.nano
	echo 'NANO_MODULES="acpi netgraph if_ef if_tap if_carp if_bridge bridgestp if_lagg if_vlan if_gre ipfw ipdivert libalias pf pflog hifn padlock safe ubsec glxsb"' >> /tmp/${NAME}.nano
	;;
	"amd64") echo 'NANO_PMAKE="make -j 3"' >> /tmp/${NAME}.nano
	echo 'NANO_MODULES="netgraph if_ef if_tap if_carp if_bridge bridgestp if_lagg if_vlan if_gre ipfw ipdivert libalias pf pflog hifn padlock safe ubsec"' >> /tmp/${NAME}.nano
	;;
	"arm") echo 'NANO_PMAKE="make"' >> /tmp/${NAME}.nano
	echo 'NANO_MODULES=""' >> /tmp/${NAME}.nano
	NANO_MAKEFS="makefs -B big \
    -o bsize=4096,fsize=512,density=8192,optimization=space"
	export NANO_MAKEFS
	;;
	"sparc64") echo 'NANO_PMAKE="make -j 8"' >> /tmp/${NAME}.nano
	echo 'NANO_MODULES="netgraph if_ef if_tap if_carp if_bridge bridgestp if_lagg if_vlan if_gre ipfw ipdivert libalias pf pflog"' >> /tmp/${NAME}.nano
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
if ($DELETE_ALL); then
	if [ -d ${NANOBSD_OBJ} ]; then
		pprint 1 "Existing working directory detected,"
		pprint 1 "but you asked for rebuild all (no -b neither -k option given)"
		pprint 1 "Do you want to continue ? (y/n)"
		USER_CONFIRM=""
        while [ "$USER_CONFIRM" != "y" -a "$USER_CONFIRM" != "n" ]; do
        	read USER_CONFIRM <&1
        done
        if [ "$USER_CONFIRM" = "n" ]; then
               exit 0     
        fi

		pprint 1 "Delete existing ${NANOBSD_OBJ} directory"
		chflags -R noschg ${NANOBSD_OBJ}
		rm -rf ${NANOBSD_OBJ}
	fi
fi
# Start nanobsd using the BSDRP configuration file
pprint 1 "Launching NanoBSD build process..."
sh ${DEBUG} ../nanobsd.sh ${SKIP_REBUILD} -c /tmp/${NAME}.nano

# Testing exit code of NanoBSD:
if [ $? -eq 0 ]; then
	pprint 1 "NanoBSD build seems finish successfully."
else
	pprint 1 "ERROR: NanoBSD meet an error, check the log files here:"
	pprint 1 "${NANOBSD_OBJ}/"	
	pprint 1 "An error during the build world or kernel can be caused by"
	pprint 1 "a bug in the FreeBSD-current code"	
	pprint 1 "try to re-sync your code" 
	exit 1
fi

# The exit code on NanoBSD doesn't work for port compilation/installation
if [ ! -f ${NANOBSD_OBJ}/_.disk.image ]; then
	pprint 1 "ERROR: NanoBSD meet an error (port installation/compilation ?)"
	exit 1
fi

FILENAME="${NAME}_${VERSION}_upgrade_${TARGET_ARCH}_${INPUT_CONSOLE}.img"

if [ -f ${NANOBSD_OBJ}/${FILENAME}.xz ]; then
	rm ${NANOBSD_OBJ}/${FILENAME}.xz
fi

mv ${NANOBSD_OBJ}/_.disk.image ${NANOBSD_OBJ}/${FILENAME}

if [ "$FAST" = "n" ]; then
	pprint 1 "Compressing ${NAME} upgrade image..."
	xz -vf ${NANOBSD_OBJ}/${FILENAME}
	pprint 1 "Generating checksum for ${NAME} upgrade image..."
	sha256 ${NANOBSD_OBJ}/${FILENAME}.xz > ${NANOBSD_OBJ}/${FILENAME}.sha256
	pprint 1 "${NAME} upgrade image file here:"
	pprint 1 "${NANOBSD_OBJ}/${FILENAME}.xz"
else
	pprint 1 "Uncompressed ${NAME} upgrade image file here:"
	pprint 1 "${NANOBSD_OBJ}/${FILENAME}"
fi

FILENAME="${NAME}_${VERSION}_full_${TARGET_ARCH}_${INPUT_CONSOLE}.img"

if [ "$FAST" = "n" ]; then
	if [ -f ${NANOBSD_OBJ}/${FILENAME}.xz ]; then
		rm ${NANOBSD_OBJ}/${FILENAME}.xz
	fi 
	pprint 1 "Compressing ${NAME} full image..." 
	xz -vf ${NANOBSD_OBJ}/${FILENAME}
	pprint 1 "Generating checksum for ${NAME} full image..."
	sha256 ${NANOBSD_OBJ}/${FILENAME}.xz > ${NANOBSD_OBJ}/${FILENAME}.sha256

   	pprint 1 "Zipped ${NAME} full image file here:"
   	pprint 1 "${NANOBSD_OBJ}/${FILENAME}.xz"
else
	pprint 1 "Unzipped ${NAME} full image file here:"
   	pprint 1 "${NANOBSD_OBJ}/${FILENAME}"
fi

pprint 1 "Zipping mtree..."
if [ -f ${NANOBSD_OBJ}/${FILENAME}.mtree.xz ]; then
	rm ${NANOBSD_OBJ}/${FILENAME}.mtree.xz
fi
mv ${NANOBSD_OBJ}/_.mtree ${NANOBSD_OBJ}/${FILENAME}.mtree
xz -vf ${NANOBSD_OBJ}/${FILENAME}.mtree
pprint 1 "Security reference mtree file here:"
pprint 1 "${NANOBSD_OBJ}/${FILENAME}.mtree.xz"

pprint 1 "Done !"
exit 0
