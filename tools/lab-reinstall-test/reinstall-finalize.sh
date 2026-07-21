#!/bin/sh
# reinstall-finalize.sh
#
# Runs AFTER an external `dd if=fresh-image of=/dev/DISK` has been
# streamed to the (now-idle) boot disk while the system was running
# on the RAM disk created by reinstall-prepare.sh.
#
# Restores the preserved /cfg contents onto the new gpt/cfg partition
# and reboots.

set -eu

[ "$(id -u)" = "0" ] || { echo "must run as root"; exit 1; }

CFG_BACKUP=/root/cfg-backup.tar.gz
[ -f "${CFG_BACKUP}" ] || { echo "no ${CFG_BACKUP} on RAM disk — nothing to restore"; }

# Locate the fresh gpt/cfg partition. Both the label name and its underlying
# device may differ (vtbd0p5 in bhyve, ada0p5 on real hw). Prefer the label.
CFG_DEV=""
for d in /dev/gpt/cfg /dev/label/cfg /dev/ufs/cfg; do
    [ -c "$d" ] && { CFG_DEV="$d"; break; }
done
[ -n "${CFG_DEV}" ] || { echo "cannot find fresh gpt/cfg partition"; exit 1; }
echo "==> Restoring /cfg onto ${CFG_DEV}"

MNT=/tmp/newcfg
/bin/mkdir -p "${MNT}"
/sbin/mount "${CFG_DEV}" "${MNT}" || { echo "mount ${CFG_DEV} failed"; exit 1; }

if [ -f "${CFG_BACKUP}" ]; then
    /usr/bin/tar -xzf "${CFG_BACKUP}" -C "${MNT}"
    # /cfg/fstab is disk-layout-specific; a legacy MBR-nanobsd system
    # will have /dev/ufs/BSDRPsN paths that break on the new GPT
    # install. Drop it so the fresh install's own /conf/base/etc/fstab
    # is used at boot.
    if [ -f "${MNT}/fstab" ]; then
        /bin/rm -f "${MNT}/fstab"
        echo "==> removed stale ${MNT}/fstab (fresh install will use its own)"
    fi
    echo "==> Restored ${CFG_DEV}"
fi

/sbin/umount "${MNT}"
/bin/rmdir "${MNT}" 2>/dev/null || true

# Best-effort GPT backup fix (some RAM-boot minimal envs don't have
# gpart recover; the fresh boot's own gpart handles it either way).
BOOT_DEV=${CFG_DEV##*/}                       # 'vtbd0p5' or 'gpt/cfg'
BOOT_DISK=${BOOT_DEV%%p[0-9]*}                # 'vtbd0'
if [ -c /dev/${BOOT_DISK} ]; then
    /sbin/gpart recover /dev/${BOOT_DISK} 2>&1 ||         echo "note: gpart recover unavailable on RAM disk; skipping"
fi

echo "==> Rebooting into fresh install"
/bin/sync
/sbin/reboot
