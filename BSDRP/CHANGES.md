# Release xxx

## Bug fixes
* Reduced periodic log reports noise
* switch back to openvpn and not the openvpn-dev branch

## New features
* replaced vim@tiny by vim@console (brings vimdiff and default plugins)

## To do
* Log file rotation and/or emails:
  * /var/spool/clientmqueue (periodic email)

-------------------------------------------------------------------------------
# Release 1.992 (06/10/2023)

## New features
* Based on FreeBSD 15-head 166a655fcf1 and ports tree 1112795aca0f
* Added ZFS support
* OpenVPN Data Channel offload (kernel module), improving speed
* Added: Open VMware tools for FreeBSD VMware guests

## Upgraded packages
* bgpq4 to 1.11
* bird to 2.13.1
* cpu microcodes to 20230808
* frr to 9.0.1
* iperf to 2.1.9
* iperf3 to 3.15
* strongswan to 5.9.11

## Packages list
* arping 2.21_1: ARP level "ping" utility
* bash 5.2.15: GNU Project's Bourne Again SHell
* bgpq4 1.11: Lightweight prefix-list generator for various routers v4
* bird2-netlink 2.13.1: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.19.1: Asynchronous DNS resolver library
* ca_root_nss 3.93: Root certificate bundle from the Mozilla Project
* cpu-microcode 1.0: Meta-package for CPU microcode updates
* cpu-microcode-amd 20230808: AMD CPU microcode updates
* cpu-microcode-intel 20230808: Intel CPU microcode updates
* cpu-microcode-rc 1.0: RC script for CPU microcode updates
* curl 8.3.0: Command line tool and library for transferring data with URLs
* dhcp6 20080615.2_3: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dtrace-toolkit 1.0_7: Collection of useful scripts for DTrace
* easy-rsa 3.1.6: Small RSA key management package based on openssl
* flashrom 1.3.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.2: RFC 2338 compliant VRRP implementation
* frr9 9.0.1: IP routing protocol suite including BGP, IS-IS, OSPF, BABEL and RIP
* frr9-pythontools 9.0.1: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* fusefs-libs 2.9.9_2: FUSE allows filesystem implementation in userspace
* gettext-runtime 0.22_1: GNU gettext runtime libraries and programs
* glib 2.78.0,2: Some useful routines of C programming (current stable version)
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 202302_1: Process Count Monitor (PCM) for Intel processors
* iperf 2.1.9: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.15: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_3: CLI to manage IPMI systems
* isc-dhcp44-server 4.4.3P1: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.17: JSON (JavaScript Object Notation) implementation in C
* libcdada 0.4.0: Basic data structures in C as libstdc++ wrapper
* libdnet 1.13_4: Simple interface to low level networking routines
* libev 4.33,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.4.4: Foreign Function Interface
* libgcrypt 1.10.2: General purpose cryptographic library based on the code from GnuPG
* libgpg-error 1.47: Common error values for all GnuPG components
* libiconv 1.17: Character set conversion library
* liblz4 1.9.4,1: LZ4 compression library, lossless and very fast
* libmspack 0.11alpha: Library for Microsoft compression formats
* libnet 1.2,1: C library for creating IP packets
* libpci 3.10.0: PCI configuration space I/O made easy
* libpfctl 0.4: Library for interaction with pf(4)
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.10.5: Library implementing the SSH2 protocol
* libucl 0.8.2: Universal configuration library parser
* libunwind 20211201_2: Generic stack unwinding library
* libxml2 2.10.4_1: XML parser library for GNOME
* libyang2 2.1.111: YANG data modeling language library, version 2
* lldpd 1.0.14: LLDP (802.1ab)/CDP/EDP/SONMP/FDP daemon and SNMP subagent
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.33.0: Unix system management and proactive monitoring
* mpd5 5.9_16: Multi-link PPP daemon based on netgraph(4)
* mpdecimal 2.5.1: C/C++ arbitrary precision decimal floating point libraries
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* mtr 0.95_1: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.4.4,1: Plugins for Nagios
* nc 1.0.1_1: Network aware cat
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20210121_1: Network performance benchmarking package
* nrpe 4.1.0: Nagios Remote Plugin Executor
* nstat g20230601,1: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* open-vm-tools-nox11 12.3.0,2: Open VMware tools for FreeBSD VMware guests (without X11)
* openvpn-auth-radius 2.1_4: RADIUS authentication plugin for OpenVPN
* openvpn-devel g20230331,1: Secure IP/Ethernet tunnel daemon
* pciids 20230922: Database of all known IDs used in PCI devices
* pcre 8.45_3: Perl Compatible Regular Expressions library
* pcre2 10.42: Perl Compatible Regular Expressions library, version 2
* perl5 5.34.1_3: Practical Extraction and Report Language
* pimd 2.3.2_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.29.0: Helper library for multiple PKCS#11 providers
* pkg 1.20.7: Package manager
* pkt-gen g2023.04.22: Packet sink/source using the netmap API
* pmacct 1.7.8: Accounting and aggregation tool for IPv4 and IPv6 traffic
* protobuf 3.21.12,1: Data interchange format library
* protobuf-c 1.4.1_1: Code generator and libraries to use Protocol Buffers from pure C
* py39-exabgp4 4.2.21: BGP engine and route injector
* py39-mrtparse 2.0.0: MRT format data parser
* py39-setuptools 63.1.0_1: Python packages installer
* python 3.9_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: Meta-port for the Python interpreter 3.x
* python39 3.9.18: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.2.1: Library for editing command lines as they are typed
* realtek-re-kmod 198.00_3: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.8.0_1: Open-source C implementation of the RPKI/Router Protocol client
* simdjson 3.1.5: Parsing gigabytes of JSON per second
* strongswan 5.9.11_2: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.14p3: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tinc 1.0.36_2: Virtual Private Network (VPN) daemon
* tmux 3.3a_1: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.8.0: UTF-8 processing library
* vim-tiny 9.0.1976: Improved version of the vi editor (tiny flavor)
* wireguard-tools 1.0.20210914_1: Fast, modern and secure VPN Tunnel
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.991 (07/05/2022)

## New features
* Based on FreeBSD 14-head 70b56f4b928 and ports tree b5d231131d6
* New drivers:
  * if_urndis drivers for Android USB tethering
  * net/realtek-re-kmod
  * net/aquantia-atlantic-kmod

## Upgraded packages
* bird to 2.0.10
* bgpq4 to 1.4
* frr to 8.2.2
* iperf3 to 3.11
* monit to 5.32
* strongswan to 5.9.6

## Packages list
* aquantia-atlantic-kmod 0.0.5_1: Aquantia AQtion (Atlantic) Network Driver (Development Preview)
* arping 2.21: ARP level "ping" utility
* bash 5.1.16: GNU Project's Bourne Again SHell
* bgpq4 1.4: Lightweight prefix-list generator for various routers v4
* bird2 2.0.10: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.18.1: Asynchronous DNS resolver library
* ca_root_nss 3.78: Root certificate bundle from the Mozilla Project
* curl 7.84.0: Command line tool and library for transferring data with URLs
* cyrus-sasl 2.1.28: RFC 2222 SASL (Simple Authentication and Security Layer)
* devcpu-data 20220510: AMD and Intel CPUs microcode updates
* devcpu-data-amd 20220414: AMD CPUs microcode updates
* devcpu-data-intel 20220510: Intel CPU microcode updates
* dhcp6 20080615.2_3: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dtrace-toolkit 1.0_6: Collection of useful scripts for DTrace
* easy-rsa 3.1.0_2: Small RSA key management package based on openssl
* flashrom 1.2: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr8 8.2.2: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* frr8-pythontools 8.2.2: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 202112: Process Count Monitor (PCM) for Intel processors
* iperf 2.1.7: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.11: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_3: CLI to manage IPMI systems
* ipsec-tools 0.8.2_12: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.2P1_1: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.16: JSON (JavaScript Object Notation) implementation in C
* libev 4.33,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.4.2: Foreign Function Interface
* libiconv 1.16: Character set conversion library
* liblz4 1.9.3,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.8.0: PCI configuration space I/O made easy
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.9.6: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang2 2.0.194: YANG data modeling language library, version 2
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.32.0: Unix system management and proactive monitoring
* mpd5 5.9_9: Multi-link PPP daemon based on netgraph(4)
* mpdecimal 2.5.1: C/C++ arbitrary precision decimal floating point libraries
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* mtr 0.95: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.4.0,1: Plugins for Nagios
* nc 1.0.1_1: Network aware cat
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* nrpe3 3.2.1: Nagios Remote Plugin Executor
* nstat 1.0_4: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap25-client 2.5.12: Open source LDAP client implementation
* openvpn 2.5.7_1: Secure IP/Ethernet tunnel daemon
* pciids 20220518: Database of all known IDs used in PCI devices
* pcre2 10.40: Perl Compatible Regular Expressions library, version 2
* perl5 5.32.1_1: Practical Extraction and Report Language
* pimd 2.3.2_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.29.0: Helper library for multiple PKCS#11 providers
* pkg 1.18.3: Package manager
* pkt-gen g2022.02.10: Packet sink/source using the netmap API
* pmacct 1.7.7: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py39-exabgp4 4.2.13_2: BGP engine and route injector
* py39-mrtparse 2.0.0: MRT format data parser
* py39-setuptools 62.1.0_1: Python packages installer
* python 3.9_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: Meta-port for the Python interpreter 3.x
* python39 3.9.13: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.1.2: Library for editing command lines as they are typed
* realtek-re-kmod 196.04: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.6.3: Open-source C implementation of the RPKI/Router Protocol client
* strongswan 5.9.6_2: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.11p3: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tinc 1.0.36_2: Virtual Private Network (VPN) daemon
* tmux 3.2a: Terminal Multiplexer
* trafshow 5.2.3_3,1: Full screen visualization of network traffic
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.7.0: UTF-8 processing library
* vim-tiny 9.0.0016: Improved version of the vi editor (tiny flavor)
* wireguard-kmod 0.0.20220615: WireGuard implementation for the FreeBSD kernel
* wireguard-tools 1.0.20210914_1: Fast, modern and secure VPN Tunnel
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.99 (25/05/2021)

## New features
* Based on FreeBSD 14-head 7b8696bf128 and ports tree 98b2a4841162
  * Add DXR routing lookup (IPv4 only)
* added netcat back
* Replaced wireguard-in-kernel by port wireguard-kernel module

## Bug fixes
* Mellanox performance with small packets forwarding
* sudo security

## Upgraded packages
* bird to 2.0.8
* bgpq4 to 0.0.7
* devcpu-data (Intel microcode updates) to 1.38
* iperf to 2.1.1.d
* monit to 5.28
* openvpn to 2.5.2
* python to 3.8
* sudo to 1.9.7

## Packages list
* arping 2.21: ARP level "ping" utility
* bash 5.1.8: GNU Project's Bourne Again SHell
* bgpq4 0.0.7: Lightweight prefix-list generator for various routers v4
* bird2 2.0.8_1: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.63: Root certificate bundle from the Mozilla Project
* curl 7.76.1: Command line tool and library for transferring data with URLs
* devcpu-data 1.38: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_3: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dtrace-toolkit 1.0_6: Collection of useful scripts for DTrace
* easy-rsa 3.0.8: Small RSA key management package based on openssl
* flashrom 1.2: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr7 7.5.1_1: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* frr7-pythontools 7.5.1_1: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 202011: Process Count Monitor (PCM) for Intel processors
* iperf 2.1.1.d_1: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.9: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_3: CLI to manage IPMI systems
* ipsec-tools 0.8.2_11: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.2_1: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.15_1: JSON (JavaScript Object Notation) implementation in C
* libev 4.33,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.3_1: Foreign Function Interface
* libiconv 1.16: Character set conversion library
* liblz4 1.9.3,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.7.0_1: PCI configuration space I/O made easy
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.9.5: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang 1.0.184: YANG data modeling language library
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.28.0: Unix system management and proactive monitoring
* mpd5 5.9: Multi-link PPP daemon based on netgraph(4)
* mpdecimal 2.5.1: C/C++ arbitrary precision decimal floating point libraries
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* mstflint-lite 4.16.0.1: Firmware Burning and Diagnostics Tools for Mellanox devices
* mtr 0.94_1: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.3.3_2,1: Plugins for Nagios
* nc 1.0.1_1: Network aware cat
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* nrpe3 3.2.1: Nagios Remote Plugin Executor
* nstat 1.0_4: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.58: Open source LDAP client implementation
* openvpn 2.5.2_1: Secure IP/Ethernet tunnel daemon
* pciids 20210426: Database of all known IDs used in PCI devices
* pcre 8.44: Perl Compatible Regular Expressions library
* perl5 5.32.1_1: Practical Extraction and Report Language
* pimd 2.3.2_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.16.3: Package manager
* pkt-gen g2019.11.07: Packet sink/source using the netmap API
* pmacct 1.7.5: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py38-exabgp4 4.2.11: BGP engine and route injector
* py38-mrtparse 2.0.0: MRT format data parser
* py38-setuptools 44.0.0_1: Python packages installer
* python 3.8_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python38 3.8.10: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.1.1: Library for editing command lines as they are typed
* rtrlib 0.6.3: Open-source C implementation of the RPKI/Router Protocol client
* strongswan 5.9.2_2: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.7: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tinc 1.0.36_2: Virtual Private Network (VPN) daemon
* tmux 3.2: Terminal Multiplexer
* trafshow 5.2.3_3,1: Full screen visualization of network traffic
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.6.1: UTF-8 processing library
* vim-tiny 8.2.2820: Improved version of the vi editor (vim binary only)
* wireguard-kmod 0.0.20210503: WireGuard implementation for the FreeBSD kernel
* wireguard-tools 1.0.20210424: Fast, modern and secure VPN Tunnel
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.98 (18/01/2021)

## New features
* Switched from FreeBSD 12-stable to FreeBSD 13-head c256048 that brings a lot of cool stufs:
  * Performance improvement
  * Multipath-routing re-introduced
  * DPDK Longest Prefix Match (LPM) modules
  * Wireguard kernel module
  * etc.
* Add Intel QuickAssist Technology (QAT) drivers
* Ports tree updated to r561897

## Bug fixes
* FRR7: Fix https://github.com/FRRouting/frr/issues/6378
* bird2: Fix multi-FIB usage by reverting bird commit 318acb0f6cb77a32aad5d7f79e06f3c5065ac702
* pkt-gen: Fix traffic generation using source and destination range

## New packages
* nc
* trafshow
* tinc
* bgptabledump2bird

## Upgraded packages
* arping 2.21
* bgpq4
* devcpu-data 1.37
* exabgp4 4.2.11
* frr7 7.5
* iperf 2.1.0.r
* iperf3 3.9
* mpd5 5.9
* mrtparse 2.0.0
* mtr 0.94
* openvpn 2.5.0
* strongswan 5.9.1
* wireguard 20201118

## Packages list
* arping 2.21: ARP level "ping" utility
* bash 5.1.4_1: GNU Project's Bourne Again SHell
* bgpq4 0.0.6: Lightweight prefix-list generator for various routers v4
* bird2 2.0.7_2: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.58: Root certificate bundle from the Mozilla Project
* curl 7.74.0: Command line tool and library for transferring data with URLs
* devcpu-data 1.37: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_3: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent. Yandex edition
* dtrace-toolkit 1.0_5: Collection of useful scripts for DTrace
* easy-rsa 3.0.8: Small RSA key management package based on openssl
* flashrom 1.2: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr7 7.5_1: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* frr7-pythontools 7.5_1: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 202011: Process Count Monitor (PCM) for Intel processors
* iperf 2.1.0.r: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.9: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_3: CLI to manage IPMI systems
* ipsec-tools 0.8.2_11: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.2_1: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.15_1: JSON (JavaScript Object Notation) implementation in C
* libev 4.33,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.3_1: Foreign Function Interface
* libiconv 1.16: Character set conversion library
* liblz4 1.9.3,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.7.0_1: PCI configuration space I/O made easy
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.9.5: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang 1.0.184: YANG data modeling language library
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.27.1: Unix system management and proactive monitoring
* mpd5 5.9: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* mstflint-lite 4.15.0.1: Firmware Burning and Diagnostics Tools for Mellanox devices
* mtr-nox11 0.94: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.3.3_2,1: Plugins for Nagios
* nc 1.0.1_1: Network aware cat
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* nrpe3 3.2.1: Nagios Remote Plugin Executor
* nstat 1.0_3: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.56: Open source LDAP client implementation
* openvpn 2.5.0: Secure IP/Ethernet tunnel daemon
* pciids 20201127: Database of all known IDs used in PCI devices
* pcre 8.44: Perl Compatible Regular Expressions library
* perl5 5.32.0_1: Practical Extraction and Report Language
* pimd 2.3.2_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.16.1: Package manager
* pkt-gen g2019.11.07: Packet sink/source using the netmap API
* pmacct 1.7.5: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py37-exabgp4 4.2.11: BGP engine and route injector
* py37-mrtparse 2.0.0: MRT format data parser
* py37-setuptools 44.0.0: Python packages installer
* python 3.7_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python37 3.7.9_1: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.0.4_1: Library for editing command lines as they are typed
* rtrlib 0.6.3: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.9.1: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.5p1: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tinc 1.0.36_2: Virtual Private Network (VPN) daemon
* tmux 3.1c: Terminal Multiplexer
* trafshow 5.2.3_3,1: Full screen visualization of network traffic
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.6.1: UTF-8 processing library
* vim-tiny 8.2.2263_1: Improved version of the vi editor (vim binary only)
* wireguard 1.0.20200827: Fast, modern and secure VPN Tunnel
* wireguard-go 0.0.20201118: WireGuard implementation in Go
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.97 (04/08/2020)

## New feature
* Load of Intel microcodes by default
* Update to 12.1-STABLE r363822

## Bug fixes
* Add Chelsio Ethernet VF driver (if_cxgbev)
* Add missing if_qlxgb.ko for Ethernet QLogic 3200 series
* Correctly disabling ICMP redirect by default

## New packages
* Mellanox Firmware tools (lite version)
* wireguard
* vim-tiny
* mrtparse: MRT format data parser
* nrpe3: nagios client (including nagios-plugins)
* perl: nrpe3's dependency
* bash: wireguard's dependency
* frr7-pythontools: Helper script to help reload frr

## Upgraded packages
* devcpu-data to 1.34 (update Intel microcode to 2019/12/28)
* easy-rsa to 3.0.7
* exabgp to 4.2.7
* FRR to 7.4
* pmacct to 1.7.4
* openvpn to 2.4.9
* strongswan to 5.8.4
* wireguard to 1.0.20200513

## Removed packages
* IPv6 multicast tools (pim6-tools, pim6dd, pim6sd)

## Packages list
* arping 2.19: ARP level "ping" utility
* bash 5.0.18_2: GNU Project's Bourne Again SHell
* bgpq3 0.1.35: Lightweight prefix-list generator for various routers
* bird2 2.0.7_1: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.55: Root certificate bundle from the Mozilla Project
* curl 7.71.1: Command line tool and library for transferring data with URLs
* devcpu-data 1.34: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_2: KAME DHCP6 client, server, and relay
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* dtrace-toolkit 1.0_5: Collection of useful scripts for DTrace
* easy-rsa 3.0.7: Small RSA key management package based on openssl
* flashrom 1.2: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr7 7.4_1: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* frr7-pythontool 7.4_1: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201902_1: Process Count Monitor (PCM) for Intel processors
* iperf 2.0.13: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.8.1: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_2: CLI to manage IPMI systems
* ipsec-tools 0.8.2_11: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.2: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.14: JSON (JavaScript Object Notation) implementation in C
* libev 4.33,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.3: Foreign Function Interface
* libiconv 1.16: Character set conversion library
* liblz4 1.9.2_1,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.7.0: PCI configuration space I/O made easy
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.9.4: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang 1.0.184: YANG data modeling language library
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.27.0: Unix system management and proactive monitoring
* mpd5 5.8_10: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* mstflint-lite 4.14.0.3: Firmware Burning and Diagnostics Tools for Mellanox devices
* mtr-nox11 0.93_1: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.3.3,1: Plugins for Nagios
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* nrpe3 3.2.1: Nagios Remote Plugin Executor
* nstat 1.0_3: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.50: Open source LDAP client implementation
* openvpn 2.4.9_3: Secure IP/Ethernet tunnel daemon
* pciids 20200624: Database of all known IDs used in PCI devices
* pcre 8.44: Perl Compatible Regular Expressions library
* perl5 5.32.0: Practical Extraction and Report Language
* pimd 2.3.2_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.14.6: Package manager
* pkt-gen g2019.11.07: Packet sink/source using the netmap API
* pmacct 1.7.4.p1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py37-exabgp4 4.2.7: BGP engine and route injector
* py37-mrtparse 1.7: MRT format data parser
* py37-setuptools 44.0.0: Python packages installer
* python 3.7_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python37 3.7.8_1: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.0.4: Library for editing command lines as they are typed
* rtrlib 0.6.3: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.8.4_1: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.2: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 3.1b: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.5.0: UTF-8 processing library
* vim-tiny 8.2.1334: Improved version of the vi editor (vim binary only)
* wireguard 1.0.20200513: Fast, modern and secure VPN Tunnel
* wireguard-go 0.0.20200320: WireGuard implementation in Go
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.96 (7/11/2019)

## Bug fix
* mlx5 drivers can't forward packets

## New packages
* iperf2 is back because iperf3 doesn't support multicast

## Packages upgrade
* openvpn to 2.4.8

## Packages list
* arping 2.19: ARP level "ping" utility
* bgpq3 0.1.35: Lightweight prefix-list generator for various routers
* bird2 2.0.7: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.4: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.47: Root certificate bundle from the Mozilla Project
* curl 7.66.0: Command line tool and library for transferring data with URLs
* devcpu-data 1.24: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_2: KAME DHCP6 client, server, and relay
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.6: Small RSA key management package based on openssl
* flashrom 1.1: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr7 7.2: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201902_1: Process Count Monitor (PCM) for Intel processors
* iperf 2.0.13: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.7: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_2: CLI to manage IPMI systems
* ipsec-tools 0.8.2_11: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.1_4: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.13.1_1: JSON (JavaScript Object Notation) implementation in C
* libev 4.24,1: Full-featured and high-performance event loop library
* libevent 2.1.11: API for executing callback functions on events or timeouts
* libffi 3.2.1_3: Foreign Function Interface
* liblz4 1.9.2,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.6.2: PCI configuration space I/O made easy
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.8.6: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang 1.0: YANG data modeling language library
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.26.0: Unix system management and proactive monitoring
* mpd5 5.8_10: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* nstat 1.0_2: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.48: Open source LDAP client implementation
* openvpn 2.4.8: Secure IP/Ethernet tunnel daemon
* pciids 20191012: Database of all known IDs used in PCI devices
* pcre 8.43_2: Perl Compatible Regular Expressions library
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.12.0: Package manager
* pkt-gen g2019.03.01: Packet sink/source using the netmap API
* pmacct 1.7.3: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py36-exabgp 4.1.2: BGP engine and route injector
* py36-setuptools 41.4.0: Python packages installer
* python 3.6_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python36 3.6.9: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.0.0: Library for editing command lines as they are typed
* rtrlib 0.6.3: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.8.1: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.29: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.9a_1: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.4.0: UTF-8 processing library
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.95 (27/10/2019)

## Bug fix
* Mellanox drivers loading (missing mlxfw.ko)

## Packages upgrade
* FRR to 7.2
* bird to 2.0.7

## Packages list
* arping 2.19: ARP level "ping" utility
* bgpq3 0.1.35: Lightweight prefix-list generator for various routers
* bird2 2.0.7: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.4: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.47: Root certificate bundle from the Mozilla Project
* curl 7.66.0: Command line tool and library for transferring data with URLs
* devcpu-data 1.24: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_2: KAME DHCP6 client, server, and relay
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.6: Small RSA key management package based on openssl
* flashrom 1.1: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr7 7.2: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201902_1: Process Count Monitor (PCM) for Intel processors
* iperf3 3.7: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_2: CLI to manage IPMI systems
* ipsec-tools 0.8.2_11: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.1_4: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.13.1_1: JSON (JavaScript Object Notation) implementation in C
* libev 4.24,1: Full-featured and high-performance event loop library
* libevent 2.1.11: API for executing callback functions on events or timeouts
* libffi 3.2.1_3: Foreign Function Interface
* liblz4 1.9.2,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.6.2: PCI configuration space I/O made easy
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.8.6: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang 1.0: YANG data modeling language library
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.26.0: Unix system management and proactive monitoring
* mpd5 5.8_10: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* nstat 1.0_2: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.48: Open source LDAP client implementation
* openvpn 2.4.7: Secure IP/Ethernet tunnel daemon
* pciids 20190725: Database of all known IDs used in PCI devices
* pcre 8.43_2: Perl Compatible Regular Expressions library
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.12.0: Package manager
* pkt-gen g2019.03.01: Packet sink/source using the netmap API
* pmacct 1.7.3: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py36-exabgp 4.1.2: BGP engine and route injector
* py36-setuptools 41.4.0: Python packages installer
* python 3.6_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python36 3.6.9: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.0.0: Library for editing command lines as they are typed
* rtrlib 0.6.3: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.8.1: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.28p1: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.9a_1: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.4.0: UTF-8 processing library
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.94 (14/10/2019)

## Special upgrade notes for installation older than BSDRP 1.93
BSDRP since 1.93 needs at minimum a 2GB disk and no more a 1GB disk.
If you've installed BSDRP on a 1GB disk: You can't upgrade it.
But if you installed it on a 2GB disk (or larger), here is how to resize system slice:
system resize-system-slice 1911680

## New features
* FreeBSD upgraded to 12.1-STABLE r353478
* Added ksym module to be able to use lockstat
* Updated tmpfs /var to 32MB
* Configuration script now check for modifications in file permission/owner too
  thanks to fabrice.bruel@orange.com

## Bug fixes
* Add a lock during firmware upgrade
* On system with partition 2 active, and after failed an upgrade (because system slice
  not expanded before upgrade), upgrade was failing because not able to detect
  the correct system partition

## New package
* nstat 1.0: replacement for bw/netstat/vmstat/pcm-memory.x

## Packages upgrade
* FRR to 7.1
* bird to 2.0.6
* exabgp to 4.1.2
* iperf to 3.7
* pmacct to 1.7.3
* strongswan to 5.8.1
* tmux to 2.9a_1

## Packages list
* arping 2.19: ARP level "ping" utility
* bgpq3 0.1.35: Lightweight prefix-list generator for various routers
* bird2 2.0.6: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.4: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.46.1: Root certificate bundle from the Mozilla Project
* curl 7.66.0: Command line tool and library for transferring data with URLs
* devcpu-data 1.24: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_2: KAME DHCP6 client, server, and relay
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.6: Small RSA key management package based on openssl
* flashrom 1.1: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr7 7.1: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* fswatch-mon 1.13.0_2: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201902_1: Process Count Monitor (PCM) for Intel processors
* iperf3 3.7: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_2: CLI to manage IPMI systems
* ipsec-tools 0.8.2_11: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.1_4: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.13.1_1: JSON (JavaScript Object Notation) implementation in C
* libev 4.24,1: Full-featured and high-performance event loop library
* libevent 2.1.11: API for executing callback functions on events or timeouts
* libffi 3.2.1_3: Foreign Function Interface
* liblz4 1.9.2,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.6.2: PCI configuration space I/O made easy
* libsodium 1.0.18: Library to build higher-level cryptographic tools
* libssh 0.8.6: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang 0.16_6: YANG data modeling language library
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.26.0: Unix system management and proactive monitoring
* mpd5 5.8_10: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* nstat 1.0_2: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.48: Open source LDAP client implementation
* openvpn 2.4.7: Secure IP/Ethernet tunnel daemon
* pciids 20190725: Database of all known IDs used in PCI devices
* pcre 8.43_2: Perl Compatible Regular Expressions library
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.12.0: Package manager
* pkt-gen g2019.03.01: Packet sink/source using the netmap API
* pmacct 1.7.3: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py36-exabgp 4.1.2: BGP engine and route injector
* py36-setuptools 41.2.0: Python packages installer
* python 3.6_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python36 3.6.9: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.0.0: Library for editing command lines as they are typed
* rtrlib 0.6.3: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.8.1: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.27_1: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.9a_1: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.4.0: UTF-8 processing library
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.93 (2019/05/30)

## New features
* New fresh installation needs a minimun of 2GB disk size,
  upgrade images are compliant with 1GB disk
* Moved FRR configuration to use unique integrated config file by default

## Bug fixes
* Disabling RADIX_MPATH (multipath) to fix a kernel panic (rt_notifydelete)

## New package
* netperf 2.7.1

## Upgraded packages
* bird to 2.0.4
* frr to 7.0
* quagga-bgp-netgen to 0.2

## Packages list
* arping 2.19: ARP level "ping" utility
* bgpq3 0.1.35: Lightweight prefix-list generator for various routers
* bird2 2.0.4_1: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.3: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.44: Root certificate bundle from the Mozilla Project
* curl 7.65.0_1: Command line tool and library for transferring data with URLs
* devcpu-data 1.22: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_2: KAME DHCP6 client, server, and relay
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.6: Small RSA key management package based on openssl
* flashrom 1.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr7 7.0: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* fswatch-mon 1.13.0_1: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201902: Process Count Monitor (PCM) for Intel processors
* iperf3 3.6: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_2: CLI to manage IPMI systems
* ipsec-tools 0.8.2_9: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.1_4: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.13.1: JSON (JavaScript Object Notation) implementation in C
* libev 4.24,1: Full-featured and high-performance event loop library
* libevent 2.1.8_3: API for executing callback functions on events or timeouts
* libffi 3.2.1_3: Foreign Function Interface
* liblz4 1.9.1,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.6.2: PCI configuration space I/O made easy
* libsodium 1.0.16: Library to build higher-level cryptographic tools
* libssh 0.8.6: Library implementing the SSH2 protocol
* libucl 0.8.1: Universal configuration library parser
* libyang 0.16_5: YANG data modeling language library
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.25.3: Unix system management and proactive monitoring
* mpd5 5.8_10: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20170921_1: Network performance benchmarking package
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.47: Open source LDAP client implementation
* openvpn 2.4.7: Secure IP/Ethernet tunnel daemon
* pciids 20190418: Database of all known IDs used in PCI devices
* pcre 8.43_1: Perl Compatible Regular Expressions library
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.10.5_5: Package manager
* pkt-gen g2019.03.01: Packet sink/source using the netmap API
* pmacct 1.7.0_1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py36-exabgp 4.0.10: BGP engine and route injector
* py36-setuptools 41.0.0: Python packages installer
* python 3.6_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python36 3.6.8_2: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.0.0: Library for editing command lines as they are typed
* rtrlib 0.5.0: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.7.2_2: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.27_1: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.8_1: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* utf8proc 2.2.0: UTF-8 processing library
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.92 (2019/03/20)

## New features
* FreeBSD upgraded to 12-STALBE r345325 (too lot's of regression with iflib
  based drivers on 12.0)
* AESNI module loaded by default

## Bug fixes
* frr rc script

## New packages
* dhcp6 (KAME DHCP6 client, server, and relay)
* x86info (x86 CPU identification and feature display utility)

## Upgraded packages
* bird to 2.0.3
* exabgp to 4.0.10
* frr to 6.0.2
* iperf to 2.0.13
* strongswan to 5.7.2
* graphpath to 1.2
* monit 5.25.3
* openvpn 2.4.7
* tmux to 2.8

## Packages list
* arping 2.19: ARP level "ping" utility
* bgpq3 0.1.35: Lightweight prefix-list generator for various routers
* bird2 2.0.3: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.2: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.43: Root certificate bundle from the Mozilla Project
* curl 7.64.0_1: Command line tool and library for transferring data with URLs
* devcpu-data 1.21: Intel and AMD CPUs microcode updates
* dhcp6 20080615.2_2: KAME DHCP6 client, server, and relay
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.5_1: Small RSA key management package based on openssl
* flashrom 1.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr6 6.0.2_1: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* fswatch-mon 1.13.0_1: Cross-platform file change monitor
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201710: Process Count Monitor (PCM) for Intel processors
* iperf 2.0.13: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.6: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_1: CLI to manage IPMI systems
* ipsec-tools 0.8.2_7: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.1_3: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.13.1: JSON (JavaScript Object Notation) implementation in C
* libev 4.24,1: Full-featured and high-performance event loop library
* libevent 2.1.8_3: API for executing callback functions on events or timeouts
* libffi 3.2.1_3: Foreign Function Interface
* liblz4 1.8.3,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.6.2: PCI configuration space I/O made easy
* libsodium 1.0.16: Library to build higher-level cryptographic tools
* libssh 0.8.6: Library implementing the SSH2 protocol
* libucl 0.8.0: Universal configuration library parser
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.25.3: Unix system management and proactive monitoring
* mpd5 5.8_10: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.47: Open source LDAP client implementation
* openvpn 2.4.7: Secure IP/Ethernet tunnel daemon
* pciids 20190213: Database of all known IDs used in PCI devices
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.10.5_5: Package manager
* pkt-gen g2017.12.12: Packet sink/source using the netmap API
* pmacct 1.7.0_1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py36-exabgp 4.0.10: BGP engine and route injector
* py36-setuptools 40.8.0: Python packages installer
* python 3.6_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python36 3.6.8: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.1: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 7.0.5: Library for editing command lines as they are typed
* rtrlib 0.5.0: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.7.2_2: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.27_1: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.8: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol
* x86info 1.31.s03: x86 CPU identification and feature display utility

-------------------------------------------------------------------------------
# Release 1.91 (19/08/2018)

## New features
* Base upgraded to FreeBSD 11.2-RELEASE-p2

## Bug fixes
* Fix upgrade script that didn't wait for autosave end
* bsnmpd not showing out octets for vlan interfaces [issue 8](https://github.com/ocochard/BSDRP/issues/8)
* FRR: Fix set metric in route-map [issue 21](https://github.com/ocochard/BSDRP/issues/21)
* VXLAN: add if_vxlan.ko modules [pull request 22](https://github.com/ocochard/BSDRP/pull/22/)

## upgraded packages
* easy-rsa to 3.0.4
* exabgp to 4.0.8
* frr to 5.0
* iperf to 2.0.12
* iperf3 to 3.6
* isc-dhcp-server to 4.4

## Packages list
* arping 2.19: ARP level "ping" utility
* bgpq3 0.1.33: Lightweight prefix-list generator for Cisco and Juniper routers
* bird2 2.0.2_2: Dynamic IP routing daemon
* bsnmp-regex 0.6_2: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.2: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.39: Root certificate bundle from the Mozilla Project
* curl 7.61.0_1: Command line tool and library for transferring data with URLs
* devcpu-data 1.20: Intel and AMD CPUs microcode updates
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.4: Small RSA key management package based on openssl
* flashrom 1.0: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr5 5.0.1_2: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* fswatch-mon 1.11.2_1: Cross-platform file change monitor
* graphpath 1.0: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201710: Process Count Monitor (PCM) for Intel processors
* iperf 2.0.12: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.6: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_1: CLI to manage IPMI systems
* ipsec-tools 0.8.2_5: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp44-server 4.4.1_3: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.13: JSON (JavaScript Object Notation) implementation in C
* libev 4.24,1: Full-featured and high-performance event loop library
* libevent 2.1.8_2: API for executing callback functions on events or timeouts
* libffi 3.2.1_2: Foreign Function Interface
* liblz4 1.8.2,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.6.2: PCI configuration space I/O made easy
* libsodium 1.0.16: Library to build higher-level cryptographic tools
* libssh 0.7.5: Library implementing the SSH1 and SSH2 protocol
* libucl 0.8.0: Universal configuration library parser
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.25.2: Unix system management and proactive monitoring
* mpd5 5.8_7: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.46: Open source LDAP client implementation
* openvpn 2.4.6_2: Secure IP/Ethernet tunnel daemon
* pciids 20180812: Database of all known IDs used in PCI devices
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.10.5_2: Package manager
* pkt-gen g2017.12.12: Packet sink/source using the netmap API
* pmacct 1.7.0: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py36-exabgp 4.0.8: BGP engine and route injector
* py36-setuptools 40.0.0: Python packages installer
* python 3.6_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python36 3.6.6_1: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.1: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 7.0.3_1: Library for editing command lines as they are typed
* rtrlib 0.5.0: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.6.3: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.24: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.7: Terminal Multiplexer
* ucarp 1.5.2.20171201: Userlevel Common Address Redundancy Protocol

-------------------------------------------------------------------------------
# Release 1.90 (01/06/2018)

## New features
* FreeBSD upgraded to 11.2-BETA3
* Yandex (ae@)'s patched: limiting forwarding and ipfw-stateful locking problem (from 5Mpps to 10Mpps on 8 cores Intel Xeon)
* pf code merged from current (from 3Mpps to 5Mpps on 8 cores Intel Xeon)
* Upgraded to bird 2, so previous configuration needs to be adapted!
    cf bird upgrade notes: https://gitlab.labs.nic.cz/labs/bird/wikis/transition-notes-to-bird-2
* Disable HyperThreading by default: This feature doesn't help regarding forwarding performance
* Add qlxgbe (QLogic 8300 series 10 Gigabit) and bnxt (Broadcom NetXtreme-C/NetXtreme-E) NIC drivers

## Removed feature
* pf's ALTQ removed: Performance impact is too huge (-50% on 4core Atom as example)
* Only 64bit images released (32bit "upgrade" images still available, but no "full" 32 bit images)

## Bug fixes
* Images CHS value fixed: An old bug in nanobsd was fixed, now disk image correctly
  uses 63 sectors and 255 heads (in place of 63 sectors and 16 heads)
* Fix loading problem with mlxen (Mellanox) drivers modules (missing Linux modules)
* Fix behavior of ix_affinity and cxgbe_affinity rc script
* Fix tenant script for generating non-conflicting epair MAC addresses
* Fix "config save" that didn't correctly delete no more existing directories neither kept full ownership of new directory
* Fix upgrade script that badly detect already /cfg mounted if jails running

## Security fixes
* Intel microcode update regarding Meltdown and Spectre (sysutils/devcpu-data, enabled by default)

## New package
* bgpq3: Generate prefix-list for bird and FRR
* intel-pcm: Tool for displaying PCM counters and energy usage
* ixl_unlock: Remove SFP restriction on ixl(4) NIC
* rtrlib: RPKI/Router Protocol client
* arping: ARP level "ping" utility

## Updated packages
* bird to 2.0.2
* devcpu-data 1.17
* dhcprelya to 6.1
* exabgp to 4.0.6
* iperf to 2.0.11
* iperf3 to 3.5
* isc-dhcp43-server to 4.3.6
* frr to 3.0.3 (4.0 is not very stable and crashs with tun/gre/gif interfaces)
* monit to 5.25
* openvpn to 2.4.6
* pmacct to 1.7.0
* python to 3.6
* smcroute to 2.4.0
* strongswan to 5.6.3
* sudo to 1.8.21
* tmux to 2.6

## Packages list
* arping 2.19: ARP level "ping" utility
* bgpq3 0.1.33: Lightweight prefix-list generator for Cisco and Juniper routers
* bird2 2.0.2_2: Dynamic IP routing daemon
* bsnmp-regex 0.6_1: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.2: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.37.1: Root certificate bundle from the Mozilla Project
* curl 7.60.0: Command line tool and library for transferring data with URLs
* devcpu-data 1.17: Intel and AMD CPUs microcode updates
* dhcprelya 6.1: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.1_1: Small RSA key management package based on openssl
* flashrom 1.0: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr3 3.0.3: IP routing protocol suite including BGP, IS-IS, OSPF and RIP
* fswatch-mon 1.11.2: Cross-platform file change monitor
* graphpath 1.0: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 201710: Process Count Monitor (PCM) for Intel processors
* iperf 2.0.11: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.5: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_1: CLI to manage IPMI systems
* ipsec-tools 0.8.2_4: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp43-server 4.3.6P1: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.13: JSON (JavaScript Object Notation) implementation in C
* libev 4.24,1: Full-featured and high-performance event loop library
* libevent 2.1.8_1: API for executing callback functions on events or timeouts
* libffi 3.2.1_2: Foreign Function Interface
* liblz4 1.8.2,1: LZ4 compression library, lossless and very fast
* libnet 1.1.6_5,1: C library for creating IP packets
* libpci 3.5.6_1: PCI configuration space I/O made easy
* libsodium 1.0.16: Library to build higher-level cryptographic tools
* libssh 0.7.5: Library implementing the SSH1 and SSH2 protocol
* libucl 0.8.0: Universal configuration library parser
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_2: Multi-link VPN
* monit 5.25.2: Unix system management and proactive monitoring
* mpd5 5.8_3: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8_1: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.46: Open source LDAP client implementation
* openvpn 2.4.6: Secure IP/Ethernet tunnel daemon
* pciids 20180428: Database of all known IDs used in PCI devices
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.10.5_1: Package manager
* pkt-gen g2017.12.12: Packet sink/source using the netmap API
* pmacct 1.7.0: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py36-exabgp 4.0.6: BGP engine and route injector
* py36-setuptools 39.2.0: Python packages installer
* python 3.6_3,2: "meta-port" for the default version of Python interpreter
* python3 3_3: The "meta-port" for version 3 of the Python interpreter
* python36 3.6.5: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.1: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 7.0.3_1: Library for editing command lines as they are typed
* rtrlib 0.5.0: Open-source C implementation of the RPKI/Router Protocol client
* smcroute 2.4.0: Static multicast routing tool
* strongswan 5.6.3: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.23_2: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.7: Terminal Multiplexer
* ucarp 1.5.2_2: Userlevel Common Address Redundancy Protocol

-------------------------------------------------------------------------------
# Release 1.80 (2017-06-30)

## New features
* FreeBSD 11-stable upgraded to r320490 (11.1-PRERELEASE)
* Quagga replaced by it's fork: FRRouting (https://frrouting.org/)
* jail/VIMAGE support added: Allow to create multi-tennant routers/firewall (read tenant help more more detail)
* autosave config daemon (autosave_enable="YES") that watches for changes in /etc and triggers "config save"
* Added chelsio_affinity and ix_affinity rc script
* dtrace modules added
* CPU microcode update enabled
* Strongswan compiled with mediation and GCM AEAD wrapper crypto plugin options
  Mediation feature example here: https://bsdrp.net/documentation/examples/strongswan_ipsec_mediation_feature

## Bug fixes
* Tayga RC script added

## Updated packages
* dhcprelya to 5.0
* iperf3 to 3.1.7
* exabgp to 3.4.19
* monit to 5.23.0
* openvpn to 2.4.3
* strongswan to 5.5.2
* tmux to 2.5

## Known bugs
* Routing multicast (using pimd) on ng interfaces (like PPP links managed by mpd5) can crash the system

## Packages list
* bird 1.6.3_3: Dynamic IP routing daemon (IPv4 version)
* bird6 1.6.3_3: Dynamic IP routing daemon (IPv6 version)
* bsnmp-regex 0.6_1: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.2: bsnmpd module that implements parts of UCD-SNMP-MIB
* ca_root_nss 3.31: Root certificate bundle from the Mozilla Project
* devcpu-data 1.10: Intel and AMD CPUs microcode updates
* dhcprelya 5.0: Lightweight DHCP relay agent. Yandex edition
* easy-rsa 3.0.1_1: Small RSA key management package based on openssl
* exabgp 3.4.19: BGP engine and route injector
* flashrom 0.9.9_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* freevrrpd 1.1_1: RFC 2338 compliant VRRP implementation
* frr 2.0: IP routing protocol suite including BGP, IS-IS, OSPF, PIM, and RIP
* fswatch-mon 1.9.3_1: Cross-platform file change monitor
* indexinfo 0.2.6: Utility to regenerate the GNU info page index
* iperf 2.0.9: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.1.7: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.18_1: CLI to manage IPMI systems
* ipsec-tools 0.8.2_2: KAME racoon IKE daemon, ipsec-tools version
* isc-dhcp43-server 4.3.5: ISC Dynamic Host Configuration Protocol server
* json-c 0.12.1: JSON (JavaScript Object Notation) implementation in C
* libev 4.22,1: Full-featured and high-performance event loop library
* libevent 2.1.8: API for executing callback functions on events or timeouts
* libffi 3.2.1: Foreign Function Interface
* libgcrypt 1.7.7: General purpose crypto library based on code used in GnuPG
* libgpg-error 1.27: Common error values for all GnuPG components
* liblz4 1.7.5,1: LZ4 compression library, lossless and very fast
* libpci 3.5.4: PCI configuration space I/O made easy
* libsodium 1.0.12: Library to build higher-level cryptographic tools
* libucl 0.8.0: Universal configuration library parser
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_1: Multi-link VPN
* monit 5.23.0: Unix system management and proactive monitoring
* mpd5 5.8: Multi-link PPP daemon based on netgraph(4)
* mrouted 3.9.8: Multicast routing daemon providing DVMRP for IPv4
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* openldap-client 2.4.45: Open source LDAP client implementation
* openvpn 2.4.3: Secure IP/Ethernet tunnel daemon
* openvpn-auth-radius 2.1_3: RADIUS authentication plugin for OpenVPN
* pciids 20170525: Database of all known IDs used in PCI devices
* pim6-tools 20061214: IPv6 multicast tools
* pim6dd 0.2.1.0.a.15: IPv6 PIM-DM multicast routing daemon
* pim6sd 2.1.0.a.23: IPv6 PIM-SM and PIM-SSM multicast routing daemon
* pimd 2.3.2: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkg 1.10.1: Package manager
* pmacct 1.6.1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* py27-setuptools 36.0.1: Python packages installer
* python 2.7_3,2: "meta-port" for the default version of Python interpreter
* python2 2_3: The "meta-port" for version 2 of the Python interpreter
* python27 2.7.13_5: Interpreted object-oriented programming language
* readline 7.0.3: Library for editing command lines as they are typed
* smcroute 2.3.1: Static multicast routing tool
* strongswan 5.5.2_1: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.8.20p2_2: Allow others to run commands as root
* tayga 0.9.2: Userland stateless NAT64 daemon
* tmux 2.5: Terminal Multiplexer
* ucarp 1.5.2_2: Userlevel Common Address Redundancy Protocol

-------------------------------------------------------------------------------
# Release 1.70 (2017-01-23)

## Special upgrade notes (installation older than BSDRP 1.60)
BSDRP since 1.60 needs at minimum a 1GB disk and no more a 512MB disk.
If you've installed BSDRP on a 512MB disk: You can't upgrade it.
But if you installed it on a 1GB disk (or larger), here is how to resize system slice:
system resize-system-slice 964000

## New features
* Upgraded to FreeBSD 11.0-STABLE r312663 (skip 11.0 for massive performance improvement)
* Re-Added: netmap-fwd (https://github.com/Netgate/netmap-fwd)
* Add FIBsync patch to netmap-fwd from Zollner Robert <wolfit_ro@yahoo.com>
* netmap pkt-gen supports IPv6, thanks to Andrey V. Elsukov (ae@freebsd.org)

## Updated packages
* bird to 1.6.3 (Large BGP communities)
* exabgp to 3.4.17
* iperf to 2.0.9
* iperf3 to 3.1.5
* ipmitool to 1.8.18
* isc-dhcp43-server to 4.3.5
* monit to 5.20.0
* mrouted to 3.9.8
* openvpn to 2.4.0
* quagga to 1.1
* strongswan to 5.5.1

## package list
* bird-1.6.3
* bird6-1.6.3
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.2
* ca_root_nss-3.28.1
* dhcprelya-4.9_1
* dlmalloc-2.8.6
* easy-rsa-3.0.1_1
* exabgp-3.4.17
* flashrom-0.9.9
* freevrrpd-1.1_1
* indexinfo-0.2.6
* iperf-2.0.9
* iperf3-3.1.5
* ipmitool-1.8.18
* ipsec-tools-0.8.2_1
* isc-dhcp43-server-4.3.5
* libev-4.22,1
* libevent2-2.0.22_1
* libffi-3.2.1
* libgcrypt-1.7.5
* libgpg-error-1.26
* liblz4-131
* libpci-3.5.2
* libsodium-1.0.11_1
* libucl-0.8.0
* lzo2-2.09
* mlvpn-2.3.1_1
* monit-5.20.0
* mpd5-5.8
* mrouted-3.9.8
* netmap-fwd-0.2
* ntraceroute-6.4.2_3
* openldap-client-2.4.44
* openvpn-2.4.0
* openvpn-auth-radius-2.1_3
* pciids-20170108
* pim6-tools-20061214
* pim6dd-0.2.1.0.a.15
* pim6sd-2.1.0.a.23
* pimd-2.3.2
* pimdd-0.2.1.0_2
* pkg-1.9.4_1
* pmacct-0.14.3_3
* py27-setuptools27-32.1.0
* python2-2_3
* python27-2.7.13_1
* quagga-1.1.0_2
* readline-6.3.8
* strongswan-5.5.1
* sudo-1.8.19p2
* tayga-0.9.2
* tmux-2.3
* ucarp-1.5.2_2

-------------------------------------------------------------------------------
# Release 1.60 (08/09/2016)

## New features
* New fresh installation needs 1GB disk size, upgrade still possible on 512MB disks
* Upgraded to FreeBSD 10.3-RELEASE-p2
* Backport shutdown +second option from -head
* Drivers added: sfxge (Solarflare 10Gb Ethernet adapter driver) and if_disc (software discard network interface)
* KTRACE enabled in kernel and kgdb tool included
* Quagga is no more enabled by default
* UTF-8 enabled by default
* New package: ntraceroute (Path MTU discovery, AS lookup)
* amdtemp drivers backported from 11.0: Allow to monitor PC Engines APU2

## Bug fix
* Disable fastforwarding too soon (tryforward is not in 10.3): Re-enable it
* Re-add netmap-ipfw
* Add a pf with fragmentation timeout fix
  source: https://lists.freebsd.org/pipermail/freebsd-pf/2016-May/008044.html
* Disable net.bpf.zerocopy_enable: It created problem with tcpdump on 10.3
* Fix dhcprelya CPU usage
* Fix pf-scrub on bridge (FreeBSD's PR 185633)

## Updated packages
* bird to 1.6.0
* exabgp to 3.4.16
* iperf to 3.1.3
* isc-dhcp43-server to 4.3.4
* monit to 5.19
* openvpn to 3.12
* strongswan to 5.5

## package list
* bird-1.6.0_1
* bird6-1.6.0_1
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.2
* ca_root_nss-3.26
* dhcprelya-4.9_1
* dlmalloc-2.8.6
* dma-0.11_1,1
* easy-rsa-3.0.1_1
* exabgp-3.4.16
* flashrom-0.9.9
* freevrrpd-1.1_1
* indexinfo-0.2.4
* iperf-2.0.5
* iperf3-3.1.3
* ipmitool-1.8.17_1
* ipsec-tools-0.8.2_1
* isc-dhcp43-server-4.3.4
* libev-4.22,1
* libevent2-2.0.22_1
* libffi-3.2.1
* libgcrypt-1.7.3
* libgpg-error-1.24
* libpci-3.5.1
* libsodium-1.0.10
* lzo2-2.09
* mlvpn-2.3.1_1
* monit-5.19.0
* mpd5-5.8
* mrouted-3.9.7_1
* ntraceroute-6.4.2_2
* openldap-client-2.4.44
* openvpn-2.3.12_1
* openvpn-auth-radius-2.1_3
* pciids-20160621
* pim6-tools-20061214
* pim6dd-0.2.1.0.a.15
* pim6sd-2.1.0.a.23
* pimd-2.3.2
* pimdd-0.2.1.0_2
* pkg-1.8.7_1
* pmacct-0.14.3_3
* py27-setuptools27-23.1.0
* python2-2_3
* python27-2.7.12
* quagga-1.0.20160315
* readline-6.3.8
* strongswan-5.5.0
* sudo-1.8.17p1
* tayga-0.9.2
* tmux-2.2_1
* ucarp-1.5.2_2

-------------------------------------------------------------------------------

# Release 1.59 (21/04/2016)

## New features
* Upgraded to FreeBSD 10.3-RELEASE
* New package: mlvpn (aggregated network links in order to benefit from
  the bandwidth of multiple links)

## Updated packages
* bsnmp-ucd to 0.4.2
* dma to 0.11
* dmidecode to 3.0
* exabgp to 3.4.15
* iperf3 to 3.1.2
* monit to 5.17
* mpd5 to 5.8
* openvpn to 2.3.10
* python to 2.7.11
* quagga to 1.0.20160315
* strongswan to 5.4.0

## package list
* bird-1.5.0_1
* bird6-1.5.0_1
* bsnmp-regex-0.6_1
* bsnmp-ucd-0.4.2
* ca_root_nss-3.22.2
* dhcprelya-4.9
* dlmalloc-2.8.6
* dma-0.11,1
* easy-rsa-3.0.1_1
* exabgp-3.4.15
* flashrom-0.9.9
* freevrrpd-1.1_1
* indexinfo-0.2.4
* iperf-2.0.5
* iperf3-3.1.2
* ipmitool-1.8.15_1
* ipsec-tools-0.8.2_1
* isc-dhcp43-server-4.3.3P1_1
* libev-4.20,1
* libevent2-2.0.22_1
* libffi-3.2.1
* libgcrypt-1.6.5_1
* libgpg-error-1.21
* libpci-3.4.1
* libsodium-1.0.8
* lzo2-2.09
* mlvpn-2.3.1
* monit-5.17.1
* mpd5-5.8
* mrouted-3.9.7_1
* openldap-client-2.4.44
* openvpn-2.3.10_2
* openvpn-auth-radius-2.1_3
* pciids-20160412
* pim6-tools-20061214
* pim6dd-0.2.1.0.a.15
* pim6sd-2.1.0.a.23
* pimd-2.3.2
* pimdd-0.2.1.0_2
* pkg-1.7.2
* pmacct-0.14.3_3
* py27-setuptools27-20.0
* python2-2_3
* python27-2.7.11_1
* quagga-1.0.20160315
* readline-6.3.8
* strongswan-5.4.0
* sudo-1.8.16
* tayga-0.9.2
* tmux-2.1_1
* ucarp-1.5.2_2

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

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
