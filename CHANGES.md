# Release 2.4 (WIP)

## New features
- Latest changes from FreeBSD main and ports at 2026/11/20
- Add a dhcp lab: DHCP relay and server, both with dnsmasq
- vrrp lab: checked by tools/regression-test.sh: VRRPv3 states, the
  virtual MAC addresses, forwarding, and a failover with preemption
  that gives both groups back to the preferred router
- Add an admin lab: tools/regression-test.sh checks config (save, diff,
  rollback, locking, rc.conf syntax check), autosave, system reboot,
  upgrade and system rollback on one VM
- Add a pimssm lab: PIM-SSM with pimd, no RP and no BSR
- Add an anycast lab: two DNS sites share one address, ExaBGP's
  healthcheck withdraws a site that stops answering, checked by
  tools/regression-test.sh
- full lab: FRRouting's pimd on R4 to test PIM-SM interoperability with
  net/pimd
- full lab: strongSwan IKEv2 route-based IPsec (if_ipsec), WireGuard,
  VXLAN, GENEVE, ipfw NAT, BFD and PIM-SSM multicast traffic, and a
  pf filtering rule, all checked by tools/regression-test.sh
- full lab: BFD between FRR and bird, ExaBGP injecting routes, a DHCPv6
  relay and server, and LLDP
- Add an rpki lab: FRR and BIRD edge routers drop RPKI-invalid hijacks
  with the ROAs of an RTR cache (rtrcache, a lab-only stand-in for a
  validator), and a new ROA stops a running hijack within seconds, checked
  by tools/regression-test.sh
- frr10: bgpd re-applies the inbound policy when the RPKI cache adds or
  withdraws a ROA, and once its initial sync is done: before, routes kept
  their old state until a manual "clear bgp ... soft in" (backport of FRR
  pull request #24131)
- Add a bng lab: a PPPoE broadband gateway (mpd5) gives each subscriber
  a fixed IPv4 address by login and a fixed /56 by DHCPv6 prefix
  delegation; the CPE puts a /64 on its LAN with rtadvd, checked by
  tools/regression-test.sh
- Add an ipv6only lab: IPv6-only access where the ISP's ipfw NAT64 and
  DNS64 reach an IPv4 server, and the CPE's CLAT (464XLAT) still gives
  its LAN IPv4, checked by tools/regression-test.sh
- Kernel: ipfw NAT64 translates fragmented IPv6 packets into valid IPv4
  fragments (same ID, payload left untouched), so UDP datagrams larger
  than the path MTU are no longer lost
- Kernel: ng_netflow sends a partly filled NetFlow export datagram every
  second instead of waiting for it to fill, so a quiet router no longer
  holds expired flows for minutes
- Add an accounting lab: the router exports NetFlow v9 (ipfw and
  ng_netflow) and pmacct's nfacctd totals each customer's traffic, in
  and out, IPv4 and IPv6, checked against known transfers by
  tools/regression-test.sh
- Add an ixp lab: two route servers, BIRD and FRR, on a peering LAN
  filter each member to its own prefixes, honour "do not announce to"
  communities and back each other up, checked by tools/regression-test.sh
- Add an rtbh lab: a customer stops a DDoS that fills its access link
  by announcing the victim with the BLACKHOLE community (RFC 7999), and
  the ISP drops the flood upstream, checked by tools/regression-test.sh
- frr10: zebra no longer turns IPv6 neighbor cache entries into kernel
  host routes, which overrode static and BGP routes to the same address
- Add a branch lab: a branch office uses two ISPs at once through two
  WireGuard tunnels, OSPF ECMP with net.route.hash_forward and BFD
  failover, checked by tools/regression-test.sh
- ecmp lab: set net.route.hash_forward=1, so it spreads flows on bhyve,
  checked by tools/regression-test.sh
- Kernel: net.route.hash_forward sysctl (default 0) hashes forwarded
  packets that arrive without a flow hash (vtnet on bhyve, NICs without
  RSS, traffic decrypted by WireGuard), so ECMP routes spread flows over
  all their nexthops instead of sending them all to the first one
- wireguard-tools: wg-quick no longer deletes the routes through the
  interface when its route monitor is killed while the interface is up
  (e.g. started from a first-boot script), and its IPv4 route cleanup
  reads the right netstat column
- pimd 3.1.0 to 3.4.0: Auto-RP support (listener, candidate RP
  announcer and mapping agent, with `autorp accept-from` to restrict
  trusted senders); privilege separation, the daemon now runs as a root
  parent plus an unprivileged child chrooted in /var/empty as `nobody`
  (`--no-privsep` restores the single root process); `pimctl -j` JSON
  output; new `pimd.conf` keywords `phyint ... passive`,
  `igmp-accept-groups`, `crp-accept-from`, `crp-accept-group`,
  `rp-set-limit` and `assert-preference`; many RFC 7761 Assert, Join and
  Prune fixes; a descriptor leaked by every `pimctl` request is fixed.
  `pimctl show compat` was removed.
- show version: report more build information
- equilibrium: confirm the converged value with a second probe

## Fixes
- Raise kern.ipc.maxsockbuf to 32 MiB: FRR daemons got 8 MiB socket
  buffers instead of the 16 MiB requested and logged it on every start
- system: fix a typo preventing system rollback
- config: "config save <name>" no longer looks for an /etc/<name> file
  ("tar: <name>: Cannot stat")
- upgrade: an interrupted upgrade no longer leaves its lock behind, and a
  refused second upgrade no longer removes the running one's lock
- upgrade: refuse a truncated image (cut ssh stream) instead of booting
  it, and aggregate pipe reads into full blocks before writing the disk
- autosave: save in-place edits of existing /etc files, not only file
  creations and removals; "service autosave stop" also stops it during a
  save, and only kills its own fswatch
- tenant: save the jail configuration after creating or deleting a jail
  (a restarted autosave waited for the next /etc change, so the jail was
  lost at reboot), and restart autosave after a delete
- config save: fail (exit 1) when a file could not be saved (full /cfg),
  and keep the previous archive until the new one is complete
- config diff: report what config save would store: deleted files,
  symlinks, new directories and mode or owner changes, not only content
  changes of regular files (a reboot silently lost them)
- config factory: archive the configuration first ("config rollback
  factory" restores it), and clear the dot files in /cfg too
- system reboot/halt: stop when the save the user asked for fails, abort
  instead of looping forever without a terminal, and only syntax-check
  rc.conf instead of running it
- ngnetflow: ngnetflow_src binds the export socket (it was sent to the
  netflow node, which refused it)
- mpd5 if-down.sh example: fix the route removal (shell error)
- rtrcache: skip malformed or out-of-range ROA lines instead of crashing
  the reload thread, answer a malformed Serial Query with Corrupt Data,
  and a router that stops reading no longer blocks notifies to the others
- tenant: exact interface name match in the duplicate check (em1 vs
  em10), collision-free epair names, clear errors for an invalid address
  or a jail id too high for its MAC address, delete works with both
  jail.conf layouts and removes the jail's configured path, a failed
  create only removes what it created and restarts autosave
- bird: write /var/run/bird.pid (bird_flags), so newsyslog's rotation
  makes it reopen /var/log/bird.log
- openvpn: /var/log/openvpn.log is now fed by syslogd and rotated without
  restarting the tunnels
- tuning: four inverted checks (tso, raw socket buffers, netisr queue)
  now advise when needed, net.link.ifqmaxlen goes to loader.conf (a boot
  tunable), the harvest_mask advice clears once applied, core count from
  kern.smp.cores (no more abort on multi-CCX CPUs), interface flags are
  appended to the existing ifconfig_<if>, AES-NI detected when compiled
  in, cxgbe advice for every T4 to T7 card; advice for sysctls removed
  with iflib (em/igb/ix process limits and queue counts) dropped
- show disk: find the boot disk on GPT images; show process mem lists
  per-process memory (it showed kernel malloc types); works without PAGER
- nic-queue-usage: read the current ixl per-queue counters, count all
  cxgbe TX packets and every TX queue; igb dropped (iflib exports no
  per-queue packet counters)
- equilibrium-noref: same fixes as equilibrium (result line always
  printed, measured duration, tolerance, flow counts), and remove -u
  (pkt-gen has no such option); both: correct the -o help (0.01 is 1%)
- Remove the igb_affinity, ix_affinity and ixiflib_affinity rc scripts:
  iflib already binds each queue interrupt to the CPU running its task
  thread, and these scripts moved the interrupt alone, away from it
  (ix_affinity also no longer matched anything). Use the iflib(4)
  loader tunables dev.<driver>.<unit>.iflib.core_offset and
  separate_txrx instead
- Remove the txabdicate rc script: iflib now uses its simple transmit
  path by default (net.iflib.prefer_mpring=0), which ignores tx_abdicate.
  With prefer_mpring=1, set dev.<driver>.<unit>.iflib.tx_abdicate in
  /etc/sysctl.conf instead
- chelsio_affinity: handle T4 and T7 cards; bxe, chelsio and
  mlx5en_affinity: reject an avoidncpu or firstcpu that leaves no CPU,
  accept 2-CPU systems; mlx5en_affinity wraps back to firstcpu, and no
  longer mixes mlx5_core1 with mlx5_core1x
- Remove dead files: rc.d/polling (no DEVICE_POLLING in the kernel),
  rc.d/pim6dd and rc.d/pim6sd (no such packages), rc.d/pimdd (the
  package ships its own), a net-snmp snmpd.conf (bsnmpd is used) and
  ssmtp.conf (not shipped)
- show mem: total from hw.realmem instead of a guess rounded from
  hw.physmem, dirty laundry pages no longer counted as available, and
  accurate field descriptions
- Ship the missing QAT firmware
- equilibrium: use the same number of IPv4 flows as IPv6
- nuageinit: rebase the read-only root patch on upstream changes

## FreeBSD notable network stack changes introduced

### Routing
- Fix an rtentry use-after-free in multipath route append
- Fix a nexthop double free in rib_copy_route() and a buffer size in
  merge_nhgrps()
- rtnetlink: use the default weight for unset weights in NHA_GROUP
- fib_algo instances torn down again on rib destroy (no more leak or
  panic on vnet destroy)
- fib_algo: respect immediate_sync in fd_ref_nhop
- fib_algo: fix a nexthop reference leak on FLM_BATCH

### pf
- First-match-wins for nat rules, even in anchors
- Do not corrupt neighbour advertisements when translating
- Check AH and IPv6 extension header lengths
- More ioctls converted to netlink, many locking and leak fixes
- Keep every chunk of a table that a ruleset defines
- pfctl: report why a table definition or a fingerprint flush failed
- pflow: destroy exporters on module unload
- pfctl: DIOCXBEGIN, DIOCXROLLBACK, DIOCXCOMMIT converted to netlink;
  `-l` to use an inherited Netlink socket
- pfsync: better handling of large packets, mbuf leak and underflow fixes
- Drop IPv6 fragmented packets whose first fragment does not carry the
  whole header chain (RFC 7112 Section 5)
- Fix nat46 ICMP handling and SCTP normalisation cleanup
- route-to on the inbound pass no longer counts forwarded IPv6 packets
  as input discards
- pfsync: do not apply a stale destination peer from a state update
- Stricter anchor name validation

### Drivers
- bnxt: kTLS TX offload, RX timestamping, HW and host TX completion
  coalescing, more Tx than Rx rings on P5+, Thor2 interrupt storm fix,
  reliability fixes after firmware resets
- igc: hardware RSS hash now agrees with the stack's configuration
- e1000, igc: fix the flow control sysctl
- ice: fix link bringup on driver load
- iflib: do not ring the transmit doorbell when nothing is pending
- iflib: pass up the frames received before a descriptor error
- cxgbe: report SR-IOV VF status, KTLS fixes
- bnxt: 400GBase-FR4 support, skip HW kTLS on old firmware
- ixgbe: Total Port Shutdown on E610, missed packets counted as input
  drops only
- ice: VSI loopback in VEB mode, VF Tx queue restart and scheduler
  failure recovery
- iavf: honor negotiated VLAN offloads, report the VF RSS configuration
- igc: count packets dropped for want of a receive descriptor
- e1000: honor the common RSS hash-field policy
- ena: v2.8.6, many RSS fixes
- vtnet: honor the advertised MTU limit on attach
- iflib: prefer simple_tx over mp_ring, a single tx DMA map, rate
  limited deferred tx ring drain
- netmap: handle TX buffers larger than MCLBYTES

### Misc
- ip_encap: optionally rehash decapsulated tunnel packets on their inner
  addresses so multipath spreads them (net.route.hash_inbound, off by
  default)
- loopback: MTU set to IF_MAXMTU
- netipsec: fix V_spd_size updates
- nd6: fix regeneration of temporary addresses in detached state
- dummynet: fix an array overflow with large pipe profiles
- ipfw: hold the sleepable upper half lock for periodic state expiry
- ng_pppoe: fix m_pullup() logic
- if_media: add 100BASE-T1, 1000BASE-T1 and 400G FR4 media types
- gre: full GRE key support
- if_geneve: several receive path fixes
- if_bridge: use the bridge's FIB for incoming unicasts
- lacp: fix interfaces with unknown media
- carp: fix a race in the netlink get handler
- netinet6: check the hop limit after pfil in ip6_tryforward(), free the
  ICMPv6 copy on all ip6_forward() error paths
- netipsec: several SA/SAH leak and lock fixes in AH, ESP and IPComp;
  reject AH IPv4/IPv6 options running past the header, fix ESP stream
  cipher counter synchronization, select outbound transmit queues by SA
- ipfilter: UDP checksum fixes
- tcp: BBR and RACK fixes, sender side SWS avoidance
- ipfw_nat: fix a buffer length check in IP_FW_NAT44_XGETLOG
- bsnmpd: SNMPv3 discovery and input validation hardening
- netinet6: ip6_tryforward() keeps the next hop chosen by an ipfw fwd
  rule, and decrements the hop limit before the outbound hooks (pf
  route-to and reply-to no longer forward with the arrival hop limit)
- netipsec: set the outer IPv6 flow label of tunnel mode packets from
  the SA, so ECMP and lagg spread IPsec tunnels
- if_epair: hash the IP header, not the Ethernet header, for queue
  fanout (no more reordering within a flow)
- ipfw: fix an off-by-one in the IP_FW_XADD rule count check
- dummynet: validate object lengths in do_config()

## Upgraded packages
* bird3: 3.3.2_1 -> 3.4.0_1
* brotli: 1.2.0,1 -> 1.2.1_1,1
* c-ares: 1.34.8 -> 1.34.9
* cpu-microcode-intel: 20260812 -> 20260925
* curl: 8.22.0 -> 8.23.0
* expat: 2.8.4 -> 2.10.0
* iperf: 2.2.1 -> 2.2.2
* iperf3: 3.21 -> 3.22.1
* liblz4: 1.10.0_2,1 -> 1.11.1,1
* libucl: 0.9.4 -> 0.10.0
* monit: 6.0.0 -> 6.1.0
* mstflint: 4.37.0.1 -> 4.38.0.1
* nrpe: 4.1.3 -> 4.2.0
* open-vm-kmod: 13.1.0.1600026,2 -> 13.1.0.1600031,2
* openvpn: 2.7.7 -> 2.7.9
* pciids: 20260912 -> 20261115
* pcre2: 10.48 -> 10.49
* pimd: 3.1.0 -> 3.4.0
* pkg: 2.8.4 -> 2.9.3
* pkt-gen: g2025.10.08 -> g2026.08.08
* protobuf-c: 1.5.1_4 -> 1.5.2
* python312: 3.12.14 -> 3.12.16
* readline: 8.3.3 -> 8.3.6
* realtek-re-kmod: 1102.01.1600026_1 -> 1102.01.1600031_3
* simdjson: 4.6.11_1 -> 5.1.1
* tmux: 3.7c -> 3.8
* vim, xxd: 9.2.0738 -> 9.2.1302

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

### iflib (Intel, Broadcom... drivers)
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
