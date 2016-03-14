#!/bin/sh
#
# OpenVPN tunnel up/down script:
# - Get environnement variable (DNS, Domain name) passed from the gateway
#    Pass them to a resolvconf configuration file and dnsmasq configuration file
# - Change LED status regarding the OpenVPN status
#
# foreign_option_1=dhcp-option DNS 10.10.10.1
# foreign_option_2=dhcp-option DNS 10.10.10.2
# We don't use the default script $PREFIX/libexec/openvpn-client.up|down

RESOLV_CONF="/tmp/ovpnif-resolv.conf"
DNSMASQ_CONF="/var/run/ovpnif-dnsmasq.conf"
DNSMASQ_RESOLV="/var/run/ovpnif-dnsmasq.resolv"

#DEBUG="/tmp/debug.txt"
#touch ${DEBUG}
#chown nobody ${DEBUG}
#echo "OpenVPN DEBUG" >> $DEBUG
#echo "Script parameters received:" >> $DEBUG
#echo $@ >> $DEBUG
#logger "openvpn call script with type: ${script_type} and args: $@"
#echo "Environnement variables:" >> $DEBUG
#printenv >> $DEBUG

# Check if we are in registered or unregistered mode
# ipfw.rules is only present if we are in registered mode
[ -f /etc/ipfw.rules ] && REGISTERED=true || REGISTERED=false

# There is a bug with the down-root plugin: ${script_type} variable is not set
[ -z ${script_type} ] && script_type="down"

case ${script_type} in
up)
	if (${REGISTERED}); then
		# Registered mode:
		# Set LED 3 on
		# Reload ipfw (because tun0 interface was inexistant during boot)
		[ -e /dev/led/led3 ] && echo "1" > /dev/led/led3
		/bin/sh /etc/ipfw.rules || /usr/bin/logger "ERROR for reloading ipfw"
	else
		# blink LED 3 slowly
		[ -e /dev/led/led3 ] && echo f9 > /dev/led/led3
	fi	
    
	# Parse the DNS server and DOMAIN list from the environnement variables setted by openvpn
	i=1
	DNS_LIST=""
	DOMAIN_LIST=""
	while true; do
		eval option=\$foreign_option_${i}
		[ -z "${option}" ] && break
		eval "
			if echo \$foreign_option_$i | grep -q \"dhcp-option DNS\"; then
				DNS=\`echo \$foreign_option_$i | cut -d ' ' -f 3\`
				DNS_LIST=\"\${DNS_LIST} \${DNS}\"
			elif echo \$foreign_option_$i | grep -q \"dhcp-option DOMAIN\"; then
				DOMAIN=\`echo \$foreign_option_$i | cut -d ' ' -f 3\`
				DOMAIN_LIST=\"\${DOMAIN_LIST} \${DOMAIN}\"
			fi
		"
		i=$(expr $i + 1) 
    done

	# Generate the resolv.conf file and reload it
	[ -f ${RESOLV_CONF} ] && rm ${RESOLV_CONF}
	for DNS in ${DNS_LIST}; do
				echo "nameserver ${DNS}" >> ${RESOLV_CONF}
	done
	first_domain=true
	for DOMAIN in ${DOMAIN_LIST}; do
		if (${first_domain}); then
			echo "domain ${DOMAIN}" >> ${RESOLV_CONF}
			first_domain=false
		else
			echo "search ${DOMAIN}" >> ${RESOLV_CONF}
		fi
	done
	if [ -f ${RESOLV_CONF} ]; then
		cat ${RESOLV_CONF} | /sbin/resolvconf -p -a ${dev} || logger "WARNING: failed to update resolvconf"
	else
		(${REGISTERED}) && logger "WARNING: Didn't receive any DNS/DOMAIN from gateway in registered mode"
	fi

	# Generate dnsmasq configuration file
	[ -f ${DNSMASQ_CONF} ] && rm ${DNSMASQ_CONF}
	for DNS in ${DNS_LIST}; do
		DOMAIN_LIST=`echo ${DOMAIN_LIST} | sed -e 's/ /\//g'`
		echo "server=/${DOMAIN_LIST}/${DNS}" >> ${DNSMASQ_CONF}
	done
	# Reload dnsmasq
	if [ -f ${DNSMASQ_CONF} ]; then
		pkill -HUP dnsmasq || logger "Can't reload dnsmasq"
	fi
	;;
down)
	# Warning: when openvpn started under "nobody" privilege, it's mandatory to load the root-down plugin (openvpn configuration file)
    # Disable LED 3
    [ -e /dev/led/led3 ] && echo "0" > /dev/led/led3
	# Clean-up resolvconf
    /sbin/resolvconf -d ${dev} -f || logger "Can't delete interface to resolvconf"
	[ -f ${RESOLV_CONF} ] && rm ${RESOLV_CONF}	
	# clean-up and reload dnsmasq_conf file
	if [ -f ${DNSMASQ_CONF} ]; then
		rm ${DNSMASQ_CONF}
		pkill -HUP dnsmasq || logger "Can't reload dnsmasq"
	fi
    ;;
esac

