# Release 1.994 (21/01/2025)

## Special instructions before upgrade
Starting with this version, BSDRP requires at least a 4GB disk.
If you installed BSDRP on a 2GB disk, upgrading will not be possible.
However, if it was installed on a 4GB or larger disk, you can resize the
system partition using the following command:
```
system resize-system-slice 3921924
```

## New features
This is an intermediate release preparing the branch 2 that will use the
poudriere-image framework in place of NanoBSD.

* New features:
  * Based on FreeBSD 15-head 8f6b66a9d3f and ports tree d995a1532b1b (21-01-2025)
* New packages:
  * dns/dnsmasq (will replace isc-dhcp44 and dhcprelya)
  * python 3.11 (this one added more than 100M of libs)
* Removed packages:
  * freevrrpd (carp is now supporting VRRP mode)
  * ucarp (no more conflict once carp enabled in VRRP mode)
  * net/aquantia-atlantic-kmod (does not build on latest head)
* Deprecated packages (will be removed in next release):
  * isc-dhcp44 (use dnsmasq, kea requires 300MB disk space with its dependencies)
  * dhcprelya (use dnsmasq)

## Upgraded packages
* bird to 2.16.1
* frr to 10.2.1
* iperf to 2.2.1
* iperf3 to 3.18
* lldpd to 1.0.18
* monit to 5.34.4
* nrpe to 4.1.3
* open-vm-tools to 12.5
* exabgp4 to 4.2.22
* strongswan to 5.9.14

## Packages list
* abseil 20240722.0: Abseil Common Libraries (C++)
* arping 2.24_1: ARP level "ping" utility
* bash 5.2.37: GNU Project's Bourne Again SHell
* bgpq4 1.12: Lightweight prefix-list generator for various routers v4
* bird2 2.16.1: Dynamic IP routing daemon
* brotli 1.1.0,1: Generic-purpose lossless compression algorithm
* bsnmp-regex 0.6_4: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5_1: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.34.4: Asynchronous DNS resolver library
* cpu-microcode 1.0_1: Meta-package for CPU microcode updates
* cpu-microcode-amd 20240810: AMD CPU microcode updates
* cpu-microcode-intel 20241112: Intel CPU microcode updates
* cpu-microcode-rc 1.0_2: RC script for CPU microcode updates
* curl 8.11.1_1: Command line tool and library for transferring data with URLs
* dhcp6 20080615.2_4: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dnsmasq 2.90_4,1: Lightweight DNS forwarder, DHCP, and TFTP server
* dtrace-toolkit 1.0_9: Collection of useful scripts for DTrace
* easy-rsa 3.2.1_1,1: Small RSA key management package based on openssl
* frr10 10.2.1: IP routing protocol suite
* frr10-pythontools 10.2.1: Provide configuration reload functionality for FRR
* fswatch-mon 1.13.0_3: Cross-platform file change monitor
* fusefs-libs 2.9.9_2: FUSE allows filesystem implementation in userspace
* gettext-runtime 0.23.1: GNU gettext runtime libraries and programs
* glib 2.80.5_1,2: Some useful routines of C programming (current stable version)
* gmp 6.3.0: Free library for arbitrary precision arithmetic
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1: Utility to regenerate the GNU info page index
* intel-pcm 202405: Process Count Monitor (PCM) for Intel processors
* iperf 2.2.1: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.18: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.19_2: CLI to manage IPMI systems
* isc-dhcp44-server 4.4.3P1_2: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.18: JSON (JavaScript Object Notation) implementation in C
* jsoncpp 1.9.6_1: JSON reader and writer library for C++
* libcdada 0.5.2: Basic data structures in C as libstdc++ wrapper
* libdnet 1.13_5: Simple interface to low level networking routines
* libev 4.33_1,1: Full-featured and high-performance event loop library
* libevent 2.1.12: API for executing callback functions on events or timeouts
* libffi 3.4.6: Foreign Function Interface
* libgcrypt 1.11.0: General purpose cryptographic library based on the code from GnuPG
* libgpg-error 1.51: Common error values for all GnuPG components
* libiconv 1.17_1: Character set conversion library
* liblz4 1.10.0,1: LZ4 compression library, lossless and very fast
* libmspack 0.11alpha: Library for Microsoft compression formats
* libnet 1.3,1: C library for creating IP packets
* libpci 3.13.0: PCI configuration space I/O made easy
* libpfctl 0.15: Library for interaction with pf(4)
* libsodium 1.0.19: Library to build higher-level cryptographic tools
* libssh 0.11.1: Library implementing the SSH2 protocol
* libucl 0.9.2: Universal configuration library parser
* libunwind 20240221_1: Generic stack unwinding library
* libxml2 2.11.9: XML parser library for GNOME
* libyang2 2.1.128: YANG data modeling language library, version 2
* lldpd 1.0.18: Link-Layer Discovery Protocol (LLDP 802.1ab) daemon
* lzo2 2.10_1: Portable speedy, lossless data compression library
* mlvpn 2.3.1_4: Multi-link VPN
* monit 5.34.4: Unix system management and proactive monitoring
* mpd5 5.9_18: Multi-link PPP daemon based on netgraph(4)
* mpdecimal 4.0.0: C/C++ arbitrary precision decimal floating point libraries
* mrouted 3.9.8_2: Multicast routing daemon providing DVMRP for IPv4
* mtr-nox11 0.95_2: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.4.4,1: Plugins for Nagios
* nc 1.0.1_2: Network aware cat
* ncurses 6.5: Library for terminal-independent, full-screen output
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20210121_2: Network performance benchmarking package
* nettle 3.10.1: Low-level cryptographic library
* nrpe 4.1.3: Nagios Remote Plugin Executor
* nstat g20230601_1,1: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* open-vm-kmod 12.5.0.1500030,2: Open VMware kernel modules for FreeBSD VMware guests
* open-vm-tools-nox11 12.5.0_1,2: Open VMware tools for FreeBSD VMware guests (without X11)
* openvpn 2.6.13: Secure IP/Ethernet tunnel daemon
* openvpn-auth-radius 2.1_4: RADIUS authentication plugin for OpenVPN
* pciids 20241125: Database of all known IDs used in PCI devices
* pcre 8.45_4: Perl Compatible Regular Expressions library
* pcre2 10.43: Perl Compatible Regular Expressions library, version 2
* perl5 5.36.3_2: Practical Extraction and Report Language
* pimd 2.3.2_1: Lightweight stand-alone PIM-SM v2 multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.29.0_3: Helper library for multiple PKCS#11 providers
* pkg 1.21.3: Package manager
* pkt-gen g2024.09.16: Packet sink/source using the netmap API
* pmacct 1.7.8_1: Accounting and aggregation tool for IPv4 and IPv6 traffic
* protobuf 28.3,1: Data interchange format library
* protobuf-c 1.4.1_7: Code generator and libraries to use Protocol Buffers from pure C
* py311-exabgp4 4.2.22: BGP engine and route injector
* py311-mrtparse 2.0.0: MRT format data parser
* py311-packaging 24.2: Core utilities for Python packages
* py311-setuptools 63.1.0_1: Python packages installer
* python 3.11_3,2: "meta-port" for the default version of Python interpreter
* python3 3_4: Meta-port for the Python interpreter 3.x
* python311 3.11.11: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.2.13_2: Library for editing command lines as they are typed
* realtek-re-kmod 1100.00.1500030_1: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.8.0_1: Open-source C implementation of the RPKI/Router Protocol client
* simdjson 3.11.5: Parsing gigabytes of JSON per second
* strongswan 5.9.14: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.16p2_1: Allow others to run commands as root
* tayga 0.9.2_2: Userland stateless NAT64 daemon
* tinc 1.0.36_3: Virtual Private Network (VPN) daemon
* tmux 3.5a: Terminal Multiplexer
* utf8proc 2.9.0: UTF-8 processing library
* vim 9.1.1043: Improved version of the vi editor (console flavor)
* wireguard-tools 1.0.20210914_3: Fast, modern and secure VPN Tunnel
* x86info 1.31.s03_1: x86 CPU identification and feature display utility
* xxd 9.1.1043: Hexdump and reverse hexdump utility from vim distribution
* zstd 1.5.6: Fast real-time compression algorithm
