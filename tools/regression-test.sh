#!/bin/sh
#
# BSDRP regression-test driver
#
# SCOPE: this driver implements assertions for the "full" lab (5 VMs - the
# BSDRP maximum-features lab), the "anycast" lab (4 VMs - anycast DNS
# failover with ExaBGP), the "branch" lab (5 VMs - branch office ECMP over
# two WireGuard tunnels), the "ecmp" lab (4 VMs - static multipath routes
# over two links), the "ixp" lab (5 VMs - redundant BIRD and FRR route
# servers on a peering LAN), the "rtbh" lab (4 VMs - remotely triggered
# blackhole against a DDoS), the "accounting" lab (5 VMs - per-customer
# traffic accounting with NetFlow and pmacct) and the "ipv6only" lab (4 VMs
# - IPv6-only access with NAT64, DNS64 and 464XLAT). Other labs declared in
# tools/BSDRP-lab-bhyve.sh (frr, bgp, vpn, mlvpn, mlppp, fairshape, jailpf,
# pimsm, pimssm, vrrp, etc.) have no assertions defined here yet - running
# this driver against them will fail with "lab '<name>' has no assertions
# implemented yet".
#
# Drives the serial consoles of a lab launched by BSDRP-lab-bhyve.sh -r <lab>
# and runs per-VM assertions. Assertions for the "full" lab are derived from
# the wiki test plan at:
#   https://bsdrp.net/documentation/examples/maximum_bsdrp_features_lab
#
# Usage:
#   sudo tools/regression-test.sh [--boot-delay <s>] <image> <lab>
#   sudo tools/regression-test.sh --no-launch <lab>
#
# Default mode (image given): wipes any prior lab state, launches the lab via
# BSDRP-lab-bhyve.sh with the correct VM count for <lab>, sleeps for the boot
# delay (default 60s) so cloud-init/labconfig has time to finish, then runs
# the assertions.
#
# --no-launch mode: assumes the lab is already running and only runs the
# assertions. Useful for inner-loop debugging when iterating on assertions
# without rebooting the VMs.
#
# Runs every assertion unconditionally, including the slow ones
# (iperf3 throughput, SNMP, gmirror, nfacctd file poll, end-to-end
# IPv6 RA acquisition).
#
# Prerequisites:
#   - expect(1) installed on the host (FreeBSD: pkg install expect).
#     We use expect to drive /dev/nmdm-BSDRP.<N>B with proper tty/line
#     discipline; raw shell redirection (printf > /dev/nmdm) does NOT
#     drive a guest login(1) reliably.
#   - For --no-launch mode, the lab must already be running. For the "full"
#     lab, the EXACT launch command is (run from the repo root, with the
#     image you want to test):
#       sudo tools/BSDRP-lab-bhyve.sh -d     # wipe any prior VMs/disks/bridges
#       sudo tools/BSDRP-lab-bhyve.sh -i BSDRP-<version>-full-amd64.img.xz \
#                                    -n 5 -r full
#     -n MUST be 5 (full lab has exactly 5 VMs).  -r full selects the lab
#     family, which makes BSDRP-lab-bhyve.sh build per-VM cloud-init disks
#     that invoke `labconfig full_vm<N>` on first boot.
#
# Exit code:
#   0  all assertions passed
#   1  one or more assertions failed
#   2  setup/usage error
#
# Design notes:
# - For each console interaction we spawn a short-lived expect(1) script
#   that opens /dev/nmdm-BSDRP.<N>B, logs in if needed, runs the command,
#   and captures output between unique start/end markers. Output is then
#   matched against a success regex; the whole check is retried up to
#   RETRY_TIMEOUT to absorb convergence delays.
# - BSDRP ships root unlocked with no password (post-script.sh sets
#   PermitRootLogin yes but never sets a password), so login is just
#   sending "root\r" at the login: prompt - no Password: step.

set -u

PROG=$(basename "$0")
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Self-elevate via sudo if not already root. nmdm devices, bhyve, bridges,
# and ifconfig all require root; rather than aborting and asking the user
# to re-run with sudo, transparently re-exec under sudo (matching the
# style of BSDRP-lab-bhyve.sh which also relies on passwordless sudo).
# Done BEFORE arg parsing so "$@" still holds the original args.
if [ "$(id -u)" -ne 0 ]; then
	if ! command -v sudo >/dev/null 2>&1; then
		echo "ERROR: must run as root (sudo not found)" >&2
		exit 2
	fi
	exec sudo "$0" "$@"
fi
LAB=""
IMAGE=""
NO_LAUNCH=0
BOOT_DELAY=60        # seconds to wait after launching the lab before probing
                     # consoles, so cloud-init's first-boot runcmd (labconfig)
                     # has time to finish writing rc.conf and restarting
                     # services. The per-assertion retry budget absorbs the
                     # remainder of convergence.

PARSE_ERROR=""
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help)
			LAB=""
			break
			;;
		--no-launch|--already-running)
			NO_LAUNCH=1
			shift
			;;
		--boot-delay)
			[ $# -ge 2 ] || { PARSE_ERROR="--boot-delay requires an argument"; break; }
			BOOT_DELAY="$2"
			shift 2
			;;
		--boot-delay=*)
			BOOT_DELAY="${1#--boot-delay=}"
			shift
			;;
		-*)
			PARSE_ERROR="unknown option: $1"
			break
			;;
		*)
			# Positional: <image> <lab> in default mode, or <lab> alone
			# in --no-launch mode. We collect into IMAGE/LAB and sort
			# them out after parsing.
			if [ -z "$IMAGE" ] && [ -z "$LAB" ]; then
				IMAGE="$1"
			elif [ -z "$LAB" ]; then
				LAB="$1"
			else
				PARSE_ERROR="too many positional arguments"
				break
			fi
			shift
			;;
	esac
done

# Sort positionals based on mode.
if [ "$NO_LAUNCH" -eq 1 ]; then
	# --no-launch: image is irrelevant. If only one positional was given,
	# treat it as the lab name.
	if [ -z "$LAB" ] && [ -n "$IMAGE" ]; then
		LAB="$IMAGE"
		IMAGE=""
	fi
	# If both positionals were given with --no-launch, the image is
	# silently ignored (warn to be friendly).
	if [ -n "$IMAGE" ]; then
		echo "WARNING: --no-launch given; ignoring image argument '$IMAGE'" >&2
		IMAGE=""
	fi
fi

NMDM_PREFIX="/dev/nmdm-BSDRP."
NMDM_SUFFIX="B"

# Per-check tunables (seconds).
LOGIN_TIMEOUT=30
CMD_TIMEOUT=30        # per-command expect timeout
RETRY_TIMEOUT=45      # default per-assertion budget before declaring FAIL.
                      # Most checks converge in <30s; 45s is the safety margin.
                      # For slow-converging items (BGP, IS-IS, mpd5 PPTP),
                      # pass a longer per-call override via assert's 6th arg.
RETRY_INTERVAL=5

PASS=0
FAIL=0
FAILED_DETAIL=""

die() { echo "ERROR: $*" >&2; exit 2; }

usage() {
	cat >&2 <<EOF
$PROG - BSDRP regression-test driver

Usage:
  sudo $PROG [--boot-delay <s>] <image> <lab>
  sudo $PROG --no-launch <lab>

In default mode the driver auto-launches the lab: it runs
'BSDRP-lab-bhyve.sh -d' to wipe any prior state, then
'BSDRP-lab-bhyve.sh -i <image> -n <count> -r <lab>' with the VM count
(and any extra option, e.g. -l 1 for ecmp) derived from the lab name, sleeps for --boot-delay seconds (default 60),
and finally runs every assertion.

In --no-launch mode the lab must already be running:
  sudo tools/BSDRP-lab-bhyve.sh -i <image> -n <count> -r <lab>
(add -l 1 for the ecmp lab)

Options:
  --no-launch        Skip the wipe+launch step (alias: --already-running).
  --boot-delay <s>   Seconds to wait after launch for cloud-init/labconfig
                     to settle (default: 60).
  -h, --help         Show this help.

Implemented labs:
  full     5 VMs - per wiki: https://bsdrp.net/documentation/examples/maximum_bsdrp_features_lab

Requires: expect(1) on the host (pkg install expect).
EOF
	exit 2
}

[ -n "$PARSE_ERROR" ] && { echo "$PROG: $PARSE_ERROR" >&2; usage; }
if [ -z "$LAB" ]; then
	# Distinguish "no args at all" (just show usage) from "args given but
	# <lab> is missing" (the common case: user passed only the image path
	# and forgot the lab name).
	if [ -n "$IMAGE" ]; then
		echo "$PROG: missing <lab> argument (got only '$IMAGE')" >&2
	fi
	usage
fi

# Validate --boot-delay is a non-negative integer.
case "$BOOT_DELAY" in
	''|*[!0-9]*) die "--boot-delay must be a non-negative integer (got '$BOOT_DELAY')" ;;
esac

# In default (launch) mode, an image path is required and must exist.
if [ "$NO_LAUNCH" -eq 0 ]; then
	[ -n "$IMAGE" ] || { echo "$PROG: <image> is required (or pass --no-launch)" >&2; usage; }
	[ -f "$IMAGE" ] || die "image not found: $IMAGE"
fi

# expect(1) is mandatory - raw shell redirection to nmdm cannot drive
# a guest login(1)/sh prompt reliably.
EXPECT_BIN=$(command -v expect 2>/dev/null || true)
[ -n "$EXPECT_BIN" ] && [ -x "$EXPECT_BIN" ] \
	|| die "expect(1) not found in PATH - install with: pkg install expect"

# === Workdir ==============================================================

WORKDIR=$(mktemp -d /tmp/bsdrp-regtest.XXXXXX) || die "cannot mktemp"

cleanup() {
	rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

# === expect-based console driver ==========================================
#
# console_run <nmdm> <cmd>
#   - opens the nmdm device, ensures we're at a shell prompt (logging in
#     as root if a login: prompt is seen),
#   - sends "$cmd" framed by unique markers, captures output between them,
#   - prints the captured output on stdout,
#   - exits 0 on success, non-zero on timeout/IO error.
#
# The expect script is heredoc'd to a temp file so the command body (which
# may contain quotes, $, etc.) is passed via an environment variable rather
# than interpolated into Tcl.

EXPECT_DRIVER="${WORKDIR}/console_run.exp"
cat >"$EXPECT_DRIVER" <<'EOF'
#!/usr/bin/env expect
# Args: <nmdm-device> <login-timeout> <cmd-timeout>
# Reads the command to run from env var REGTEST_CMD.
# Prints captured command output (between START_<tag>_S and END_<tag>_E)
# on stdout. Exits non-zero on any timeout.

if {$argc < 3} {
    puts stderr "usage: $argv0 <nmdm> <login_timeout> <cmd_timeout>"
    exit 2
}
set nmdm        [lindex $argv 0]
set login_to    [lindex $argv 1]
set cmd_to      [lindex $argv 2]
set cmd         $env(REGTEST_CMD)

# Unique marker so we can pluck just this command's output out of the
# console stream (other VMs/services may be logging concurrently).
set tag [pid]_[clock clicks]
set start_marker "REGTEST_S_${tag}"
set end_marker   "REGTEST_E_${tag}"

# Open the nmdm device for read+write and spawn expect on the resulting fd.
if {[catch {open $nmdm "r+"} fd]} {
    puts stderr "open $nmdm failed: $fd"
    exit 3
}
fconfigure $fd -translation binary -buffering none
# CRITICAL: silence the spawned process's stdout passthrough so our captured
# output isn't polluted with the entire console banter (prompts, echoed
# commands, marker lines, etc.). Without this, console_run's stdout =
# everything expect saw + our final puts $captured -- which breaks any
# caller that does $(console_run ...) and tries to parse just the command
# output (e.g. capturing an IPv6 address via awk).
# -noecho on `spawn` suppresses the "spawn [open ...]" banner that spawn
# prints to its own stdout (not gated by log_user).
log_user 0
spawn -noecho -open $fd

# Nudge the console so we see *something* (login: or a prompt).
# A bare \r is not enough when cloud-init's labconfig is still running
# with the console attached - getty has not taken back the tty. Sending
# Ctrl-C interrupts any still-running labconfig (it has already done its
# sysrc work by the time we attach) and frees the line for getty.
send "\x03"
sleep 1
send "\r"

set timeout $login_to
expect {
    -re {login: *$} {
        send "root\r"
        # After "root\r" we may see motd / "Last login:" / etc. before $/#.
        # Don't reset timeout - the prompt should arrive quickly after.
        exp_continue
    }
    -re {Password: *$} {
        # BSDRP root has no password, but be defensive.
        send "\r"
        exp_continue
    }
    -re {[#$] $} {
        # Already at a shell prompt.
    }
    timeout {
        puts stderr "TIMEOUT waiting for login/prompt"
        exit 4
    }
}

# Frame the command with markers so we can extract just its output.
# Use printf so the markers print on their own lines even if $cmd doesn't
# end with a newline. We anchor the start marker on a NEWLINE: the
# command itself is echoed by the tty and contains the literal marker
# text, but only the real printf output puts the marker after a \n.
set timeout $cmd_to
send "printf '\\n%s\\n' '${start_marker}'; ${cmd}; printf '%s\\n' '${end_marker}_END'\r"

# Wait for the start marker preceded by a newline (skips the echoed command line).
expect {
    -re "\n${start_marker}\r?\n" {}
    timeout {
        puts stderr "TIMEOUT waiting for start marker"
        exit 5
    }
}

# Buffer output until end marker.
set captured ""
expect {
    -re "(.*)${end_marker}_END" {
        set captured $expect_out(1,string)
    }
    timeout {
        puts stderr "TIMEOUT waiting for end marker"
        exit 6
    }
}

# Strip CR noise.
regsub -all "\r" $captured "" captured
puts -nonewline $captured
exit 0
EOF
chmod +x "$EXPECT_DRIVER"

# Run a single command on a VM console, return its stdout.
# Optional 3rd arg overrides per-call CMD_TIMEOUT (seconds) for slow
# commands (newfs, large kldload, etc).
console_run() {
	# Args: nmdm cmd [cmd_timeout_override]
	local nmdm="$1" cmd="$2" cmd_to="${3:-$CMD_TIMEOUT}"
	[ -n "$cmd_to" ] || cmd_to="$CMD_TIMEOUT"
	REGTEST_CMD="$cmd" "$EXPECT_BIN" -f "$EXPECT_DRIVER" \
		"$nmdm" "$LOGIN_TIMEOUT" "$cmd_to" 2>/dev/null
}

# Retry a console command until its output matches success_regex or we
# exceed the per-call timeout (default RETRY_TIMEOUT).
# Prints the last output on stdout.
# Note: ${4:-...} is required because the script runs under set -u.
retry_check() {
	# Args: nmdm cmd success_regex [timeout_override]
	local nmdm="$1" cmd="$2" success_regex="$3"
	local timeout="${4:-$RETRY_TIMEOUT}"
	# Allow empty 4th arg from assert() to also mean "use default":
	[ -n "$timeout" ] || timeout="$RETRY_TIMEOUT"
	local t=0 out
	while [ "$t" -lt "$timeout" ]; do
		out=$(console_run "$nmdm" "$cmd" || true)
		if printf '%s' "$out" | grep -Eq -- "$success_regex"; then
			printf '%s' "$out"
			return 0
		fi
		sleep "$RETRY_INTERVAL"
		t=$((t + RETRY_INTERVAL))
	done
	printf '%s' "$out"
	return 1
}

# === Recording ============================================================

record() {
	local vm="$1" check="$2" status="$3" detail="$4"
	if [ "$status" = "PASS" ]; then
		PASS=$((PASS + 1))
		echo "  [PASS] VM${vm}: ${check}"
	else
		FAIL=$((FAIL + 1))
		echo "  [FAIL] VM${vm}: ${check} - ${detail}"
		FAILED_DETAIL="${FAILED_DETAIL}
VM${vm} ${check}: ${detail}"
	fi
}

# Shorthand: run a retry_check and record PASS/FAIL.
# Optional 6th arg overrides RETRY_TIMEOUT for slow-converging checks
# (e.g. mpd5 PPTP, IS-IS adjacency). Keep the default short so failures
# don't bloat total runtime: 8 fails × 45s = 6 min, vs 16 min at 120s.
# Note: ${6:-} (not $6) is required because the script runs under set -u.
assert() {
	# Args: vm name nmdm cmd success_regex [timeout_override]
	local vm="$1" name="$2" nmdm="$3" cmd="$4" rx="$5" timeout="${6:-}"
	if retry_check "$nmdm" "$cmd" "$rx" "$timeout" >/dev/null; then
		record "$vm" "$name" PASS ""
	else
		record "$vm" "$name" FAIL "no match for /$rx/"
	fi
}

# === Topology dump =========================================================
#
# Prints interfaces and routing tables for one VM. Informational only - does
# NOT record PASS/FAIL. Used in Phase 1 of the driver so the operator (and
# the log) sees the full topology BEFORE any ping/iperf assertion runs.
dump_vm_topology() {
	local vm="$1" nmdm="$2"
	echo "--- VM${vm}: interfaces ---"
	console_run "$nmdm" \
		"ifconfig -a | grep -E '^[a-z]|inet |inet6 [^f]|carp:|laggproto|status:|vhid'" \
		2>/dev/null | sed 's/^/    /'
	echo "--- VM${vm}: IPv4 route table ---"
	console_run "$nmdm" "netstat -rn -f inet 2>&1" 2>/dev/null | sed 's/^/    /'
	echo "--- VM${vm}: IPv6 route table ---"
	console_run "$nmdm" "netstat -rn -f inet6 2>&1" 2>/dev/null | sed 's/^/    /'
}

# === full lab: assertions from the wiki ===================================
#
# Source: https://bsdrp.net/documentation/examples/maximum_bsdrp_features_lab
# Each check below cites the wiki section it implements.

# ---- R1 ------------------------------------------------------------------
lab_full_vm1() {
	local nmdm="$1"

	# wiki/R1 Basic Connectivity
	assert 1 "hostname is R1" "$nmdm" "hostname" '^R1$'
	assert 1 "lagg0 loadbalance mode" "$nmdm" \
		"ifconfig lagg0" 'laggproto loadbalance'

	# wiki/R1 SSH Access
	assert 1 "sshd service running" "$nmdm" \
		"service sshd status 2>&1" 'is running'

	# wiki/R1: lagg0 should have a DHCP-acquired address. The DHCP server
	# is dhcpd inside jail5 (R5) - this validates DHCP relay (R2) too.
	# Testing R1 last in lab_vm_order is not enough to make this converge:
	# R1 boots before jail5 exists, so its first DHCPDISCOVER goes
	# unanswered and dhclient then backs off 2/4/8/16/32/64s before asking
	# again. The lease therefore lands minutes after boot, long after the
	# default 45s budget, and the next two checks are downstream of it.
	# Give the lease a budget that covers a couple of backoff rounds.
	assert 1 "lagg0 has DHCP-acquired IPv4 (10.0.12.1)" "$nmdm" \
		"ifconfig lagg0 inet" 'inet 10\.0\.12\.1[[:space:]]' 240
	# Default route points to R2's CARP VIP. It arrives with the lease, so
	# a short budget is enough once the check above has passed - and keeps
	# a genuinely leaseless lab from paying 240s again here.
	assert 1 "default route via R2 CARP (10.0.12.254)" "$nmdm" \
		"netstat -rn4 2>&1" 'default[[:space:]]+10\.0\.12\.254' 60

	# Reachability sanity check before iperf3 - if R1 cannot reach jail6 the
	# iperf3 run is pointless and reports faster.
	# Path: R1 -> R2 -> PPTP tunnel (shaped by R4 pipes) -> R4 -> R5 -> jail6.
	# Also downstream of the lease: short budget for the same reason.
	assert 1 "R1 reachability to jail6 (10.0.56.6)" "$nmdm" \
		"ping -c 3 -W 2000 10.0.56.6 2>&1" '[123] packets received' 60

	# IPv6 control plane end to end. Forward path: RA default route via
	# R2 -> BGP IPv6 (R2 FRR <-> R3 bird) -> RIPng (R3 -> R4). Return path:
	# OSPFv3 over the ng1 PPTP tunnel (R4 -> R2). A break in any of these
	# IPv6 protocols fails this ping.
	assert 1 "R1 IPv6 reachability to R4 lo1 (2001:db8::4)" "$nmdm" \
		"ping6 -c 3 2001:db8::4 2>&1" '[123] packets received' 60

	# WireGuard road warrior to R4's loopback: the pings run inside the
	# tunnel, the handshake timestamp proves the keys were accepted.
	assert 1 "WireGuard: ping R4 through wg0 (10.9.14.4)" "$nmdm" \
		"ping -c 3 -W 1000 10.9.14.4 2>&1" '[123] packets received' 60
	assert 1 "WireGuard: ping6 R4 through wg0 (2001:db8:914::4)" "$nmdm" \
		"ping6 -c 2 2001:db8:914::4 2>&1" '[12] packets received'
	assert 1 "WireGuard: handshake with R4 completed" "$nmdm" \
		"wg show wg0 latest-handshakes 2>&1" '[[:space:]][1-9][0-9]+$'

	# DHCPv6 address from dhcp6s on R3, relayed by R2's dhcp6relay. Like the
	# DHCPv4 lease, the first Solicits go out before the server is up and
	# dhcp6c backs off (up to 120s between them).
	assert 1 "DHCPv6: lagg0 leased 2001:db8:12::1xx via R2's relay" "$nmdm" \
		"ifconfig lagg0 inet6" 'inet6 2001:db8:12::1[0-9a-f]{2} prefixlen 128' 240

	# wiki/R1 SNMP: bsnmpget to jail6 returns sysName.0 = "jail6".
	# Exercises the same full path as the iperf3 test but with bsnmpd
	# in jail6 - confirms snmp UDP/161 traverses the PPTP tunnel both
	# ways and that jail6's bsnmpd is reachable via its IPv4 address.
	assert 1 "R1 SNMP get sysName.0 from jail6 (IPv4)" "$nmdm" \
		"bsnmpget -s 10.0.56.6 sysName.0 2>&1" 'sysName\.0[[:space:]]*=[[:space:]]*jail6'

	# wiki/R1 SNMP UCD MIB: bsnmpwalk under 1.3.6.1.4.1.2021.100.2.0
	# (Net-SNMP versionTag) must return a value, which proves that
	# jail6's bsnmpd has the UCD module (snmp_ucd.so) loaded. The
	# value is the bsnmp-ucd port's CVS Name tag (e.g.
	# "$Name: bsnmp-ucd-0-4-3 $") - we just match on "bsnmp-ucd".
	assert 1 "R1 SNMP walk UCD versionTag from jail6 (IPv4)" "$nmdm" \
		"bsnmpwalk -s 10.0.56.6 1.3.6.1.4.1.2021.100.2.0 2>&1" \
		'bsnmp-ucd'

	# wiki/R1 SNMP IPv6: same path but to jail6's SLAAC address (must
	# be resolved first because jail6 has no static ::6, only autoconf).
	# Two-step: query the address from jail5's nmdm, then issue bsnmpget.
	local nmdm5_v6="${NMDM_PREFIX}5${NMDM_SUFFIX}"
	local jail6_v6
	jail6_v6=$(console_run "$nmdm5_v6" \
		"jexec jail6 ifconfig lagg0 inet6 | awk '/inet6 2001:/{print \$2; exit}'" \
		| tr -d '[:space:]')
	if [ -n "$jail6_v6" ]; then
		assert 1 "R1 SNMP get sysName.0 from jail6 (IPv6)" "$nmdm" \
			"bsnmpget -s [${jail6_v6}]:161 sysName.0 2>&1" \
			'sysName\.0[[:space:]]*=[[:space:]]*jail6'
	else
		record 1 "R1 SNMP get sysName.0 from jail6 (IPv6)" FAIL \
			"could not resolve jail6 SLAAC IPv6 from jail5"
	fi

	# wiki/R1 GEOM mirror: build a small 2-way mirror over memory disks
	# and newfs it. Validates that geom_mirror.ko is shipped + loadable,
	# that mdconfig works, and that newfs can format the mirror. The
	# final assertion checks the mirror state is COMPLETE (both halves
	# in sync, which is immediate for fresh empty MDs). Cleanup runs
	# unconditionally afterwards so the test is idempotent.
	#
	# NOTE: we kldload geom_mirror explicitly. On FreeBSD (verified on
	# 16-CURRENT, both stock and BSDRP), `gmirror label` does NOT
	# auto-load the module — it writes the on-disk metadata via
	# /lib/geom/geom_mirror.so and exits 0 silently, but kldstat shows
	# the module is not loaded and `gmirror status` then complains
	# "Command 'status' not available; try 'load' first."
	# This is stock FreeBSD behavior, not a BSDRP regression.
	# IMPORTANT: each console_run sends ONE line over the guest's TTY,
	# which is in canonical mode with MAX_INPUT = 255 bytes. Longer
	# lines are SILENTLY truncated, dropping trailing commands. We split
	# the gmirror setup into several short console_run calls instead.
	console_run "$nmdm" \
		"gmirror destroy r1regress 2>/dev/null; mdconfig -d -u md10 2>/dev/null; mdconfig -d -u md11 2>/dev/null" 30 >/dev/null
	console_run "$nmdm" "kldload geom_mirror" 30 >/dev/null
	console_run "$nmdm" \
		"mdconfig -s 100m -u md10 && mdconfig -s 100m -u md11 && gmirror label r1regress md10 md11 && newfs /dev/mirror/r1regress >/dev/null 2>&1 && echo GMIRROR_OK" 60 >/dev/null
	assert 1 "R1 gmirror 2-way mirror COMPLETE (geom_mirror.ko)" "$nmdm" \
		"gmirror status 2>&1" 'mirror/r1regress[[:space:]]+COMPLETE'
	# Cleanup: destroy mirror, free the MD backing stores, AND kldunload
	# geom_mirror so a subsequent run of this test (without rebooting the
	# VMs) starts from a clean "module unloaded" state. Split into short
	# lines because the guest TTY MAX_INPUT is 255 bytes (see above).
	console_run "$nmdm" \
		"gmirror destroy r1regress 2>/dev/null; mdconfig -d -u md10 2>/dev/null; mdconfig -d -u md11 2>/dev/null" 30 >/dev/null
	console_run "$nmdm" "kldunload geom_mirror 2>/dev/null" 30 >/dev/null
}

# ---- R2 ------------------------------------------------------------------
lab_full_vm2() {
	local nmdm="$1"

	# wiki/R2 Basic Connectivity
	assert 2 "hostname is R2" "$nmdm" "hostname" '^R2$'
	# em0 (or vtnet0) carries 10.0.12.2/24
	assert 2 "10.0.12.2 on em0/vtnet0" "$nmdm" \
		"ifconfig | grep -E 'inet 10\\.0\\.12\\.2 '" 'inet 10\.0\.12\.2'

	# wiki/R2 BGP with IPsec
	# Wiki says: `vtsh -c "show bgp summary"` -> peer 10.0.23.3 Established.
	# FRR's `show bgp summary` shows a numeric PfxRcd in the State column
	# when a session is Established (a state word otherwise).
	assert 2 "BGP peer 10.0.23.3 Established" "$nmdm" \
		"vtysh -c 'show bgp summary' 2>&1" \
		'10\.0\.23\.3[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9:]+[[:space:]]+[0-9]+'

	# Same Established pattern on the IPv6 session, which FRR only lists
	# under the IPv6 unicast address family.
	assert 2 "BGP peer 2001:db8:23::3 Established" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast summary' 2>&1" \
		'2001:db8:23::3[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9:]+[[:space:]]+[0-9]+'

	# wiki/R2 IPsec TCP-MD5: setkey -D shows SAD entries for 10.0.23.{2,3}
	# and 2001:db8:23::{2,3}.
	assert 2 "IPsec SA to 10.0.23.3 present" "$nmdm" \
		"setkey -D 2>&1" '10\.0\.23\.3'
	assert 2 "IPsec SA to 2001:db8:23::3 present" "$nmdm" \
		"setkey -D 2>&1" '2001:db8:23::3'

	# The SAs above are actually used: BGP segments arrive signed and
	# every signature verifies. An Established session alone does not
	# prove this.
	assert 2 "TCP-MD5 signed segments received" "$nmdm" \
		"netstat -s -p tcp 2>&1" '[1-9][0-9]* packets with matching signature received'
	assert 2 "TCP-MD5 no bad signature" "$nmdm" \
		"netstat -s -p tcp 2>&1" '^[[:space:]]*0 packets with bad signature received'

	# wiki/R2 Reachability: ping R3's loopback.
	assert 2 "ping R3 loopback 10.0.0.3" "$nmdm" \
		"ping -c 2 -W 1000 10.0.0.3 2>&1" '0(\.0)?% packet loss|1 packets received|2 packets received'

	# wiki/R2 CARP: em0 alias 10.0.12.254/32 vhid 1
	assert 2 "CARP vhid 1 on em0/vtnet0" "$nmdm" \
		"ifconfig | grep -E 'vhid 1'" 'vhid 1'

	# wiki/R2 PPTP VPN Server: mpd5 listens on tcp/1723.
	assert 2 "mpd5 listening on tcp/1723" "$nmdm" \
		"sockstat -4 -l -p 1723 2>&1" 'mpd5|1723'

	# Both PPTP bundles from R4 negotiated: ng0 carries the IPCP pair,
	# ng1 the IPv6 address set by mpd5's if-up.sh. R2 is probed first, so
	# give the PPTP handshake time to finish.
	assert 2 "PPTP ng0 up (10.4.24.2 --> 10.4.24.4)" "$nmdm" \
		"ifconfig ng0 2>&1" 'inet 10\.4\.24\.2 --> 10\.4\.24\.4' 120
	assert 2 "PPTP ng1 up (2001:db8:24::2)" "$nmdm" \
		"ifconfig ng1 2>&1" 'inet6 2001:db8:24::2 ' 120

	# wiki/R2 DHCP relay: dhcprelya running.
	assert 2 "dhcprelya running" "$nmdm" \
		"pgrep -lf dhcprelya || echo none" 'dhcprelya'

	# wiki/R2 OSPF area 0 has routes.
	assert 2 "OSPF area 0.0.0.0 has routes" "$nmdm" \
		"vtysh -c 'show ip ospf route' 2>&1" 'O[[:space:]]|0\.0\.0\.0'

	# OSPFv3 adjacency to R4 over the ng1 (IPv6 PPTP) tunnel.
	assert 2 "OSPFv3 neighbor R4 (0.0.0.4) Full on ng1" "$nmdm" \
		"vtysh -c 'show ipv6 ospf6 neighbor' 2>&1" '^0\.0\.0\.4[[:space:]].*Full.*ng1' 60

	# BFD sessions to R4, registered by OSPF on ng0 (IPv4) and OSPFv3 on
	# ng1 (IPv6, link-local endpoints).
	assert 2 "BFD peer 10.4.24.4 up (OSPF on ng0)" "$nmdm" \
		"vtysh -c 'show bfd peers brief' 2>&1" '10\.4\.24\.2[[:space:]]+10\.4\.24\.4[[:space:]]+up'
	assert 2 "BFD IPv6 peer up (OSPFv3 on ng1)" "$nmdm" \
		"vtysh -c 'show bfd peers brief' 2>&1" 'fe80::[0-9a-f:]+[[:space:]]+fe80::[0-9a-f:]+[[:space:]]+up'

	# BFD between two implementations: FRR bfdd here, bird on R3, both
	# registered by the BGP sessions.
	assert 2 "BFD peer 10.0.23.3 up (BGP, bird)" "$nmdm" \
		"vtysh -c 'show bfd peers brief' 2>&1" '10\.0\.23\.2[[:space:]]+10\.0\.23\.3[[:space:]]+up'
	assert 2 "BFD peer 2001:db8:23::3 up (BGP, bird)" "$nmdm" \
		"vtysh -c 'show bfd peers brief' 2>&1" '2001:db8:23::2[[:space:]]+2001:db8:23::3[[:space:]]+up'

	# ExaBGP on R4 -> bird on R3 -> FRR here: the TEST-NET prefixes arrive
	# with ExaBGP's AS and next hop, learned from R3. Lines joined so the AS
	# path, next hop and best flag match as one entry.
	assert 2 "ExaBGP: 192.0.2.0/24 from R4 relayed by bird" "$nmdm" \
		"vtysh -c 'show ip bgp 192.0.2.0/24' 2>&1 | paste -s -d ' ' -" \
		'65004[[:space:]]+10\.0\.34\.4 from 10\.0\.23\.3 .*best'
	assert 2 "ExaBGP: 2001:db8:ffff::/48 from R4 relayed by bird" "$nmdm" \
		"vtysh -c 'show bgp ipv6 2001:db8:ffff::/48' 2>&1 | paste -s -d ' ' -" \
		'65004[[:space:]]+2001:db8:34::4 from 2001:db8:23::3 .*best'

	# R1's DHCPv6 relay towards R3 (asserted end to end on R1).
	assert 2 "dhcp6relay running" "$nmdm" \
		"pgrep -lf sbin/dhcp6relay || echo none" 'dhcp6relay'

	# LLDP: the host bridges between VMs drop the LLDP multicast address
	# (802.1D reserved range), so R4 is only seen across the VXLAN overlay.
	assert 2 "LLDP: neighbor R4 over vxlan0" "$nmdm" \
		"lldpcli -f keyvalue show neighbors 2>&1" '^lldp\.vxlan0\.chassis\.name=R4$'

	# Route-based IPsec: strongSwan negotiates IKEv2 and installs the ESP
	# SAs for if_ipsec ipsec0 (reqid 100), underlay 10.0.23.2 <-> 10.0.34.4
	# through R3. R2 initiates; give it time to retry while routes converge.
	assert 2 "IPsec: IKEv2 SA up, ipsec0 CHILD_SA installed (AES-GCM)" "$nmdm" \
		"swanctl --list-sas 2>&1" 'ipsec0: #[0-9]+, reqid 100, INSTALLED, TUNNEL, ESP:AES_GCM_16-256' 120
	assert 2 "IPsec: ping R4 through ipsec0 (10.8.24.4)" "$nmdm" \
		"ping -c 2 -W 1000 10.8.24.4 2>&1" '[12] packets received'
	assert 2 "IPsec: ping6 R4 through ipsec0 (2001:db8:824::4)" "$nmdm" \
		"ping6 -c 2 2001:db8:824::4 2>&1" '[12] packets received'
	# The pings above decrypted on the inbound SA.
	assert 2 "IPsec: inbound ESP SA counted packets" "$nmdm" \
		"swanctl --list-sas 2>&1" 'in  [0-9a-f]+, +[1-9][0-9]* bytes'

	# L2 overlays to R4: VXLAN over the IPv4 loopbacks, GENEVE over the
	# IPv6 ones. The first ping may be lost to ARP over the overlay.
	assert 2 "VXLAN: vxlan0 vni 42 10.0.0.2 -> 10.0.0.4" "$nmdm" \
		"ifconfig vxlan0 2>&1" 'vni 42 local 10\.0\.0\.2:4789 remote 10\.0\.0\.4:4789'
	assert 2 "VXLAN: ping R4 over vxlan0 (10.7.24.4)" "$nmdm" \
		"ping -c 2 -W 1000 10.7.24.4 2>&1" '[12] packets received'
	assert 2 "GENEVE: ping R4 over geneve0 (10.7.25.4)" "$nmdm" \
		"ping -c 2 -W 1000 10.7.25.4 2>&1" '[12] packets received'
	assert 2 "GENEVE: ping6 R4 over geneve0 (2001:db8:725::4)" "$nmdm" \
		"ping6 -c 2 2001:db8:725::4 2>&1" '[12] packets received'

	# wiki/R2 pimd running. Cross-checked from R4's neighbor table in
	# lab_full_vm4 (R4 sees R2 over both ng0/ng1 PPTP tunnels).
	assert 2 "pimd running" "$nmdm" \
		"pgrep -lf sbin/pimd || echo none" 'pimd'

	# wiki/R2 is the PIM Candidate-BSR and wins the election (priority 200),
	# and is deliberately NOT a Candidate-RP: R4 runs FRR's pimd as the sole
	# CRP, so every Bootstrap carries an RP the other implementation wrote
	# the Advertisement for. The BSR address is not asserted: pimd picks its
	# highest active address, which depends on PPP link order.
	assert 2 "PIM elected BSR priority 200" "$nmdm" \
		"pimctl show status 2>&1" 'Priority[[:space:]]*:[[:space:]]*200'
	assert 2 "PIM Candidate-RP disabled (R4/FRR is the RP)" "$nmdm" \
		"pimctl show status 2>&1 | grep -A2 'Candidate RP'" 'Disabled'

	# wiki/R2 BSR learned R4's Candidate-RP-Advertisement. This is FRR's
	# CRP-Adv parsed by pimd's BSR - one of the two directions only a
	# mixed-implementation lab can test.
	assert 2 "PIM RP set learned 10.0.0.4 from FRR's CRP-Adv" "$nmdm" \
		"pimctl show rp 2>&1" '224\.0\.0\.0/4[[:space:]]+10\.0\.0\.4' 120
}

# ---- R3 ------------------------------------------------------------------
lab_full_vm3() {
	local nmdm="$1"

	# wiki/R3 Basic Connectivity
	assert 3 "hostname is R3" "$nmdm" "hostname" '^R3$'
	assert 3 "VLAN 23: 10.0.23.3 on em1.23/vtnet1.23" "$nmdm" \
		"ifconfig | grep -E 'inet 10\\.0\\.23\\.3 '" 'inet 10\.0\.23\.3'

	# wiki/R3 BGP via bird: protocols R2inet4 and R2inet6 Established.
	# Match each by name so one session cannot pass for the other.
	assert 3 "bird BGP to R2 (IPv4) Established" "$nmdm" \
		"birdc show protocols 2>&1" 'R2inet4[[:space:]]+BGP.*Established'
	assert 3 "bird BGP to R2 (IPv6) Established" "$nmdm" \
		"birdc show protocols 2>&1" 'R2inet6[[:space:]]+BGP.*Established'

	# bird's side of the BFD sessions with FRR on R2. Single-hop, so the
	# interface column names the VLAN 23 link.
	assert 3 "bird BFD session to R2 (10.0.23.2) Up" "$nmdm" \
		"birdc show bfd sessions 2>&1" '^10\.0\.23\.2[[:space:]]+[a-z]+1\.23[[:space:]]+Up'
	assert 3 "bird BFD session to R2 (2001:db8:23::2) Up" "$nmdm" \
		"birdc show bfd sessions 2>&1" '^2001:db8:23::2[[:space:]]+[a-z]+1\.23[[:space:]]+Up'

	# ExaBGP sessions from R4 and the prefixes it injects.
	assert 3 "bird BGP to ExaBGP (IPv4) Established" "$nmdm" \
		"birdc show protocols 2>&1" 'EXA4[[:space:]]+BGP.*Established'
	assert 3 "bird BGP to ExaBGP (IPv6) Established" "$nmdm" \
		"birdc show protocols 2>&1" 'EXA6[[:space:]]+BGP.*Established'
	assert 3 "ExaBGP: 192.0.2.0/24 received (AS65004)" "$nmdm" \
		"birdc show route 192.0.2.0/24 2>&1" '\[EXA4 .*\[AS65004i\]'
	assert 3 "ExaBGP: 2001:db8:ffff::/48 received (AS65004)" "$nmdm" \
		"birdc show route 2001:db8:ffff::/48 2>&1" '\[EXA6 .*\[AS65004i\]'

	# DHCPv6 server for R1 (asserted end to end on R1).
	assert 3 "dhcp6s running" "$nmdm" \
		"pgrep -lf sbin/dhcp6s || echo none" 'dhcp6s'

	# wiki/R3 IPsec to R2
	assert 3 "IPsec SA to 10.0.23.2 present" "$nmdm" \
		"setkey -D 2>&1" '10\.0\.23\.2'
	assert 3 "IPsec SA to 2001:db8:23::2 present" "$nmdm" \
		"setkey -D 2>&1" '2001:db8:23::2'
	assert 3 "TCP-MD5 signed segments received" "$nmdm" \
		"netstat -s -p tcp 2>&1" '[1-9][0-9]* packets with matching signature received'
	assert 3 "TCP-MD5 no bad signature" "$nmdm" \
		"netstat -s -p tcp 2>&1" '^[[:space:]]*0 packets with bad signature received'

	# wiki/R3 RIP/RIPng routes from R4 visible in bird.
	assert 3 "bird RIP routes present" "$nmdm" \
		"birdc show route 2>&1" 'RIP|via 10\.0\.34'

	# wiki/R3 PF: pfctl reports state info and rules.
	assert 3 "pf enabled" "$nmdm" \
		"pfctl -si 2>&1" 'Status: Enabled'

	# pf keeps state for the PPTP tunnels R2<->R4 that transit R3: the
	# GRE data channel, IPv4 and IPv6.
	assert 3 "pf GRE state 10.0.0.2 <-> 10.0.0.4 (PPTP transit)" "$nmdm" \
		"pfctl -ss 2>&1" 'gre 10\.0\.0\.[24] (->|<-) 10\.0\.0\.[24] '
	assert 3 "pf GRE state 2001:db8::2 <-> 2001:db8::4 (PPTP transit)" "$nmdm" \
		"pfctl -ss 2>&1" 'gre 2001:db8::[24] (->|<-) 2001:db8::[24] '

	# R3's pf drops transit TCP to port 2323. Probe from R2 towards R4's
	# loopback, which routes through R3: the SYN must time out rather
	# than be refused by R4. A non-filtered port is the control: refused
	# proves R4 is reachable, so the timeout comes from pf.
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	assert 2 "control: tcp/2324 to R4 refused (not filtered)" "$nmdm2" \
		"nc -v -z -w 3 10.0.0.4 2324 2>&1" 'Connection refused'
	assert 2 "R3 pf drops tcp/2323 to R4 (IPv4)" "$nmdm2" \
		"nc -v -z -w 3 10.0.0.4 2323 2>&1" 'Operation timed out'
	assert 2 "R3 pf drops tcp/2323 to R4 (IPv6)" "$nmdm2" \
		"nc -v -z -w 3 2001:db8::4 2323 2>&1" 'Operation timed out'
	# pfctl -sl: label evals packets bytes ...; the SYNs above must have
	# hit the rule.
	assert 3 "pf block rule counted the dropped SYNs" "$nmdm" \
		"pfctl -sl 2>&1" '^lab-block-2323 [0-9]+ [1-9][0-9]* '
}

# ---- R4 ------------------------------------------------------------------
lab_full_vm4() {
	local nmdm="$1"

	# wiki/R4 Basic Connectivity
	assert 4 "hostname is R4" "$nmdm" "hostname" '^R4$'
	assert 4 "lo1 carries 10.0.0.4" "$nmdm" \
		"ifconfig lo1" 'inet 10\.0\.0\.4'

	# wiki/R4 PPTP client: ng0 should appear once the tunnel comes up.
	# mpd5 brings up ng0 (IPv4 PPTP) and ng1 (IPv6 PPTP) toward R2.
	assert 4 "ng0 (PPTP IPv4) up" "$nmdm" \
		"ifconfig ng0 2>&1" 'inet 10\.4\.24\.4 --> 10\.4\.24\.2'
	assert 4 "ng1 (PPTP IPv6) up" "$nmdm" \
		"ifconfig ng1 2>&1" 'inet6 2001:db8:24::4 '

	# Traffic through both MPPE-encrypted tunnels to R2's end.
	assert 4 "ping R2 through ng0 (10.4.24.2)" "$nmdm" \
		"ping -c 2 -W 1000 10.4.24.2 2>&1" '[12] packets received'
	assert 4 "ping6 R2 through ng1 (2001:db8:24::2)" "$nmdm" \
		"ping6 -c 2 2001:db8:24::2 2>&1" '[12] packets received'

	# OSPFv3 and BFD, the R4 side of the R2 checks.
	assert 4 "OSPFv3 neighbor R2 (0.0.0.2) Full on ng1" "$nmdm" \
		"vtysh -c 'show ipv6 ospf6 neighbor' 2>&1" '^0\.0\.0\.2[[:space:]].*Full.*ng1'
	assert 4 "BFD peer 10.4.24.2 up (OSPF on ng0)" "$nmdm" \
		"vtysh -c 'show bfd peers brief' 2>&1" '10\.4\.24\.4[[:space:]]+10\.4\.24\.2[[:space:]]+up'
	assert 4 "BFD IPv6 peer up (OSPFv3 on ng1)" "$nmdm" \
		"vtysh -c 'show bfd peers brief' 2>&1" 'fe80::[0-9a-f:]+[[:space:]]+fe80::[0-9a-f:]+[[:space:]]+up'

	# wiki/R4 IS-IS: neighbor to R5 (or jail5).
	assert 4 "IS-IS neighbor Up" "$nmdm" \
		"vtysh -c 'show isis neighbor' 2>&1" 'Up[[:space:]]'

	# wiki/R4 OSPF routes learned.
	assert 4 "OSPF routes installed" "$nmdm" \
		"vtysh -c 'show ip route ospf' 2>&1" '^O'

	# wiki/R4 RIP active.
	assert 4 "RIP active in FRR" "$nmdm" \
		"vtysh -c 'show ip rip' 2>&1" 'Network|RIP'

	# wiki/R4 IPFW pipes 40/41 (10Mbit) and 60/61 (20Mbit).
	# Output format is "00040:  10.000 Mbit/s ..." - allow decimals.
	assert 4 "IPFW pipe 40 = 10 Mbit/s" "$nmdm" \
		"ipfw pipe show 2>&1" '00040:[[:space:]]+10(\.[0-9]+)?[[:space:]]*Mbit'
	assert 4 "IPFW pipe 60 = 20 Mbit/s" "$nmdm" \
		"ipfw pipe show 2>&1" '00060:[[:space:]]+20(\.[0-9]+)?[[:space:]]*Mbit'

	# wiki/R4 runs FRR's pimd, NOT net/pimd: the two cannot share the
	# kernel's MRT socket. Match the full path - a bare "pgrep -lf pimd"
	# matches /usr/local/lib/frr/pimd just as happily as /usr/local/sbin/pimd
	# and would pass whichever daemon were running.
	assert 4 "FRR pimd running" "$nmdm" \
		"pgrep -lf lib/frr/pimd || echo none" 'pimd'
	assert 4 "net/pimd NOT running (FRR owns the MRT socket)" "$nmdm" \
		"pgrep -lf sbin/pimd || echo none" '^none$'

	# wiki/R4 PIM neighbors: R4 should peer with R5 over vtnet3 (10.0.45.5)
	# and with R2 over both PPTP tunnels (ng0 IPv4 = 10.4.24.2, ng1 IPv6 leg
	# = 10.6.24.2). PIM must be enabled on BOTH legs: R2's elected BSR
	# address is its ng1 address, so R4's RPF towards the BSR is ng1 and a
	# Bootstrap arriving on ng0 alone would be dropped by the RPF check.
	assert 4 "PIM neighbor R5 (10.0.45.5) on vtnet3" "$nmdm" \
		"vtysh -c 'show ip pim neighbor' 2>&1" '10\.0\.45\.5'
	assert 4 "PIM neighbor R2 (10.4.24.2) on ng0" "$nmdm" \
		"vtysh -c 'show ip pim neighbor' 2>&1" '10\.4\.24\.2'
	assert 4 "PIM neighbor R2 (10.6.24.2) on ng1" "$nmdm" \
		"vtysh -c 'show ip pim neighbor' 2>&1" '10\.6\.24\.2'

	# wiki/R4 is the sole Candidate-RP and must NOT be a Candidate-BSR: an
	# FRR that is itself the BSR never puts its own CRP into the Bootstrap it
	# originates, leaving the RP set empty.
	assert 4 "FRR Candidate-RP is 10.0.0.4" "$nmdm" \
		"vtysh -c 'show ip pim bsr candidate-rp' 2>&1" '10\.0\.0\.4'

	# wiki/R4 learned R2's Bootstrap: pimd's BSM parsed by FRR. The reverse
	# of the CRP-Adv direction asserted on R2.
	assert 4 "FRR accepted pimd's Bootstrap (BSR 10.4.24.2)" "$nmdm" \
		"vtysh -c 'show ip pim bsr' 2>&1" '10\.4\.24\.2' 120

	# wiki/R4 won the RP election with the RP set R2's BSR flooded back.
	assert 4 "FRR is the elected RP for 224.0.0.0/4 (Source: BSR)" "$nmdm" \
		"vtysh -c 'show ip pim rp-info' 2>&1" '10\.0\.0\.4.*224\.0\.0\.0/4.*yes.*BSR' 120

	# wiki/R4 Netflow exporter to 10.0.45.5:2055.
	assert 4 "netflow exporting to 10.0.45.5:2055" "$nmdm" \
		"sockstat 2>&1 | grep -E '10\\.0\\.45\\.5(:|\\.)2055' || echo none" \
		'10\.0\.45\.5'

	# IPsec responder side of R2's IKEv2 tunnel, and the NAT instance
	# exercised in Phase 3.
	assert 4 "IPsec: ipsec0 CHILD_SA installed (responder)" "$nmdm" \
		"swanctl --list-sas 2>&1" 'ipsec0: #[0-9]+, reqid 100, INSTALLED, TUNNEL'
	assert 4 "NAT: ipfw nat 1 translates to 10.0.34.44" "$nmdm" \
		"ipfw nat show config 2>&1" 'nat 1 config ip 10\.0\.34\.44'

	# ExaBGP (asserted through bird on R3 and FRR on R2) and the R4 end of
	# the LLDP check across vxlan0.
	assert 4 "ExaBGP running" "$nmdm" \
		"pgrep -lf 'm exabgp' || echo none" 'exabgp'
	assert 4 "LLDP: neighbor R2 over vxlan0" "$nmdm" \
		"lldpcli -f keyvalue show neighbors 2>&1" '^lldp\.vxlan0\.chassis\.name=R2$'

	# Note: the iperf3 throughput tests for R4's pipes 40/41/60/61 are
	# driven from R1 in the Phase 3 throughput postlude, AFTER every VM
	# has been probed and assertions recorded (so failures point at
	# routing convergence before failing on shaping).
}

# Helpers for the iperf3 end-to-end shaping check (Phase 3 throughput postlude).
# Per the wiki, the iperf3 *client* runs on R1 (not R4) so traffic transits
# R1 -> R2 -> PPTP tunnel (10.0.0.2 <-> 10.0.0.4) -> R4 -> R5 -> jail6.
# IPFW pipes 40/41 on R4 match traffic between the two PPTP loopbacks, so
# the tunnel-encapsulated traffic gets shaped.
lab_full_throughput() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm5="${NMDM_PREFIX}5${NMDM_SUFFIX}"

	# iperf3 runs for -t 10s plus connection setup; bump the per-cmd timeout
	# for this section so the client doesn't get cut off mid-stream.
	local saved_cmd_to="$CMD_TIMEOUT"
	CMD_TIMEOUT=45

	# Start an iperf3 server in jail6. Kill any prior instance first.
	console_run "$nmdm5" "jexec jail6 pkill iperf3 2>/dev/null; sleep 1; jexec jail6 iperf3 -sD" >/dev/null
	sleep 2

	# Query jail6's SLAAC IPv6 address (needed for the IPv6 leg).
	local v6
	v6=$(console_run "$nmdm5" \
		"jexec jail6 ifconfig lagg0 inet6 | awk '/inet6 2001:/{print \$2; exit}'" \
		| tr -d '[:space:]')

	# --- IPv4 leg: pipes 40/41 = 10 Mbit/s, expect 7-12 Mbit/s ---
	# Parse the sender's bitrate by anchoring on the "Mbits/sec" unit and
	# reading the field immediately before it. This is robust to column
	# layout differences between TCP/UDP and across iperf3 versions.
	local out4 bw4
	out4=$(console_run "$nmdm1" "iperf3 -c 10.0.56.6 -t 10 -f m 2>&1")
	bw4=$(echo "$out4" | awk '/sender/ {for(i=1;i<=NF;i++) if($i=="Mbits/sec") {print $(i-1); exit}}')
	if [ -n "$bw4" ] && \
	   awk -v b="$bw4" 'BEGIN{exit !(b>=7 && b<=12)}'; then
		record 4 "iperf3 IPv4 shaped to 10 Mbit/s (got ${bw4} Mbit/s)" PASS ""
	else
		record 4 "iperf3 IPv4 shaped to 10 Mbit/s" FAIL "got '${bw4}' Mbit/s (expected 7-12)"
	fi

	# --- IPv6 leg: pipes 60/61 = 20 Mbit/s, expect 10-22 Mbit/s ---
	# Range is wider than IPv4 because IPv6 traffic through the ng1 PPTP6
	# tunnel carries more per-packet overhead (larger headers + PPTP/GRE +
	# possible MPPC compression renegotiation) so the application-layer
	# goodput lands well below the 20 Mbit/s pipe rate.  Observed in
	# practice on a freshly-converged lab: ~14-15 Mbit/s.
	if [ -n "$v6" ]; then
		local out6 bw6
		echo "  [info] iperf3 IPv6 target: ${v6}"
		out6=$(console_run "$nmdm1" "iperf3 -6 -c ${v6} -t 10 -f m 2>&1")
		bw6=$(echo "$out6" | awk '/sender/ {for(i=1;i<=NF;i++) if($i=="Mbits/sec") {print $(i-1); exit}}')
		if [ -n "$bw6" ] && \
		   awk -v b="$bw6" 'BEGIN{exit !(b>=10 && b<=22)}'; then
			record 4 "iperf3 IPv6 shaped (~20 Mbit/s pipe; got ${bw6} Mbit/s)" PASS ""
		else
			# Dump the last 12 lines of iperf3 output so we can see WHY parsing failed.
			echo "  [info] iperf3 IPv6 last output:"
			printf '%s\n' "$out6" | tail -12 | sed 's/^/    /'
			record 4 "iperf3 IPv6 shaped (~20 Mbit/s pipe)" FAIL "got '${bw6}' Mbit/s (expected 10-22)"
		fi
	else
		record 4 "iperf3 IPv6 shaped to 20 Mbit/s" FAIL "could not resolve jail6 SLAAC IPv6"
	fi

	# Stop the iperf3 server.
	console_run "$nmdm5" "jexec jail6 pkill iperf3" >/dev/null

	lab_full_nat_multicast

	# --- jail5 nfacctd output file ---
	# nfacctd in jail5 receives NetFlow v9 from R4 and writes a CSV per
	# print_refresh_time (default 300s) ONLY when at least one flow has
	# arrived during the interval. The iperf3 runs above guarantee fresh
	# flows; we then poll up to ~6 min for the file to appear.
	#
	# The 5-minute print cycle is wall-clock aligned (file name is
	# /tmp/file-YYYYMMDD-HHMM.txt with HHMM rounded to print_refresh_time),
	# so worst case we just missed a flush and must wait nearly a full
	# cycle. Cap at 360s and poll every 15s to stay friendly to the
	# console driver.
	echo "  [info] Polling for jail5 nfacctd output (up to 360s)..."
	local nf_deadline=$(( $(date +%s) + 360 ))
	local nf_found=""
	while [ "$(date +%s)" -lt "$nf_deadline" ]; do
		# Wrap the glob in `sh -c` inside the jail so /tmp/file-*.txt
		# expands against jail5's filesystem, not R5's host.
		nf_found=$(console_run "$nmdm5" \
			"jexec jail5 sh -c 'ls /tmp/file-*.txt 2>/dev/null | head -1'" \
			2>/dev/null | tr -d '[:space:]')
		case "$nf_found" in
			/tmp/file-*) break ;;
		esac
		sleep 15
	done
	case "$nf_found" in
		/tmp/file-*)
			record 5 "jail5: nfacctd output file present (${nf_found})" PASS ""
			;;
		*)
			record 5 "jail5: nfacctd output file present" FAIL \
				"no /tmp/file-*.txt after 360s of polling post-iperf3"
			;;
	esac

	CMD_TIMEOUT="$saved_cmd_to"
}

# ---- R5 + jail5 + jail6 --------------------------------------------------
lab_full_vm5() {
	local nmdm="$1"

	# wiki/R5: both jails must be running.
	assert 5 "hostname is R5" "$nmdm" "hostname" '^R5$'

	# wiki/R5: pimd runs INSIDE jail5 (not on the R5 host). R4 sees jail5's
	# pimd on vtnet3 because the jail uses VNET=disabled and shares the
	# host's network stack. Check with jexec; pimctl from outside the jail
	# cannot find the daemon's socket.
	assert 5 "jail5: pimd running" "$nmdm" \
		"jexec jail5 pgrep -lf sbin/pimd || echo none" 'pimd'
	assert 5 "jail5: PIM neighbor R4 (10.0.45.4) on vtnet3" "$nmdm" \
		"jexec jail5 pimctl show neighbor 2>&1" '10\.0\.45\.4'

	# wiki/R5 jail5 is two hops from the BSR (R2), with FRR on R4 in
	# between. It can only hold the RP set if FRR parsed R2's Bootstrap AND
	# flooded it onward - the one property only a middle-box lab can test,
	# and the reason R4 runs FRR rather than net/pimd. jail5 is itself
	# neither CBSR nor CRP, so nothing here is locally originated.
	assert 5 "jail5: learned BSR 10.4.24.2 relayed by FRR" "$nmdm" \
		"jexec jail5 pimctl show status 2>&1" '10\.4\.24\.2' 120
	assert 5 "jail5: learned RP 10.0.0.4 relayed by FRR" "$nmdm" \
		"jexec jail5 pimctl show rp 2>&1" '224\.0\.0\.0/4[[:space:]]+10\.0\.0\.4' 120
	local jls_out
	jls_out=$(retry_check "$nmdm" "jls -N" 'jail5') || true
	if echo "$jls_out" | grep -q jail5; then
		record 5 "jail5 running" PASS ""
	else
		record 5 "jail5 running" FAIL "jail5 not in jls -N"
	fi
	if echo "$jls_out" | grep -q jail6; then
		record 5 "jail6 running" PASS ""
	else
		record 5 "jail6 running" FAIL "jail6 not in jls -N"
	fi

	# --- jail5 checks (run via jexec) ---

	# wiki/jail5: hostname.
	assert 5 "jail5: hostname is jail5" "$nmdm" \
		"jexec jail5 hostname" '^jail5$'
	# wiki/jail5: IS-IS database populated.
	assert 5 "jail5: IS-IS database populated" "$nmdm" \
		"jexec jail5 vtysh -c 'show isis database' 2>&1" 'LSP|Sequence'
	# wiki/jail5: dhcpd running. isc-dhcpd uses raw BPF sockets (not regular
	# UDP), so it doesn't appear in sockstat -u; we check the process instead.
	assert 5 "jail5: dhcpd running" "$nmdm" \
		"jexec jail5 pgrep -lf dhcpd || echo none" 'dhcpd'
	# wiki/jail5: rtadvd process running.
	assert 5 "jail5: rtadvd running" "$nmdm" \
		"jexec jail5 pgrep -lf rtadvd || echo none" 'rtadvd'

	# Note: jail5 nfacctd output file check moved to Phase 3
	# (lab_full_throughput) because the file only appears after nfacctd's
	# print_refresh_time (300s) elapses AND it has received flows. Phase 3
	# both generates iperf3 traffic and waits long enough for the flush.

	# --- jail6 checks ---

	# wiki/jail6: hostname.
	assert 5 "jail6: hostname is jail6" "$nmdm" \
		"jexec jail6 hostname" '^jail6$'
	# wiki/jail6: lagg0 failover proto, with DHCP-acquired address.
	assert 5 "jail6: lagg0 failover proto" "$nmdm" \
		"jexec jail6 ifconfig lagg0" 'laggproto failover'

	# wiki/jail6: lagg0 has an IPv6 autoconf address (from rtadvd in jail5).
	assert 5 "jail6: lagg0 has SLAAC IPv6" "$nmdm" \
		"jexec jail6 ifconfig lagg0 inet6" 'autoconf'
	# wiki/jail6: bsnmpd answers sysName.0 with "jail6".
	assert 5 "jail6: bsnmpd answers sysName.0" "$nmdm" \
		"jexec jail6 bsnmpget -s localhost sysName.0 2>&1" 'jail6'

	# LLDP across the epair between the jails, the only point-to-point
	# Ethernet link in the lab without a host bridge in the middle. jail6's
	# side is the lagg0 member.
	assert 5 "LLDP: jail5 sees jail6 on epair0a" "$nmdm" \
		"jexec jail5 lldpcli -f keyvalue show neighbors 2>&1" '^lldp\.epair0a\.chassis\.name=jail6$'
	assert 5 "LLDP: jail6 sees jail5 on epair0b" "$nmdm" \
		"jexec jail6 lldpcli -f keyvalue show neighbors 2>&1" '^lldp\.epair0b\.chassis\.name=jail5$'
}

# ---- NAT and multicast traffic (Phase 3) ---------------------------------
lab_full_nat_multicast() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local nmdm3="${NMDM_PREFIX}3${NMDM_SUFFIX}"
	local nmdm4="${NMDM_PREFIX}4${NMDM_SUFFIX}"
	local nmdm5="${NMDM_PREFIX}5${NMDM_SUFFIX}"

	# NAT: R3 has no route back to jail6's LAN, so this ping only works
	# because R4 translates 10.0.56.6 to 10.0.34.44. Check the far end
	# first: pf's ICMP state is the shortest lived.
	assert 5 "NAT: jail6 reaches R3 10.0.34.3 through R4's NAT" "$nmdm5" \
		"jexec jail6 ping -c 3 -W 1000 10.0.34.3 2>&1" '[123] packets received'
	assert 3 "NAT: R3 sees jail6 as 10.0.34.44" "$nmdm3" \
		"pfctl -ss 2>&1" 'icmp 10\.0\.34\.3:8 <- 10\.0\.34\.44:'
	assert 4 "NAT: ipfw nat 1 log counts the ICMP alias" "$nmdm4" \
		"ipfw nat 1 show log 2>&1" 'icmp=[1-9]'

	# PIM-SSM data path: jail6 sends to the channel (10.0.56.6, 232.1.1.1),
	# R1 joins it with IGMPv3. Path: jail5 (pimd) -> R4 (FRR pimd) -> ng0
	# -> R2 (pimd) -> R1. SSM rather than the ASM range: R2's RPF towards
	# the RP 10.0.0.4 goes via R3, which runs no PIM, so (*,G) joins never
	# reach R4 and an ASM stream is never delivered to R1.
	local mc_join="iperf -s -u -B 232.1.1.1 -H 10.0.56.6 -i 1"
	console_run "$nmdm1" "pkill -x iperf; ($mc_join > /tmp/mc.log 2>&1 &)" >/dev/null
	assert 4 "PIM-SSM: R1's (S,G) join reached R4, OIF ng0" "$nmdm4" \
		"vtysh -c 'show ip mroute' 2>&1" \
		'10\.0\.56\.6[[:space:]]+232\.1\.1\.1[[:space:]].*(vtnet3|em3)[[:space:]]+ng0' 60
	# 1000-byte datagrams fit the ng0 MTU (1456): no fragmentation.
	console_run "$nmdm5" \
		"jexec jail6 iperf -c 232.1.1.1 -u -T 32 -t 3 -b 1M -l 1000 >/dev/null 2>&1" 30 >/dev/null
	assert 1 "PIM-SSM: R1 received the stream (<5% loss)" "$nmdm1" \
		"cat /tmp/mc.log" ' [0-9]+/[1-9][0-9]{2,} \([0-4](\.[0-9]+)?%\)'
	assert 2 "PIM-SSM: R2 kernel forwarded it (MFC packet count)" "$nmdm2" \
		"netstat -g -f inet 2>&1" '10\.0\.56\.6[[:space:]]+232\.1\.1\.1[[:space:]]+[1-9]'

	# Same stream with iperf's default 1470-byte datagrams: R4 fragments
	# them for ng0 and R2 forwards the fragments. R2 is not a member, but
	# ip_input() still hands every multicast packet to the local stack
	# after ip_mforward() queued its copy, and ip_reass() rewrites the
	# fragment header in place: the copy must own its header for R1 to get
	# intact fragments.
	console_run "$nmdm1" "pkill -x iperf; ($mc_join > /tmp/mc-frag.log 2>&1 &)" >/dev/null
	assert 4 "PIM-SSM: join still in place for the fragmented run" "$nmdm4" \
		"vtysh -c 'show ip mroute' 2>&1" \
		'10\.0\.56\.6[[:space:]]+232\.1\.1\.1[[:space:]].*(vtnet3|em3)[[:space:]]+ng0' 60
	console_run "$nmdm5" \
		"jexec jail6 iperf -c 232.1.1.1 -u -T 32 -t 3 -b 1M >/dev/null 2>&1" 30 >/dev/null
	assert 1 "PIM-SSM: fragmented datagrams forwarded intact (<5% loss)" "$nmdm1" \
		"cat /tmp/mc-frag.log" ' [0-9]+/[1-9][0-9]{2,} \([0-4](\.[0-9]+)?%\)'
	console_run "$nmdm1" "pkill -x iperf" >/dev/null
}

# ---- Failover (Phase 4) --------------------------------------------------
# Each step breaks one thing, checks the lab reacts, then restores it. The
# restore runs whatever the checks returned, so a failed step does not
# cascade into the next one.
#
# Both CARP groups have a single member (R2 on R1's LAN, jail5 on jail6's
# LAN), so there is no election to test. net.inet.carp.allow=0 forces the
# vhid to INIT, which releases the virtual address; allow=1 restarts the
# state machine and, hearing no other master, the vhid becomes MASTER
# again. That covers the state transitions and the address ownership.
lab_full_failover() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local nmdm4="${NMDM_PREFIX}4${NMDM_SUFFIX}"
	local nmdm5="${NMDM_PREFIX}5${NMDM_SUFFIX}"
	local if2

	# R2 runs this vhid in VRRPv3 mode (carpver 3): its status line is
	# "vrrp: <state> vrid 1", not "carp: <state> vhid 1".
	if2=$(console_run "$nmdm2" "ifconfig -l | grep -qw vtnet0 && echo vtnet0 || echo em0" | tr -d '[:space:]')
	console_run "$nmdm2" "sysctl net.inet.carp.allow=0" >/dev/null
	assert 2 "CARP: carp.allow=0 puts vrid 1 in INIT" "$nmdm2" \
		"ifconfig $if2 2>&1" 'vrrp: INIT vrid 1'
	assert 1 "CARP: gateway 10.0.12.254 unreachable while R2 is INIT" "$nmdm1" \
		"ping -c 2 -W 1000 10.0.12.254 2>&1" ' 0 packets received'
	console_run "$nmdm2" "sysctl net.inet.carp.allow=1" >/dev/null
	assert 2 "CARP: carp.allow=1 brings vrid 1 back to MASTER" "$nmdm2" \
		"ifconfig $if2 2>&1" 'vrrp: MASTER vrid 1'
	assert 1 "CARP: gateway 10.0.12.254 reachable again" "$nmdm1" \
		"ping -c 2 -W 1000 10.0.12.254 2>&1" '[12] packets received'

	# jail5 owns jail6's gateway, IPv4 and IPv6, on the same vhid.
	console_run "$nmdm5" "jexec jail5 sysctl net.inet.carp.allow=0" >/dev/null
	assert 5 "CARP: jail5 vhid 1 INIT with carp.allow=0" "$nmdm5" \
		"jexec jail5 ifconfig epair0a 2>&1" 'carp: INIT vhid 1'
	assert 5 "CARP: jail6 gateway 10.0.56.254 unreachable" "$nmdm5" \
		"jexec jail6 ping -c 2 -W 1000 10.0.56.254 2>&1" ' 0 packets received'
	assert 5 "CARP: jail6 gateway 2001:db8:56::fe unreachable" "$nmdm5" \
		"jexec jail6 ping6 -c 2 2001:db8:56::fe 2>&1" ' 0 packets received'
	console_run "$nmdm5" "jexec jail5 sysctl net.inet.carp.allow=1" >/dev/null
	assert 5 "CARP: jail5 vhid 1 back to MASTER" "$nmdm5" \
		"jexec jail5 ifconfig epair0a 2>&1" 'carp: MASTER vhid 1'
	assert 5 "CARP: jail6 gateway 10.0.56.254 reachable again" "$nmdm5" \
		"jexec jail6 ping -c 2 -W 1000 10.0.56.254 2>&1" '[12] packets received'
	assert 5 "CARP: jail6 gateway 2001:db8:56::fe reachable again" "$nmdm5" \
		"jexec jail6 ping6 -c 2 2001:db8:56::fe 2>&1" '[12] packets received'

	# BFD: silence R4's end of ng0. Without BFD, R2 only notices when the
	# OSPF dead interval (40s) expires; with it, the session times out in
	# under a second and OSPF drops the neighbor at once. The 10s budget
	# is far below the dead interval, so a pass can only come from BFD.
	console_run "$nmdm4" "ifconfig ng0 down" >/dev/null
	assert 2 "BFD: R2 drops OSPF neighbor on ng0 within 10s of R4 going silent" "$nmdm2" \
		"vtysh -c 'show ip ospf neighbor' 2>&1 | grep -c ng0" '^0$' 10
	console_run "$nmdm4" "ifconfig ng0 up" >/dev/null
	assert 2 "BFD: OSPF neighbor 0.0.0.4 back to Full on ng0" "$nmdm2" \
		"vtysh -c 'show ip ospf neighbor' 2>&1" '^0\.0\.0\.4[[:space:]].*Full.*ng0' 90
	assert 2 "BFD: peer 10.4.24.4 back up" "$nmdm2" \
		"vtysh -c 'show bfd peers brief' 2>&1" '10\.4\.24\.2[[:space:]]+10\.4\.24\.4[[:space:]]+up' 60
}

# === anycast lab ==========================================================
#
# Two DNS sites announce the same anycast address through ExaBGP's
# healthcheck; the edge prefers site A (MED 100) over site B (MED 200).
# The site's TXT record names the site that answered.

ANYCAST_DIG4="host -W 1 -t TXT site.anycast.lab 192.0.2.53 2>&1"
ANYCAST_DIG6="host -W 1 -t TXT site.anycast.lab 2001:db8:53::53 2>&1"

lab_anycast_vm1() {
	local nmdm="$1"

	assert 1 "hostname is client" "$nmdm" "hostname" '^client$'
	# Downstream of every other VM: give BGP and the healthcheck time to
	# converge after boot.
	assert 1 "anycast DNS 192.0.2.53 answered by site A" "$nmdm" \
		"$ANYCAST_DIG4" 'descriptive text "site-A"' 120
	assert 1 "anycast DNS 2001:db8:53::53 answered by site A" "$nmdm" \
		"$ANYCAST_DIG6" 'descriptive text "site-A"' 60
}

lab_anycast_vm2() {
	local nmdm="$1"

	assert 2 "hostname is edge" "$nmdm" "hostname" '^edge$'
	# Established sessions show a prefix count in the State/PfxRcd column.
	assert 2 "BGP session to site A (10.0.23.3) Established" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast summary' 2>&1" '^10\.0\.23\.3 .* [0-9]+ +[0-9]+ +N/A$' 120
	assert 2 "BGP session to site B (10.0.24.4) Established" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast summary' 2>&1" '^10\.0\.24\.4 .* [0-9]+ +[0-9]+ +N/A$' 60
	assert 2 "BGP session to site A (2001:db8:23::3) Established" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast summary' 2>&1" '^2001:db8:23::3 .* [0-9]+ +[0-9]+ +N/A$' 60
	assert 2 "BGP session to site B (2001:db8:24::4) Established" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast summary' 2>&1" '^2001:db8:24::4 .* [0-9]+ +[0-9]+ +N/A$' 60
	# Both sites announce the anycast address; site A wins on MED. Lines
	# joined so the next hop, MED and best flag match as one path.
	assert 2 "192.0.2.53/32 announced by both sites" "$nmdm" \
		"vtysh -c 'show ip bgp 192.0.2.53/32' 2>&1" 'Paths: \(2 available'
	assert 2 "192.0.2.53/32 best path: site A, MED 100" "$nmdm" \
		"vtysh -c 'show ip bgp 192.0.2.53/32' 2>&1 | paste -s -d ' ' -" \
		'10\.0\.23\.3 from 10\.0\.23\.3 [^ ]+ +Origin IGP, metric 100, valid, external, best'
	assert 2 "2001:db8:53::53/128 best path: site A" "$nmdm" \
		"vtysh -c 'show bgp ipv6 2001:db8:53::53/128' 2>&1 | paste -s -d ' ' -" \
		'2001:db8:23::3 from 2001:db8:23::3 [^ ]+ +Origin IGP, metric [0-9]+, valid, external, best'
}

# Site checks shared by VM3 (A) and VM4 (B). $1: VM, $2: site, $3: nmdm
lab_anycast_site() {
	local vm="$1" site="$2" nmdm="$3"

	assert "$vm" "hostname is site${site}" "$nmdm" "hostname" "^site${site}\$"
	assert "$vm" "lo1 carries the anycast address 192.0.2.53" "$nmdm" \
		"ifconfig lo1 2>&1" 'inet 192\.0\.2\.53 '
	assert "$vm" "local dnsmasq answers as site-${site}" "$nmdm" \
		"host -W 1 -t TXT site.anycast.lab 127.0.0.1 2>&1" "descriptive text \"site-${site}\""
	assert "$vm" "ExaBGP healthcheck running" "$nmdm" \
		"pgrep -lf exabgp-healthcheck || echo none" 'exabgp-healthcheck'
}

lab_anycast_vm3() { lab_anycast_site 3 A "$1"; }
lab_anycast_vm4() { lab_anycast_site 4 B "$1"; }

# Phase 4: break site A twice, its DNS daemon then its whole uplink, and
# check the client is served by site B, then by site A again.
lab_anycast_failover() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local nmdm3="${NMDM_PREFIX}3${NMDM_SUFFIX}"
	local if3

	# The healthcheck fails twice (--fall 2, 1s apart) and withdraws the
	# route: a few seconds.
	console_run "$nmdm3" "service dnsmasq stop" >/dev/null
	assert 1 "DNS down on site A: site B answers 192.0.2.53" "$nmdm1" \
		"$ANYCAST_DIG4" 'descriptive text "site-B"' 15
	assert 1 "DNS down on site A: site B answers 2001:db8:53::53" "$nmdm1" \
		"$ANYCAST_DIG6" 'descriptive text "site-B"' 15
	assert 2 "DNS down on site A: route withdrawn, only site B left" "$nmdm2" \
		"vtysh -c 'show ip bgp 192.0.2.53/32' 2>&1" 'Paths: \(1 available'
	console_run "$nmdm3" "service dnsmasq start" >/dev/null
	assert 1 "DNS back on site A: site A answers again" "$nmdm1" \
		"$ANYCAST_DIG4" 'descriptive text "site-A"' 15

	# A dead site cannot withdraw anything: the edge's 9s hold timer
	# notices the silence.
	if3=$(console_run "$nmdm3" "ifconfig -l | grep -qw vtnet1 && echo vtnet1 || echo em1" | tr -d '[:space:]')
	console_run "$nmdm3" "ifconfig $if3 down" >/dev/null
	assert 1 "site A unreachable: site B answers within the hold time" "$nmdm1" \
		"$ANYCAST_DIG4" 'descriptive text "site-B"' 20
	console_run "$nmdm3" "ifconfig $if3 up" >/dev/null
	assert 1 "site A reachable again: site A answers again" "$nmdm1" \
		"$ANYCAST_DIG4" 'descriptive text "site-A"' 90
}

# === branch lab ===========================================================
#
# The branch reaches HQ over two WireGuard tunnels, one per ISP, with OSPF,
# OSPFv3 and BFD on both: equal costs give ECMP routes, and
# net.route.hash_forward=1 spreads the flows over them.

lab_branch_vm1() {
	local nmdm="$1"

	assert 1 "hostname is pc" "$nmdm" "hostname" '^pc$'
	# Downstream of both tunnels and OSPF: give them time after boot.
	assert 1 "ping HQ 10.0.5.5 through the tunnels" "$nmdm" \
		"ping -c 2 -t 5 10.0.5.5 2>&1" ' 0\.0% packet loss' 120
	assert 1 "ping HQ 2001:db8:5::5 through the tunnels" "$nmdm" \
		"ping -6 -c 2 -t 5 2001:db8:5::5 2>&1" ' 0\.0% packet loss' 60
}

# Tunnel endpoint checks shared by the branch (VM2) and HQ (VM5).
# $1: VM, $2: hostname, $3: remote LAN IPv4 address, $4: IPv6, $5: nmdm
lab_branch_router() {
	local vm="$1" name="$2" lan4="$3" lan6="$4" nmdm="$5" t

	assert "$vm" "hostname is ${name}" "$nmdm" "hostname" "^${name}\$"
	assert "$vm" "net.route.hash_forward is 1" "$nmdm" \
		"sysctl -n net.route.hash_forward" '^1$'
	for t in 0 1; do
		# latest-handshakes prints 0 until a handshake completes.
		assert "$vm" "wg${t} handshake done" "$nmdm" \
			"wg show wg${t} latest-handshakes 2>&1" '[[:space:]][1-9][0-9]+$' 60
		assert "$vm" "OSPF neighbor Full over wg${t}" "$nmdm" \
			"vtysh -c 'show ip ospf neighbor' 2>&1" " Full/.* wg${t}:" 90
		assert "$vm" "OSPFv3 neighbor Full over wg${t}" "$nmdm" \
			"vtysh -c 'show ipv6 ospf6 neighbor' 2>&1" " Full/.* wg${t}\[" 90
	done
	assert "$vm" "4 BFD sessions up (OSPF and OSPFv3, both tunnels)" "$nmdm" \
		"vtysh -c 'show bfd peers brief' 2>&1 | grep -c ' up '" '^4$' 60
	assert "$vm" "ECMP route to ${lan4} over both tunnels" "$nmdm" \
		"netstat -rn -f inet | grep -E '^${lan4}[ /]' | awk '{print \$NF}' | sort | paste -s -d ' ' -" \
		'^wg0 wg1$' 60
	assert "$vm" "ECMP route to ${lan6} over both tunnels" "$nmdm" \
		"netstat -rn -f inet6 | grep -E '^${lan6}[ /]' | awk '{print \$NF}' | sort | paste -s -d ' ' -" \
		'^wg0 wg1$' 60
}

lab_branch_vm2() { lab_branch_router 2 branch 10.0.5.5 2001:db8:5::5 "$1"; }
lab_branch_vm5() { lab_branch_router 5 hq 10.0.12.0 2001:db8:12:: "$1"; }

# ISP router: forwards IPv4 between the branch and HQ. $1: VM, $2: site,
# $3: nmdm
lab_branch_isp() {
	local vm="$1" site="$2" nmdm="$3"

	assert "$vm" "hostname is isp${site}" "$nmdm" "hostname" "^isp${site}\$"
	assert "$vm" "reaches the branch (10.0.2${vm}.2)" "$nmdm" \
		"ping -c 2 -t 5 10.0.2${vm}.2 2>&1" ' 0\.0% packet loss'
	assert "$vm" "reaches HQ (10.0.${vm}5.5)" "$nmdm" \
		"ping -c 2 -t 5 10.0.${vm}5.5 2>&1" ' 0\.0% packet loss'
}

lab_branch_vm3() { lab_branch_isp 3 A "$1"; }
lab_branch_vm4() { lab_branch_isp 4 B "$1"; }

# Phase 3: the PC sends 256 UDP flows to HQ, one per source port; the
# branch counts how many leave through each tunnel. Without a flow hash
# every flow would take the same tunnel.
lab_branch_throughput() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local af dst counts c0 c1

	for af in 4 6; do
		[ "$af" = 4 ] && dst=10.0.5.5 || dst=2001:db8:5::5
		console_run "$nmdm2" "for i in wg0 wg1; do (timeout 90 tcpdump -lnqi \$i udp port 9 2>/dev/null | wc -l > /tmp/ecmp.\$i &); done; sleep 2" >/dev/null
		console_run "$nmdm1" "for p in \$(jot 256 20000); do echo x | nc -${af} -u -w0 -p \$p ${dst} 9; done" >/dev/null
		counts=$(console_run "$nmdm2" "pkill -f 'tcpdump -lnqi'; sleep 1; echo \$(cat /tmp/ecmp.wg0) \$(cat /tmp/ecmp.wg1)" | tail -1)
		c0=$(echo "$counts" | awk '{print $1 + 0}')
		c1=$(echo "$counts" | awk '{print $2 + 0}')
		echo "  IPv${af} flows per tunnel: wg0=${c0} wg1=${c1}"
		# 256 flows over 2 nexthops: anything above 64 each is a spread,
		# a collapse gives 256 and 0.
		if [ "$c0" -gt 64 ] && [ "$c1" -gt 64 ]; then
			record 2 "IPv${af} ECMP spreads 256 flows over both tunnels" PASS ""
		else
			record 2 "IPv${af} ECMP spreads 256 flows over both tunnels" FAIL "wg0=${c0} wg1=${c1}"
		fi
	done
}

# Phase 4: ISP-A loses its link to HQ. The tunnels stay up as interfaces,
# so only BFD notices: the branch must drop the wg0 route within seconds,
# then restore ECMP when the link comes back.
lab_branch_failover() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local nmdm3="${NMDM_PREFIX}3${NMDM_SUFFIX}"
	local route4="netstat -rn -f inet | grep -E '^10\.0\.5\.5 ' | awk '{print \$NF}' | sort | paste -s -d ' ' -"
	local if3

	if3=$(console_run "$nmdm3" "ifconfig -l | grep -qw vtnet3 && echo vtnet3 || echo em3" | tr -d '[:space:]')
	console_run "$nmdm3" "ifconfig $if3 down" >/dev/null
	assert 2 "ISP-A down: route to HQ only over wg1" "$nmdm2" "$route4" '^wg1$' 10
	assert 1 "ISP-A down: HQ still reachable" "$nmdm1" \
		"ping -c 2 -t 5 10.0.5.5 2>&1" ' 0\.0% packet loss' 10
	console_run "$nmdm3" "ifconfig $if3 up" >/dev/null
	assert 2 "ISP-A back: ECMP over both tunnels again" "$nmdm2" "$route4" '^wg0 wg1$' 90
}

# === ecmp lab =============================================================
#
# VM2 and VM3 are joined by two links and route 10.0.0.0/16 and
# 2001:db8::/32 over both with static multipath routes; VM1 and VM4 are the
# hosts at each end. net.route.hash_forward=1 spreads the flows.

lab_ecmp_host() {
	# $1: VM, $2: remote host IPv4, $3: IPv6, $4: nmdm
	local vm="$1" dst4="$2" dst6="$3" nmdm="$4"

	assert "$vm" "hostname is VM${vm}" "$nmdm" "hostname" "^VM${vm}\$"
	assert "$vm" "ping ${dst4} over the ECMP paths" "$nmdm" \
		"ping -c 2 -t 5 ${dst4} 2>&1" ' 0\.0% packet loss' 60
	assert "$vm" "ping ${dst6} over the ECMP paths" "$nmdm" \
		"ping -6 -c 2 -t 5 ${dst6} 2>&1" ' 0\.0% packet loss' 60
}

lab_ecmp_router() {
	# $1: VM, $2: nmdm
	local vm="$1" nmdm="$2"

	assert "$vm" "hostname is VM${vm}" "$nmdm" "hostname" "^VM${vm}\$"
	assert "$vm" "net.route.hash_forward is 1" "$nmdm" \
		"sysctl -n net.route.hash_forward" '^1$'
	assert "$vm" "ECMP route to 10.0.0.0/16 over both links" "$nmdm" \
		"netstat -rn -f inet | grep -E '^10\.0\.0\.0/16 ' | awk '{print \$NF}' | sort | paste -s -d ' ' -" \
		'^vtnet1 vtnet3$'
	assert "$vm" "ECMP route to 2001:db8::/32 over both links" "$nmdm" \
		"netstat -rn -f inet6 | grep -E '^2001:db8::/32 ' | awk '{print \$NF}' | sort | paste -s -d ' ' -" \
		'^vtnet1 vtnet3$'
}

lab_ecmp_vm1() { lab_ecmp_host 1 10.0.34.4 2001:db8:34::4 "$1"; }
lab_ecmp_vm2() { lab_ecmp_router 2 "$1"; }
lab_ecmp_vm3() { lab_ecmp_router 3 "$1"; }
lab_ecmp_vm4() { lab_ecmp_host 4 10.0.12.1 2001:db8:12::1 "$1"; }

# Output packets of a VM's two ECMP links, "vtnet1 vtnet3". $1: nmdm
ecmp_opkts() {
	console_run "$1" "echo \$(netstat -I vtnet1 -n | awk 'NR==2{print \$8}') \$(netstat -I vtnet3 -n | awk 'NR==2{print \$8}')" | tail -1
}

# Phase 3: a host sends 256 UDP flows, one per source port, to the other
# host; the router in front of it must send them over both links. Done in
# both directions: VM1 to VM4 through VM2, VM4 to VM1 through VM3.
lab_ecmp_throughput() {
	local src rtr dst4 dst6 af dst before after c1 c3

	for src in 1 4; do
		if [ "$src" = 1 ]; then
			rtr=2 dst4=10.0.34.4 dst6=2001:db8:34::4
		else
			rtr=3 dst4=10.0.12.1 dst6=2001:db8:12::1
		fi
		for af in 4 6; do
			[ "$af" = 4 ] && dst=$dst4 || dst=$dst6
			before=$(ecmp_opkts "${NMDM_PREFIX}${rtr}${NMDM_SUFFIX}")
			console_run "${NMDM_PREFIX}${src}${NMDM_SUFFIX}" \
				"for p in \$(jot 256 20000); do echo x | nc -${af} -u -w0 -p \$p ${dst} 9; done" >/dev/null
			after=$(ecmp_opkts "${NMDM_PREFIX}${rtr}${NMDM_SUFFIX}")
			c1=$(echo "$before $after" | awk '{print $3 - $1}')
			c3=$(echo "$before $after" | awk '{print $4 - $2}')
			echo "  VM${rtr} IPv${af} packets per link: vtnet1=${c1} vtnet3=${c3}"
			# 256 flows over 2 links: anything above 64 each is a
			# spread, a collapse gives 256 and 0.
			if [ "$c1" -gt 64 ] && [ "$c3" -gt 64 ]; then
				record "$rtr" "IPv${af} ECMP spreads 256 flows over both links" PASS ""
			else
				record "$rtr" "IPv${af} ECMP spreads 256 flows over both links" FAIL "vtnet1=${c1} vtnet3=${c3}"
			fi
		done
	done
}

# === rtbh lab =============================================================
#
# The ISP limits the customer link to 10 Mbit/s and honours the BLACKHOLE
# community on the customer's routes; the customer triggers it with a
# static route tagged 666.

lab_rtbh_vm1() {
	local nmdm="$1"

	assert 1 "hostname is internet" "$nmdm" "hostname" '^internet$'
	assert 1 "ping the victim 203.0.113.10" "$nmdm" \
		"ping -c 2 -t 5 203.0.113.10 2>&1" ' 0\.0% packet loss' 90
	assert 1 "ping the service 203.0.113.20" "$nmdm" \
		"ping -c 2 -t 5 203.0.113.20 2>&1" ' 0\.0% packet loss'
	assert 1 "ping the victim 2001:db8:113::10" "$nmdm" \
		"ping -6 -c 2 -t 5 2001:db8:113::10 2>&1" ' 0\.0% packet loss' 30
}

lab_rtbh_vm2() {
	local nmdm="$1"

	assert 2 "hostname is isp" "$nmdm" "hostname" '^isp$'
	assert 2 "customer link limited to 10 Mbit/s" "$nmdm" \
		"ipfw pipe 1 show 2>&1" '10\.000 Mbit/s'
	assert 2 "BGP session to the customer (10.0.23.3) Established" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast summary' 2>&1" '^10\.0\.23\.3 .* [0-9]+ +[0-9]+ +N/A$' 60
	assert 2 "BGP session to the customer (2001:db8:23::3) Established" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast summary' 2>&1" '^2001:db8:23::3 .* [0-9]+ +[0-9]+ +N/A$' 60
	assert 2 "customer aggregate 203.0.113.0/24 received" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast 203.0.113.0/24' 2>&1" '10\.0\.23\.3 from 10\.0\.23\.3'
	assert 2 "discard next-hop 192.0.2.1 is a blackhole route" "$nmdm" \
		"netstat -rn -f inet | grep -E '^192\.0\.2\.1 '" ' UH[^ ]*B '
}

lab_rtbh_vm3() {
	local nmdm="$1"

	assert 3 "hostname is customer" "$nmdm" "hostname" '^customer$'
	assert 3 "203.0.113.0/24 advertised to the ISP" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast neighbors 10.0.23.2 advertised-routes' 2>&1" '203\.0\.113\.0/24'
	assert 3 "2001:db8:113::/48 advertised to the ISP" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast neighbors 2001:db8:23::2 advertised-routes' 2>&1" '2001:db8:113::/48'
}

lab_rtbh_vm4() {
	local nmdm="$1"

	assert 4 "hostname is servers" "$nmdm" "hostname" '^servers$'
	assert 4 "iperf3 server running on the victim" "$nmdm" \
		"pgrep -x iperf3 || echo none" '^[0-9]+$'
}

# Phase 4: flood the victim from the internet, check the other service
# suffers, trigger the blackhole on the customer, check the ISP drops the
# flood and the service recovers, then withdraw the trigger.
lab_rtbh_failover() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local nmdm3="${NMDM_PREFIX}3${NMDM_SUFFIX}"
	# Prints "congested" above 20% loss, "clean" at 0%.
	local probe20="ping -i 0.2 -c 25 203.0.113.20 2>&1 | awk '/packet loss/ {l = \$7 + 0; print (l > 20) ? \"congested\" : (l == 0) ? \"clean\" : \"lossy\"}'"
	local trig="ip route 203.0.113.10/32 blackhole tag 666"
	local trig6="ipv6 route 2001:db8:113::10/128 blackhole tag 666"

	console_run "$nmdm1" "(iperf3 -c 203.0.113.10 -u -b 50M -l 1400 -t 300 > /dev/null 2>&1 &)" >/dev/null
	assert 1 "flood fills the customer link: service 203.0.113.20 loses packets" "$nmdm1" \
		"$probe20" '^congested$' 30

	console_run "$nmdm3" "vtysh -c 'conf t' -c '$trig' -c '$trig6'" >/dev/null
	assert 2 "victim 203.0.113.10/32 blackholed at the ISP" "$nmdm2" \
		"netstat -rn -f inet | grep -E '^203\.0\.113\.10 '" ' UH[^ ]*B ' 15
	assert 2 "victim 2001:db8:113::10 blackholed at the ISP" "$nmdm2" \
		"netstat -rn -f inet6 | grep -E '^2001:db8:113::10 '" ' UH[^ ]*B ' 15
	assert 2 "BLACKHOLE route gets NO_EXPORT at the ISP" "$nmdm2" \
		"vtysh -c 'show bgp ipv4 unicast 203.0.113.10/32' 2>&1" 'Community: blackhole no-export'
	assert 1 "flood dropped upstream: service 203.0.113.20 clean again" "$nmdm1" \
		"$probe20" '^clean$' 30

	console_run "$nmdm3" "vtysh -c 'conf t' -c 'no $trig' -c 'no $trig6'" >/dev/null
	console_run "$nmdm1" "pkill iperf3" >/dev/null
	assert 2 "trigger withdrawn: victim routed to the customer again" "$nmdm2" \
		"netstat -rn -f inet | grep -cE '^203\.0\.113\.10 '" '^0$' 15
	assert 1 "victim 203.0.113.10 reachable again" "$nmdm1" \
		"ping -c 2 -t 5 203.0.113.10 2>&1" ' 0\.0% packet loss' 30
}

# === ixp lab ==============================================================
#
# Two route servers (rs1 BIRD, rs2 FRR) on a shared peering LAN; three
# members peer with both. as64502 also announces a hijack of as64501's
# space; as64503 tags its routes "not to AS 64502".

lab_ixp_vm1() {
	local nmdm="$1" as af

	assert 1 "hostname is rs1" "$nmdm" "hostname" '^rs1$'
	for as in 64501 64502 64503; do
		for af in 4 6; do
			assert 1 "BIRD session as${as}_v${af} Established" "$nmdm" \
				"birdc show protocols as${as}_v${af} 2>&1" 'Established' 60
		done
	done
	assert 1 "hijack 198.51.100.128/25 from as64502 filtered" "$nmdm" \
		"birdc show route filtered protocol as64502_v4 2>&1" '^198\.51\.100\.128/25 '
	assert 1 "hijack 2001:db8:a:8000::/49 from as64502 filtered" "$nmdm" \
		"birdc show route filtered protocol as64502_v6 2>&1" '^2001:db8:a:8000::/49 '
}

lab_ixp_vm2() {
	local nmdm="$1"

	assert 2 "hostname is rs2" "$nmdm" "hostname" '^rs2$'
	assert 2 "FRR sessions to the 3 members Established (IPv4)" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast summary' 2>&1 | grep -cE '^10\.0\.0\.[345] .* [0-9]+ +[0-9]+ +N/A$'" '^3$' 60
	assert 2 "FRR sessions to the 3 members Established (IPv6)" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast summary' 2>&1 | grep -cE '^2001:db8::[345] .* [0-9]+ +[0-9]+ +N/A$'" '^3$' 60
	assert 2 "hijack 198.51.100.128/25 from as64502 filtered" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast neighbors 10.0.0.4 filtered-routes' 2>&1" '198\.51\.100\.128/25'
	assert 2 "hijack 2001:db8:a:8000::/49 from as64502 filtered" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast neighbors 2001:db8::4 filtered-routes' 2>&1" '2001:db8:a:8000::/49'
}

# $1: VM, $2: AS, $3: peer AS, $4: peer's IPv4 prefix, $5: peer's lo1
# IPv4, $6: peer's IPv6 lo1, $7: nmdm
lab_ixp_member() {
	local vm="$1" as="$2" pas="$3" pfx="$4" lo4="$5" lo6="$6" nmdm="$7"
	local nh="10\\.0\\.0\\.$((pas - 64498))"

	assert "$vm" "hostname is as${as}" "$nmdm" "hostname" "^as${as}\$"
	assert "$vm" "${pfx} learned from both route servers" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast ${pfx}' 2>&1" 'Paths: \(2 available' 60
	# Both paths read "  <peer AS>": no route server AS prepended.
	assert "$vm" "${pfx}: AS path is ${pas} alone" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast ${pfx}' 2>&1 | grep -E '^  [0-9 ]+$' | sort -u | tr -d ' \\n'; echo" \
		"^${pas}\$"
	assert "$vm" "${pfx}: next-hop is AS${pas} itself" "$nmdm" \
		"route -n get ${lo4} 2>&1" "gateway: ${nh}\$"
	assert "$vm" "ping AS${pas} ${lo4} across the LAN" "$nmdm" \
		"ping -c 2 -t 5 -S \$(ifconfig lo1 | awk '/inet /{print \$2}') ${lo4} 2>&1" ' 0\.0% packet loss' 30
	assert "$vm" "ping AS${pas} ${lo6} across the LAN" "$nmdm" \
		"ping -6 -c 2 -t 5 -S \$(ifconfig lo1 | awk '/inet6 2001/{print \$2}') ${lo6} 2>&1" ' 0\.0% packet loss' 30
}

lab_ixp_vm3() {
	lab_ixp_member 3 64501 64502 203.0.113.0/24 203.0.113.1 2001:db8:b::1 "$1"
}

lab_ixp_vm4() {
	local nmdm="$1"

	lab_ixp_member 4 64502 64501 198.51.100.0/24 198.51.100.1 2001:db8:a::1 "$nmdm"
	assert 4 "192.0.2.0/24 (tagged 0:64502 by as64503) not received" "$nmdm" \
		"vtysh -c 'show bgp ipv4 unicast 192.0.2.0/24' 2>&1" 'Network not in table'
	assert 4 "2001:db8:c::/48 (tagged 0:64502 by as64503) not received" "$nmdm" \
		"vtysh -c 'show bgp ipv6 unicast 2001:db8:c::/48' 2>&1" 'Network not in table'
}

lab_ixp_vm5() {
	local nmdm="$1"

	lab_ixp_member 5 64503 64501 198.51.100.0/24 198.51.100.1 2001:db8:a::1 "$nmdm"
	assert 5 "hijacked 198.51.100.200 still routed to as64501" "$nmdm" \
		"route -n get 198.51.100.200 2>&1" 'gateway: 10\.0\.0\.3$'
	# rs1 (BIRD) passes on as64501's link-local next-hop too.
	assert 5 "hijacked 2001:db8:a:8000::1 still routed to as64501" "$nmdm" \
		"route -n get -inet6 2001:db8:a:8000::1 2>&1" \
		'gateway: (2001:db8::3|fe80::[0-9a-f:]+:3%vtnet4)$'
}

# Phase 4: stop each route server in turn while as64503 pings as64501:
# the members keep the other server's routes and no packet is lost.
lab_ixp_failover() {
	local nmdm1="${NMDM_PREFIX}1${NMDM_SUFFIX}"
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local nmdm5="${NMDM_PREFIX}5${NMDM_SUFFIX}"
	local paths="vtysh -c 'show bgp ipv4 unicast 198.51.100.0/24' 2>&1"
	local rs vm nmdm stop start

	for rs in 1 2; do
		if [ "$rs" = 1 ]; then
			nmdm="$nmdm1" stop="service bird stop" start="service bird start"
		else
			nmdm="$nmdm2" stop="service frr stop" start="service frr start"
		fi
		console_run "$nmdm5" "(ping -i 0.2 -c 100 -S 192.0.2.1 198.51.100.1 > /tmp/ixp-ping.log 2>&1 &)" >/dev/null
		console_run "$nmdm" "$stop" >/dev/null
		assert 5 "rs${rs} down: 198.51.100.0/24 kept from the other server" "$nmdm5" \
			"$paths" 'Paths: \(1 available' 30
		assert 5 "rs${rs} down: no packet lost to as64501" "$nmdm5" \
			"tail -2 /tmp/ixp-ping.log" ' 0\.0% packet loss' 40
		console_run "$nmdm" "$start" >/dev/null
		assert 5 "rs${rs} back: 198.51.100.0/24 from both servers again" "$nmdm5" \
			"$paths" 'Paths: \(2 available' 90
	done
}

# === accounting lab =======================================================
#
# The router exports NetFlow v9 to the collector, where nfacctd totals
# bytes per customer and direction (tag: customer x 100, +1 in, +2 out).

ACCT_QUERY="pmacct -s -p /tmp/accounting.pipe"

lab_accounting_vm1() {
	local nmdm="$1"

	assert 1 "hostname is internet" "$nmdm" "hostname" '^internet$'
	assert 1 "iperf3 server running" "$nmdm" \
		"pgrep -x iperf3 || echo none" '^[0-9]+$'
}

lab_accounting_vm2() {
	local nmdm="$1"

	assert 2 "hostname is router" "$nmdm" "hostname" '^router$'
	assert 2 "outgoing packets skip the NetFlow tee" "$nmdm" \
		"ipfw list 900 2>&1" '^00900 skipto 1100 ip from any to any out$'
	assert 2 "ng_netflow exporting v9 to the collector" "$nmdm" \
		"ngctl show netflow: 2>&1" 'export9 +netflow_export'
	assert 2 "ng_netflow tuned (5s inactive timeout)" "$nmdm" \
		"ngctl msg netflow: info 2>&1" 'Inactive timeout=5 '
}

# $1: VM, $2: hostname, $3: nmdm
lab_accounting_customer() {
	local vm="$1" name="$2" nmdm="$3"

	assert "$vm" "hostname is ${name}" "$nmdm" "hostname" "^${name}\$"
	assert "$vm" "ping the internet 10.0.12.1" "$nmdm" \
		"ping -c 2 -t 5 10.0.12.1 2>&1" ' 0\.0% packet loss' 60
	assert "$vm" "ping the internet 2001:db8:12::1" "$nmdm" \
		"ping -6 -c 2 -t 5 2001:db8:12::1 2>&1" ' 0\.0% packet loss' 30
}

lab_accounting_vm3() { lab_accounting_customer 3 customer-a "$1"; }
lab_accounting_vm4() { lab_accounting_customer 4 customer-b "$1"; }

lab_accounting_vm5() {
	local nmdm="$1"

	assert 5 "hostname is collector" "$nmdm" "hostname" '^collector$'
	assert 5 "nfacctd live table answers" "$nmdm" \
		"$ACCT_QUERY 2>&1" '^TAG +PACKETS +BYTES'
}

# Phase 3: transfer known volumes with iperf3, then check the collector
# accounted each one to the right customer and direction: between 100%
# and 120% of the payload (TCP/IP headers, and the ACKs of the other
# transfer). Counting forwarded packets both in and out would give 200%.
lab_accounting_throughput() {
	local nmdm3="${NMDM_PREFIX}3${NMDM_SUFFIX}"
	local nmdm4="${NMDM_PREFIX}4${NMDM_SUFFIX}"
	local nmdm5="${NMDM_PREFIX}5${NMDM_SUFFIX}"
	local iperf="/usr/local/bin/iperf3"

	console_run "$nmdm5" "$ACCT_QUERY -e" >/dev/null
	assert 3 "customer-a downloads 40 MiB over IPv4" "$nmdm3" \
		"$iperf -c 10.0.12.1 -R -n 40M 2>&1" 'receiver' 60
	assert 3 "customer-a uploads 10 MiB over IPv6" "$nmdm3" \
		"$iperf -6 -c 2001:db8:12::1 -n 10M 2>&1" 'receiver' 60
	assert 4 "customer-b downloads 20 MiB over IPv6" "$nmdm4" \
		"$iperf -6 -c 2001:db8:12::1 -R -n 20M 2>&1" 'receiver' 60
	acct_check 101 40 "customer-a in (IPv4 download)"
	acct_check 102 10 "customer-a out (IPv6 upload)"
	acct_check 201 20 "customer-b in (IPv6 download)"
	# The files are written a minute or two after their time-bin.
	assert 5 "billing CSV files hold customer-a's 40 MiB download" "$nmdm5" \
		"cat /var/log/accounting-*.csv 2>&1 | awk -F, '\$1 == 101 { s += \$3 } END { print (s >= 40 * 1048576) ? \"ok\" : \"short\", s }'" \
		'^ok ' 180
}

# $1: tag, $2: MiB transferred, $3: description
acct_check() {
	local nmdm5="${NMDM_PREFIX}5${NMDM_SUFFIX}"

	assert 5 "accounted ${3}: 100-120% of ${2} MiB" "$nmdm5" \
		"$ACCT_QUERY | awk '\$1 == $1 { r = \$3 / ($2 * 1048576); printf \"%s %.3f\\n\", (r >= 1 && r <= 1.2) ? \"ok\" : \"off\", r }'" \
		'^ok ' 30
}

# === ipv6only lab =========================================================
#
# IPv6-only access: the CPE reaches the IPv4 server through the ISP's NAT64
# (nat64lsn, prefix 2001:db8:64::/96), natively over IPv6 with DNS64 and,
# for its IPv4 LAN, through its own CLAT (nat64clat, 464XLAT).

lab_ipv6only_vm1() {
	local nmdm="$1"

	assert 1 "hostname is server" "$nmdm" "hostname" '^server$'
	assert 1 "iperf3 server running" "$nmdm" \
		"pgrep -x iperf3 || echo none" '^[0-9]+$'
	assert 1 "no IPv6 global address (IPv4-only server)" "$nmdm" \
		"ifconfig -a inet6 | grep -c 'inet6 2001'" '^0$'
}

lab_ipv6only_vm2() {
	local nmdm="$1"

	assert 2 "hostname is nat64" "$nmdm" "hostname" '^nat64$'
	assert 2 "nat64lsn pool 198.51.100.0/28, prefix 2001:db8:64::/96" "$nmdm" \
		"ipfw nat64lsn isp list 2>&1" \
		'prefix4 198\.51\.100\.0/28 prefix6 2001:db8:64::/96'
	assert 2 "DNS64 answers the server's synthesized AAAA" "$nmdm" \
		"host -t AAAA server.example.net ::1 2>&1" \
		'has IPv6 address 2001:db8:64::cb00:710a$'
}

lab_ipv6only_vm3() {
	local nmdm="$1"

	assert 3 "hostname is cpe" "$nmdm" "hostname" '^cpe$'
	assert 3 "no IPv4 default route (IPv6-only access)" "$nmdm" \
		"netstat -rn -f inet | grep -c '^default'" '^0$'
	assert 3 "nat64clat with CLAT prefix 2001:db8:3:464::/96" "$nmdm" \
		"ipfw nat64clat clat list 2>&1" \
		'clat_prefix 2001:db8:3:464::/96 plat_prefix 2001:db8:64::/96'
	assert 3 "ping the NAT64 router 2001:db8:23::1" "$nmdm" \
		"ping -6 -c 2 -t 5 2001:db8:23::1 2>&1" ' 0\.0% packet loss' 60
}

lab_ipv6only_vm4() {
	local nmdm="$1"

	assert 4 "hostname is client" "$nmdm" "hostname" '^client$'
	assert 4 "DNS64 resolves server.example.net into the NAT64 prefix" \
		"$nmdm" "host -t AAAA server.example.net 2>&1" \
		'has IPv6 address 2001:db8:64::cb00:710a$' 60
	assert 4 "NAT64: ping server.example.net over IPv6" "$nmdm" \
		"ping -6 -c 2 -t 5 server.example.net 2>&1" ' 0\.0% packet loss' 30
	assert 4 "464XLAT: ping 203.0.113.10 over IPv4" "$nmdm" \
		"ping -4 -c 2 -t 5 203.0.113.10 2>&1" ' 0\.0% packet loss' 30
}

# Phase 3: TCP transfers both ways through each path (path MTU discovery
# included), UDP datagrams too large for the IPv6 access, then the NAT64
# states of both the CLAT and the native IPv6 address of the client.
lab_ipv6only_throughput() {
	local nmdm2="${NMDM_PREFIX}2${NMDM_SUFFIX}"
	local nmdm4="${NMDM_PREFIX}4${NMDM_SUFFIX}"
	local iperf="/usr/local/bin/iperf3"

	assert 4 "464XLAT: iperf3 upload 20 MiB over IPv4" "$nmdm4" \
		"$iperf -4 -c 203.0.113.10 -n 20M 2>&1" 'receiver' 60
	assert 4 "464XLAT: iperf3 download 20 MiB over IPv4" "$nmdm4" \
		"$iperf -4 -c 203.0.113.10 -R -n 20M 2>&1" 'receiver' 60
	assert 4 "NAT64: iperf3 download 20 MiB from server.example.net" \
		"$nmdm4" "$iperf -6 -c server.example.net -R -n 20M 2>&1" \
		'receiver' 60
	# 1472-byte UDP payloads make 1500-byte IPv4 packets, 1520 bytes
	# in IPv6: each one crosses the IPv6 access as two fragments.
	assert 4 "464XLAT: fragmented UDP upload, nothing lost" "$nmdm4" \
		"$iperf -4 -c 203.0.113.10 -u -l 1472 -b 1M -t 2 2>&1" \
		' 0/[1-9][0-9]* \(0%\) +receiver' 60
	assert 4 "464XLAT: fragmented UDP download, nothing lost" "$nmdm4" \
		"$iperf -4 -c 203.0.113.10 -u -l 1472 -b 1M -t 2 -R 2>&1" \
		' 0/[1-9][0-9]* \(0%\) +receiver' 60
	assert 2 "NAT64 state for the client's CLAT address" "$nmdm2" \
		"ipfw nat64lsn isp show states 2>&1" \
		'^2001:db8:3:464::c0a8:10a(:[0-9]+)? +198\.51\.100\.'
	assert 2 "NAT64 state for the client's IPv6 address" "$nmdm2" \
		"ipfw nat64lsn isp show states 2>&1" \
		'^2001:db8:3::10(:[0-9]+)? +198\.51\.100\.'
}

# === Lab metadata =========================================================

lab_vm_count() {
	case "$1" in
		accounting) echo 5 ;;
		anycast)   echo 4 ;;
		branch)    echo 5 ;;
		full)      echo 5 ;;
		ipv6only)  echo 4 ;;
		ixp)       echo 5 ;;
		frr)       echo 7 ;;
		bgp)       echo 7 ;;
		vpn)       echo 5 ;;
		mlvpn)     echo 6 ;;
		mlppp)     echo 6 ;;
		dhcp)      echo 3 ;;
		ecmp)      echo 4 ;;
		fairshape) echo 5 ;;
		jailpf)    echo 5 ;;
		pimsm)     echo 4 ;;
		pimssm)    echo 4 ;;
		rtbh)      echo 4 ;;
		vrrp)      echo 4 ;;
		*)         echo 0 ;;
	esac
}

# Extra BSDRP-lab-bhyve.sh options a lab needs, beyond -n and -r.
lab_launch_opts() {
	case "$1" in
		ecmp) echo "-l 1" ;;	# second VM2-VM3 link on the shared LAN
		ixp)  echo "-l 1" ;;	# the peering LAN
	esac
}

# Order in which VMs are tested. In the "full" lab, R1 is the end-user
# client whose connectivity depends on every other router being up and
# converged (DHCP relay through R2 to dhcpd in jail5/R5, plus full
# routing reachability to jail6 through R2/R4). Testing it last gives
# the routing protocols and DHCP relay time to settle.
lab_vm_order() {
	case "$1" in
		full) echo "2 3 4 5 1" ;;
		*)    seq 1 "$(lab_vm_count "$1")" ;;
	esac
}

# === Driver ===============================================================

VM_COUNT=$(lab_vm_count "$LAB")
[ "$VM_COUNT" -gt 0 ] || die "unsupported lab: $LAB"

case "$LAB" in
	accounting|full|anycast|branch|ecmp|ipv6only|ixp|rtbh) ;;
	*) die "lab '$LAB' has no assertions implemented yet (only 'accounting', 'full', 'anycast', 'branch', 'ecmp', 'ipv6only', 'ixp' and 'rtbh' have them)" ;;
esac

# --- Phase 0: launch the lab (unless --no-launch) ------------------------
# Done AFTER lab-name validation so a typo doesn't destroy a running lab.
if [ "$NO_LAUNCH" -eq 0 ]; then
	LAB_LAUNCHER="${SCRIPT_DIR}/BSDRP-lab-bhyve.sh"
	[ -x "$LAB_LAUNCHER" ] || die "lab launcher not found or not executable: $LAB_LAUNCHER"

	echo "=== Phase 0: launch lab=${LAB} (image=${IMAGE}, VMs=${VM_COUNT}) ==="

	# Step 1: wipe any prior state. Required so cloud-init's first-boot
	# runcmd re-fires `labconfig` on the new VMs — otherwise stale /cfg
	# from a previous run keeps the old config and labconfig is silently
	# skipped (see CLAUDE.md gotcha).
	echo "+ $LAB_LAUNCHER -d"
	"$LAB_LAUNCHER" -d || die "failed to wipe prior lab state ($LAB_LAUNCHER -d exited non-zero)"

	# Step 2: launch the lab with the correct VM count for this lab.
	LAUNCH_OPTS=$(lab_launch_opts "$LAB")
	echo "+ $LAB_LAUNCHER -i $IMAGE -n $VM_COUNT $LAUNCH_OPTS -r $LAB"
	# shellcheck disable=SC2086 # LAUNCH_OPTS holds several words
	"$LAB_LAUNCHER" -i "$IMAGE" -n "$VM_COUNT" $LAUNCH_OPTS -r "$LAB" \
		|| die "failed to launch lab ($LAB_LAUNCHER -i ... -r $LAB exited non-zero)"

	# Step 3: give cloud-init / labconfig time to finish before we start
	# driving the consoles. The per-assertion retry budget absorbs the
	# rest of convergence.
	echo "  waiting ${BOOT_DELAY}s for cloud-init/labconfig to settle..."
	sleep "$BOOT_DELAY"
fi

VM_ORDER=$(lab_vm_order "$LAB")
echo "=== BSDRP regression test: lab=${LAB}, VMs=${VM_COUNT} (order: ${VM_ORDER}) ==="

# Build the list of VMs whose consoles are actually reachable.  The three
# phases below all iterate over this list, so we only probe each VM's login
# once.
LIVE_VMS=""
for vm in $VM_ORDER; do
	nmdm="${NMDM_PREFIX}${vm}${NMDM_SUFFIX}"
	if [ ! -e "$nmdm" ]; then
		echo "  [SKIP] VM${vm}: console ${nmdm} not found (is the lab running?)"
		continue
	fi
	if ! console_run "$nmdm" "true" >/dev/null; then
		record "$vm" "console login" FAIL "no login/prompt within ${LOGIN_TIMEOUT}s"
		continue
	fi
	LIVE_VMS="${LIVE_VMS} ${vm}"
done

# --- Phase 1: dump interfaces + routing tables for every live VM ---------
# Informational only.  Useful for debugging convergence failures that the
# downstream assert phase will catch.
echo
echo "=== Phase 1: topology (interfaces + routing tables) ==="
for vm in $LIVE_VMS; do
	nmdm="${NMDM_PREFIX}${vm}${NMDM_SUFFIX}"
	dump_vm_topology "$vm" "$nmdm"
done

# --- Phase 2: per-VM assertions (hostname/daemons/pings/etc.) ------------
echo
echo "=== Phase 2: per-VM assertions ==="
for vm in $LIVE_VMS; do
	nmdm="${NMDM_PREFIX}${vm}${NMDM_SUFFIX}"
	echo "--- VM${vm} (${nmdm}) ---"
	fn="lab_${LAB}_vm${vm}"
	if type "$fn" >/dev/null 2>&1; then
		"$fn" "$nmdm"
	else
		echo "  [skip] VM${vm}: no assertions defined (${fn} not found)"
	fi
done

# --- Phase 3: throughput postlude (iperf3 across the shaped path) --------
# Only runs for labs with a defined throughput driver.
fn="lab_${LAB}_throughput"
if type "$fn" >/dev/null 2>&1; then
	echo
	echo "=== Phase 3: end-to-end throughput ==="
	"$fn"
fi

# --- Phase 4: failover (break something on purpose, then restore it) -----
# Runs last: every step disturbs the lab. Only for labs with a driver.
fn="lab_${LAB}_failover"
if type "$fn" >/dev/null 2>&1; then
	echo
	echo "=== Phase 4: failover ==="
	"$fn"
fi

echo
echo "=== Summary: ${PASS} passed, ${FAIL} failed ==="
if [ "$FAIL" -gt 0 ]; then
	printf '%s\n' "$FAILED_DETAIL" >&2
	exit 1
fi
exit 0
