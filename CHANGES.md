# Release 2.1 (2026/03/13)

## New features
- Latest changes from FreeBSD main and ports at 2026/03/13
- Add cloud-init support
- Fix VRRP preemption
- Fix missing USB drivers for tethering
- Had to remove vpp (build issue due to latest dpdk)

## FreeBSD notable network stack changes introduced

### CARP
- carp: fix global demotion counter to VRRP advertisements
- carp6: revise the generation of ND6 NA

### PF / pfsync
- Introduce source and state limiters (configurable action on limiter exceeded, default block)
- NAT64: fix min-ttl/set-tos, handle TTL expired, fix nat-to/rdr-to on in/out rules
- IPv6 divert: pass v6 packets to divert socket, handle divert packets
- pfctl: change default limiter action from no-match to block
- Fix SCTP panic, pfsync incorrect unlock, rule/state/interface counters
- Fix endpoint-independent crash, udp_mapping cleanup, ICMP divert state handling
- Fix natpass, no rdr, pcounters array size, off-by-one in getcreators

### IPFW
- Add support for masked IP-address lookups
- Create BPF tap points for every log rule, ipfw0/ipfwlog0 without ifnet(9)

### IPv6 / NDP / ICMPv6
- net.inet6.ip6.use_stableaddr is switched to on by default
- NDP: Add support for Gratuitous Neighbor Discovery (GRAND)
- NDP: implement delayed anycast and proxy NA
- Fix ICMPv6 csum_flags on mbuf reuse

### Interfaces: ifconfig, iflib, lagg, vlan, epair, ovpn, vxlan
- iflib: SIOCGIFDOWNREASON ioctl support; tx desc reclaim threshold; KTLS offload support
- lagg: locking fix on start; LACP port map sorted by ifindex
- epair: add VLAN_HWTAGGING support
- vlan: fix panic on interface removal
- if_ovpn: add interface counters
- if_vxlan: fix byteorder of source port

## Upgraded packages
* lldpd-tiny 1.0.19_1: replaces lldpd full flavor (smaller footprint)
* bash: 5.3.3 -> 5.3.9
* bgpq4: 1.12 -> 1.14
* bird2: 2.17.2 -> 2.18
* brotli: 1.1.0 -> 1.2.0
* cpu-microcode-amd: 20250729 -> 20251202
* cpu-microcode-intel: 20250812 -> 20260227
* dmidecode: 3.6 -> 3.7
* dnsmasq: 2.91 -> 2.92
* easy-rsa: 3.2.4 -> 3.2.5
* frr10: 10.4.1 -> 10.5.2
* iperf3: 3.19.1 -> 3.20
* mstflint: 4.33.0.1 -> 4.35.0.1
* open-vm-kmod: 12.5.2 -> 13.0.10
* open-vm-tools-nox11: 12.5.2 -> 13.0.10
* openvpn: 2.6.15 -> 2.6.19
* pkt-gen: g2024.09.16 -> g2025.10.08
* python311: 3.11.13 -> 3.11.15
* realtek-re-kmod: 1100.00 -> 1101.00
* strongswan: 6.0.1 -> 6.0.4
* tayga: 0.9.5 -> 0.9.6
* wireguard-tools: 1.0.20210914 -> 1.0.20250521

## Packages list
* abseil 20250127.1_1: Abseil Common Libraries (C++)
* arping 2.25: ARP level "ping" utility
* bash 5.3.9: GNU Project's Bourne Again SHell
* bgpq4 1.14: Lightweight prefix-list generator for various routers v4
* bird2 2.18: Dynamic IP routing daemon
* brotli 1.2.0,1: Generic-purpose lossless compression algorithm
* bsnmp-regex 0.6_4: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5_1: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.34.6: Asynchronous DNS resolver library
* cpu-microcode 1.0_1: Meta-package for CPU microcode updates
* cpu-microcode-amd 20251202: AMD CPU microcode updates
* cpu-microcode-intel 20260227: Intel CPU microcode updates
* cpu-microcode-rc 1.0_2: RC script for CPU microcode updates
* curl 8.17.0: Command line tool and library for transferring data with URLs
* dhcp6 20080615.2_4: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dmidecode 3.7: Tool for dumping DMI (SMBIOS) contents in human-readable format
* dnsmasq 2.92_2,1: Lightweight DNS forwarder, DHCP, and TFTP server
* dtrace-toolkit 1.0_11: Collection of useful scripts for DTrace
* easy-rsa 3.2.5_1,1: Small RSA key management package based on openssl
* expat 2.7.4: XML 1.0 parser written in C
* flashrom 1.6.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* frr10 10.5.2: IP routing protocol suite
* frr10-pythontools 10.5.2: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_3: Cross-platform file change monitor
* fusefs-libs 2.9.9_2: FUSE allows filesystem implementation in userspace
* gettext-runtime 0.26: GNU gettext runtime libraries and programs
* glib 2.84.4,2: Some useful routines of C programming (current stable version)
* gmp 6.3.0: Free library for arbitrary precision arithmetic
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1_1: Utility to regenerate the GNU info page index
* intel-pcm 202405_5: Process Count Monitor (PCM) for Intel processors
* iperf 2.2.1: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.20_1: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.19_3: CLI to manage IPMI systems
* isc-dhcp44-server 4.4.3P1_2: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.18: JSON (JavaScript Object Notation) implementation in C
* jsoncpp 1.9.6_1: JSON reader and writer library for C++
* ksh 1.0.10: ksh93u+m is the renewed development of ksh93 based on AT&T ksh93u+m (stable)
* libcdada 0.5.2: Basic data structures in C as libstdc++ wrapper
* libdnet 1.13_5: Simple interface to low level networking routines
* libedit 3.1.20251016_1,1: Command line editor library
* libev 4.33_1,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.5.1: Foreign Function Interface
* libgcrypt 1.12.0_1: General purpose cryptographic library based on the code from GnuPG
* libgpg-error 1.59: Common error values for all GnuPG components
* libiconv 1.18_1: Character set conversion library
* libidn2 2.3.8: Implementation of IDNA2008 internationalized domain names
* liblz4 1.10.0_2,1: LZ4 compression library, lossless and very fast
* libnet 1.3,1: C library for creating IP packets
* libpci 3.14.0: PCI configuration space I/O made easy
* libpfctl 0.17: Library for interaction with pf(4)
* libsodium 1.0.21: Library to build higher-level cryptographic tools
* libssh 0.11.4: Library implementing the SSH2 protocol
* libucl 0.9.4: Universal configuration library parser
* libunistring 1.4.2: Unicode string library
* libunwind 20250904: Generic stack unwinding library
* libxml2 2.15.2: XML parser library for GNOME
* libyang2 2.1.128: YANG data modeling language library, version 2
* lldpd-tiny 1.0.19_1: Link-Layer Discovery Protocol (LLDP 802.1ab) daemon
* lua53 5.3.6_1: Powerful, efficient, lightweight, embeddable scripting language
* lua54 5.4.8: Powerful, efficient, lightweight, embeddable scripting language
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_5: Multi-link VPN
* monit 5.35.2: Unix system management and proactive monitoring
* mpd5 5.9_18: Multi-link PPP daemon based on netgraph(4)
* mpdecimal 4.0.1: C/C++ arbitrary precision decimal floating point libraries
* mrouted 3.9.8_2: Multicast routing daemon providing DVMRP for IPv4
* mstflint 4.35.0.1: Firmware Burning and Diagnostics Tools for Mellanox devices
* mtr-nox11 0.96: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.4.4_1,1: Plugins for Nagios
* nc 1.0.1_2: Network aware cat
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20210121_2: Network performance benchmarking package
* nettle 3.10.2: Low-level cryptographic library
* nrpe 4.1.3: Nagios Remote Plugin Executor
* nstat g20250705,1: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* open-vm-kmod 13.0.10.1600013,2: Open VMware kernel modules for FreeBSD VMware guests
* open-vm-tools-nox11 13.0.10,2: Open VMware tools for FreeBSD VMware guests (without X11)
* openvpn 2.6.19: Secure IP/Ethernet tunnel daemon
* openvpn-auth-radius 2.1_4: RADIUS authentication plugin for OpenVPN
* pciids 20260309: Database of all known IDs used in PCI devices
* pcre2 10.47_1: Perl Compatible Regular Expressions library, version 2
* perl5 5.42.1: Practical Extraction and Report Language
* perl5.40 5.40.3_2: Practical Extraction and Report Language
* pimd 2.3.2b_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.31.0: Helper library for multiple PKCS#11 providers
* pkg 2.6.2: Package manager
* pkt-gen g2025.10.08: Packet sink/source and bandwidth/delay emulator using the netmap API
* pmacct 1.7.8_1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* protobuf 29.6,1: Data interchange format library
* protobuf-c 1.5.1_3: Code generator and libraries to use Protocol Buffers from pure C
* py311-exabgp4 4.2.22_1: BGP engine and route injector
* py311-mrtparse 2.0.0_1: MRT format data parser
* py311-packaging 26.0: Core utilities for Python packages
* py311-setuptools 63.1.0_3: Python packages installer
* python 3.11_3,2: "meta-port" for the default version of Python interpreter
* python3 3_4: Meta-port for the Python interpreter 3.x
* python311 3.11.15: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.3.3: Library for editing command lines as they are typed
* realtek-re-kmod 1101.00.1600013: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.8.0_1: Open-source C implementation of the RPKI/Router Protocol client
* simdjson 4.3.1: Parsing gigabytes of JSON per second
* strongswan 6.0.4: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.17p2_2: Allow others to run commands as root
* tayga 0.9.6: Userland stateless NAT64 daemon
* tinc 1.0.36_3: Virtual Private Network (VPN) daemon
* tmux 3.6a: Terminal Multiplexer
* vim 9.2.0140: Improved version of the vi editor (console flavor)
* wireguard-tools 1.0.20250521_1: Fast, modern and secure VPN Tunnel
* xxd 9.2.0140: Hexdump and reverse hexdump utility from vim distribution
* zstd 1.5.7_1: Fast real-time compression algorithm
