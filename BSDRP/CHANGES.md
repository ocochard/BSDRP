# Release 1.59 (Not released)

## Updated packagesu
* dmidecode to 3.0
* exabgp to 3.4.13
* mpd5 to 5.8
* openvpn to 2.3.10
* python27 to 2.7.11

## package list
* bird-1.5.0_1
* bird6-1.5.0_1
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.1
* ca_root_nss-3.21
* dhcprelya-4.9
* dlmalloc-2.8.6
* dma-v0.9_1,1
* dmidecode-3.0
* easy-rsa-2.2.2
* exabgp-3.4.13
* flashrom-0.9.7_3
* freevrrpd-1.1_1
* indexinfo-0.2.4
* iperf-2.0.5
* iperf3-3.1.1
* ipmitool-1.8.15_1
* ipsec-tools-0.8.2_1
* isc-dhcp43-server-4.3.3
* libevent2-2.0.22_1
* libffi-3.2.1
* libftdi-0.20_4
* libgcrypt-1.6.4_3
* libgpg-error-1.20_1
* libpci-3.4.0
* lzo2-2.09
* monit-5.15
* mpd5-5.8
* mrouted-3.9.7_1
* openldap-client-2.4.43
* openvpn-2.3.10
* openvpn-auth-radius-2.1_3
* pciids-20151224
* pim6-tools-20061214
* pim6dd-0.2.1.0.a.15
* pim6sd-2.1.0.a.23
* pimd-2.3.2
* pimdd-0.2.1.0_2
* pkg-1.6.2
* pmacct-0.14.3_3
* py27-setuptools27-19.2
* python2-2_3
* python27-2.7.11_1
* quagga-0.99.24.1_2
* readline-6.3.8
* strongswan-5.3.5_1
* sudo-1.8.15
* tayga-0.9.2
* tmux-2.1_1
* ucarp-1.5.2_2

-----------------------------------------------------

# Release 1.58 (10/12/2015)

## Important tip for upgrading "fresh 1.57 install"
* Fresh BSDRP 1.57 installation contains an UFS label bug. And this bug need
  to be fixed before starting the upgrade process.
  A script is available for fixing this problem, here is how to use it:
  fetch http://dev.bsdrp.net/fixlabel.sh
  sh ./fixlabel.sh
  and follow instructions

## New features
* Upgrade to 10.2-RELEASE-p8
* Disable Chelsio NIC features useless in a simple router (cxgbe.toecaps_allowed=0)
* Disable vlan_hwtso feature by default
* Added an installation helper option: "system install <target-disk>"
* Added userland symbols/debug in the debug archive
* Serial port default speed is now set to 115200 bauds (new installation), an
  upgrade will not change the previous console speed

## New packages
* iperf 3.1
* flashrom: Allow to upgrade BIOS on supported device

## Bug fixed
* Fixed bad UFS labeling introduced on 1.57
* Fixed 'config put/get' script
* Boot0 will stop to reset serial speed at 9600 bauds

## Updated packages
* ipmitool to 1.8.15
* isc-dhcp43-server to 4.3.3
* exabgp to 3.4.12
* monit to 5.15
* mrouted to 3.9.7
* strongswan to 5.3.5
* tmux 2.1

## Package list
* bird-1.5.0_1
* bird6-1.5.0_1
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.1
* ca_root_nss-3.20.1
* dhcprelya-4.9
* dlmalloc-2.8.6
* dma-v0.9_1,1
* dmidecode-2.12_1
* easy-rsa-2.2.2
* exabgp-3.4.12_1
* flashrom-0.9.7_3
* freevrrpd-1.1_1
* indexinfo-0.2.4
* iperf-2.0.5
* iperf3-3.1.1
* ipmitool-1.8.15_1
* ipsec-tools-0.8.2_1
* isc-dhcp43-server-4.3.3
* libevent2-2.0.22_1
* libffi-3.2.1
* libftdi-0.20_4
* libgcrypt-1.6.4_2
* libgpg-error-1.20_1
* libpci-3.4.0
* lzo2-2.09
* monit-5.15
* mpd5-5.7_3
* mrouted-3.9.7_1
* openldap-client-2.4.43
* openvpn-2.3.8
* openvpn-auth-radius-2.1_3
* pciids-20151205
* pim6-tools-20061214
* pim6dd-0.2.1.0.a.15
* pim6sd-2.1.0.a.23
* pimd-2.3.1
* pimdd-0.2.1.0_2
* pkg-1.6.2
* pmacct-0.14.3_3
* py27-setuptools27-18.7
* python2-2_3
* python27-2.7.10_1
* quagga-0.99.24.1_2
* readline-6.3.8
* strongswan-5.3.5_1
* sudo-1.8.15
* tayga-0.9.2
* tmux-2.1
* ucarp-1.5.2_2

-----------------------------------------------------
# Release 1.57 (16/08/2015)

## New features
* Upgraded to FreeBSD 10.2-RELEASE
* Enable getty on serial port 1 and 2 by default
* Added script for doing IPSec benchmark using Equilibrium throughput method

## Bug fixes
* Fix Emulex oce(4) promiscious/carp behavior (thanks Sergey Akhmatov from FreeBSD ML-net)

## Updated packages
* openvpn to 2.3.8
* strongswan to 5.3.2

## Package list
* bird-1.5.0_1
* bird6-1.5.0_1
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.1
* dhcprelya-4.9
* dlmalloc-2.8.6
* dma-v0.9_1,1
* easy-rsa-2.2.2
* exabgp-3.4.8
* freevrrpd-1.1_1
* indexinfo-0.2.3
* iperf-2.0.5
* ipmitool-1.8.14_1
* ipsec-tools-0.8.2_1
* isc-dhcp43-server-4.3.2_1
* libevent2-2.0.22_1
* libffi-3.2.1
* libgcrypt-1.6.3
* libgpg-error-1.19_1
* lzo2-2.09
* mcast-tools-20061214_1
* monit-5.14
* mpd5-5.7_3
* mrouted-3.9.6_1
* netmap-ipfw-0.1
* openldap-client-2.4.41
* openvpn-2.3.8
* openvpn-auth-radius-2.1_3
* pimd-2.2.1
* pimdd-0.2.1.0_1
* pkg-1.5.6
* pmacct-0.14.3_3
* py27-setuptools27-17.0
* python2-2_3
* python27-2.7.10
* quagga-0.99.24.1_2
* readline-6.3.8
* strongswan-5.3.2
* sudo-1.8.14p3
* tayga-0.9.2
* tmux-2.0
* ucarp-1.5.2_2

-----------------------------------------------------
# Release 1.56 (2015/05/15)

## New features
* Python interpreter added: This brings a lot's of new possiblity like being manageable by ansible.
  Python by itself added 70MB to the 120MB (nanobsd + all packages), but there is still about 30MB of free space.
* Kernel: I2C generic I/O device drivers added
* New package: ExaBGP (https://github.com/Exa-Networks/exabgp)

## Bug fixes
* Upgraded to FreeBSD 10.1-RELEASE-p10
* Rotating bird and openvpn log file by default

## Updated packages
* bird to 1.5.0
* quagga to 0.99.24
* monit to 5.12.2
* pimd to 2.2.1
* sudo to 1.8.13
* strongswan to 5.3.0
* tmux to 2.0

## Package list
* bird-1.5.0_1
* bird6-1.5.0_1
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.1
* dhcprelya-4.8_1
* dlmalloc-2.8.6
* dma-v0.9_1,1
* easy-rsa-2.2.0.m
* exabgp-3.4.8
* freevrrpd-1.1_1
* indexinfo-0.2.3
* iperf-2.0.5
* ipmitool-1.8.14_1
* ipsec-tools-0.8.2
* isc-dhcp43-server-4.3.2
* libevent2-2.0.22_1
* libffi-3.2.1
* libgcrypt-1.6.3
* libgpg-error-1.19
* lzo2-2.09
* mcast-tools-20061214_1
* monit-5.12.2
* mpd5-5.7_2
* mrouted-3.9.6_1
* netmap-ipfw-0.1
* openldap-client-2.4.40_1
* openvpn-2.3.6_4
* openvpn-auth-radius-2.1_3
* pimd-2.2.1
* pimdd-0.2.1.0_1
* pkg-1.5.2
* pmacct-0.14.3_3
* py27-setuptools27-5.5.1_1
* python2-2_3
* python27-2.7.9_1
* quagga-0.99.24.1_1
* readline-6.3.8
* strongswan-5.3.0_1
* sudo-1.8.13
* tayga-0.9.2
* tmux-2.0
* ucarp-1.5.2_2

-----------------------------------------------------

# Release 1.55 (2015/03/21)

## New features
* Enable infiniband (OFED) drivers with mlx(4)
* Enable ICMP reply from incoming interface for non-local packets by default

## New packages
* pmacct (http://www.pmacct.net/)

## Bug fixes
* Upgraded to FreeBSD 10.1-RELEASE-p8
* Re-add mrouted and netmap-ipfw
* pf anchor fixes (PR/196314 and PR/183198)
* Allow unsupported SFP on Intel NIC by default

## Updated packages
* ipsec-tools to 0.8.2
* monit to 5.12.1
* quagga NOT upgraded to 0.99.24 (there is an OSPF v3 regression)

## Package list
* bird-1.4.5_2
* bird6-1.4.5_2
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.1
* dhcprelya-4.8_1
* dlmalloc-2.8.6
* dma-v0.9_1,1
* easy-rsa-2.2.0.m
* freevrrpd-1.2
* indexinfo-0.2.3
* iperf-2.0.5
* ipmitool-1.8.14_1
* ipsec-tools-0.8.2
* isc-dhcp43-server-4.3.2
* libevent2-2.0.22_1
* libgcrypt-1.6.3
* libgpg-error-1.17
* lzo2-2.09
* mcast-tools-20061214_1
* monit-5.12.1
* mpd5-5.7_1
* mrouted-3.9.6_1
* netmap-ipfw-0.1
* openldap-client-2.4.40_1
* openvpn-2.3.6_1
* openvpn-auth-radius-2.1_3
* pimd-2.2.0
* pimdd-0.2.1.0_1
* pkg-1.4.12
* pmacct-0.14.3_3
* quagga23-0.99.23.1_4
* strongswan-5.2.2_1
* sudo-1.8.12
* tayga-0.9.2
* tmux-1.9a_1
* ucarp-1.5.2_2

-----------------------------------------------------

# Release 1.54 (2015/01/02)

## Bug fixes
* Upgraded to FreeBSD 10.1-RELEASE-p3
* 'config save' correctly backup new empty directories

## Updated packages
* bird to 1.4.5
* openvpn to 2.3.6
* pimd to 2.2.0
* strongswan to 5.2.1

## Package list
* bird-1.4.5_1
* bird6-1.4.5_1
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.1
* dhcprelya-4.8_1
* dlmalloc-2.8.6
* dma-v0.9_1,1
* easy-rsa-2.2.0.m
* freevrrpd-1.1_1
* indexinfo-0.2.2
* iperf-2.0.5
* ipmitool-1.8.14_1
* ipsec-tools-0.8.1_7
* isc-dhcp43-server-4.3.1
* libevent2-2.0.21_3
* libgcrypt-1.6.1_5
* libgpg-error-1.17
* lzo2-2.08_1
* mcast-tools-20061214_1
* monit-5.11
* mpd5-5.7_1
* openldap-client-2.4.40_1
* openvpn-2.3.6_1
* openvpn-auth-radius-2.1_2
* pimd-2.2.0
* pimdd-0.2.1.0_1
* pkg-1.4.3
* quagga-0.99.23.1_2
* strongswan-5.2.1
* sudo-1.8.11.p1
* tayga-0.9.2
* tmux-1.9a
* ucarp-1.5.2_2

-----------------------------------------------------

# Release 1.53 (2014/11/19)

## New features
* Upgraded to FreeBSD 10.1
* Replaced package: ssmtp by dma (DragonFly Mail Agent): FreeBSD 11.0 will include DMA in base
* Kernel: Enable dtrace and add Emulex OneConnect 10Gb NIC drivers (oce)
* Distribute kernel debug (symbols) archive

## Bug fixes
* /data directory was missing on i386 full-images
* Prevent 'config save' to follow symlink
* fix 'system dual-console' on serial image

## New packages
* monit: Process monitoring tool
* dma: DragonFly Mail Agent

## Updated packages
* quagga 0.99.22.4 to 0.99.23.1
* openvpn 2.3.4 to 2.3.5

## Package list
* bird-1.4.4_2
* bird6-1.4.4_2
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.1
* dhcprelya-4.8_1
* dlmalloc-2.8.6
* dma-v0.9_1,1
* easy-rsa-2.2.0.m
* freevrrpd-1.1_1
* indexinfo-0.2
* iperf-2.0.5
* ipmitool-1.8.14_1
* ipsec-tools-0.8.1_7
* isc-dhcp43-server-4.3.1
* libevent2-2.0.21_3
* libgcrypt-1.6.1_5
* libgpg-error-1.17
* lzo2-2.08_1
* mcast-tools-20061214_1
* monit-5.10
* mpd5-5.7_1
* openldap-client-2.4.40
* openvpn-2.3.5
* openvpn-auth-radius-2.1_2
* pimd-devel-2.1.8
* pimdd-0.2.1.0_1
* pkg-1.3.8_3
* quagga-0.99.23.1_2
* strongswan-5.2.0_1
* sudo-1.8.11.p1
* tayga-0.9.2
* tmux-1.9.a_2
* ucarp-1.5.2_2

-----------------------------------------------------

# Release 1.52 (2014/09/13)

## New features
* Upgraded to FreeBSD 10-stable rev 271528 (close to 10.1)
* quagga-re replaced by quagga: quagga-re seems no more updated
* Disable LRO and TSO on all interfaces by default
    * For reverting, edit /etc/rc.conf.misc and set disablelrotso_enable to NO
    * More information about why disabling LRO/TSO on a router here: http://bsdrp.net/documentation/technical_docs/performance?&#nic_drivers_tuning

## Bug fixes
* Disable high-resolution on VGA console: This created colors problem on VMware and VirtualBox graphical screen
* fix RC polling script that tried to enable polling on all interfaces
* fix ipsec startup script: Display a warning message in place of exiting
* fixed setkey with TCP signature

## Developer's corner
* Sources migrated from SourceForge to github (https://github.com/ocochard/BSDRP)

## Updated packages
* bird to 1.4.4
* isc-dhcp43-server to 4.3.1
* quagga-re 0.99.17.12 to quagga 0.99.22.4
* strongswan to 5.2.0

## Package list
* bird-1.4.4
* bird6-1.4.4
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.0
* dhcprelya-4.8_1
* dlmalloc-2.8.6
* easy-rsa-2.2.0.m
* freevrrpd-1.1
* indexinfo-0.2
* iperf-2.0.5
* ipmitool-1.8.14_1
* ipsec-tools-0.8.1_7
* isc-dhcp43-server-4.3.1
* libevent2-2.0.21_2
* libgcrypt-1.6.1_5
* libgpg-error-1.13_1
* lzo2-2.08
* mcast-tools-20061214_1
* mpd5-5.7_1
* openldap-client-2.4.39_2
* openvpn-2.3.4
* openvpn-auth-radius-2.1_2
* pimd-devel-2.1.8
* pimdd-0.2.1.0_1
* pkg-1.3.7
* quagga-0.99.22.4_4
* ssmtp-2.64_1
* strongswan-5.2.0_1
* sudo-1.8.10.p3_1
* tayga-0.9.2
* tmux-1.9.a_2
* ucarp-1.5.2_2

## UPGRADE PROCEDURE (if your installation is older than BSDRP 1.51)

BSDRP since 1.51 needs at minimum a 512MB disk and no more a 256MB disk.

If you've installed BSDRP on a 256MB disk: You can't upgrade it.

But you installed it on a 512MB disk (or larger), here is how to resize the partitionning system:

    cd /tmp
    fetch https://raw.githubusercontent.com/ocochard/BSDRP/master/BSDRP/tools/resize_nanobsd.sh
	sh ./resize_nanobsd.sh

-----------------------------------------------------

# Release 1.51 (2014/06/11)

## New features
* Upgraded to FreeBSD 10-STABLE (10.0-RELEASE has too lot's of regression)
* New kernel modules added: HyperV
* Extras patches:
	* pfSense's net.isr patch: net.isr.maxthreads=ncpu and compliant with polling
	* pf UDP NAT patch (kern/181690)
	* Fix Realtek 8111G NIC support (misc/181703)
    * bsnmpd costemic patch
      http://lists.freebsd.org/pipermail/freebsd-net/2013-April/035171.html
	* multi-threaded netblast (bin/179085)
    * Fix netmap's pkt-gen checksum bug (bin/187149)
* Default configuration:
	* Do not enable sshd by default
    * Bump the ramdisk size /var to 20MB
* mpd5: provide example scripts for if-up and if-down
* Removed packages:
	* NetPIPE
	* isc-dhcp-relay replaced by dhcprelya
* New packages:
    * security/strongswan: IKEv2
* openvpn: radius module added
* Lab script: New script with bhyve support

## Special note
* Minimum disk size requierement increased to 512MB for new install:
    * Install (full) images are now 512MB size
    * Update images are still 256MB size

## Important upgrade notes
* CARP configuration need to be upgraded: https://www.freebsd.org/doc/handbook/carp.html
* isc-dhcpd-relay was replaced by dhcprelya: replace dhcrelay_* lines by dhcprelya_* in rc.conf

## Known bugs (Need some C knowledge to fix them)
* pimd and pimdd are broken

## Updated packages
 * bird to 1.4.3
 * ipmitoo to 1.8.14
 * tmux to 1.9.a
 * openvpn to 2.3.4

## Installed packages
* bird-1.4.3
* bird6-1.4.3
* bsnmp-regex-0.6
* bsnmp-ucd-0.4.0
* dhcprelya-4.8
* dlmalloc-2.8.6
* easy-rsa-2.2.0.m
* freevrrpd-1.1
* iperf-2.0.5
* ipmitool-1.8.14
* ipsec-tools-0.8.1_6
* isc-dhcp43-server-4.3.0_1
* libevent2-2.0.21_1
* libgcrypt-1.5.3_2
* libgpg-error-1.13_1
* lzo2-2.06_3
* mcast-tools-20061214_1
* mpd5-5.7_1
* openldap-client-2.4.39
* openvpn-2.3.4
* openvpn-auth-radius-2.1_1
* pimd-devel-2.1.8
* pimdd-0.2.1.0_1
* pkg-1.2.7_2
* quagga-re-0.99.17.12_1
* ssmtp-2.64_1
* strongswan-5.1.3
* sudo-1.8.10.p3
* tayga-0.9.2
* tmux-1.9.a_1
* ucarp-1.5.2_2

-----------------------------------------------------
# Release 1.5 (2013/10/27)

## New features
* Upgraded to FreeBSD 9.2-RELEASE
* Extras patches:
	* Autotuning mbuf patch
	http://lists.freebsd.org/pipermail/freebsd-stable/2013-July/074129.html
	* pf UDP NAT patch (kern/181690)
	* Fix Realtek 8111G NIC support (misc/181703)
    * bsnmpd costemic patch
      http://lists.freebsd.org/pipermail/freebsd-net/2013-April/035171.html
	* multi-threaded netblast (bin/179085)
* Add stf — 6to4 tunnel interface module
* Added hwpmc modules for spoting performance issue
    * Example: kldload hwpmc; pmcstat -T -S instructions
* New tools:
    * cryptotest for measuring hardware-assisted crypto performance
      Example: kldload aesni; cryptotest -z 2048
    * cxgbtool/cxgbetool tools for configuring embedded firewall in Chelsio NIC
	* OpenVPN
* New rc scripts:
    * ngnetflow
## Bug fixes
* fix "system expand-data-slice"
* "config save" still save the configuration even if configuration archive failed
* Quagga rc script create /var/log/quagga dir
* fix default syslogd flags that prevent logging to remote machines
* Dirty fix regarding GRE interface not in RUNNING state (kern/164475)

## Removed
* rvi script: CVS is not is FreeBSD base anymore
* net/fprobe: FreeBSD's native ng_netflow supports netflow v5 and v9

## Updated packages
* bird to 1.3.11
* isc-dhcp42-server and relay to 4.2.5
* mpd 5.7
* tmux to 1.8

## Misc for developers/testers
* bisection-gen.sh: Permit to generate a list of BSDRP image based on a list of FreeBSD svn-revision number
* bench-lab.sh: Permit to automatize multiple upgrade image + configuration sets + bench tests 

## Installed packages
* NetPIPE-3.7.1
* bird-1.3.11_2
* bird6-1.3.11_1
* bsnmp-regex-0.6
* bsnmp-ucd-0.4.0
* dlmalloc-2.8.6
* easy-rsa-2.2.0.m
* freevrrpd-1.1
* iperf-2.0.5
* ipmitool-1.8.12_4
* ipsec-tools-0.8.0_3
* isc-dhcp42-relay-4.2.5
* isc-dhcp42-server-4.2.5
* libevent-1.4.14b_2
* libgcrypt-1.5.3
* libgpg-error-1.12
* lzo2-2.06_1
* mcast-tools-20061214_1
* mpd-5.7
* mrouted-3.9.6_1
* openldap-client-2.4.36
* openvpn-2.3.2
* pftop-0.7_2
* pimdd-0.2.1.0_1
* pkg-1.1.4_8
* quagga-re-0.99.17.12_1
* ssmtp-2.64
* sudo-1.8.8
* tayga-0.9.2
* tmux-1.8_1
* ucarp-1.5.2_2

-----------------------------------------------------
# Release 1.4 (2013/03/21)

## New features
* Update to FreeBSD 9.1-RELEASE-p1
* Extras patches:
    * pf source entry removing too slow
      http://lists.freebsd.org/pipermail/freebsd-net/2013-March/034897.html
    * interfaces route add/delete
      http://lists.freebsd.org/pipermail/freebsd-net/2013-March/034801.html
    * bsnmpd SNMPv3 engine discovery is broken
      http://www.freebsd.org/cgi/query-pr.cgi?pr=174974
* Add pfsync,coretemp and amdtemp modules
* Replace net-snmp by bsnmpd (with ucd and regex modules)
* Enable blackhole(8) by default for IPv4
* netsend and netreceive updated (backported from -current)
* Add 'system dual-console': Permit to enable dual vga/serial mode
* New package: tayga (userland stateless NAT64 daemon)

## Bug fixes
* Revert to use dual vga/serial mode on the vga image: Somes servers have buggy serial support
* Disable "device tcl" (CAM Target Layer, useless for a router) that consume 32MB of RAM

## Updated packages
* quagga-re to 0.99.17.12

## Installed packages
* NetPIPE-3.7.1                  A self-scaling network benchmark
* bird-1.3.9_1                   Dynamic IP routing daemon (IPv4 version)
* bird6-1.3.9_1                  Dynamic IP routing daemon (IPv6 version)
* bsnmp-regex-0.5_2              A bsnmpd module allowing creation of counters from log files
* bsnmp-ucd-0.3.6                A bsnmpd module that implements parts of UCD-SNMP-MIB
* bsnmptools-0.0.20060818_2      Snmp client tools
* dlmalloc-2.8.4                 Small, fast malloc library by Doug Lea
* fprobe-1.1_1                   Tool that collects network traffic data
* freevrrpd-1.1                  This a VRRP RFC2338 Compliant implementation under FreeBSD
* iperf-2.0.5                    A tool to measure maximum TCP and UDP bandwidth
* ipfw-user-0.1                  Netmap-enabled IPFW userspace version
* ipmitool-1.8.12_2              CLI to manage IPMI systems
* ipsec-tools-0.8.0_3            KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp42-relay-4.2.4         The ISC Dynamic Host Configuration Protocol relay
* isc-dhcp42-server-4.2.4_2      The ISC Dynamic Host Configuration Protocol server
* libevent-1.4.14b_2             Provides an API to execute callback functions on certain events
* libgcrypt-1.5.0_1              General purpose crypto library based on code used in GnuPG
* libgpg-error-1.11              Common error values for all GnuPG components
* mcast-tools-20061214_1         IPv6 multicast routing daemons and tools
* mpd-5.6                        Multi-link PPP daemon based on netgraph(4)
* mrouted-3.9.6_1                Multicast routing daemon providing DVMRP for IPv4
* openldap-client-2.4.34         Open source LDAP client implementation
* pftop-0.7_1                    Utility for real-time display of statistics for pf
* pimdd-0.2.1.0                  UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg-1.0.9_2                    New generation package manager
* quagga-re-0.99.17.12           A branch of popular quagga software pointed at stability
* ssmtp-2.64                     Extremely simple MTA to get mail off the system to a mail hub
* sudo-1.8.6.p7                  Allow others to run commands as root
* tayga-0.9.2                    Userland stateless NAT64 daemon
* tmux-1.7_1                     A Terminal Multiplexer
* ucarp-1.5.2_1                  Userlevel Common Address Redundancy Protocol
* virtio-kmod-9.1-0.242658       virtio kernel modules port for 8.[23]/9.[01]

-----------------------------------------------------
# Release 1.3 (2013/01/14)

## New features
* New arch available: sparc64

## Bug fixes
* Add the missing ipfw_nat module
* Netmap fixes by sync code with -current
    * Works on amd64 arch only
    * NIC compatibles: em(4) and re(4) nic, not ixgbe(4)

## Updated packages
* Bird to 1.3.9

## Installed packages
* NetPIPE-3.7.1                  A self-scaling network benchmark
* bird-1.3.9                     Dynamic IP routing daemon (IPv4 version)
* bird6-1.3.9                    Dynamic IP routing daemon (IPv6 version)
* dlmalloc-2.8.4                 Small, fast malloc library by Doug Lea
* fprobe-1.1_1                   Tool that collects network traffic data
* freevrrpd-1.1                  This a VRRP RFC2338 Compliant implementation under FreeBSD
* iperf-2.0.5                    A tool to measure maximum TCP and UDP bandwidth
* ipfw-user-0.1                  Netmap-enabled IPFW userspace version
* ipmitool-1.8.12_1              CLI to manage IPMI systems
* ipsec-tools-0.8.0_3            KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp42-relay-4.2.4         The ISC Dynamic Host Configuration Protocol relay
* isc-dhcp42-server-4.2.4_2      The ISC Dynamic Host Configuration Protocol server
* libevent-1.4.14b_2             Provides an API to execute callback functions on certain events
* libgcrypt-1.5.0_1              General purpose crypto library based on code used in GnuPG
* libgpg-error-1.10              Common error values for all GnuPG components
* mcast-tools-20061214_1         IPv6 multicast routing daemons and tools
* mpd-5.6                        Multi-link PPP daemon based on netgraph(4)
* mrouted-3.9.6_1                Multicast routing daemon providing DVMRP for IPv4
* net-snmp-5.7.2_1               An extendable SNMP implementation
* openldap-client-2.4.33_1       Open source LDAP client implementation
* pftop-0.7_1                    Utility for real-time display of statistics for pf
* pimdd-0.2.1.0                  UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg-1.0.4_1                    New generation package manager
* quagga-re-0.99.17.11           A branch of popular quagga software pointed at stability
* ssmtp-2.64                     Extremely simple MTA to get mail off the system to a mail hub
* sudo-1.8.6.p3_1                Allow others to run commands as root
* tmux-1.7_1                     A Terminal Multiplexer
* ucarp-1.5.2_1                  Userlevel Common Address Redundancy Protocol
* virtio-kmod-9.1-0.242658       virtio kernel modules port for 8.[23]/9.[01]

-----------------------------------------
# Release 1.2 (2012/12/20)

## New features
* Update base to FreeBSD 9.1-Release
* Add Kernel drivers: netmap (framework for fast packet I/O), Encapsulating Interface (enc), some 1OG NICs (cxgb, cxgbe, mxge, nxge), SCSI/RAID controllers, Intel ICH watchdog, ipmi, asni and virtio
* FreeBSD patches:
	* kern/163208 PF state key linking mismatch
	* if_bridge and if_lagg: increased performance (from -current)
	* boot-loader and dual console (vga/serial)
      no more hang if no serial port present, the vga image have dual console (vga/serial) enabled
	* syslogd: IPv6 support (from -current)
* Default kern.ipc.nmbclusters increased to 275MB
* Re-enable DMA and disk-caching
* Transmit and receive descriptors for igb(4) and em(4) set to max (4096) and kern.ipc.nmbclusters increased
  This changes create problems on i386 arch with less than 256Mb of RAM
  For solving it: Remove all line that contains hw.*.?xd in /boot/loader.conf.local
* Migrated to the new pkg tool
* New packages:
	* mctest (a multicast test tool)
    * net/pimdd
    * security/sudo
    * sysutils/ipmitool
    * security/ipsec-tools
* Man pages are now included
* Add 'system rollback': Rollback to previous version
* Add 'system expand-data-slice': Expand the size of /data to all available space on disk and enable soft update journaling on it.
* Redirect periodic output to a log file
* User customized /boot/loader.conf.local file is preserved after an upgrade
* Add version number on the boot menu
* Build script speed improvement: add mdmfs support, kept distfiles in the same folder as FreeBSD sources, didn't compile all kernel modules 
* Lab tools: Scripts adapted to virtualbox 4.2 (maximum number of NIC increased to 36) and virtio mode supported

## Updated packages
* Bird to 1.3.8
* Quagga to Quagga-RE 0.99.17.11
* ISC-isc-dhcp to 4.2.4-P1
* freevrrpd to 1.1
* net-snmp 5.7.2
* mrouted to 3.9.6

## Notes
Regarding netmap:
* Only 3 demos tools available:
    * ipfw-userland version (use /usr/local/bin/ipfw in place of /usr/bin/ipfw)
    * pkt-gen: a packet sink/source
    * bridge: a two-port jumper wire
* Support only theses NICs: em, igb, lem, re, ixgbe
* Minimum RAM requirements was increased to 512MB (netmap needs about 200MB)
* More information about netmap: http://info.iet.unipi.it/~luigi/netmap/

## Installed packages
* NetPIPE-3.7.1                  A self-scaling network benchmark
* bird-1.3.8                     Dynamic IP routing daemon (IPv4 version)
* bird6-1.3.8                    Dynamic IP routing daemon (IPv6 version)
* dlmalloc-2.8.4                 Small, fast malloc library by Doug Lea
* fprobe-1.1_1                   Tool that collects network traffic data
* freevrrpd-1.1                  This a VRRP RFC2338 Compliant implementation under FreeBSD
* iperf-2.0.5                    A tool to measure maximum TCP and UDP bandwidth
* ipfw-user-0.1                  Netmap-enabled IPFW userspace version
* ipmitool-1.8.12_1              CLI to manage IPMI systems
* ipsec-tools-0.8.0_3            KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp42-relay-4.2.4         The ISC Dynamic Host Configuration Protocol relay
* isc-dhcp42-server-4.2.4_2      The ISC Dynamic Host Configuration Protocol server
* libevent-1.4.14b_2             Provides an API to execute callback functions on certain events
* libgcrypt-1.5.0_1              General purpose crypto library based on code used in GnuPG
* libgpg-error-1.10              Common error values for all GnuPG components
* mcast-tools-20061214_1         IPv6 multicast routing daemons and tools
* mpd-5.6                        Multi-link PPP daemon based on netgraph(4)
* mrouted-3.9.6                  Multicast routing daemon providing DVMRP for IPv4
* net-snmp-5.7.2_1               An extendable SNMP implementation
* openldap-client-2.4.33_1       Open source LDAP client implementation
* pftop-0.7_1                    Utility for real-time display of statistics for pf
* pimdd-0.2.1.0                  UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg-1.0.3_1                    New generation package manager
* quagga-re-0.99.17.11           A branch of popular quagga software pointed at stability
* ssmtp-2.64                     Extremely simple MTA to get mail off the system to a mail hub
* sudo-1.8.6.p3_1                Allow others to run commands as root
* tmux-1.7_1                     A Terminal Multiplexer
* ucarp-1.5.2_1                  Userlevel Common Address Redundancy Protocol
* virtio-kmod-9.1-0.242658       virtio kernel modules port for 8.[23]/9.[01]
 
----------------------------
# Release 1.1 (2012/02/16)

## New features
* Upade base to FreeBSD 8.2-RELEASE-p6
* netblast/netstend/netreceive bench tools now support IPv6
* Add keymap languages files
* Add a tools for using Quagga as BGP route generator: quagga-bgp-netgen
* Lab script: Permit to configure routers' RAM size
* Kernel: Disable softupdates and swapping, enable IPSEC NAT-T

## Bug fix
* fix "can't set default locale" message
* netstat -z now clear IPv6 stats too (bin/153206)

## Updated packages
* Bird to 1.3.6
* net-snmp to 5.7.1_4
* tmux to 1.6
* mpd to 5.6

## Installed packages
* NetPIPE-3.7.1       A self-scaling network benchmark
* bird-1.3.6          Dynamic IP routing daemon (IPv4 version)
* bird6-1.3.6         Dynamic IP routing daemon (IPv6 version)
* dlmalloc-2.8.4      Small, fast malloc library by Doug Lea
* fprobe-1.1_1        Tool that collects network traffic data
* freevrrpd-1.0       This a VRRP RFC2338 Compliant implementation under FreeBSD
* iperf-2.0.5         A tool to measure maximum TCP and UDP bandwidth
* isc-dhcp42-relay-4.2.3 The ISC Dynamic Host Configuration Protocol relay
* isc-dhcp42-server-4.2.3_2 The ISC Dynamic Host Configuration Protocol server
* libevent-1.4.14b_2  Provides an API to execute callback functions on certain ev
* mcast-tools-20061214_1 IPv6 multicast routing daemons and tools
* mpd-5.6             Multi-link PPP daemon based on netgraph(4)
* mrouted-3.9.5       Multicast routing daemon providing DVMRP for IPv4
* net-snmp-5.7.1_4    An extendable SNMP implementation
* quagga-0.99.20_3    Free RIPv1, RIPv2, OSPFv2, BGP4, IS-IS route software
* ssmtp-2.64          Extremely simple MTA to get mail off the system to a mail h
* tmux-1.6            A Terminal Multiplexer
* ucarp-1.5.2_1       Userlevel Common Address Redundancy Protocol

----------------------------
# Release 1.0 (2011/10/04)

## New features
* Upade base to FreeBSD 8.2-RELEASE-p4
* Add FreeBSD network benchmark tools: netblast,netsend and netreceive
* Use XZ in place of BZIP2 for config files archives
* mtree: remove md5 checksum
* kernel patched for bird and FIB usage
* Freevrrp rc script: Auto-load netgraph modules
* Add telnet (usefull for connecting local mpd control port)

## Bug fixes
* fix "config save", that save unmodified files and didn't delete old files
* fix "show" that didn't support more than 1 option
* Fix ndp tools installation
* Fix default bird startup scripts that used bad folder for control socket
* Fix Ethernet interfaces names in bird
* Fix the upgrade script (merge changes in /boot/loader.conf)
* Fix a carp bug when preemption is enabled (kern/161123)
* Forgot to add the dummynet kernel module
* Build tool: Add a check to the FreeBSD source code branch used

## Updated packages
* Quagga to 0.99.20
* Bird to 1.3.3 (support FIB and include config file)
* mrouted to 3.9.5
* net-snmp to 5.7
* isc-dhcp server/relay to 4.2.2

## Installed packages
* NetPIPE-3.7.1       A self-scaling network benchmark
* bird-1.3.3          Dynamic IP routing daemon (IPv4 version)
* bird6-1.3.3         Dynamic IP routing daemon (IPv6 version)
* dlmalloc-2.8.4      Small, fast malloc library by Doug Lea
* expat-2.0.1_2       XML 1.0 parser written in C
* fprobe-1.1_1        Tool that collects network traffic data
* freevrrpd-1.0       This a VRRP RFC2338 Compliant implementation under FreeBSD
* iperf-2.0.5         A tool to measure maximum TCP and UDP bandwidth
* isc-dhcp42-relay-4.2.2 The ISC Dynamic Host Configuration Protocol relay
* isc-dhcp42-server-4.2.2 The ISC Dynamic Host Configuration Protocol server
* libevent-1.4.14b_2  Provides an API to execute callback functions on certain ev
* libpdel-0.5.3_4     Packet Design multi-purpose C library for embedded applicat
* mcast-tools-20061214_1 IPv6 multicast routing daemons and tools
* mpd-5.5             Multi-link PPP daemon based on netgraph(4)
* mrouted-3.9.5       Multicast routing daemon providing DVMRP for IPv4
* net-snmp-5.7_3      An extendable SNMP implementation
* quagga-0.99.20      Free RIPv1, RIPv2, OSPFv2, BGP4, IS-IS route software
* ssmtp-2.64          Extremely simple MTA to get mail off the system to a mail h
* tmux-1.5            A Terminal Multiplexer
* ucarp-1.5.2_1       Userlevel Common Address Redundancy Protocol

---------------------------------------------------------
# Release 0.35 (2011/03/06)

## WARNING
Special upgrade procedure is needed for this release ! (check notes)

## New features
* Update to FreeBSD 8.2-RELEASE
* BSDRP's nanobsd patches were include to FreeBSD-current, then replace BSDRP's nanobsd by FreeBSD's nanobsd
* Reduce bootloader timeout to 1 second
* Reduce the security level of the kernel to default value (loading kernel module is easiest)
* Use xz in place of bzip2 for BSDRP files (images, mtree)
* Possibility to use a post-upgrade script included in the new image during upgrade
* Detect KVM guest usage
* MS Windows Virtualbox lab script improvement: Permit to use a 'shared with host (hostonly)' interface
* Added: net/mpd5, a PPP Multilink daemon (multilink, PAP, CHAP, MS-CHAP and EAP authentication, PPTP, L2TP, PPPoE, etc...)
* Disable polling by default: Modern NIC include interrupt management and enabling polling on this modern NIC can reduce performance

## Bug fixes
* Hardened the upgrade and config scripts
* Add missing kernel modules and binary: ipfw_nat, libaliase, pflog, tap interface

## Updated packages
* freeVRRPd (It depends of some netgraph modules now)
* Quagga
* Bird
* tmux
* ssmtp

## Know bugs
* "system endpoint" seams to decrease TCP performance in place of increase them
* FreeBSD Bootloader manager (boot0) didn't support serial speed value more than 9600 baud (kernel and console use 38400)

## Upgrade procedure
The new nanobsd script change the glabel name scheme of the partition, then the embedded upgrade script can't manage
theses new names.
You need to use a special upgrade script, that will convert partition name.

1 Download the special upgrade script to your router in /tmp
  As example, using fetch:
  cd /tmp
  fetch http://bsdrp.net/tools/upgrade-to-035
  chmod +x /tmp/upgrade-to-035
2 Launch the upgrade using this newly downloaded upgrade script
  As example, from a SSH server:
  ssh username@ssh-sever-name cat /directory-to/BSDRP_0.35_upgrade_i386_serial.img.xz | unxz | /tmp/upgrade-to-035
3 Once done, reboot and answer "no" to the question "Do you want to save your configuration?"

## Installed packages
* NetPIPE-3.7.1       A self-scaling network benchmark
* bird-1.2.5          Dynamic IP routing daemon (IPv4 version)
* bird6-1.2.5         Dynamic IP routing daemon (IPv6 version)
* dlmalloc-2.8.4      Small, fast malloc library by Doug Lea
* expat-2.0.1_1       XML 1.0 parser written in C
* fprobe-1.1_1        Tool that collects network traffic data
* freevrrpd-1.0       This a VRRP RFC2338 Compliant implementation under FreeBSD
* iperf-2.0.5         A tool to measure maximum TCP and UDP bandwidth
* isc-dhcp31-relay-3.1.ESV,1 The ISC Dynamic Host Configuration Protocol relay
* isc-dhcp31-server-3.1.ESV,1 The ISC Dynamic Host Configuration Protocol server
* libevent-1.4.14b_2  Provides an API to execute callback functions on certain ev
* libpdel-0.5.3_4     Packet Design multi-purpose C library for embedded applicat
* mcast-tools-20061214_1 IPv6 multicast routing daemons and tools
* mpd-5.5             Multi-link PPP daemon based on netgraph(4)
* mrouted-3.9_1       Multicast routing daemon providing DVMRP for IPv4
* net-snmp-5.5_4      An extendable SNMP implementation
* quagga-0.99.17_5    Free RIPv1, RIPv2, OSPFv2, BGP4, IS-IS route software
* ssmtp-2.64          Extremely simple MTA to get mail off the system to a mail h
* tmux-1.4_4          A Terminal Multiplexer
* ucarp-1.5.2_1       Userlevel Common Address Redundancy Protocol

-------------------------------------------
# Release 0.34 (2010/09/15)

## New features
* Kernel:
	* Add ipdivert module 
	* Re-enable kbd-mux that permit to use USB keyboard
* Clean the default /etc/rc.conf, put specials BSDRP parameters in /etc/rc.conf.misc 
* Add tmux (terminal multiplexer)
* Add patch that permit to compile net/bird and net/bird6 on sparc64
* Secure quagga VTY by listenning to localhost only (thankt to Nugroho Atmotaruno)
* Updated ports:
	* Bird to 1.2.4
	* Quagga to 0.99.17

## Bug fix
* Fix ipfw module load by adding libalias module 
* Fix ucarp comportement by using carp-up/carp-down script that create an alias for the virtual IP on the master host
* Fix writing ssh keys for root (Thanks to Christian Degen)
* Fix crontab backup (Thanks to Christian Degen)
* Fix the problem of "Device not configured." after an upgrade (using gpart in place of fdisk)
* Fix error message "blanktimevidcontrol: not found" (Thanks to Nugroho Atmotaruno)

## Know bug
* "system endpoint" seams to decrease TCP performance in place of increase them

## Installed packages
* NetPIPE-3.7.1       A self-scaling network benchmark
* bird-1.2.4          Dynamic IP routing daemon (IPv4 version)
* bird6-1.2.4         Dynamic IP routing daemon (IPv6 version)
* dlmalloc-2.8.4      Small, fast malloc library by Doug Lea
* fprobe-1.1_1        Tool that collects network traffic data
* freevrrpd-0.9.3     This a VRRP RFC2338 Compliant implementation under FreeBSD
* iperf-2.0.4         A tool to measure maximum TCP and UDP bandwidth
* isc-dhcp31-relay-3.1.3_1 The ISC Dynamic Host Configuration Protocol relay
* isc-dhcp31-server-3.1.3_1 The ISC Dynamic Host Configuration Protocol server
* libevent-1.4.14b_1  Provides an API to execute callback functions on certain ev
* mcast-tools-20061214 IPv6 multicast routing daemons and tools
* mrouted-3.9_1       Multicast routing daemon providing DVMRP for IPv4
* net-snmp-5.5_4      An extendable SNMP implementation
* quagga-0.99.17      Free RIPv1, RIPv2, OSPFv2, BGP4, IS-IS route software
* ssmtp-2.62.3        Extremely simple MTA to get mail off the system to a mail h
* tmux-1.3            A Terminal Multiplexer
* ucarp-1.5.2_1       Userlevel Common Address Redundancy Protocol

---------------------------------------------------
# Release 0.33 (2010/07/21)

## New features
* Media size needs reduced from 512MB to 256MB (Thanks Warner Losh)
* Based on FreeBSD 8.1-Release
* Security: Reference file available for integrity check (mtree with sha256 and md5 hash)
* Change serial port default speed to 38400 baud (8 bits, no parity, and 1 stop bit)
* Kernel:
	* CPU support: Geode, Soekris, Elan
	* siis drivers (SiliconImage Serial ATA Host Controller)
* Kernel modules added:
	* GRE module (GRE and MOBILE encapsulation)
	* Hifn 7751/7951/7811/7955/7956 crypto accelerator padlock
	  (cryptographic functions and RNG in VIA C3, C7 and Eden processors)
	* safe (SafeNet crypto accelerator)
	* ubsec (SafeNet crypto accelerator)
	* glxsb (i386 only: Geode LX Security Block crypto accelerator)
* Replace dhcprelya by isc-dhcp-relay
* Replace XORP by BIRD (BIRD is more used and lighter)
* Upgraded ports:
	* quagga from quagga-0.99.15_5 to 0.99.16
	* ucarp from 1.5.1 to 1.5.2
* Add isc-dhcp-server: Permit to use BSDRP as a DHCP server
* Add ssmtp: Permit to send mail from BSDRP
* Add some bench tools: iperf and netpipe
* Add IPv6 multicast PIM routing daemons and tools
* Add IPv4 DVMRP (multicast) routing daemon: mrouted
* Add "show tech-support"
* Add multiple VHID support on rc CARP script
* Sysctl: Do not generate core files, enable zerocopy for bpf by default
* Re-enable "system virtualize" for FreeBSD 8.1
  reduce kern.hz in VM (seem that FBSD 8.1 didn't auto-adapt anymore)
* Removed VIM-lite: Ratio size/feature (syntaxe colorization) not enough usefull
* Use UTF-8 for console
* Disable ATA DMA in loader.conf for fixing Soekris boot
* Remove sendmail error message during bootup (thanks Nugroho Atmotaruno)

Related:
* Add a MS Windows VBScript for BSDRP VirtualBox lab:
  http://bsdrp.svn.sourceforge.net/viewvc/bsdrp/trunk/virtualbox.vbs

## Bugs fixes
* Quagga IPv6 address on interface (quagga bug id 408)
* Virtual box lab script: Fix problem with use of serial line terminal emulation (thanks to Baptiste Daroussin)
* Add a delay during boot sequence for permit to boot from USB device (FreeBSD 8.0/8.1 bug: usb/143790)
* Fix RC polling script that display inversed result
* vga consoles are disabled on the serial release (prevent to display getty errors messages)
* Fix upgrade script that can't change the active partition

## Installed packages
* bird-1.2.3, Dynamic IP routing daemon (IPv4 version) 
* bird6-1.2.3, Dynamic IP routing daemon (IPv6 version) 
* dlmalloc-2.8.4, Small, fast malloc library by Doug Lea 
* fprobe-1.1_1, Tool that collects network traffic data 
* freevrrpd-0.9.3, This a VRRP RFC2338 Compliant implementation under FreeBSD 
* iperf-2.0.4, A tool to measure maximum TCP and UDP bandwidth
* isc-dhcp31-relay-3.1.3_1, The ISC Dynamic Host Configuration Protocol relay 
* isc-dhcp31-server-3.1.3_1, The ISC Dynamic Host Configuration Protocol server 
* mcast-tools-20061214, IPv6 multicast routing daemons and tools 
* mrouted-3.9_1, Multicast routing daemon providing DVMRP for IPv4
* NetPIPE-3.7.1, A self-scaling network benchmark
* net-snmp-5.5_3, An extendable SNMP implementation 
* openlldp-0.3.a_1, Link Layer Discovery Protocol daemon 
* quagga-0.99.16, Free RIPv1, RIPv2, OSPFv2, BGP4, IS-IS route software
* ssmtp-2.62.3, Extremely simple MTA to get mail off the system to a mail hub 
* ucarp-1.5.2, Userlevel Common Address Redundancy Protocol 

--------------------------------------------------
# Release 0.32 (2010/02/17)
## New features
* Based on FreeBSD 8.0-Release-p2
* Add tools:
	* "show memory" and "show traffic" options
	* "rvi" , that use RCS revisionning for editing file
	* "config put" / "config get" , permit to send/download config file (SCP)
* Add fprobe (NetFlow probes)
* Add OpenLLDP (Link-Layer Discovery Protocol)
* Add dhcprelya (DHCP relay)
* Disable "system virtualized" tuning tool when detecting FreeBSD 8
* Replace carp in kernel by ucarp (userland carp)
* Add VRRP (using FreeVRRPd)
* Move packet filter from kernel to a module (disable pfsync and pflog)
* Provide Qemu and Virtualbox lab scripts (see http://bsdrp.net for more information)
* Upgrade to Quagga 0.99.15
* Kernel more smaller: Disable audit, MAC, Gjournal
* Increase /var to 10Mb

## Bugs fixes
* Remove vm-check in /root/.cshrc that prevent use of scp
* Serial port no more mandatory for vga release (#2857424)
* Keyboard works under Virtualbox (#2840062)
* nsswitch error messages in /var/log/cron
* Bad xorp default configuration file 

## Know bugs
* Quagga: Can't set IPv6 address on interface (https://bugzilla.quagga.net/show_bug.cgi?id=408)
* Virtualbox lab script: TAB and arrows key didn't works using the serial release (socat problem ?)
* There are lot's of regression in FreeBSD 8.0-Release, will release a new as soon as 8.1-Release
  will be available

-----------------------------------------------------
# Release 0.31 (2009/08/30)

## New features
* Add Virtualbox detection on "system check-vm" (thanks to Baptiste Chaussade)
* Cleanup default /etc/rc.conf
* Remove not impacting sysctl tunning (TCP endpoint related)
* Prevent somes warning message during startup (dumpdev, net-snmp)
* Kernel : enable Packet filter (mandatory for altq), enable ALTQ_NOPPC because kernel use SMP

## Bug fixes
* "system check-vm" tool badly detected allready tuned system 
* make.sh need to be started twice for generating the images (Bug 2843819)
* Adapt nsswitch.conf to BSDRP (WITHOUT_NIS)
* Problem with bad permission on saved configuration directories, that prevent to start Quagga after a reboot (Bug 2843816)
* "system virtualized" hang the system by baddly remount an allready mounted filesystem (Bug 2843819)
* Add bridgestp module (needed for bridge)
* upgrade script doesn't works (#2846985): After using geom debug and boo0cfg, all UFS label are removed, the / is no more useable.

## Know bug
* Keyboard input don't works under VirtualBox (#2840062)

---------------------------------------------------------------
# Release 0.3 (2009/08/16)

## New features
* Downgrade to FreeBSD 7.2 (permit to use it in production environement without waiting for FreeBSD 8.0 stable)
* Add XORP (http://www.xorp.org/): Add VRRP and PIM (with OSPF, BGP, RIP)
* Add ISISd with Quagga
* Enable IPv6 forwarding by default
* Enable carp,lagg,vlan,netgraph,zero_copy_sockets in the kernel
* Cleanup: Remove all non usefull kernel modules, remove perl, gzip kernel, replace vim with vim-lite, remove docs/infos files
* Begin to tune kernel and sysctl values
* Enable device polling for all NIC that support it  and changes kern.HZ from 1000 to 2000
* BSDRP script: Add system tool, and prevent to halt/reboot without saving configuration
* Add warning if running under Qemu without tuning kern.hz is detected
* Build tools:
	* Patch NanoBSD with a proposed patch (http://www.freebsd.org/cgi/query-pr.cgi?pr=136889)
	* Permit to build BSDRP from a FreeBSD 7.2 or 8.0 source base
	* Prevent to rebuild ports for each nanobsd image rebuild
	* Create a qemu script for testing BSDRP
	* Replace questions in the make.sh script by command line options
	* Add auto-cleanup function of unmounted unionfs directory

## Bugs fix
* Fix quagga vty permission: This bug prevent to start quagga after a reboot
* Adapt NanoBSD update script to the new comportement of boot0cfg since FreeBSD 7.2: This bug prevent to boot on the correct
slice after an upgrade.
* Fix TARGET_ARCH variable in make.sh for compiling ports

----------------------------------------------------------------
# Release 0.2 (2009/07/12)

## New features
* Upgrade to FreeBSD 8.0-BETA1
* Removing "ad0" or "da0" dependency using glabel: Big thanks to Scott Ullrich (pfSense) for this tips!
* Reduce the minimum disk size from 1GB to 512MB
* Tune Kernel: Enable MROUTING and ALTQ, MULTIPLE FIB (4), disable flowtable
* Improve/fix bugs in the BSDRP scripts: upgrade and config

-----------------------------------------------------------------
# Release 0.1 (2009/07/04)

First Release that include:
* Base FreeBSD 8.0-CURRENT system (NanoBSD), without VIMAGE support
* Customized script (config, upgrade, help, command completion, etc.)
* Quagga ready to use (OSPFv2, OSPFv3, RIP, RIPng and BGP)
