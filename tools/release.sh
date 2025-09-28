#!/bin/sh
# This script upload images and generate dokuwiki
# XXX sourceforge downloading speed too slow need to enable mirrors
# For list of installed software to be include in CHANGES
# /usr/local/poudriere/data/images/packages.list
# For list of installed software to be incluled in AUTHORS
# /usr/local/poudriere/data/images/packages.license.list

set -eu
# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# General variables
: ${DRY:=""}
poudriere_imgdir="/usr/local/poudriere/data/images"

usage () {
	echo "$0 [ upload | dokuwiki ]"
	echo " - upload: Upload all images to SourceForge"
	echo " - dokuwiki: Generate dokuwiki table of images"
	exit 0
}

upload(){
  local ver=$1
  local arch=$2
	${DRY} scp CHANGES.md cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/${ver}
  FILE_LIST=$(ls ${poudriere_imgdir}/BSDRP-${ver}-*-${arch}.*)
			${DRY} scp ${FILE_LIST} cochard,bsdrp@frs.sourceforge.net:/home/frs/project/b/bs/bsdrp/BSD_Router_Project/${ver}/${arch}
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
	[ -d ${OBJ_BASE_DIR}/${PROJECT}.sparc64 ] && ARCH_LIST="${ARCH_LIST}sparc64"
	for type in ${FILE_TYPE}; do
		TITLE_SET=false
		OLD_TYPE=""
		echo ""
		echo "type: ${type}"
		echo ""
		FILE_LIST=""
 		for arch in ${ARCH_LIST}; do
			FILE_LIST="${FILE_LIST} $(ls ${OBJ_BASE_DIR}/${PROJECT}.${arch}/ | cut -d '/' -f 5 | grep '^BSDRP-' | grep ${type} | grep '\.xz$')"
    	done

		for file in ${FILE_LIST}; do
			if [ "${type}" == "mtree" ]; then
				if ! ($TITLE_SET); then
					echo "^ Arch ^ Console ^ File ^"
					TITLE_SET=true
                fi
				ARCH=$(basename ${file} | cut -d '-' -f 3 | cut -d '.' -f 1)
				echo -n "| ${ARCH}"
				echo -n " | $(echo ${file} | cut -d '-' -f 4 | cut -d '.' -f 1)"
			elif [ "${type}" == "debug" ]; then
				if ! ($TITLE_SET); then
					echo "^ Arch ^ File ^"
					TITLE_SET=true
				fi
				ARCH=$(basename ${file} | cut -d '-' -f 4 | cut -d '.' -f 1)
				echo -n "| ${ARCH}"
			else
				if ! ( $TITLE_SET ) && [ "${type}" != "${OLD_TYPE}" ]; then
					echo "^ Arch ^ Console ^ File ^ Checksum ^"
					TITLE_SET=true
					OLD_TYPE=${type}
				else
					TITLE_SET=false
				fi
				ARCH=$(basename ${file} | cut -d '-' -f 4 | cut -d '.' -f 1)
				echo -n "| ${ARCH}"
				echo -n " | $(echo ${file} | cut -d '-' -f 5 | cut -d '.' -f 1)"
			fi
			echo -n " | [[$URL/${ARCH}/${file}/download|${file}]]"
			case ${type} in
			mtree | debug)
				echo -n " |"
				;;
			*)
				echo -n " | [[$URL/${ARCH}/${file}.sha256 |"
				echo -n "${file}.sha256]] |"
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

if [ -r BSDRP/Files/etc/version ]; then
  version=$(cat BSDRP/Files/etc/version)
else
  die "No BSDRP/Files/etc/version"
fi

arch=$(uname -p)

if [ "$1" = "upload" -a $# -eq 1 ]; then
  echo "Missing destination directory, examples:"
  echo "- nightly/2012-09-05"
  echo "- 2.0"
  echo
  usage
fi


if [ "$1" = "dokuwiki" -a $# -eq 1 ]; then
  echo "Missing destination directory, examples:"
  echo "- nightly/2012-09-05"
  echo "- 2.0"
  echo
  usage
fi

$1 ${version} ${arch}
