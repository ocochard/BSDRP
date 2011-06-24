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


### TODO ###
# Add multithread feature

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

# usage: Display command line help
usage () {
	echo "$0 -h -c commands_list_file -l device_list_file -e extra_ssh_option"
	echo "  -c commands_list_file : Text file that contains list of commands to be send to remote device"
	echo "  -l device_list_file : Text file that contains list of device hostname or IP addresses"
	echo "  -x extra option: for adding one SSH command line option (like -p for changing default port)"
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

for DEVICE in `cat ${DEVICES_LIST_FILE}`; do
	echo "Sending commands to ${DEVICE}..."
	if empty -f -i ${DEVICE}.input -o ${DEVICE}.output -p ${DEVICE}.pid -L ${DEVICE}.log ssh ${SSH_OPTION} ${LOGIN}@${DEVICE}; then
		# WARNING: Security problem here, because PASSWORD is visible in the output of ps (need to use idea from empty man page)
		set +e
		empty -w -i ${DEVICE}.output -o ${DEVICE}.input "no)?" "yes\n" "assword:" "${PASSWORD}\n"
		RETURN_CODE=$?
		# If first value returned, need to enter the password new
		if [ ${RETURN_CODE} -eq 1 ]; then
			empty -w -i ${DEVICE}.output -o ${DEVICE}.input "assword:" "${PASSWORD}\n"
		elif [ ${RETURN_CODE} -ne 2 ]; then	
			echo "ERROR: Bad password"
			empty -k `cat ${DEVICE}.pid`
			exit
		fi
		for CMD in `cat ${COMMANDS_LIST_FILE}`; do
			empty -w -i ${DEVICE}.output -o ${DEVICE}.input "${DEVICE_PROMPT}" "${CMD}\n"
			RETURN_CODE=$?
			if [ ${RETURN_CODE} -ne 1 ]; then
				echo "ERROR: Can't send ${CMD} to ${DEVICE}"
            fi
		done
		if ! empty -k `cat ${DEVICE}.pid`; then
			echo "ERROR: Can't kill process for ${DEVICE}"
		fi
	else
		echo "ERROR: Can't open SSH to ${DEVICE}"
	fi
done
