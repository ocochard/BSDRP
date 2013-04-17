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
# TO DO
CFG_DIR_LIST=''

# Number of iteration for the same tests (for filling ministat)
TEST_ITER_MAX=5

# Host IP/hostname
TESTER_1_ADMIN="192.168.5.1"
TESTER_2_ADMIN="192.168.5.2"
DUT_ADMIN="192.168.5.3"

#netblast need these information:
TESTER_1_LAB="1.1.1.1"
TESTER_2_LAB="2.2.2.2"

#netmap pkt-gen need these information:
TESTER_1_LAB_IF="em0"
TESTER_1_LAB_IF_MAC="00:1b:21:d5:66:0e"
TESTER_2_LAB_IF="em0"
TESTER_2_LAB_IF_MAC="00:1b:21:d5:66:15"
DUT_LAB_IF_MAC_TO_T1="00:0e:0c:de:45:de"
DUT_LAB_IF_MAC_TO_T2="00:0e:0c:de:45:df"
PKT_TO_SEND="100000000"

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
	eval ${SSH_CMD} $1 $2 && return 0 || return 1
}

reboot_dut () {
	# Reboot the dut
	# Need to wait an online return before continuing too
	echo -n "Rebooting DUT and waiting device return online..."
	rcmd ${DUT_ADMIN} reboot > /dev/null 2>&1
	# || die "Can't reboot the DUT after bench TEST/CFG/IMG: ${TEST_ITER}/${CONFIG_ITER}/${IMAGE_ITER}"
	sleep 10
	#wait-for-dut online and in forwarding mode
	local REBOOT_TIMEOUT=120
	while ! rcmd ${TESTER_1_ADMIN} "ping -c 2 ${TESTER_2_LAB}" > /dev/null 2>&1; do
		sleep 5
		REBOOT_TIMEOUT=`expr ${REBOOT_TIMEOUT} - 1`
		[ ${REBOOT_TIMEOUT} -eq 0 ] && die "DUT didn't switch in forwarding mode after `expr 120 \* 5` seconds"
	done
	echo "done"
	return 0
}

bench () {
	# Benching script
	# $1: Directory/prefix-name of output log file
	echo "Start bench serie $1"
	for ITER in `seq 1 ${TEST_ITER_MAX}`; do
		#start netreceive on TESTER2
		#CMD="netreceive 9090"
		#start pkt-gen on TESTER2
		CMD="pkt-gen -i ${TESTER_2_LAB_IF} -w 8"

		echo "CMD: ${CMD}" > $1.${ITER}.receiver
		rcmd ${TESTER_2_ADMIN} "${CMD}" >> $1.${ITER}.receiver 2>&1 &
		#JOB_RECEIVER=$!
		
		#Alternate method with log file stored on TESTER (if tool is verbose)	
		#rcmd ${TESTER_2_ADMIN} "nohup netreceive 9090 \>\& /tmp/bench.log.receiver \&"
		#start netblast on TESTER1
		#CMD="netblast ${TESTER_2_LAB} 9090 0 10"
		CMD="pkt-gen -i ${TESTER_1_LAB_IF} -t ${PKT_TO_SEND} -l 42 -d ${TESTER_2_LAB} -D ${DUT_LAB_IF_MAC_TO_T1} -s ${TESTER_1_LAB} -w 10"
		echo "CMD: ${CMD}" > $1.${ITER}.sender
		rcmd ${TESTER_1_ADMIN} "${CMD}" >> $1.${ITER}.sender 2>&1 &
		JOB_SENDER=$!
		echo -n "Waiting for end of bench ${TEST_ITER}/${TOTAL_TEST}..."
		wait ${JOB_SENDER}
		rcmd ${TESTER_2_ADMIN} "pkill pkt-gen" || echo "DEBUG: Can't kill pkt-gen"
		
		#scp ${TESTER_2_ADMIN}:/tmp/bench.log.receiver $1.${ITER}.receiver
		#kill ${JOB_RECEIVER}
	
		echo "done"

		# if we did the last test, we can exit (avoid to wait for an useless reboot)
		[ ${TEST_ITER} -eq ${TOTAL_TEST} ] && return 0
		TEST_ITER=`expr ${TEST_ITER} + 1`
		
		# if we did the last test of the serie, we can exit and avoid an useless reboot
		# because after this last, it will be rebooted outside this function
		[ ${ITER} -eq ${TEST_ITER_MAX} ] && return 0	
		
		reboot_dut
	done
	return 0
}

upload_cfg () {
	# Uploading configuration to the DUT
	# $1: Path to the directory dir that conains configurations files
	echo "TODO: uploading cfg $1"
	return 0
}

icmp_test_all () {
	# Test if we can ping to all devices
	local PING_ACCESS_OK=true
	echo "Testing ICMP connectivity to each devices:"
	for HOST in ${TESTER_1_ADMIN} ${TESTER_2_ADMIN} ${DUT_ADMIN}; do
		echo -n "  ${HOST}..."
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
	echo "Testing SSH connectivity with key to each devices:"
	for HOST in ${TESTER_1_ADMIN} ${TESTER_2_ADMIN} ${DUT_ADMIN}; do
		echo -n "  ${HOST}..."
		if ! rcmd ${HOST} "show ver" > /dev/null 2>&1; then
			echo ""
			echo -n "    Pushing ssh key to ${HOST}..."
			if [ -f ~/.ssh/id_rsa.pub ]; then
				cat ~/.ssh/id_rsa.pub | ssh -2 -q -o "StrictHostKeyChecking no" root@${HOST} "cat >> ~/.ssh/authorized_keys" > /dev/null 2>&1
			elif [ -f ~/.ssh/id_dsa.pub ]; then
				cat ~/.ssh/id_dsa.pub | ssh -2 -q -o "StrictHostKeyChecking no" root@${HOST} "cat >> ~/.ssh/authorized_keys" > /dev/null 2>&1
			else
				echo "NOK"
				die "Didn't found user public SSH key"
			fi
		else
			echo "OK"
		fi
	done
	return 0
}

upgrade_image () {
	# Upgrade remote image
	# $1 Full path to the image
	echo -n "Upgrading..."
	if echo $1 | grep -q ".img.xz"; then
		cat $1 | rcmd  ${DUT_ADMIN} "xzcat \| upgrade" > /dev/null 2>&1
	else
		cat $1 | rcmd ${DUT_ADMIN} "cat \| upgrade" > /dev/null 2>&1
	fi
	echo "done"
	return 0
}

##### Main

echo "BSDRP automatized upgrade/configuration-sets/benchs script"
[ -d ${BENCH_DIR} ] || mkdir -p ${BENCH_DIR}
[ -f ${BENCH_DIR}/bench.1.info ] && die "You really should clean-up all previous reports in ${BENCH_DIR} before to mismatch your differents results"

icmp_test_all || die "ICMP connectivity test failed"
ssh-add -l > /dev/null 2 || echo "WARNING: No key loaded in ssh-agent?"
ssh_push_key || ( echo "SSH connectivity test failed";exit 1 )

echo "Starting the benchs"
for UPGRADE_IMAGE in ${IMAGE_LIST}; do
	echo "Testing image serie: ${UPGRADE_IMAGE}"
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
echo "All bench tests were done, results in ${BENCH_DIR}"
