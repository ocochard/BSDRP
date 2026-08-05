# Release 2.3 (2026/08/05)

## New features
- Latest changes from FreeBSD main and ports at 2026/08/05
- bird2 to bird3 (major version upgrade)
- Add lab-reinstall-test: remote reinstall via RAM-boot + ssh|dd
- Replace gpartfix rc script with stock growfs
- Ship additional USB and serial kernel modules
- jail tenant tool: add -l flag to list configured jails
- Python 3.11 to 3.12; ExaBGP and related tools rebuilt on Python 3.12
- New port: intel-nvmupdate-100g (Intel 100G NVM update utility)

## Fixes
- config save: validate rc.conf before persisting
- config save: exclude ssh agent socket directories from saved config
- Add extra delay to reliably detect the UFS label at boot
- jail tenant tool: harden against edge cases in cleanup and ID derivation
- jail tenant tool: recover gracefully from orphan configs on delete
- jail tenant tool: fix broken grep pattern for interface duplicate check
- jail tenant tool: trap-based cleanup on partial jail creation failure
- jail tenant tool: derive next jail ID from configs, avoid jail.lastid single point of failure

## Upgraded packages
* bird: 2 -> 3.3.2
* cpu-microcode-intel: 20260512 -> 20260512_1
* dnsmasq: 2.92rel2,1 -> 2.93,1
* frr10: 10.6.1 -> 10.7.0
* frr10-pythontools: 10.6.1 -> 10.7.0
* fswatch-mon: 1.13.0_3 -> 1.20.1
* monit: 5.35.2 -> 6.0.0
* mpd5: 5.9_18 -> 5.9_19
* open-vm-kmod: 13.0.10.1600018,2 -> 13.1.0.1600019,2
* open-vm-tools-nox11: 13.0.10,2 -> 13.1.0,2
* openvpn: 2.7.4 -> 2.7.5_1
* realtek-re-kmod: 1101.00.1600018 -> 1102.01.1600019_1
* strongswan: 6.0.6 -> 6.0.7
* wireguard-tools: 1.0.20250521_1 -> 1.0.20260223

## Removed packages
- None (bird2, python311 and py311-* were upgraded/renamed, not dropped)

## Packages list
* abseil 20250127.1_1: Abseil Common Libraries (C++)
* arping 2.25: ARP level "ping" utility
* bash 5.3.15: GNU Project's Bourne Again SHell
* bgpq4 1.16: Lightweight prefix-list generator for various routers v4
* bird3 3.3.2: Dynamic multithreaded IP routing daemon
* brotli 1.2.0,1: Generic-purpose lossless compression algorithm
* bsnmp-regex 0.6_4: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5_1: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.34.8: Asynchronous DNS resolver library
* cpu-microcode 1.0_1: Meta-package for CPU microcode updates
* cpu-microcode-amd 20251202: AMD CPU microcode updates
* cpu-microcode-intel 20260512_1: Intel CPU microcode updates
* cpu-microcode-rc 1.0_2: RC script for CPU microcode updates
* curl 8.21.0: Command line tool and library for transferring data with URLs
* dhcp6 20080615.2_4: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dmidecode 3.7: Tool for dumping DMI (SMBIOS) contents in human-readable format
* dnsmasq 2.93,1: Lightweight DNS forwarder, DHCP, and TFTP server
* dtrace-toolkit 1.0_11: Collection of useful scripts for DTrace
* easy-rsa 3.2.6,1: Small RSA key management package based on openssl
* expat 2.8.2: XML 1.0 parser written in C
* flashrom 1.6.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* frr10 10.7.0: IP routing protocol suite
* frr10-pythontools 10.7.0: Provide configuration reload functionality for FRR
* fswatch-mon 1.20.1: Cross-platform file change monitor
* fusefs-libs 2.9.9_2: FUSE allows filesystem implementation in userspace
* gettext-runtime 1.0_1: GNU gettext runtime libraries and programs
* glib 2.86.4,2: Some useful routines of C programming (current stable version)
* gmp 6.3.0: Free library for arbitrary precision arithmetic
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1_1: Utility to regenerate the GNU info page index
* intel-nvmupdate-100g 4.30: NVM Update Utility for Intel(R) 100G Ethernet Adapters
* intel-pcm 202405_8: Process Count Monitor (PCM) for Intel processors
* iperf 2.2.1: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.21: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.19_3: CLI to manage IPMI systems
* isc-dhcp44-server 4.4.3P1_2: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.19: JSON (JavaScript Object Notation) implementation in C
* jsoncpp 1.9.6_1: JSON reader and writer library for C++
* ksh 1.0.10: ksh93u+m is the renewed development of ksh93 based on AT&T ksh93u+m (stable)
* libcdada 0.5.2: Basic data structures in C as libstdc++ wrapper
* libdnet 1.13_5: Simple interface to low level networking routines
* libedit 3.1.20260512,1: Command line editor library
* libev 4.33_1,1: Full-featured and high-performance event loop library
* libevent 2.1.13: API for executing callback functions on events or timeouts
* libffi 3.7.1: Foreign Function Interface
* libgcrypt 1.12.2: General purpose cryptographic library based on the code from GnuPG
* libgpg-error 1.61: Common error values for all GnuPG components
* libiconv 1.18_1: Character set conversion library
* libidn2 2.3.8: Implementation of IDNA2008 internationalized domain names
* liblz4 1.10.0_2,1: LZ4 compression library, lossless and very fast
* libnet 1.3,1: C library for creating IP packets
* libpci 3.15.0: PCI configuration space I/O made easy
* libpfctl 0.17: Library for interaction with pf(4)
* libsodium 1.0.22: Library to build higher-level cryptographic tools
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
* mlvpn 2.3.5_1: Multi-link VPN
* monit 6.0.0: Unix system management and proactive monitoring
* mpd5 5.9_19: Multi-link PPP daemon based on netgraph(4)
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
* open-vm-kmod 13.1.0.1600019,2: Open VMware kernel modules for FreeBSD VMware guests
* open-vm-tools-nox11 13.1.0,2: Open VMware tools for FreeBSD VMware guests (without X11)
* openvpn 2.7.5_1: Secure IP/Ethernet tunnel daemon
* openvpn-auth-radius 2.1_4: RADIUS authentication plugin for OpenVPN
* pciids 20260711: Database of all known IDs used in PCI devices
* pcre2 10.47_1: Perl Compatible Regular Expressions library, version 2
* perl5 5.42.3: Practical Extraction and Report Language
* pimd 2.3.2b_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.31.0: Helper library for multiple PKCS#11 providers
* pkg 2.8.1_1: Package manager
* pkt-gen g2025.10.08: Packet sink/source and bandwidth/delay emulator using the netmap API
* pmacct 1.7.8_1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* protobuf 29.6,1: Data interchange format library
* protobuf-c 1.5.1_4: Code generator and libraries to use Protocol Buffers from pure C
* py312-exabgp4 4.2.22_1: BGP engine and route injector
* py312-mrtparse 2.2.0: MRT format data parser
* py312-packaging 26.2: Core utilities for Python packages
* py312-setuptools 63.1.0_3: Python packages installer
* python312 3.12.13_3: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.3.3: Library for editing command lines as they are typed
* realtek-re-kmod 1102.01.1600019_1: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.8.0_1: Open-source C implementation of the RPKI/Router Protocol client
* simdjson 4.6.6: Parsing gigabytes of JSON per second
* strongswan 6.0.7: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.17p2_2: Allow others to run commands as root
* tayga 0.9.6: Userland stateless NAT64 daemon
* tinc 1.0.37: Virtual Private Network (VPN) daemon
* tmux 3.7b: Terminal Multiplexer
* vim 9.2.0738: Improved version of the vi editor (console flavor)
* wireguard-tools 1.0.20260223: Fast, modern and secure VPN Tunnel
* xxd 9.2.0738: Hexdump and reverse hexdump utility from vim distribution
* zstd 1.5.7_2: Fast real-time compression algorithm

