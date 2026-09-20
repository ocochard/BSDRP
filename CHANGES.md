# Release 2.3 (2026/09/20)

## New features
- Latest changes from FreeBSD main and ports at 2026/09/20
- bird2 to bird3 (major version upgrade)
- pimd 2.3.2b to 3.1.0 (major version upgrade): the daemon rescans the
  kernel interface list while running, so an interface configured after
  pimd started (PPP or L2TP link, tunnel, VLAN added in service) becomes
  a PIM vif on its own, including the `phyint` lines of a `pimd.conf`
  naming an interface that did not exist at startup. Daemonizing now
  releases the controlling terminal, so a pimd started from its rc script
  on a console no longer dies on the next INTR typed there. SSM support
  is advertised (PIM-SM/SSM).
- Add lab-reinstall-test: remote reinstall via RAM-boot + ssh|dd
- Replace gpartfix rc script with stock growfs
- Ship additional USB and serial kernel modules
- jail tenant tool: add -l flag to list configured jails
- Python 3.11 to 3.12; ExaBGP and related tools rebuilt on Python 3.12
- New Intel NIC maintenance tools: intel-epct (Ethernet Port
  Configuration Tool) and the NVM update utilities for I210, I225/I226
  and X550 adapters

## Fixes
- config save: validate rc.conf before persisting
- config save: exclude ssh agent socket directories from saved config
- config: setlock no longer removes another instance's lock, and reports
  a failure instead of exiting 0
- autosave: a refused instance no longer tears down the running daemon
- Add extra delay to reliably detect the UFS label at boot
- jail tenant tool: don't fight with autosave, and stop failing on an
  existing jail
- jail tenant tool: harden against edge cases in cleanup and ID derivation
- jail tenant tool: recover gracefully from orphan configs on delete
- jail tenant tool: fix broken grep pattern for interface duplicate check
- jail tenant tool: trap-based cleanup on partial jail creation failure
- jail tenant tool: derive next jail ID from configs, avoid jail.lastid single point of failure

## FreeBSD notable network stack changes introduced

### iflib (Intel, Chelsio, Broadcom... drivers)
- New "simple_tx" transmit path: packets are sent directly while the
  transmit queue mutex is available, and only contending threads defer
  through a bounded buf_ring. It outperforms mp_ring by a wide margin
  when the CPU, not the NIC, is the bottleneck. It is **not** the default
  yet: set the loader tunable `net.iflib.prefer_mpring=0` for all iflib
  interfaces, or `dev.<driver>.<unit>.iflib.simple_tx=1` for one of them.
  Related knobs: `net.iflib.max_producers`,
  `net.iflib.simple_drain_quota`, `net.iflib.simple_txbr_size`. Note that
  `tx_abdicate` is ignored when simple_tx is used, and simple_tx is
  disabled on an interface using ALTQ.
- Driver-provided transmit queue selection, RSS configuration queries,
  and per-packet RX hardware timestamps plumbed to mbufs
- led(4) devices created for the NICs that expose one
- TX watchdog now requires sustained demand before firing, and counts
  its resets in a sysctl
- Many SR-IOV hardening fixes (ice, ixgbe, igbv): VF requests made
  idempotent, VFs isolated after malicious-driver detection, mailbox
  flood protection, VF status reported through netlink and ifconfig

### Packet filtering
- pf: syncookies are now sent from the receiving thread
- pf: a crafted reset packet can no longer drop a TCP state
- pf: fragment reassembly key includes the direction
- pf: securelevel off-by-one, and several crash fixes (low memory,
  sendfile, outbound NULL dereference, overlapping group and interface
  names)
- pfsync: works over interfaces with a large MTU
- libalias: buffer overflow in RTSP aliasing fixed
- ipfw/nat64 and nat64lsn: type confusion panic when using the wrong
  NAT64 instance type fixed; checksum fixed after NAT
- ipfilter: PPTP proxy length underflow fixed

### Routing
- fib-aware address selection: `ifa_ifwithroute()`, `rt_getifa_fib()`,
  ICMP redirect verification and `bind(2)` with `*.bind_all_fibs` all
  look the address up in the right FIB
- fib_algo: nexthop index collision across address families fixed, and a
  radix_masks leak in radix_lockless
- Nexthop groups subscribe to interface link events and replace
  unreachable nexthops
- ICMP redirects only update the FIB the redirect arrived on
- netlink: RTA_PREFSRC support, if_gif netlink support, FreeBSD-specific
  IFLAF_GROUP, PF command decoding

### TCP
- Host cache is now used for socket buffer sizing, and reports more
  statistics
- PRR implementation aligned with RFC 9937
- TCP-MD5 accounting fixes, stricter SEG.SEQ validation for RST segments

### Interfaces
- vlan: the parent is notified when a VLAN ID is replaced
- if_bridge: only the inspected headers are pulled up, drops on the
  fragmentation path are counted, NULL softc dereference fixed
- epair: IFCAP_MEXTPG support, receive checksum offloading can be
  disabled
- New media types: 800GBase-X, 200Gbit/s per lane, 10GBase-BX BiDi

## Upgraded packages
* bird: 2 -> 3.3.2_1
* cpu-microcode-intel: 20260512 -> 20260812
* dnsmasq: 2.92rel2,1 -> 2.93,1
* frr10: 10.6.1 -> 10.7.1
* frr10-pythontools: 10.6.1 -> 10.7.1
* fswatch-mon: 1.13.0_3 -> 1.20.1
* monit: 5.35.2 -> 6.0.0
* mpd5: 5.9_18 -> 5.9_19
* mstflint: 4.36.0.1 -> 4.37.0.1
* open-vm-kmod: 13.0.10.1600018,2 -> 13.1.0.1600026,2
* open-vm-tools-nox11: 13.0.10,2 -> 13.1.0,2
* openvpn: 2.7.4 -> 2.7.7
* pimd: 2.3.2b_1 -> 3.1.0
* pmacct: 1.7.8_1 -> 1.7.9
* realtek-re-kmod: 1101.00.1600018 -> 1102.01.1600026_1
* strongswan: 6.0.6 -> 6.1.0
* wireguard-tools: 1.0.20250521_1 -> 1.0.20260223

## Removed packages
- intel-nvmupdate-100g: renamed upstream to intel-nvmupdate-e810, which
  is not in the BSDRP package list: the image no longer carries an NVM
  update utility for E810 100G adapters
- bird2, python311 and py311-* were upgraded/renamed, not dropped

## Packages list
* abseil 20250127.1_2: Abseil Common Libraries (C++)
* arping 2.25: ARP level "ping" utility
* bash 5.3.20: GNU Project's Bourne Again SHell
* bgpq4 1.16: Lightweight prefix-list generator for various routers v4
* bird3 3.3.2_1: Dynamic multithreaded IP routing daemon
* brotli 1.2.0,1: Generic-purpose lossless compression algorithm
* bsnmp-regex 0.6_4: bsnmpd module allowing creation of counters from log files
* bsnmp-ucd 0.4.5_1: bsnmpd module that implements parts of UCD-SNMP-MIB
* c-ares 1.34.8: Asynchronous DNS resolver library
* cpu-microcode 1.0_1: Meta-package for CPU microcode updates
* cpu-microcode-amd 20251202: AMD CPU microcode updates
* cpu-microcode-intel 20260812: Intel CPU microcode updates
* cpu-microcode-rc 1.0_2: RC script for CPU microcode updates
* curl 8.22.0: Command line tool and library for transferring data with URLs
* dhcp6 20080615.2_4: KAME DHCP6 client, server, and relay
* dhcprelya 6.1_1: Lightweight DHCP relay agent (Yandex edition)
* dmidecode 3.7: Tool for dumping DMI (SMBIOS) contents in human-readable format
* dnsmasq 2.93,1: Lightweight DNS forwarder, DHCP, and TFTP server
* dtrace-toolkit 1.0_11: Collection of useful scripts for DTrace
* easy-rsa 3.2.6,1: Small RSA key management package based on openssl
* expat 2.8.4: XML 1.0 parser written in C
* flashrom 1.6.0_1: Utility for reading, writing, verifying, and erasing flash ROM chips
* frr10 10.7.1: IP routing protocol suite
* frr10-pythontools 10.7.1: Provide configuration reload functionality for FRR
* fswatch-mon 1.20.1: Cross-platform file change monitor
* fusefs-libs 2.9.9_2: FUSE allows filesystem implementation in userspace
* gettext-runtime 1.0_1: GNU gettext runtime libraries and programs
* glib 2.88.3,2: Some useful routines of C programming (current stable version)
* gmp 6.3.0: Free library for arbitrary precision arithmetic
* graphpath 1.2: Generates an ASCII network diagram from the route table
* indexinfo 0.3.1_1: Utility to regenerate the GNU info page index
* intel-epct 1.39.56.9: Intel(R) Ethernet Port Configuration Tool
* intel-nvmupdate-i210 2.00: NVM Update Utility for Intel(R) Ethernet I210 Series
* intel-nvmupdate-i225-i226 20260904: NVM update utility for Intel I225 and I226 Ethernet controllers
* intel-nvmupdate-x550 3.70: NVM Update Utility for Intel(R) Ethernet X550 Series
* intel-pcm 202405_8: Process Count Monitor (PCM) for Intel processors
* iperf 2.2.1: Tool to measure maximum TCP and UDP bandwidth
* iperf3 3.21: Improved tool to measure TCP and UDP bandwidth
* ipmitool 1.8.19_3: CLI to manage IPMI systems
* isc-dhcp44-server 4.4.3P1_2: ISC Dynamic Host Configuration Protocol server
* ixl_unlock 1: Disable SFP Module Qualification on Intel XL710 network cards
* json-c 0.19_1: JSON (JavaScript Object Notation) implementation in C
* jsoncpp 1.9.8: JSON reader and writer library for C++
* ksh 1.0.10: ksh93u+m is the renewed development of ksh93 based on AT&T ksh93u+m (stable)
* libcdada 0.6.4: Basic data structures in C as libstdc++ wrapper
* libdnet 1.13_5: Simple interface to low level networking routines
* libedit 3.1.20260512,1: Command line editor library
* libev 4.33_1,1: Full-featured and high-performance event loop library
* libevent 2.1.13: API for executing callback functions on events or timeouts
* libffi 3.8.0: Foreign Function Interface
* libgcrypt 1.12.4: General purpose cryptographic library based on the code from GnuPG
* libgpg-error 1.61: Common error values for all GnuPG components
* libiconv 1.18_1: Character set conversion library
* libidn2 2.3.8: Implementation of IDNA2008 internationalized domain names
* liblz4 1.10.0_2,1: LZ4 compression library, lossless and very fast
* libnet 1.3,1: C library for creating IP packets
* libpci 3.15.0: PCI configuration space I/O made easy
* libpfctl 0.17: Library for interaction with pf(4)
* libsodium 1.0.22: Library to build higher-level cryptographic tools
* libssh 0.12.2: Library implementing the SSH2 protocol
* libucl 0.9.4: Universal configuration library parser
* libunistring 1.4.2: Unicode string library
* libunwind 20250904: Generic stack unwinding library
* libxml2 2.15.4: XML parser library for GNOME
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
* mstflint 4.37.0.1: Firmware Burning and Diagnostics Tools for Mellanox devices
* mtr-nox11 0.96: Traceroute and ping in a single network diagnostic tool
* nagios-plugins 2.4.4_1,1: Plugins for Nagios
* nc 1.0.1_2: Network aware cat
* netmap-fwd 0.2: IPv4 router over netmap for FreeBSD
* netperf 2.7.1.p20210121_2: Network performance benchmarking package
* nettle 3.10.2: Low-level cryptographic library
* nrpe 4.1.3: Nagios Remote Plugin Executor
* nstat g20250705,1: Replacement for bw/netstat/vmstat/pcm-memory.x
* ntraceroute 6.4.2_3: Ubiquitous network routing analysis tool
* open-vm-kmod 13.1.0.1600026,2: Open VMware kernel modules for FreeBSD VMware guests
* open-vm-tools-nox11 13.1.0,2: Open VMware tools for FreeBSD VMware guests (without X11)
* openvpn 2.7.7: Secure IP/Ethernet tunnel daemon
* openvpn-auth-radius 2.1_4: RADIUS authentication plugin for OpenVPN
* pciids 20260912: Database of all known IDs used in PCI devices
* pcre2 10.48: Perl Compatible Regular Expressions library, version 2
* perl5 5.42.3: Practical Extraction and Report Language
* pimd 3.1.0: Lightweight stand-alone PIM-SM/SSM multicast routing daemon
* pimdd 0.2.1.0_3: UO Dense Protocol-Independent Multicast (PIM-DM) daemon for IPv4
* pkcs11-helper 1.31.0: Helper library for multiple PKCS#11 providers
* pkg 2.8.4: Package manager
* pkt-gen g2025.10.08: Packet sink/source and bandwidth/delay emulator using the netmap API
* pmacct 1.7.9: Accounting and aggregation tool for IPv4 and IPv6 traffic
* protobuf 29.6,1: Data interchange format library
* protobuf-c 1.5.1_4: Code generator and libraries to use Protocol Buffers from pure C
* py312-exabgp4 4.2.22_1: BGP engine and route injector
* py312-mrtparse 2.2.0: MRT format data parser
* py312-packaging 26.3: Core utilities for Python packages
* py312-setuptools 63.1.0_3: Python packages installer
* python312 3.12.14: Interpreted object-oriented programming language
* quagga-bgp-netgen 0.2: Generates Quagga/FRR bgp configuration file with lot's of routes
* readline 8.3.3: Library for editing command lines as they are typed
* realtek-re-kmod 1102.01.1600026_1: Kernel driver for Realtek PCIe Ethernet Controllers
* rtrlib 0.8.0_1: Open-source C implementation of the RPKI/Router Protocol client
* simdjson 4.6.11_1: Parsing gigabytes of JSON per second
* strongswan 6.1.0: Open Source IKEv2 IPsec-based VPN solution
* sudo 1.9.17p2_2: Allow others to run commands as root
* tayga 0.9.6: Userland stateless NAT64 daemon
* tinc 1.0.37: Virtual Private Network (VPN) daemon
* tmux 3.7c: Terminal Multiplexer
* vim 9.2.0738: Improved version of the vi editor (console flavor)
* wireguard-tools 1.0.20260223: Fast, modern and secure VPN Tunnel
* xxd 9.2.0738: Hexdump and reverse hexdump utility from vim distribution
* zstd 1.5.7_2: Fast real-time compression algorithm
