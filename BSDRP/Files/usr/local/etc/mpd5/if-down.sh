#!/bin/sh
#Example of if-down.sh script to be used with mpd5
#mpd5 call script with options:
#interface proto local-ip remote-ip authname peer-address
#example:
#command "/urs/local/etc/mpd5/if-down.sh ng0 inet 10.3.23.1/32 10.3.23.10 '-' '10.0.23.2'"
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
