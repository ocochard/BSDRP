# Release 2.2 (2026/05/21)

## New features
- Latest changes from FreeBSD main and ports at 2026/05/21
- Added  geom_mirror kernel module

## Fixes
- `expand_data_slice()`: replace hardcoded `ada0` with `boot_dev`
- post-upgrade script: unquote `DEBUG_PROPAGATE` so the variable is
  expanded correctly

## FreeBSD notable network stack changes introduced

### PF / pfsync
- Restrict pf netlink operations and flag changes when securelevel is set
- pfsync: reject invalid SCTP states
- Improve SCTP and ASCONF chunk validation
- Fix duplicate-rule detection for automatic tables; always warn on duplicates
- Fix hashing of IP address ranges; include all elements when hashing rules

### IPFW / dummynet
- Treat IPv6 address with zero mask as any
- Fix IPv6 flow-label matching

### IPv6 / NDP / ICMPv6
- nd6: add support for Route Information Option (RFC 4191)
- nd6: ignore entire PI if it violates RFC 4862 section 5.5.3
- nd6: fix delayed NA for proxy addresses
- ndp: accept multiple queued ND for non-GRAND NAs
- ndp: don't send unsolicited NA for multicast address
- ecn(9): update tunneling functions to RFC 6040
- ip6_mroute: FIBify; handle interface detach events; VNETify counters

### Interfaces
- New if_geneve(4) driver implementing Geneve (RFC 8926)
- lacp: fix link state with multiple aggregators
- rss_config: option to enable RSS UDP hashing

### Routing / netlink / FIB / netgraph
- Routing: add support for metric
- Make ip_tryforward() FIB-aware for local traffic

## Upgraded packages
* bgpq4: 1.14 -> 1.16
* bird2: 2.18 -> 2.18.1_1
* cpu-microcode-intel: 20260227 -> 20260512
* curl: 8.17.0 -> 8.20.0
* easy-rsa: 3.2.5_1 -> 3.2.6
* expat: 2.7.4 -> 2.8.1
* frr10: 10.5.2 -> 10.6.1
* gettext-runtime: 0.26 -> 1.0_1
* glib: 2.84.4 -> 2.86.4
* iperf3: 3.20_1 -> 3.21
* libgcrypt: 1.12.0_1 -> 1.12.2
* libgpg-error: 1.59 -> 1.61
* libpci: 3.14.0 -> 3.15.0
* libssh: 0.11.4 -> 0.12.0_1
* libxml2: 2.15.2 -> 2.15.3
* libyang2 2.1.128 -> libyang3 3.13.6
* lldpd-tiny: 1.0.19_1 -> 1.0.21
* mstflint: 4.35.0.1 -> 4.36.0.1
* openvpn: 2.6.19 -> 2.7.4
* perl5: 5.42.1 -> 5.42.2
* pkg: 2.6.2 -> 2.7.5
* simdjson: 4.3.1 -> 4.6.4
* strongswan: 6.0.4 -> 6.0.6
* tinc: 1.0.36_3 -> 1.0.37
* tmux: 3.6a -> 3.6b_1
* vim/xxd: 9.2.0140 -> 9.2.0461

## Removed packages
* perl5.40 (5.40.4): legacy pin removed; the ports default `perl5` (5.42)
  pulled in by dtrace-toolkit and nagios-plugins is sufficient, and shipping
  both interpreters wasted ~30 MiB on the image

## Packages list
* abseil 20250127.1_1: Abseil Common Libraries (C++)
* arping 2.25: ARP level "ping" utility
* bash 5.3.9: GNU Project's Bourne Again SHell
* bgpq4 1.16: Lightweight prefix-list generator for various routers v4
* bird2 2.18.1_1: Dynamic IP routing daemon
* brotli 1.2.0,1: Generic-purpose lossless compression algorithm
* bsnmp-regex 0.6_4: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5_1: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.34.6: Asynchronous DNS resolver library
* cpu-microcode 1.0_1: Meta-package for CPU microcode updates
* cpu-microcode-amd 20251202: AMD CPU microcode updates
* cpu-microcode-intel 20260512: Intel CPU microcode updates
* cpu-microcode-rc 1.0_2: RC script for CPU microcode updates
* curl 8.20.0: Command line tool and library for transferring data with URLs
* dhcp6 20080615.2_4: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dmidecode 3.7: Tool for dumping DMI (SMBIOS) contents in human-readable format
* dnsmasq 2.92rel2,1: Lightweight DNS forwarder, DHCP, and TFTP server
* dtrace-toolkit 1.0_11: Collection of useful scripts for DTrace
* easy-rsa 3.2.6,1: Small RSA key management package based on openssl
* expat 2.8.1: XML 1.0 parser written in C
* flashrom 1.6.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* frr10 10.6.1: IP routing protocol suite
* frr10-pythontools 10.6.1: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_3: Cross-platform file change monitor
* fusefs-libs 2.9.9_2: FUSE allows filesystem implementation in userspace
* gettext-runtime 1.0_1: GNU gettext runtime libraries and programs
* glib 2.86.4,2: Some useful routines of C programming (current stable version)
* gmp 6.3.0: Free library for arbitrary precision arithmetic
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1_1: Utility to regenerate the GNU info page index
* intel-pcm 202405_8: Process Count Monitor (PCM) for Intel processors
* iperf 2.2.1: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.21: Improved tool to measure TCP and UDP bandwidth
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
* libgcrypt 1.12.2: General purpose cryptographic library based on the code from GnuPG
* libgpg-error 1.61: Common error values for all GnuPG components
* libiconv 1.18_1: Character set conversion library
* libidn2 2.3.8: Implementation of IDNA2008 internationalized domain names
* liblz4 1.10.0_2,1: LZ4 compression library, lossless and very fast
* libnet 1.3,1: C library for creating IP packets
* libpci 3.15.0: PCI configuration space I/O made easy
* libpfctl 0.17: Library for interaction with pf(4)
* libsodium 1.0.21: Library to build higher-level cryptographic tools
* libssh 0.12.0_1: Library implementing the SSH2 protocol
* libucl 0.9.4: Universal configuration library parser
* libunistring 1.4.2: Unicode string library
* libunwind 20250904: Generic stack unwinding library
* libxml2 2.15.3: XML parser library for GNOME
* libyang3 3.13.6: YANG data modeling language library, version 3
* lldpd-tiny 1.0.21: Link-Layer Discovery Protocol (LLDP 802.1ab) daemon
* lua53 5.3.6_1: Powerful, efficient, lightweight, embeddable scripting language
* lua54 5.4.8: Powerful, efficient, lightweight, embeddable scripting language
* lzo2 2.10_2: Portable speedy, lossless data compression library
* mlvpn 2.3.1_5: Multi-link VPN
* monit 5.35.2: Unix system management and proactive monitoring
* mpd5 5.9_18: Multi-link PPP daemon based on netgraph(4)
* mpdecimal 4.0.1: C/C++ arbitrary precision decimal floating point libraries
* mrouted 3.9.8_2: Multicast routing daemon providing DVMRP for IPv4
* mstflint 4.36.0.1: Firmware Burning and Diagnostics Tools for Mellanox devices
* mtr-nox11 0.96: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.4.4_1,1: Plugins for Nagios
* nc 1.0.1_2: Network aware cat
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20210121_2: Network performance benchmarking package
* nettle 3.10.2: Low-level cryptographic library
* nrpe 4.1.3: Nagios Remote Plugin Executor
* nstat g20250705,1: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* open-vm-kmod 13.0.10.1600018,2: Open VMware kernel modules for FreeBSD VMware guests
* open-vm-tools-nox11 13.0.10,2: Open VMware tools for FreeBSD VMware guests (without X11)
* openvpn 2.7.4: Secure IP/Ethernet tunnel daemon
* openvpn-auth-radius 2.1_4: RADIUS authentication plugin for OpenVPN
* pciids 20260514: Database of all known IDs used in PCI devices
* pcre2 10.47_1: Perl Compatible Regular Expressions library, version 2
* perl5 5.42.2: Practical Extraction and Report Language
* pimd 2.3.2b_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.31.0: Helper library for multiple PKCS#11 providers
* pkg 2.7.5: Package manager
* pkt-gen g2025.10.08: Packet sink/source and bandwidth/delay emulator using the netmap API
* pmacct 1.7.8_1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* protobuf 29.6,1: Data interchange format library
* protobuf-c 1.5.1_4: Code generator and libraries to use Protocol Buffers from pure C
* py311-exabgp4 4.2.22_1: BGP engine and route injector
* py311-mrtparse 2.0.0_1: MRT format data parser
* py311-packaging 26.2: Core utilities for Python packages
* py311-setuptools 63.1.0_3: Python packages installer
* python311 3.11.15_2: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.3.3: Library for editing command lines as they are typed
* realtek-re-kmod 1101.00.1600018: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.8.0_1: Open-source C implementation of the RPKI/Router Protocol client
* simdjson 4.6.4: Parsing gigabytes of JSON per second
* strongswan 6.0.6: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.17p2_2: Allow others to run commands as root
* tayga 0.9.6: Userland stateless NAT64 daemon
* tinc 1.0.37: Virtual Private Network (VPN) daemon
* tmux 3.6b_1: Terminal Multiplexer
* vim 9.2.0461: Improved version of the vi editor (console flavor)
* wireguard-tools 1.0.20250521_1: Fast, modern and secure VPN Tunnel
* xxd 9.2.0461: Hexdump and reverse hexdump utility from vim distribution
* zstd 1.5.7_1: Fast real-time compression algorithm

