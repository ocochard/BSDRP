#!/bin/sh
#
# Continuous Integration QEMU test script for BSDRP
# This script tests BSDRP images by booting them in QEMU and verifying successful startup

set -euf

PROJECT=TESTING
ARCH=amd64

# Error handling function - prints error message to stderr and exits
# Arguments:
#   $*: Error message to display
# Returns: exits with code 1
die()
{
	echo "$*" 1>&2
	exit 1
}

# And, boot in QEMU.
: ${BOOTLOG:=${TMPDIR:-/tmp}/ci-qemu-test-boot.log}
IMG=$(ls workdir/${PROJECT}.${ARCH}/ | grep 'full-amd64-serial.img$')
if [ -z ${IMG} ]; then
	echo "DEBUG:"
	ls workdir/${PROJECT}.${ARCH}/
	die "No IMG found"
fi

MD=$(mdconfig -a -t vnode -f workdir/${PROJECT}.${ARCH}/${IMG})
TMP=$(mktemp -d)
mount /dev/${MD}s3 ${TMP}
cat > ${TMP}/rc.conf.local <<EOF
#!/bin/sh

echo "Hello world."
/sbin/shutdown -p now
EOF
umount ${TMP}
rm -r ${TMP}
mdconfig -du ${MD}
set +e
timeout 300 \
	qemu-system-x86_64 -m 512M -nodefaults \
	-serial stdio -vga none -nographic -monitor none \
	-snapshot -hda workdir/${PROJECT}.${ARCH}/${IMG} 2>&1 | tee ${BOOTLOG}
set -e

# Check whether we succesfully booted...
if grep -q 'Hello world' ${BOOTLOG}; then
	echo "OK"
else
	die "Did not boot successfully, see ${BOOTLOG}"
	if [ -r ${BOOTLOG} ]; then
		echo "Displaying qemu boot log"
		cat ${BOOTLOG}
	fi
fi
