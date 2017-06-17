#!/bin/sh
#This script permit to help the generation and uploading process of new images
#It generate the dokuwiki table too
# For list of installed software to be include in CHANGES
# cat /usr/obj/BSDRP.amd64/packages.info
# (it's a pkg query \*\ %n\ %v:\ %c)
# For list of installed software to be incluled in AUTHORS
# pkg query \*\ %n,\ license:%L,\ %w

set -e
# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# General variables
#DRY="echo"
# Set PROJECT variable like this example:
# env PROJECT=BSDRPcur BSDRP/tools/release.sh generate
# env DISK_SIZE=512 BSDRP/tools/release.sh generate fast
DRY=""
SRC_DIR="/usr/local/BSDRP"
[ -n "${PROJECT}" ] || PROJECT="BSDRP"
set -u
OBJ_BASE_DIR="/usr/obj"
VERSION=""
FAST_MODE=false
if [ `uname -m` = "sparc64" ]; then
	ARCH_LIST="sparc64"
else
	ARCH_LIST='
i386
amd64
'
fi
CONSOLE_LIST='
vga
serial
'

usage () {
	echo "$0 [ generate | upload | dokuwiki ]"
	echo " - generate [fast]: clean and generate all arch/console images"
	echo "                    fast mode avoid rebuilding all"
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
	
	# Build of each arch/console
    for arch in ${ARCH_LIST}; do
		# Initial build (update and rebuild all)
		if ! ($FAST_MODE); then
			( cd ${SRC_DIR}
        	${DRY} ./make.sh -p ${PROJECT} -u -f -y -a ${arch}
        	)
		fi
		if ! ($FAST_MODE); then
        	[ -f ${OBJ_BASE_DIR}/${PROJECT}.${arch}/_.mtree ] || die "problem during initial build of ${arch}"
		fi
		for console in ${CONSOLE_LIST}; do
			[ "${arch}" = "i386_xenpv" -a "${console}" = "serial" ] && continue
			[ "${arch}" = "sparc64" -a "${console}" = "serial" ] && continue
			[ ! -f ${PROJECT}/kernels/${arch} ] && continue
        	( cd ${SRC_DIR}
        	${DRY} ./make.sh -p ${PROJECT} -b -a ${arch} -c ${console}
        	)
			if [ "${arch}" = "i386_xenpv" -o "${arch}" = "sparc64" ]; then
   				[ -f ${OBJ_BASE_DIR}/${PROJECT}.${arch}/BSDRP-${VERSION}-${arch}.mtree.xz ] || die "problem during final build regarding of ${arch}-${console}"
	     	else	
				[ -f ${OBJ_BASE_DIR}/${PROJECT}.${arch}/BSDRP-${VERSION}-${arch}-${console}.mtree.xz ] || die "problem during final build regarding of ${arch}-${console}"
			fi
			echo "done" > ${OBJ_BASE_DIR}/${PROJECT}.${arch}/release.done
		done
    done
	exit 0
}

upload(){
	# Display the CHANGES between line "# Release X.Y" and "------" and put it in README.md
	sed -n -e "/# Release ${VERSION}/,/----/ p" ${PROJECT}/CHANGES.md > /tmp/README.md
	${DRY} scp /tmp/README.md cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/$1
	FILE_LIST=''
	if [ -d ${OBJ_BASE_DIR}/${PROJECT}.sparc64 ]; then
		ARCH_LIST="${ARCH_LIST}sparc64"
	fi
	for arch in ${ARCH_LIST}; do
		if [ -f ${OBJ_BASE_DIR}/${PROJECT}.${arch}/release.done ]; then
			FILE_LIST=`ls ${OBJ_BASE_DIR}/${PROJECT}.${arch}/BSDRP-*`
			${DRY} scp ${FILE_LIST} cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/$1/${arch}
		fi
	done
	exit 0
}

dokuwiki(){
	URL="https://sourceforge.net/projects/bsdrp/files/BSD_Router_Project/$1"
	FILE_TYPE='
	full
	upgrade
	mtree
	debug
	'
	if [ -d ${OBJ_BASE_DIR}/${PROJECT}.sparc64 ]; then
		ARCH_LIST="${ARCH_LIST}sparc64"
	fi
	
	for type in ${FILE_TYPE}; do
		TITLE_SET=false
		OLD_TYPE=""
		echo ""
		echo "type: ${type}"
		echo ""
		FILE_LIST=""
 		for arch in ${ARCH_LIST}; do
			FILE_LIST="${FILE_LIST} `ls ${OBJ_BASE_DIR}/${PROJECT}.${arch}/BSDRP-* | cut -d '/' -f 5 | grep ${type} | grep ".xz"`"
    	done

		for file in ${FILE_LIST}; do
			if [ "${type}" == "mtree" ]; then
				if ! ($TITLE_SET); then
					echo "^ Arch ^ Console ^ File ^"
					TITLE_SET=true
                fi
				ARCH=`basename ${file} | cut -d '-' -f 3 | cut -d '.' -f 1`
				echo -n "| ${ARCH}"
				echo -n " | `echo ${file} | cut -d '-' -f 4 | cut -d '.' -f 1`"
			elif [ "${type}" == "debug" ]; then
				if ! ($TITLE_SET); then
					echo "^ Arch ^ File ^"
					TITLE_SET=true
				fi
				ARCH=`basename ${file} | cut -d '-' -f 4 | cut -d '.' -f 1`
				echo -n "| ${ARCH}"
			else
				if ! ( $TITLE_SET ) && [ "${type}" != "${OLD_TYPE}" ]; then
					#echo "^ Type ^ Arch ^ Console ^ File ^ Checksum ^"
					echo "^ Arch ^ Console ^ File ^ Checksum ^"
					TITLE_SET=true
					OLD_TYPE=${type}
				else
					TITLE_SET=false
				fi
				ARCH=`basename ${file} | cut -d '-' -f 4 | cut -d '.' -f 1`
				#echo -n "| `echo ${file} | cut -d '-' -f 3`"
				echo -n "| ${ARCH}"
				echo -n " | `echo ${file} | cut -d '-' -f 5 | cut -d '.' -f 1`"
			fi
			echo -n " | [[$URL/${ARCH}/${file}/download|${file}]]"
			case ${type} in
			mtree | debug)
				echo -n " |"
				;;
			*)
				echo -n " | [[$URL/${ARCH}/`echo ${file} | sed -e 's/xz/sha256/g'` |"
				echo -n "`echo ${file} | sed -e 's/xz/sha256/g'`]] |"
				;;
			esac
			echo ""
		done # for file
	done # for type
	exit 0
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
	VERSION=`cat ${SRC_DIR}/${PROJECT}/Files/etc/version`
fi

if [ $# -eq 1 ]; then
	$1
elif [ $2 = "fast" ]; then
	FAST_MODE=true
fi
$1 $2
