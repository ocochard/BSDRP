#!/bin/sh

# mputconfig: Send commands to multi remote device with little dependency (only empty tools needed)
# http://bsdrp.net
#
# Copyright (c) 2011, The BSDRP Development Team
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

set -e

### Functions ###

# system_check: Check if empty is installed
system_check () {
	if ! whereis -b empty > /dev/null 2>&1; then
		echo "ERROR: empty (http://empty.sourceforge.net/) is a mandatory dependency"
		echo "Install it under FreeBSD:"
		echo "   cd /usr/ports/net/empty; make install clean"
		echo "   or pkg_add -r empty"	
		exit 2
	fi
}

clean_close () {
	local DEVICE=$1
	if [ -f ${DEVICE}.pid ]; then
        # Empty should close by itself (clean command line have an exit or logout at the end)
        sleep 5
    fi

	if [ -f ${DEVICE}.pid ]; then
        echo "WARNING: Still pid for ${DEVICE}, can be a missing exit/logout commands at the end of commands-list file, or SSH error" >> ${LOG_FILE}
        if ! empty -k `cat ${DEVICE}.pid` > /dev/null 2>&1; then
            echo "ERROR: Can't force-kill process for ${DEVICE}" >> ${LOG_FILE}
        fi
    fi

}
# Send command to given host
put_cmd () {
    echo "INFO: Sending commands to $1..." >> ${LOG_FILE}
	local DEVICE=$1
	local RETURN_CODE=1
    set +e
    empty -f -i ${DEVICE}.input -o ${DEVICE}.output -p ${DEVICE}.pid -L ${DEVICE}.log ssh ${SSH_OPTION} ${LOGIN}@${DEVICE} > /dev/null 2>&1
    # empty return code is true (0) even if ssh connection failed
    # WARNING: Security problem here, because PASSWORD is visible in the output of ps (need to use idea from empty man page)
    empty -t ${TIMEOUT} -w -i ${DEVICE}.output -o ${DEVICE}.input "no)?" "yes\n" "assword:" "${PASSWORD}\n" > /dev/null 2>&1
    RETURN_CODE=$?
    # If first value returned, need to enter the password new
    if [ ${RETURN_CODE} -eq 1 ]; then
        empty -t ${TIMEOUT} -w -i ${DEVICE}.output -o ${DEVICE}.input "assword:" "${PASSWORD}\n" > /dev/null 2>&1
    elif [ ${RETURN_CODE} -ne 2 ]; then
        echo "ERROR: Bad password or connection error for ${DEVICE}" >> ${LOG_FILE}
		clean_close ${DEVICE}
        return 1
    fi
    for CMD in `cat ${COMMANDS_LIST_FILE}`; do
        empty -t ${TIMEOUT} -w -i ${DEVICE}.output -o ${DEVICE}.input "${DEVICE_PROMPT}" "${CMD}\n" > /dev/null 2>&1
        RETURN_CODE=$?
        if [ ${RETURN_CODE} -ne 1 ]; then
            echo "ERROR: Can't send ${CMD} to ${DEVICE}" >> ${LOG_FILE}
        fi
    done
	clean_close ${DEVICE}
	set -e
	return 0
}
# usage: Display command line help
usage () {
	echo "$0 -h -c commands_list_file -l device_list_file [-e extra_ssh_option] [-t parrallel_threads]"
	echo "  -c commands_list_file : Text file that contains list of commands to be send to remote device"
	echo "  -l device_list_file : Text file that contains list of device hostname or IP addresses"
	echo "  -x extra option: for adding one SSH command line option (like -p for changing default port)"
	echo "  -t number_of_parrallel_threads: 5 by default"
	echo "  -h                  : Display usage guide"		
	exit 1
}

### Main Code ###

# Variables
COMMANDS_LIST_FILE=""
DEVICES_LIST_FILE=""
LOGIN=""
PASSWORD=""
SSH_OPTION=""
DEVICE_PROMPT='#'
LOG_FILE="mputconfig.log"
TIMEOUT="5"
THREADS="5"

if [ $# -eq 0 ] ; then
        usage
fi

args=`getopt c:l:h $*`

set -- $args
for i do
        case "$i"
        in
        -c)
			COMMANDS_LIST_FILE=$2
			shift
			shift
			;;
		-l)
			DEVICES_LIST_FILE=$2
            shift
            shift
            ;;
		-h)
			usage
			shift
			;;
		-x)
			SSH_OPTION=$2
            shift
            shift
            ;;
		-t)
			THREADS=$2
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

set -u

system_check

# Check input files

if [ "${COMMANDS_LIST_FILE}" != "" ]; then
	if [ ! -f "${COMMANDS_LIST_FILE}" ]; then
		echo "ERROR: No file ${COMMANDS_LIST_FILE} found"
		exit 2
	fi
else
	echo "ERROR: No commands file given"
	usage
fi

if [ "${DEVICES_LIST_FILE}" != "" ]; then
	if [ ! -f "${DEVICES_LIST_FILE}" ]; then
    	echo "ERROR: No file ${DEVICES_LIST_FILE} found"
    	exit 2
	fi
else
	echo "ERROR: No devices liste file given"
	usage
fi

# login and password input
echo -n "Enter the common login to all your devices: "
read LOGIN

echo -n "Enter the common password to all your devices: "
stty -echo
read PASSWORD
stty echo
echo ""

IFS="
"

date >> ${LOG_FILE}

# Don't know how to do a simple `jobs | wc -l` in sh/tcsh
for DEVICE in `cat ${DEVICES_LIST_FILE}`; do
	jobs > dirtyhack
	while [ `wc -l dirtyhack | tr -s " " | cut -f 2 -d " "` -ge ${THREADS} ]; do
		sleep 5
		jobs > dirtyhack
	done
		put_cmd ${DEVICE} &
		jobs > dirtyhack
done
jobs > dirtyhack
while [ `wc -l dirtyhack | tr -s " " | cut -f 2 -d " "` -ne 0 ]; do
	sleep 5
	jobs > dirtyhack
done
