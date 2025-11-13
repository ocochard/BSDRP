#!/bin/sh
#
# MPD5 interface up script for BSDRP
# Handles IPv4 and IPv6 route addition when PPP interface comes up
#
# Called by mpd5 with the following arguments:
#   $1: interface (e.g., ng0)
#   $2: protocol (inet/inet6)
#   $3: local IP address
#   $4: remote IP address
#   $5: authentication name
#   $6: DNS1 server IP (optional)
#   $7: DNS2 server IP (optional)
#   $8: peer address
#
# Examples:
#   if-up.sh ng0 inet 10.3.23.1/32 10.3.23.10 '-' '' '' '10.1.23.2'
#   if-up.sh ng0 inet6 fe80::5ef3:fcff:fee5:a4c0%ng0 fe80::5ef3:fcff:fee5:7338%ng0 '-' '10.1.23.2'
#
# Returns: 0 on success, 1 on failure
set -e
logger "$0 called with parameters: $@"
remote_inet="1.1.1.0/24"
remote_inet6="2001:db8:1:: -prefixlen 64"
eval "
	if route get -net -\$2 \${remote_$2}; then
		logger \"route \${remote_$2} already present\"
		return 0
	else
		cmd=\"route add -\$2 \${remote_$2} \$4\"
	fi
"
if $cmd; then
	logger "$0: $cmd successfull"
	return 0
else
	logger "$0: $cmd failed"
	return 1
fi

