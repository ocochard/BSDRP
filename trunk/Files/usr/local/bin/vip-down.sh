#! /bin/sh
exec 2> /dev/null
logger ucarp vip-down script called: Removing alias $2 on $1
if ! /sbin/ifconfig "$1" -alias "$2"; then
	logger ucarp vip-down script failled to remove alias $2 on $1!
fi
