#!/bin/sh
# Small script testing to boot image disk until login: prompt

set -eu

BSDRP_DIR="/usr/local/BSDRP/tools"
CR="/tmp/validate-images-status.txt"
[ -f ${CR} ] && rm ${CR}

# Error handling function - prints error message and exits
# Arguments:
#   $@: Error message to display
# Returns: exits with code 1
die() { echo -n "ERROR: " >&2; echo "$@" >&2; exit 1; }

# Run a virtual machine with specified image for testing
# Arguments:
#   $1: Path to the disk image file
# Returns: 0 on success
run_vm () {
	echo "stop BSDRP-bhyve lab..."
	${BSDRP_DIR}/BSDRP-lab-bhyve.sh -s
	${BSDRP_DIR}/BSDRP-lab-bhyve.sh -e -i $1
}

# Test if VM boots successfully by waiting for login prompt
# Arguments:
#   $1: Name/path of the image being tested
# Returns: 0 on success, logs results to status file
test_vm () {
	if /tmp/wait-for-login; then
		echo "Success: $1" >> ${CR}
	else
		echo "Failed: $1" >> ${CR}
	fi
}

# Stop and destroy the running virtual machine
# Arguments: none
# Returns: 0 on success
stop_vm () {
	${BSDRP_DIR}/BSDRP-lab-bhyve.sh -s
	${BSDRP_DIR}/BSDRP-lab-bhyve.sh -d
}
### main

[ $# -lt 1 ] && die "Missing directory as argument"

[ -f ${BSDRP_DIR}/BSDRP-lab-bhyve.sh ] || die "Can't found BSDRP-lab-bhyve.sh"
[ -f /usr/local/bin/expect ] || die "Can't found expect installed"

IMAGES_DIR=$1

if ! [ -d ${IMAGES_DIR} ]; then
	die "${IMAGES_DIR} is not a directory"
fi

cat <<EOF >/tmp/wait-for-login
#!/usr/local/bin/expect -f
set timeout 30
spawn cu -l /dev/nmdm1B

expect {
    "login:" { puts "Login detected"; exit 0}
    timeout { puts "Timeout"; exit 1 }
}
EOF
chmod +x /tmp/wait-for-login

echo "Testing to boot VM until to reach login prompt"
for IMAGE in $(ls -1 ${IMAGES_DIR}/BSDRP-* | egrep 'full.*\.img($|\.xz)'); do
	run_vm ${IMAGE}
	test_vm ${IMAGE}
	stop_vm
done
