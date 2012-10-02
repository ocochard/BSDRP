#!/bin/sh
#This script permit to help the generation and uploading process of new images
#It generate the dokuwiki table too
set -eu

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# General variables
#DRY="echo"
DRY=""
SRC_DIR="/usr/local/BSDRP"
OBJ_BASE_DIR="/usr/obj"
VERSION=""
ARCH_LIST='
i386
i386_xenpv
amd64
'
CONSOLE_LIST='
vga
serial
'

usage () {
	echo "$0 [ generate | upload | dokuwiki ]"
	echo " - generate: clean and generate all arch/console images"
	echo " - upload: Upload all images to SourceForge"
	echo " - dokuwiki: Generate dokuwiki table of images"
	exit 0
}

##### Check if previous NanoBSD make stop correctly by unoumt all tmp mount
# exit with 0 if no problem detected                                            # exit with 1 if problem detected, but clean it                                 # exit with 2 if problem detected and can't clean it
check_clean() {
    # Patch from Warner Losh (imp@)
	__a=`mount | grep $1 | awk '{print length($3), $3;}' | sort -rn | awk '{$1=""; print;}'`
	if [ -n "$__a" ]; then
        echo "unmounting $__a"                                                          umount $__a
    fi                                                                          }

generate(){
	[ -d ${SRC_DIR} ] || die "Doesn't found source dir: ${SRC_DIR}"
	# cleanup obj dir
	#for arch in ${ARCH_LIST}; do
	#	OBJ_DIR="${OBJ_BASE_DIR}/BSDRP.${arch}"
	#		if [ -d ${OBJ_DIR} ]; then
	#			echo "Cleaning dir ${OBJ_DIR}..."
#			check_clean ${OBJ_DIR}
#			${DRY} rm -rf ${OBJ_DIR}
#		fi
#	done
	
	# Build of each arch/console
    for arch in ${ARCH_LIST}; do
		# Initial build (update and rebuild all)
		( cd ${SRC_DIR}
        ${DRY} ./make.sh -u -f -y -a ${arch}
        )
        [ -f ${OBJ_BASE_DIR}/BSDRP.${arch}/_.mtree ] || die "problem during initial build of ${arch}"
		for console in ${CONSOLE_LIST}; do
			[ "${arch}" = "i386_xenpv" -a "${console}" = "serial" ] && continue
        	( cd ${SRC_DIR}
        	${DRY} ./make.sh -b -a ${arch} -c ${console}
        	)
			if [ "${arch}" = "i386_xenpv" ]; then
   				[ -f ${OBJ_BASE_DIR}/BSDRP.${arch}/BSDRP-${VERSION}-${arch}.mtree.xz ] || die "problem during final build regarding of ${arch}-${console}"
	     	else	
				[ -f ${OBJ_BASE_DIR}/BSDRP.${arch}/BSDRP-${VERSION}-${arch}-${console}.mtree.xz ] || die "problem during final build regarding of ${arch}-${console}"
			fi
			echo "done" > ${OBJ_BASE_DIR}/BSDRP.${arch}/release.done
		done
    done

}

upload(){

	FILE_LIST='
    /usr/local/BSDRP/CHANGES
    '
	for arch in ${ARCH_LIST}; do
		[ -f ${OBJ_BASE_DIR}/BSDRP.${arch}/release.done ] && FILE_LIST="${FILE_LIST} `ls ${OBJ_BASE_DIR}/BSDRP.${arch}/BSDRP-*`"
	done
	${DRY} scp ${FILE_LIST} cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/$1
}

dokuwiki(){
	URL="https://sourceforge.net/projects/bsdrp/files/BSD_Router_Project/${DEST}"
	FILE_TYPE='
	full
	upgrade
	mtree
	'

	for type in ${FILE_TYPE}; do
		echo ""
		echo "type: ${type}"
		echo ""
		FILE_LIST=""
 		for arch in ${ARCH_LIST}; do
			FILE_LIST="${FILE_LIST} `ls ${OBJ_BASE_DIR}/BSDRP.${arch}/BSDRP-* | cut -d '/' -f 5 | grep ${type} | grep ".xz"`"
    	done

		for file in ${FILE_LIST}; do
			if [ "${type}" != "mtree" ]; then
				echo "^ Type ^ Arch ^ Console ^ File ^ Checksum ^"
				echo -n "| `echo ${file} | cut -d '-' -f 3`"
				echo -n " | `echo ${file} | cut -d '-' -f 4`"
				echo -n " | `echo ${file} | cut -d '-' -f 5 | cut -d '.' -f 1`"
			else
				echo "^ Arch ^ Console ^ File ^"
				echo -n "| `echo ${file} | cut -d '-' -f 3`"
				echo -n " | `echo ${file} | cut -d '-' -f 4 | cut -d '.' -f 1`"
			fi
			echo -n " | [[$URL/${file}/download|${file}]]"
			if [ "${type}" != "mtree" ]; then
				echo -n " | [[$URL/ `echo ${file} | sed -e 's/xz/sha256/g'`|"
				echo -n "`echo ${file} | sed -e 's/xz/sha256/g'`]] |"
			fi
			echo ""
		done
	done
}

# Main part

if [ $# -lt 1 ]; then
	echo " Missing argument"
	usage
fi

if [ "$1" = "upload" -a $# -eq 1 ]; then
    echo "Missing destination directory (like: nightly/2012-09-05)"
    echo
	usage
fi


if [ "$1" = "dokuwiki" -a $# -eq 1 ]; then
    echo "Missing destination directory (like: nightly/2012-09-05)"
    echo
	usage
fi

if [ ! -d ${SRC_DIR} ]; then
	echo "You need to install BSDRP source"
else
	VERSION=`cat ${SRC_DIR}/Files/etc/version`
fi

if [ $# -eq 1 ]; then
	$1
else
	$1 $2
fi
