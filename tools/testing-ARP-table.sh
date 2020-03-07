#!/bin/sh
# Check possible number limitation of 2048 ARP entries
# Generate a vnet jail with 2100 configured epairs
# Then from the host, ping all those epairs and displaying number of ARP entries
# Ram disk /tmp is too small on a BSDRP to use this script, need to increase it:
# mount -uw /
# echo "124000" > /conf/base/var/md_size
# mount -ur /
# reboot
set -eu
dec2dot () {
    # $1 is a decimal number
    # output is pointed decimal (IP address format)
    printf '%d.%d.%d.%d\n' $(printf "%x\n" $1 | sed 's/../0x& /g')
}

MAX=2100
# Start addressing shared LAN at 192.0.2.0 (in decimal to easily increment it)
ipepairbase=3221225984
setup_bridge () {
  ifconfig bridge create name maximum up
  ifconfig maximum inet 192.0.254.254/16
}

create_jail_conf () {
  cat > /etc/jail.conf <<EOF
macgenerator {
  jid = 1;
  host.hostname = "macgenerator";
  #exec.start = '';
  exec.stop = '';
  path = /;
  mount.nodevfs;
  persist;
  vnet new;
EOF

  for i in $(jot ${MAX}); do
    ifconfig epair$i create up
    ifconfig maximum addm epair${i}a edge epair${i}a
    echo "vnet.interface  += \"epair${i}b\";" >> /etc/jail.conf
  done
  echo "}" >> /etc/jail.conf
}

jail_start () {
  service jail onestart
  sysctl net.inet.icmp.icmplim=0
  jexec macgenerator sysctl net.inet.icmp.icmplim=0
}

jail_if_config () {
  jexec macgenerator ifconfig lo1 create
  jexec macgenerator ifconfig lo1 inet 127.0.0.1/8 up
  for i in $(jot ${MAX}); do
    ipdot=$( dec2dot $(( ipepairbase + i)) )
    jexec macgenerator ifconfig epair${i}b inet ${ipdot}/16 up
  done
}

jail_ping () {
  ipepairbase=3221225984
  set +e
  for i in $(jot ${MAX}); do
    ipdot=$( dec2dot $(( ipepairbase + i)) )
    ping -c 4 ${ipdot} &
  done
}

setup_bridge
create_jail_conf
jail_start
jail_if_config
jail_ping

echo "Number of entries in ARP table learned on the bridge interface:"
arp -na -i maximum | wc -l
