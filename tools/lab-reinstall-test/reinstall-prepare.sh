#!/bin/sh
# reinstall-prepare.sh [--commit]
#
# Build a RAM rootfs; when --commit is passed, call reboot -r to switch onto
# it. Without --commit, the RAM disk stays mounted at /tmp/newroot for
# inspection (nothing destructive happens).

set -eu

COMMIT=false
[ "${1:-}" = "--commit" ] && COMMIT=true

MD_UNIT=42
MD_SIZE_MB=512
NEW_ROOT=/tmp/newroot

[ "$(id -u)" = "0" ] || { echo "must run as root"; exit 1; }
mount | grep -q " on / .*ufs" || { echo "root not ufs"; exit 1; }

# Detect boot disk by tracing root mount back through GEOM
ROOT_PROVIDER=$(mount | awk '$3 == "/" {print $1}' | sed 's|^/dev/||')
UNDERLYING=$(glabel status | awk -v l="${ROOT_PROVIDER}" '$1 == l {print $3}')
[ -z "${UNDERLYING}" ] && UNDERLYING="${ROOT_PROVIDER}"
CURDISK=$(echo "${UNDERLYING}" | sed -E 's|p[0-9]+$||; s|s[0-9]+a?$||')
[ -n "${CURDISK}" ] || { echo "cannot detect boot disk"; exit 1; }
echo "==> boot disk: /dev/${CURDISK}"

# Detect primary network iface (the one holding the default route)
LIVE_IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
[ -z "${LIVE_IFACE}" ] && LIVE_IFACE=$(ifconfig -l | tr ' ' '\n' | grep -E '^(vt|em|igb|ix)' | head -1)
LIVE_IFCONFIG=$(ifconfig ${LIVE_IFACE} 2>/dev/null | awk '/inet / {printf "inet %s netmask %s", $2, $4; exit}')
# Capture the default gateway so we can restore it after ifconfig on the
# RAM boot. Without this, a client behind a router loses SSH after reroot.
# Empty when no default route exists (L2-adjacent client) — the RAM rc
# handles both cases.
LIVE_DEFAULT_GW=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')
echo "==> primary iface: ${LIVE_IFACE} (${LIVE_IFCONFIG})"
[ -n "${LIVE_DEFAULT_GW}" ] && echo "==> default gw: ${LIVE_DEFAULT_GW}"

# Create RAM disk
if [ -e /dev/md${MD_UNIT} ]; then
    umount /dev/md${MD_UNIT} 2>/dev/null || true
    mdconfig -d -u ${MD_UNIT} 2>/dev/null || true
fi
echo "==> creating md${MD_UNIT} (${MD_SIZE_MB} MB)"
mdconfig -a -t malloc -s ${MD_SIZE_MB}m -u ${MD_UNIT}
newfs -L RAMROOT -U /dev/md${MD_UNIT} >/dev/null
mkdir -p ${NEW_ROOT}
mount /dev/md${MD_UNIT} ${NEW_ROOT}

# Copy /rescue and set up minimum FreeBSD tree
echo "==> populating ${NEW_ROOT}"
mkdir -p ${NEW_ROOT}/bin ${NEW_ROOT}/sbin ${NEW_ROOT}/lib ${NEW_ROOT}/libexec \
         ${NEW_ROOT}/usr/bin ${NEW_ROOT}/usr/sbin ${NEW_ROOT}/usr/lib \
         ${NEW_ROOT}/etc ${NEW_ROOT}/etc/ssh ${NEW_ROOT}/etc/pam.d \
         ${NEW_ROOT}/dev ${NEW_ROOT}/tmp ${NEW_ROOT}/var/log ${NEW_ROOT}/var/run \
         ${NEW_ROOT}/var/empty ${NEW_ROOT}/root/.ssh ${NEW_ROOT}/proc
chmod 1777 ${NEW_ROOT}/tmp
chmod 555 ${NEW_ROOT}/var/empty
chmod 700 ${NEW_ROOT}/root/.ssh

# Copy binaries + their shared libraries. /rescue is absent on BSDRP
# (WITHOUT_RESCUE) so we cherry-pick what we need from the live system.
copy_with_libs () {
    src=$1
    [ -f "${src}" ] || { echo "MISSING: ${src}"; return; }
    dst=${NEW_ROOT}${src}
    mkdir -p "$(dirname ${dst})"
    cp -p "${src}" "${dst}"
    ldd -f "%p\n" "${src}" 2>/dev/null | sort -u | while read lib; do
        [ -f "${lib}" ] || continue
        dlib="${NEW_ROOT}${lib}"
        [ -f "${dlib}" ] && continue
        mkdir -p "$(dirname ${dlib})"
        cp -p "${lib}" "${dlib}"
    done
}
for f in /sbin/init /bin/sh /sbin/mount /sbin/umount /sbin/reboot \
         /sbin/mdconfig /sbin/ifconfig /sbin/route /sbin/newfs \
         /sbin/sysctl /sbin/dhclient /bin/dd /bin/ls /bin/cat /bin/cp \
         /bin/mkdir /bin/rm /bin/chmod /bin/ln /bin/sleep /bin/sync \
         /bin/kill /bin/ps /bin/echo /bin/date /bin/hostname /bin/pwd \
         /usr/bin/head /usr/bin/tail /usr/bin/id /usr/bin/tr /usr/bin/grep \
         /usr/bin/awk /usr/bin/sed /usr/bin/tee /usr/bin/find /usr/bin/killall \
         /usr/sbin/sshd /usr/libexec/sshd-session /usr/libexec/sshd-auth \
         /usr/sbin/sockstat /usr/sbin/chown /usr/bin/tar /usr/bin/gzip \
         /usr/bin/uname /sbin/gpart /sbin/dumpon; do
    copy_with_libs "$f"
done
# Dynamic linker (referenced in ELF headers, ldd may miss it)
mkdir -p ${NEW_ROOT}/libexec
[ -f /libexec/ld-elf.so.1 ] && cp -p /libexec/ld-elf.so.1 ${NEW_ROOT}/libexec/

# System databases and configs sshd/PAM/nsswitch need
for f in /etc/nsswitch.conf /etc/master.passwd /etc/passwd /etc/pwd.db /etc/spwd.db \
         /etc/group /etc/login.conf /etc/login.conf.db /etc/hosts /etc/resolv.conf \
         /etc/services /etc/protocols /etc/shells /etc/localtime \
         /etc/ssh/sshd_config /etc/ssh/moduli \
         /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key.pub \
         /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub \
         /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key.pub; do
    [ -f "${f}" ] && { mkdir -p "${NEW_ROOT}$(dirname ${f})"; cp -p "${f}" "${NEW_ROOT}${f}"; }
done
# PAM configs sshd loads
for f in /etc/pam.d/sshd /etc/pam.d/system /etc/pam.d/other; do
    [ -f "${f}" ] && cp -p "${f}" "${NEW_ROOT}/etc/pam.d/"
done
# PAM libraries
for lib in /usr/lib/pam_*.so.6 /usr/lib/pam_*.so; do
    [ -f "${lib}" ] || continue
    dst=${NEW_ROOT}/usr/lib/$(basename ${lib})
    cp -p "${lib}" "${dst}"
done

# root's authorized_keys
for f in /root/.ssh/authorized_keys /etc/dot.ssh.root/authorized_keys; do
    if [ -f "${f}" ]; then
        cp -p "${f}" ${NEW_ROOT}/root/.ssh/authorized_keys
        break
    fi
done

# Preserve /cfg
if ! mount | grep -q " on /cfg "; then
    mount /cfg 2>/dev/null || true
fi
if mount | grep -q " on /cfg "; then
    tar -czf ${NEW_ROOT}/root/cfg-backup.tar.gz -C /cfg .
    umount /cfg || true
    echo "==> saved /cfg to ${NEW_ROOT}/root/cfg-backup.tar.gz"
fi

# fstab for RAM root
cat > ${NEW_ROOT}/etc/fstab <<FSTAB
/dev/md${MD_UNIT}  /       ufs   rw   1 1
proc               /proc   procfs rw  0 0
FSTAB

# rc.conf for RAM boot
cat > ${NEW_ROOT}/etc/rc.conf <<RCCONF
hostname="ramboot"
sshd_enable="YES"
ifconfig_${LIVE_IFACE}="${LIVE_IFCONFIG}"
RCCONF

# Minimal /etc/rc: init(8) runs this directly. Cannot rely on system rc.d.
cat > ${NEW_ROOT}/etc/rc <<RCEOF
#!/bin/sh
# Redirect stdout+err to console for the whole rc.
exec >/dev/console 2>&1
echo "MARK 1: rc entered, pwd=\$(pwd)"
echo "MARK 2: mounting devfs"; /sbin/mount -t devfs devfs /dev
echo "MARK 3: mounting tmpfs /var/run"; /sbin/mount -t tmpfs tmpfs /var/run
echo "MARK 4: mounting tmpfs /tmp"; /sbin/mount -t tmpfs tmpfs /tmp
echo "MARK 5: bringing up lo0"
/sbin/ifconfig lo0 inet 127.0.0.1/8 up
echo "MARK 6: bringing up ${LIVE_IFACE}"
/sbin/ifconfig ${LIVE_IFACE} ${LIVE_IFCONFIG}
/sbin/ifconfig ${LIVE_IFACE} | head -5
# Restore default route if the pre-reroot system had one. Empty
# LIVE_DEFAULT_GW is fine — clients on the same L2 don't need it.
if [ -n "${LIVE_DEFAULT_GW}" ]; then
    echo "MARK 6b: adding default route via ${LIVE_DEFAULT_GW}"
    /sbin/route add default ${LIVE_DEFAULT_GW} 2>&1
fi
echo "MARK 7: starting sshd"
/usr/sbin/sshd -e
echo "MARK 8: sshd exit code \$?"
# Wait a moment then verify sshd
/bin/sleep 2
/bin/ps ax 2>&1 | grep -v grep | grep sshd || echo "MARK 8b: sshd NOT in process list"
/usr/sbin/sockstat -l 2>&1 | grep :22 || echo "MARK 8c: no listener on :22"
echo "MARK 9: rc reached idle loop"
while :; do
    /bin/sleep 60
    echo "HEARTBEAT rc alive"
done
RCEOF
chmod 755 ${NEW_ROOT}/etc/rc

# Sanity
[ -x ${NEW_ROOT}/sbin/init ] || { echo "FAIL: /sbin/init missing"; exit 1; }
[ -f ${NEW_ROOT}/usr/sbin/sshd ] || { echo "FAIL: sshd missing"; exit 1; }
[ -f ${NEW_ROOT}/etc/rc ] || { echo "FAIL: /etc/rc missing"; exit 1; }
[ -f ${NEW_ROOT}/root/.ssh/authorized_keys ] || echo "WARN: no authorized_keys"

echo "==> RAM rootfs ready at ${NEW_ROOT}"
echo "==> size: $(du -sh ${NEW_ROOT} | awk '{print $1}')"

if ! ${COMMIT}; then
    echo ""
    echo "==> Dry run complete. Inspect ${NEW_ROOT}."
    echo "==> To commit and reroot: re-run with --commit"
    exit 0
fi

# Commit path: kenv + reboot -r
sync
umount ${NEW_ROOT}
kenv vfs.root.mountfrom="ufs:/dev/md${MD_UNIT}"
echo "==> Calling reboot -r"
sleep 1
exec reboot -r
