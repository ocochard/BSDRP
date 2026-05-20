#!/bin/sh
#
# BSDRP regression-test driver
#
# SCOPE: this driver currently only implements assertions for the "full" lab
# (5 VMs - the BSDRP maximum-features lab). Other labs declared in
# tools/BSDRP-lab-bhyve.sh (frr, bgp, vpn, mlvpn, mlppp, ecmp, fairshape,
# jailpf, pimsm, vrrp, etc.) have no assertions defined here yet - running
# this driver against them will fail with "lab '<name>' has no assertions
# implemented yet (only 'full' is)".
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
derived from the lab name, sleeps for --boot-delay seconds (default 60),
and finally runs every assertion.

In --no-launch mode the lab must already be running:
  sudo tools/BSDRP-lab-bhyve.sh -i <image> -n <count> -r <lab>

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
	# R1 is tested last in the lab_vm_order so by now DHCP/relay/routing
	# have all had time to converge.
	assert 1 "lagg0 has DHCP-acquired IPv4 (10.0.12.1)" "$nmdm" \
		"ifconfig lagg0 inet" 'inet 10\.0\.12\.1[[:space:]]'
	# Default route points to R2's CARP VIP.
	assert 1 "default route via R2 CARP (10.0.12.254)" "$nmdm" \
		"netstat -rn4 2>&1" 'default[[:space:]]+10\.0\.12\.254'

	# Reachability sanity check before iperf3 - if R1 cannot reach jail6 the
	# iperf3 run is pointless and reports faster.
	# Path: R1 -> R2 -> PPTP tunnel (shaped by R4 pipes) -> R4 -> R5 -> jail6.
	assert 1 "R1 reachability to jail6 (10.0.56.6)" "$nmdm" \
		"ping -c 3 -W 2000 10.0.56.6 2>&1" '[123] packets received'

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

	# wiki/R2 IPsec TCP-MD5: setkey -D shows SAD entries for 10.0.23.{2,3}
	assert 2 "IPsec SA to 10.0.23.3 present" "$nmdm" \
		"setkey -D 2>&1" '10\.0\.23\.3'

	# wiki/R2 Reachability: ping R3's loopback.
	assert 2 "ping R3 loopback 10.0.0.3" "$nmdm" \
		"ping -c 2 -W 1000 10.0.0.3 2>&1" '0(\.0)?% packet loss|1 packets received|2 packets received'

	# wiki/R2 CARP: em0 alias 10.0.12.254/32 vhid 1
	assert 2 "CARP vhid 1 on em0/vtnet0" "$nmdm" \
		"ifconfig | grep -E 'vhid 1'" 'vhid 1'

	# wiki/R2 PPTP VPN Server: mpd5 listens on tcp/1723.
	assert 2 "mpd5 listening on tcp/1723" "$nmdm" \
		"sockstat -4 -l -p 1723 2>&1" 'mpd5|1723'

	# wiki/R2 DHCP relay: dhcprelya running.
	assert 2 "dhcprelya running" "$nmdm" \
		"pgrep -lf dhcprelya || echo none" 'dhcprelya'

	# wiki/R2 OSPF area 0 has routes.
	assert 2 "OSPF area 0.0.0.0 has routes" "$nmdm" \
		"vtysh -c 'show ip ospf route' 2>&1" 'O[[:space:]]|0\.0\.0\.0'

	# wiki/R2 pimd running. Cross-checked from R4's neighbor table in
	# lab_full_vm4 (R4 sees R2 over both ng0/ng1 PPTP tunnels).
	assert 2 "pimd running" "$nmdm" \
		"pgrep -lf pimd || echo none" 'pimd'
}

# ---- R3 ------------------------------------------------------------------
lab_full_vm3() {
	local nmdm="$1"

	# wiki/R3 Basic Connectivity
	assert 3 "hostname is R3" "$nmdm" "hostname" '^R3$'
	assert 3 "VLAN 23: 10.0.23.3 on em1.23/vtnet1.23" "$nmdm" \
		"ifconfig | grep -E 'inet 10\\.0\\.23\\.3 '" 'inet 10\.0\.23\.3'

	# wiki/R3 BGP via bird: peer R2inet4 should be 'up'/Established.
	assert 3 "bird BGP to R2 Established" "$nmdm" \
		"birdc show protocols 2>&1" 'BGP.*([Ee]stablished|[Uu]p)'

	# wiki/R3 IPsec to R2
	assert 3 "IPsec SA to 10.0.23.2 present" "$nmdm" \
		"setkey -D 2>&1" '10\.0\.23\.2'

	# wiki/R3 RIP/RIPng routes from R4 visible in bird.
	assert 3 "bird RIP routes present" "$nmdm" \
		"birdc show route 2>&1" 'RIP|via 10\.0\.34'

	# wiki/R3 PF: pfctl reports state info and rules.
	assert 3 "pf enabled" "$nmdm" \
		"pfctl -si 2>&1" 'Status: Enabled'
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
		"ifconfig ng0 2>&1" 'inet 10\.4\.24\.4|inet 10\.'

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

	# wiki/R4 pimd running.
	assert 4 "pimd running" "$nmdm" \
		"pgrep -lf pimd || echo none" 'pimd'

	# wiki/R4 PIM neighbors: R4 should peer with R5 over vtnet3 (10.0.45.5)
	# and with R2 over both PPTP tunnels (ng0 IPv4 = 10.4.24.2, ng1 IPv6 leg
	# = 10.6.24.2). Neighbor uptime is non-zero when the adjacency is up;
	# the table also lists the peer IP on its own row, so we just match the
	# expected address strings.
	assert 4 "PIM neighbor R5 (10.0.45.5) on vtnet3" "$nmdm" \
		"pimctl show neighbor 2>&1" '10\.0\.45\.5'
	assert 4 "PIM neighbor R2 (10.4.24.2) on ng0" "$nmdm" \
		"pimctl show neighbor 2>&1" '10\.4\.24\.2'
	assert 4 "PIM neighbor R2 (10.6.24.2) on ng1" "$nmdm" \
		"pimctl show neighbor 2>&1" '10\.6\.24\.2'

	# wiki/R4 PIM BSR/RP set: both R2 (10.6.24.2) and R4 (10.6.24.4) are
	# candidate RPs for 224.0.0.0/4 at priority 20. Static SSM mapping
	# 232.0.0.0/8 -> 169.254.0.1 is always present.
	assert 4 "PIM RP set has 224.0.0.0/4 candidates" "$nmdm" \
		"pimctl show rp 2>&1" '224\.0\.0\.0/4'

	# wiki/R4 Netflow exporter to 10.0.45.5:2055.
	assert 4 "netflow exporting to 10.0.45.5:2055" "$nmdm" \
		"sockstat 2>&1 | grep -E '10\\.0\\.45\\.5(:|\\.)2055' || echo none" \
		'10\.0\.45\.5'

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
		"jexec jail5 pgrep -lf pimd || echo none" 'pimd'
	assert 5 "jail5: PIM neighbor R4 (10.0.45.4) on vtnet3" "$nmdm" \
		"jexec jail5 pimctl show neighbor 2>&1" '10\.0\.45\.4'
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
}

# === Lab metadata =========================================================

lab_vm_count() {
	case "$1" in
		full)      echo 5 ;;
		frr)       echo 7 ;;
		bgp)       echo 7 ;;
		vpn)       echo 5 ;;
		mlvpn)     echo 6 ;;
		mlppp)     echo 6 ;;
		ecmp)      echo 6 ;;
		fairshape) echo 5 ;;
		jailpf)    echo 5 ;;
		pimsm)     echo 4 ;;
		vrrp)      echo 4 ;;
		*)         echo 0 ;;
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
	full) ;;
	*) die "lab '$LAB' has no assertions implemented yet (only 'full' is)" ;;
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
	echo "+ $LAB_LAUNCHER -i $IMAGE -n $VM_COUNT -r $LAB"
	"$LAB_LAUNCHER" -i "$IMAGE" -n "$VM_COUNT" -r "$LAB" \
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

echo
echo "=== Summary: ${PASS} passed, ${FAIL} failed ==="
if [ "$FAIL" -gt 0 ]; then
	printf '%s\n' "$FAILED_DETAIL" >&2
	exit 1
fi
exit 0
