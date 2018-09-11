#!/bin/sh

set -eu

SVN_CMD=""
rev=""

# We need to use standard SVN language
export LANG=C
export LC_MESSAGES=C

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

# Get last svn rev
# $1: Folder to sync
# return (echo) revision number
get_last_rev () {
	[ -d $1 ] || die "No folder $1 found"
	${SVN_CMD} up $1 || die "Error during ${SVN_CMD} of $1"
	rev=$(${SVN_CMD} info $1 | grep "Last Changed Rev" | cut -w -f 4)
	[ -z "${rev}" ] && die "No revision number found"
	#rev=${rev%%.}
	# Test if it's an integer
	[ $rev -eq $rev ] || die "Revision number is not an integer"
	return 0
}

# Update make.conf
# $1 File to update
# $2 key to replace
# $3 new value
# Replace line in form $1="old-num" by $1="$2"
# like SRC_REV="1111", by SRC_REV="2222"
update () {
	[ -f $1 ] || die "No file $1 found"
	[ -z "$2" ] && die "Bug calling update_make: no key"
	[ -z "$3" ] && die "Bug calling update_make: no new value"
	#echo $1 $2 $3
	sed -i "" -e "s/^$2.*/$2=\"$3\"/" $1 || die "sed error for $1 $2 $3"
	# sed 's/^SRC_REV.*/This line is removed by the admin./'
}
SVN_CMD=$(which svn) || SVN_CMD=$(which svnlite)

for i in BSDRP BSDRPstable BSDRPcur RELEASE STABLE HEAD TESTING; do
	if [ -d $i/FreeBSD/src ]; then
		get_last_rev $i/FreeBSD/src
		update $i/make.conf SRC_REV $rev
	fi
done

get_last_rev BSDRP/FreeBSD/ports
update BSDRP/make.conf PORTS_REV $rev

