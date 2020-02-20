#!/bin/sh

# Testing BSDRP with qemu

set -euf

die()
{
	echo "$*" 1>&2
	exit 1
}

# And, boot in QEMU.
: ${BOOTLOG:=${TMPDIR:-/tmp}/ci-qemu-test-boot.log}
IMG=$(ls workdir/BSDRP.amd64/ | grep 'full-amd64-serial.img$')
if [ -z ${IMG} ]; then
	echo "DEBUG:"
	ls workdir/BSDRP.amd64/
	die "No IMG found"
fi

MD=$(mdconfig -a -t vnode -f workdir/BSDRP.amd64/${IMG})
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
timeout 300 \
	qemu-system-x86_64 -m 256M -nodefaults \
	-serial stdio -vga none -nographic -monitor none \
	-snapshot -hda workdir/BSDRP.amd64/${IMG} 2>&1 | tee ${BOOTLOG}

# Check whether we succesfully booted...
if grep -q 'Hello world' ${BOOTLOG}; then
	echo "OK"
else
	die "Did not boot successfully, see ${BOOTLOG}"
fi
