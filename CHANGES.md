# Release 2.0 (2025/09/28)

## Special instructions before upgrade
BSDRP 1.994 or later is required.
Upgrading will not add the dual UEFI/BIOS mode, neither the MBR to GPT conversion:
A full reinstall is required for those new features.

## New features
* The Nanobsd framework was replaced by poudriere-image. This brings:
  * Support for both BIOS and UEFI boot and GPT partition type
     * A full reinstall is required to migrate from MBR to GPT
  * Packages are now built using the official poudriere method
* New packages:
  * net/vpp
  * flashrom
  * mstflint, Mellanox NIC tools
* Removed packages:
  * isc-dhcp44 (use dnsmasq)
  * dhcprelya (use dnsmasq)

## Upgraded packages
* bird to 2.17
* cpu-microcodes
* dnsmasq to 2.90
* frr 10.4.1 (lua scripting enabled)
* iperf to 3.19
* lldp to 1.0.19
* monit to 5.35
* mtr to 0.96
* openvpn 2.6.15
* strongswan 6.0.1

## Packages list
* abseil 20250127.1: Abseil Common Libraries (C++)
* arping 2.25: ARP level "ping" utility
* bash 5.3.3_1: GNU Project's Bourne Again SHell
* bgpq4 1.12: Lightweight prefix-list generator for various routers v4
* bird2 2.17.2_1: Dynamic IP routing daemon
* brotli 1.1.0,1: Generic-purpose lossless compression algorithm
* bsnmp-regex 0.6_4: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5_1: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.34.5: Asynchronous DNS resolver library
* cpu-microcode 1.0_1: Meta-package for CPU microcode updates
* cpu-microcode-amd 20250729: AMD CPU microcode updates
* cpu-microcode-intel 20250812: Intel CPU microcode updates
* cpu-microcode-rc 1.0_2: RC script for CPU microcode updates
* curl 8.15.0: Command line tool and library for transferring data with URLs
* dhcp6 20080615.2_4: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dmidecode 3.6: Tool for dumping DMI (SMBIOS) contents in human-readable format
* dnsmasq 2.91_2,1: Lightweight DNS forwarder, DHCP, and TFTP server
* dpdk22.11 22.11.2.1600000_1: DPDK: Software libraries for packet processing
* dtrace-toolkit 1.0_11: Collection of useful scripts for DTrace
* easy-rsa 3.2.4,1: Small RSA key management package based on openssl
* expat 2.7.2: XML 1.0 parser written in C
* flashrom 1.6.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* frr10 10.4.1: IP routing protocol suite
* frr10-pythontools 10.4.1: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_3: Cross-platform file change monitor
* fusefs-libs 2.9.9_2: FUSE allows filesystem implementation in userspace
* gettext-runtime 0.23.1: GNU gettext runtime libraries and programs
* glib 2.84.1_3,2: Some useful routines of C programming (current stable version)
* gmp 6.3.0: Free library for arbitrary precision arithmetic
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1_1: Utility to regenerate the GNU info page index
* intel-pcm 202405_3: Process Count Monitor (PCM) for Intel processors
* iperf 2.2.1: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.19.1: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.19_3: CLI to manage IPMI systems
* isa-l 2.31.1: Intel(R) Intelligent Storage Acceleration Libray
* isc-dhcp44-server 4.4.3P1_2: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* jansson 2.14.1: C library for encoding, decoding, and manipulating JSON data
* json-c 0.18: JSON (JavaScript Object Notation) implementation in C
* jsoncpp 1.9.6_1: JSON reader and writer library for C++
* ksh 1.0.10: ksh93u+m is the renewed development of ksh93 based on AT&T ksh93u+m (stable)
* libcdada 0.5.2: Basic data structures in C as libstdc++ wrapper
* libdnet 1.13_5: Simple interface to low level networking routines
* libedit 3.1.20250104,1: Command line editor library
* libepoll-shim 0.0.20240608: Small epoll implementation using kqueue
* libev 4.33_1,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.5.1: Foreign Function Interface
* libgcrypt 1.11.2: General purpose cryptographic library based on the code from GnuPG
* libgpg-error 1.55: Common error values for all GnuPG components
* libiconv 1.17_1: Character set conversion library
* libidn2 2.3.8: Implementation of IDNA2008 internationalized domain names
* libinotify 20240724_3: Kevent based inotify compatible library
* liblz4 1.10.0,1: LZ4 compression library, lossless and very fast
* libnet 1.3,1: C library for creating IP packets
* libpcap 1.10.5: Ubiquitous network traffic capture library
* libpci 3.14.0: PCI configuration space I/O made easy
* libpfctl 0.17: Library for interaction with pf(4)
* libsodium 1.0.19: Library to build higher-level cryptographic tools
* libssh 0.11.2: Library implementing the SSH2 protocol
* libucl 0.9.2_2: Universal configuration library parser
* libunistring 1.3: Unicode string library
* libunwind 20240221_2: Generic stack unwinding library
* libxml2 2.14.5: XML parser library for GNOME
* libyang2 2.1.128: YANG data modeling language library, version 2
* lldpd 1.0.19_1: Link-Layer Discovery Protocol (LLDP 802.1ab) daemon
* lua53 5.3.6_1: Powerful, efficient, lightweight, embeddable scripting language
* lua54 5.4.8: Powerful, efficient, lightweight, embeddable scripting language
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_4: Multi-link VPN
* monit 5.35.2: Unix system management and proactive monitoring
* mpd5 5.9_18: Multi-link PPP daemon based on netgraph(4)
* mpdecimal 4.0.1: C/C++ arbitrary precision decimal floating point libraries
* mrouted 3.9.8_2: Multicast routing daemon providing DVMRP for IPv4
* mstflint 4.33.0.1: Firmware Burning and Diagnostics Tools for Mellanox devices
* mtr-nox11 0.96: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.4.4,1: Plugins for Nagios
* nc 1.0.1_2: Network aware cat
* net-snmp 5.9.4_6,1: Extendable SNMP implementation
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20210121_2: Network performance benchmarking package
* nettle 3.10.2: Low-level cryptographic library
* nrpe 4.1.3: Nagios Remote Plugin Executor
* nstat g20250705,1: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* open-vm-kmod 12.5.2.1600000,2: Open VMware kernel modules for FreeBSD VMware guests
* open-vm-tools-nox11 12.5.2,2: Open VMware tools for FreeBSD VMware guests (without X11)
* openvpn 2.6.15: Secure IP/Ethernet tunnel daemon
* openvpn-auth-radius 2.1_4: RADIUS authentication plugin for OpenVPN
* pciids 20250711: Database of all known IDs used in PCI devices
* pcre2 10.45_1: Perl Compatible Regular Expressions library, version 2
* perl5 5.42.0_1: Practical Extraction and Report Language
* perl5.40 5.40.3_2: Practical Extraction and Report Language
* pimd 2.3.2b_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.29.0_3: Helper library for multiple PKCS#11 providers
* pkg 2.3.1: Package manager
* pkgconf 2.4.3,1: Utility to help to configure compiler and linker flags
* pkt-gen g2024.09.16: Packet sink/source using the netmap API
* pmacct 1.7.8_1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* protobuf 29.5,1: Data interchange format library
* protobuf-c 1.5.1_3: Code generator and libraries to use Protocol Buffers from pure C
* py311-exabgp4 4.2.22_1: BGP engine and route injector
* py311-mrtparse 2.0.0_1: MRT format data parser
* py311-packaging 25.0: Core utilities for Python packages
* py311-pyelftools 0.31: Library for analyzing ELF files and DWARF debugging information
* py311-setuptools 63.1.0_3: Python packages installer
* python 3.11_3,2: "meta-port" for the default version of Python interpreter
* python3 3_4: Meta-port for the Python interpreter 3.x
* python311 3.11.13_1: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.2.13_2: Library for editing command lines as they are typed
* realtek-re-kmod 1100.00.1600000_1: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.8.0_1: Open-source C implementation of the RPKI/Router Protocol client
* simdjson 4.0.5: Parsing gigabytes of JSON per second
* strongswan 6.0.1: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.17p2: Allow others to run commands as root
* tayga 0.9.5: Userland stateless NAT64 daemon
* tinc 1.0.36_3: Virtual Private Network (VPN) daemon
* tmux 3.5a_1: Terminal Multiplexer
* vim 9.1.1744: Improved version of the vi editor (console flavor)
* vpp 24.06_1: VPP: A fast, scalable layer 2-4 multi-platform network stack
* wireguard-tools 1.0.20210914_3: Fast, modern and secure VPN Tunnel
* xxd 9.1.1744: Hexdump and reverse hexdump utility from vim distribution
* zstd 1.5.7: Fast real-time compression algorithm
