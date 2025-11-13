#!/bin/sh
#
# MPD5 interface down script for BSDRP
# Handles IPv4 and IPv6 route removal when PPP interface goes down
#
# Called by mpd5 with the following arguments:
#   $1: interface (e.g., ng0)
#   $2: protocol (inet/inet6)
#   $3: local IP address
#   $4: remote IP address
#   $5: authentication name
#   $6: peer address
#
# Example:
#   if-down.sh ng0 inet 10.3.23.1/32 10.3.23.10 '-' '10.0.23.2'
#
# Returns: 0 on success, 1 on failure
logger "$0 called with parameters: $@"
remote_inet="1.1.1.0/24"
remote_inet6="2001:db8:1::1 -prefixlen 64"
eval "
	if ! route get -net -\$2 ${remote_$2}; then
		logger "Route ${remote_inet} not in table"
		return 0
	else
		cmd=\"route del \${remote_$2} \$4\"
	fi
"
if $cmd; then
	logger "if-down: ${cmd} succesfull"
	return 0
else
	logger "if-down: ${cmd} failed"
	return 1
fi
