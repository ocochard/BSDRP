#!/bin/sh
#
# Bench-lab for BSD Router Project 
# http://bsdrp.net
# 
# Purpose:
#  This script permit to automatize benching multiple BSDRP images and/or configuration parameters.
#  In a lab like this one:
#  +----------+     +-------------------------+     +----------+ 
#  | Tester_1 |<--->| Device Under Test (DUT) |<--->| Tester_2 | 
#  +----------+     +-------------------------+     +----------+
#      |                       |                         |
#    ------- admin network ---------------------------------
#
#  this script permit to:
#  1. change configuration or upgrade image of the DUT (BSDRP based) and reboot it
#  2. once rebooted, start some tests on the 2 testers and collect the result
#  All commands are ssh.
#   

set -eu

##### User modifiable variables section #####

# Bench result directory
BENCH_DIR="/tmp/benchs"

# List of IMAGES (upgrade type only) to tests
IMAGE_LIST='
/tmp/BSDRP-244900-upgrade-amd64-serial.img
/tmp/BSDRP-247463-upgrade-amd64-serial.img
/tmp/BSDRP-249330-upgrade-amd64-serial.img
'

# List of configurations folder to tests
# These directory should contains the configuration files like:
# /boot/loader.conf.local, /etc/rc.conf, /etc/sysctl.conf
CFG_DIR_LIST=''

# Number of iteration for the same tests (for filling ministat)
TEST_ITER_MAX=2

# Host IP/hostname
TESTER_1_ADMIN="192.168.56.11"
TESTER_2_ADMIN="192.168.56.13"
DUT_ADMIN="192.168.56.12"

TESTER_1_LAB="1.1.1.1"
TESTER_2_LAB="2.2.2.2"

# SSH Command line
SSH_CMD="/usr/bin/ssh -x -a -q -2 -o \"PreferredAuthentications publickey\" -o \"StrictHostKeyChecking no\" -l root"

###### End of user modifiable variable section #####

# Counters
CONFIG_ITER=1
IMAGE_ITER=1
TEST_ITER=1

# Counting total number of tests bench
TOTAL_TEST=0                                                                                                                
for IMG in ${IMAGE_LIST};  do
	if [ -n "${CFG_DIR_LIST}" ]; then
		for CFG in ${CFG_DIR_LIST}; do
			TOTAL_TEST=`expr ${TOTAL_TEST} + 1 \* ${TEST_ITER_MAX}`
		done
	else
		TOTAL_TEST=`expr ${TOTAL_TEST} + 1 \* ${TEST_ITER_MAX}`
	fi
done

# An usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

rcmd () {
	# Send remote command
	# $1: hostname
	# $2: command to send
	# return 0 if OK, 1 if not
	if eval ${SSH_CMD} $1 $2; then
		return 0
	else
		return 1
	fi	
}

reboot_dut () {
	# Reboot the dut
	# Force a configuration saving before ?
	# This will disconnect the ssh access, and we need to wait for timeout...
	rcmd ${DUT_ADMIN} reboot || die "Can't reboot the DUT after bench TEST/CFG/IMG: ${TEST_ITER}/${CONFIG_ITER}/${IMAGE_ITER}"
	sleep 5
}

bench () {
	# Benching script
	# $1: Directory/prefix-name of output log file
	echo "bench: $1"
	for ITER in `seq 1 ${TEST_ITER_MAX}`; do
		#wait-for-dut online and in forwarding mode
		local REBOOT_TIMEOUT=120
		while ! rcmd ${TESTER_1_ADMIN} "ping -c 2 ${TESTER_2_LAB}" > /dev/null 2>&1; do
			sleep 5
			REBOOT_TIMEOUT=`expr ${REBOOT_TIMEOUT} - 1`
			[ ${REBOOT_TIMEOUT} -eq 0 ] && die "DUT didn't switch in forwarding mode after `expr 120 \* 5` seconds"
		done
		#start receiver
		rcmd ${TESTER_2_ADMIN} "netreceive 9090" > $1.${TEST_ITER}.receiver 2>&1 &
		#|| die "Can't start receiver"
		#JOB_RECEIVER=$!
		
		#Alternate method with log file stored on TESTER (if tool is verbose)	
		#rcmd ${TESTER_2_ADMIN} "nohup netreceive 9090 \>\& /tmp/bench.log_${TEST_ITER}_receiver \&"
		#start generator
		rcmd ${TESTER_1_ADMIN} "netblast ${TESTER_2_LAB} 9090 0 10" > $1.${TEST_ITER}.sender 2>&1 &
		# || die "Can't start sender"	
		JOB_SENDER=$!
		echo "Waiting for end of bench ${TEST_ITER}/${TOTAL_TEST}..."
		wait ${JOB_SENDER}
		rcmd ${TESTER_2_ADMIN} "pkill netreceive"
		
		#scp ${TESTER_2_ADMIN}:/tmp/bench.log_${TEST_ITER}_receiver $1.${TEST_ITER}.receiver
		#kill ${JOB_RECEIVER}
		TEST_ITER=`expr ${TEST_ITER} + 1`
		reboot_dut
	done
}

upload_cfg () {
	# Uploading configuration to the DUT
	# $1: Path to the directory dir that conains configurations files
	echo "uploading cfg $1"
}

icmp_test_all () {
	# Test if we can ping to all devices
	local PING_ACCESS_OK=true
	echo "Testing ICMP connectivity to each devices:"
	for HOST in ${TESTER_1_ADMIN} ${TESTER_2_ADMIN} ${DUT_ADMIN}; do
		echo -n "${HOST}..."
		if ping -c 3 ${HOST} > /dev/null 2>&1; then
			echo "OK"
		else
			echo "NOK"
			PING=false
		fi
	done
	( ${PING_ACCESS_OK} ) && return 0 || return 1
}

ssh_push_key () {
	# Pushing ssh key
	for HOST in ${TESTER_1_ADMIN} ${TESTER_2_ADMIN} ${DUT_ADMIN}; do
		if ! rcmd ${HOST} "show ver" > /dev/null 2>&1; then
			echo -n "Pushing ssh key to ${HOST}..."
			if [ -f ~/.ssh/id_rsa.pub ]; then
				cat ~/.ssh/id_rsa.pub | ssh -2 -q -o "StrictHostKeyChecking no" root@${HOST} "cat >> ~/.ssh/authorized_keys"
			elif [ -f ~/.ssh/id_dsa.pub ]; then
				cat ~/.ssh/id_dsa.pub | ssh -2 -q -o "StrictHostKeyChecking no" root@${HOST} "cat >> ~/.ssh/authorized_keys"
			fi
		fi
	done
}

upgrade_image () {
	# Upgrade remote image
	# $1 Full path to the image
	echo "UPGRADING to $1..."
	if echo $1 | grep -q ".img.xz"; then
		cat $1 | rcmd  ${DUT_ADMIN} "xzcat \| upgrade"
	else
		cat $1 | rcmd ${DUT_ADMIN} "cat \| upgrade"
	fi
}

##### Main

[ -d ${BENCH_DIR} ] || mkdir -p ${BENCH_DIR}
[ -f ${BENCH_DIR}/bench.1.info ] && die "You really should clean-up all previous reports in ${BENCH_DIR} before to mismatch your differents results"

icmp_test_all && echo "ping tests OK" || die "ICMP connectivity test failed"
ssh-add -l > /dev/null 2 || echo "WARNING: No key loaded in ssh-agent?"
ssh_push_key || ( echo "SSH connectivity test failed";exit 1 )

for UPGRADE_IMAGE in ${IMAGE_LIST}; do
	upgrade_image ${UPGRADE_IMAGE} || die "Can't upgrade to image ${UPGRADE_IMAGE}"
	if [ -n "${CFG_DIR_LIST}" ]; then
		for CFG in ${CFG_DIR_LIST}; do
			echo "Starting sub-configuration serie bench test: ${CFG}..."
			upload_cfg ${CFG}
			reboot_dut
			echo "Image: ${UPGRADE_IMAGE}" > ${BENCH_DIR}/bench.${IMAGE_ITER}.${CFG_ITER}.info
			echo "CFG: ${CFG}" >> ${BENCH_DIR}/bench.${IMAGE_ITER}.${CFG_ITER}.info
			echo "Start time: `date`" >> ${BENCH_DIR}/bench.${IMAGE_ITER}.${CFG_ITER}.info
			bench ${BENCH_DIR}/bench.${IMAGE_ITER}.${CFG_ITER}
			CONFIG_ITER=`expr ${CONFIG_ITER} + 1`
		done
	else
		reboot_dut
		echo "Image: ${UPGRADE_IMAGE}" > ${BENCH_DIR}/bench.${IMAGE_ITER}.info
		echo "Start time: `date`" >> ${BENCH_DIR}/bench.${IMAGE_ITER}.info
		bench ${BENCH_DIR}/bench.${IMAGE_ITER}
		IMAGE_ITER=`expr ${IMAGE_ITER} + 1`
	fi
done
echo "All bench tests were done"
