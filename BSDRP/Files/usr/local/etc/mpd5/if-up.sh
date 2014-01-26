#!/bin/sh
#Example of if-up.sh script to be used with mpd5
#mpd5 call script with options:
#interface proto local-ip remote-ip authname [ dns1 server-ip ] [ dns2 server-ip ] peer-address
#Examples
#command "/usr/local/etc/mpd5/if-up.sh ng0 inet 10.3.23.1/32 10.3.23.10 '-' '' '' '10.1.23.2'"
#command "/usr/local/etc/mpd5/if-up.sh ng0 inet6 fe80::5ef3:fcff:fee5:a4c0%ng0 fe80::5ef3:fcff:fee5:7338%ng0 '-' '10.1.23.2'"
#mpd5 wait for 0 as successful
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

