#!/bin/sh
#
# OpenVPN Registration tunnel up/down script:
# ipfw didn't have tun0 interface during startup, then it need to be
# reloaded after openvpn create and setup the tun0 interface

case ${script_type} in
up)
    /bin/sh /etc/ipfw.rules || /usr/bin/logger "ERROR for reloading ipfw"
    ;;
down)
    ;;
esac
