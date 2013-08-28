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
#    -----------------admin network (ssh)--------------------
#
#  this script permit to:
#  1. change configuration or upgrade image of the DUT (BSDRP based) and reboot it
#  2. once rebooted, start some tests on the 2 testers and collect the result
#  All commands are ssh.
#   

set -eu

##### User modifiable variables section #####

# Don't forget to modify the bench commands in bench() too !!

# Host IP/hostname
TESTER_1_ADMIN="192.168.1.1"
TESTER_2_ADMIN="192.168.1.3"
DUT_ADMIN="192.168.1.2"

#netblast need these information:
TESTER_1_LAB="1.1.1.1"
TESTER_2_LAB="2.2.2.3"

#netmap pkt-gen need these information:
TESTER_1_LAB_IF="igb2"
TESTER_1_LAB_IF_MAC="00:1b:21:d4:3f:2a"
TESTER_2_LAB_IF="igb3"
TESTER_2_LAB_IF_MAC="00:1b:21:c4:95:7b"
DUT_LAB_IF_MAC_TO_T1="00:1b:21:d3:8f:3e"
DUT_LAB_IF_MAC_TO_T2="00:1b:21:d3:8f:3f"
PKT_TO_SEND="100000000"

# SSH Command line
SSH_CMD="/usr/bin/ssh -x -a -q -2 -o \"PreferredAuthentications publickey\" -o \"StrictHostKeyChecking no\" -l root"

###### End of user modifiable variable section #####

# Counters
CONFIG_ITER=1
IMAGE_ITER=1
TEST_ITER=1

# Counting total number of tests bench
# And checking file/directory presence
TOTAL_TEST=0                                                                                                                
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
	# WARNING: If configuration was not saved, it will ask user for configuration saving
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
		CMD="pkt-gen -f rx -i ${TESTER_2_LAB_IF} -w 8"

		echo "CMD: ${CMD}" > $1.${ITER}.receiver
		rcmd ${TESTER_2_ADMIN} "${CMD}" >> $1.${ITER}.receiver 2>&1 &
		#JOB_RECEIVER=$!
		
		#Alternate method with log file stored on TESTER (if tool is verbose)	
		#rcmd ${TESTER_2_ADMIN} "nohup netreceive 9090 \>\& /tmp/bench.log.receiver \&"
		#start netblast on TESTER1
		#CMD="netblast ${TESTER_2_LAB} 9090 0 10"
		CMD="pkt-gen -f tx -i ${TESTER_1_LAB_IF} -t ${PKT_TO_SEND} -l 42 \
		-d ${TESTER_2_LAB} -D ${DUT_LAB_IF_MAC_TO_T1} -s ${TESTER_1_LAB} \
    	-w 8"
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

bench_cfg () {
	# Bench this configuration-set
	# $1: configuration-set dir
	# $2: output-file-prefix	
	echo "Starting sub-configuration serie bench test: $1..."
	upload_cfg $1 || die "Can't upload $1"
	reboot_dut
	echo "Image: ${UPGRADE_IMAGE}" > $2.info
	echo "CFG: ${CFG}" >> $2.info
	echo "Start time: `date`" >> $2.info
	bench $2
}

upload_cfg () {
	# Uploading configuration to the DUT
	# $1: Path to the directory that contains configuration files
	echo "Uploading cfg $1"
	if [ -d $1/boot ]; then
		# Before putting file in /boot, we need to remount in RW mode
		if ! rcmd ${DUT_ADMIN} "mount -uw /" > /dev/null 2>&1; then
			return 1
		fi
	fi
	if ! scp -r -2 -o "PreferredAuthentications publickey" -o "StrictHostKeyChecking no" $1/* root@${DUT_ADMIN}:/ > /dev/null 2>&1; then
		return 1
	fi
	if rcmd ${DUT_ADMIN} "config save" > /dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

icmp_test_all () {
	# Test if we can ping all devices
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
		if ! rcmd ${HOST} "uname" > /dev/null 2>&1; then
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

usage () {
	if [ $# -lt 1 ]; then
		echo "$0 [-h] [-c configuration-sets-dir] [-i nanobsd-images-dir] [-n iteration] [-d benchs-dir]"
		echo "  nanobsd-images-dir: Directory where are all update nanobsd images"
		echo "  configuration-sets-dir: Directory that include directory for each configuration sets to test"
		echo "  iteration: number of iteration to do for each test"
		echo "  bench-dir: Where to put the results"
		exit 1 
	fi
}

##### Main

# List of configuration sets directory
CFG_LIST=''
# list of nanobsd upgrade image to be benched
IMAGES_LIST=''
# Number of iteration for the same tests (for filling ministat)
TEST_ITER_MAX=5
# Bench result directory
BENCH_DIR="/tmp/benchs"

args=`getopt c:d:i:hn: $*`

set -- $args
for i
do
    case "$i" in
        -c)
			CFG_LIST=`ls -1d $2/*`			
            shift
            shift
            ;;
        -d)
            BENCH_DIR="$2"
            shift
            shift
            ;;  
        -i)
       		IMAGES_LIST=`ls -1 $2/BSDRP-* | grep upgrade`     
			shift
            shift
            ;;
		-h)
			usage
			shift
			;;
        -n)
			TEST_ITER_MAX=$2	
            shift
			shift
            ;;
        --)
            shift
            break
        esac
done

if [ $# -gt 0 ] ; then
    echo "$0: Extraneous arguments supplied"
    usage
fi

if [ -n "${IMAGES_LIST}" ]; then
	for IMG in ${IMAGES_LIST};  do
		[ -f ${IMG} ] || die "Can't found file {IMG}"
		for CFG in ${CFG_LIST}; do
			[ -d ${CFG} ] || die "Can't found directory ${CFG}"
			TOTAL_TEST=`expr ${TOTAL_TEST} + 1 \* ${TEST_ITER_MAX}`
		done
		TOTAL_TEST=`expr ${TOTAL_TEST} + 1 \* ${TEST_ITER_MAX}`
	done
elif [ -n "${CFG_LIST}" ]; then
	 for CFG in ${CFG_LIST}; do
		[ -d ${CFG} ] || die "Can't found directory ${CFG}"
        TOTAL_TEST=`expr ${TOTAL_TEST} + 1 \* ${TEST_ITER_MAX}`
	done
else
	TOTAL_TEST=${TEST_ITER_MAX}
fi

echo "BSDRP automatized upgrade/configuration-sets/benchs script"
echo ""
echo "This script will start ${TOTAL_TEST} bench tests using:"
echo " - Number of iteration: ${TEST_ITER_MAX}"
echo -n " - Multiples images to test: "
[ -n "${IMAGES_LIST}" ] && echo "yes" || echo "no"
echo -n " - Multiples configuration-sets to test: "
[ -n "${CFG_LIST}" ] && echo "yes" || echo "no"
echo " - Results dir: ${BENCH_DIR}"
echo ""

[ -d ${BENCH_DIR} ] || mkdir -p ${BENCH_DIR}
ls ${BENCH_DIR} | grep -q bench && die "You really should clean-up all previous reports in ${BENCH_DIR} before to mismatch your differents results"

echo -n "Do you want to continue ? (y/n): " 
USER_CONFIRM=''                            
while [ "$USER_CONFIRM" != "y" -a "$USER_CONFIRM" != "n" ]; do                            
	read USER_CONFIRM <&1                                                                                           
done                                                                                                                
[ "$USER_CONFIRM" = "n" ] && exit 0

icmp_test_all || die "ICMP connectivity test failed"
ssh-add -l > /dev/null 2 || echo "WARNING: No key loaded in ssh-agent?"
ssh_push_key || ( echo "SSH connectivity test failed";exit 1 )

echo "Starting the benchs"
if [ -n "${IMAGES_LIST}" ]; then
	for UPGRADE_IMAGE in ${IMAGES_LIST}; do
		echo "Testing image serie: ${UPGRADE_IMAGE}"
		upgrade_image ${UPGRADE_IMAGE} || die "Can't upgrade to image ${UPGRADE_IMAGE}"
		if [ -n "${CFG_LIST}" ]; then
			for CFG in ${CFG_LIST}; do
				bench_cfg ${CFG} ${BENCH_DIR}/bench.${IMAGE_ITER}.${CONFIG_ITER}
				CONFIG_ITER=`expr ${CONFIG_ITER} + 1`
			done
		else
			reboot_dut
			echo "Image: ${UPGRADE_IMAGE}" > ${BENCH_DIR}/bench.${IMAGE_ITER}.info
			echo "Start time: `date`" >> ${BENCH_DIR}/bench.${IMAGE_ITER}.info
			bench ${BENCH_DIR}/bench.${IMAGE_ITER}
		fi
		IMAGE_ITER=`expr ${IMAGE_ITER} + 1`
	done
# bad copy/past, need to re-think this part
elif  [ -n "${CFG_LIST}" ]; then
	UPGRADE_IMAGE="none"
	for CFG in ${CFG_LIST}; do
		bench_cfg ${CFG} ${BENCH_DIR}/bench.${CONFIG_ITER}
        CONFIG_ITER=`expr ${CONFIG_ITER} + 1`
   done
else
	UPGRADE_IMAGE="none"
	reboot_dut
	echo "Image: none" > ${BENCH_DIR}/bench.info
	echo "Start time: `date`" >> ${BENCH_DIR}/bench.info
	bench ${BENCH_DIR}/bench
fi # -n "${IMAGES_LIST}"
echo "All bench tests were done, results in ${BENCH_DIR}"
