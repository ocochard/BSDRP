#! /bin/sh
exec 2> /dev/null
logger ucarp vip-up script called: Adding $2 as alias on $1
if ! /sbin/ifconfig "$1" alias "$2" netmask 255.255.255.255; then
	logger ucarp vip-up script failled to configure alias $2 on $1!
fi
