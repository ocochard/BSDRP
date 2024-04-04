#!/bin/sh
#
# poudriere cleanup phase is run at 'almost' the last stage
# (notice fstab is generated after)
# so overlaydir is already copied and packages installed

# cleanup phase (when the clean way fails)
# - Use WITHOUT_ in image-BSDRPj-src.conf
# - Excluding files from package to be installed (in pkg.conf)
# in place of having to cleanup here

# Not all WITHOUT_ options are correctly applied during image generation
# - Some /usr/include are still here
# - some ports aren't happy with excluding /usr/local/include (net-snmp)

# XXX Need to build /usr/src/tools/tools/netrate/netblast&netreceive

# If port related, it is recommanded to add list of file in the pkg.conf file
# That will avoid installing files during packages installation
# About pkg-static: https://github.com/freebsd/pkg/issues/2190
TO_REMOVE='
usr/local/sbin/pkg-static
usr/include
usr/local/include
'

if [ -z "${WORLDDIR}" ]; then
	echo "ERROR: Empty variable WORLDDIR"
	exit 1
fi

for i in ${TO_REMOVE}; do
	if [ -e ${WORLDDIR}/$i ]; then
		rm -rf ${WORLDDIR}/$i
	fi
done

# System customization
# Imported from the nanobsd bsdrp_custom ()
# Mainly renaming NANO_WORLDDIR by WORLDDIR

# boot.config used by boot(8) and uefi(8)
# -D : boot with the dual console configuration
# Disabled: Could generate multiple errors messages on screen
# echo "-D" > ${WORLDDIR}/boot.config

# Replace BSDRP_VERSION in /boot/lua/brand-bsdrp.lua with the version number in etc/version
sed -i "" -e /BSDRP_VERSION/s//$(cat ${WORLDDIR}/etc/version)/ ${WORLDDIR}/boot/lua/brand-bsdrp.lua

# SSH:
# - Allow root (the only user by default)
# - Disable reverse DNS
(
	echo "UseDNS no"
	echo "PermitRootLogin yes"
) >> ${WORLDDIR}/etc/ssh/sshd_config

# Disable system beep and enable color with csh
(
  echo "set nobeep"
  echo "setenv CLICOLOR true"
) >> ${WORLDDIR}/etc/csh.cshrc
# cpio (cust_install_file) doesn't support symlink
# relocate /root/.ssh to /etc/dot.root.ssh
# This permit to save ssh keys
mkdir -p ${WORLDDIR}/etc/dot.ssh.root
ln -s ../etc/dot.ssh.root ${WORLDDIR}/root/.ssh
# relocate /root/.* to /etc/dot.*
ln -s ../etc/dot.vimrc ${WORLDDIR}/root/.vimrc
rm ${WORLDDIR}/root/.shrc
ln -s ../etc/dot.shrc ${WORLDDIR}/root/.shrc
ln -s ../etc/dot.complete ${WORLDDIR}/root/.complete
rm ${WORLDDIR}/root/.cshrc
ln -s ../etc/dot.cshrc ${WORLDDIR}/root/.cshrc

# Add fdesc (mandatory to use bash) and procfs to fstab
(
	echo "fdesc   /dev/fd         fdescfs         rw      0       0"
	echo "proc    /proc           procfs          rw      0       0"
) >> ${WORLDDIR}/etc/fstab

# relocate /var/cron to /etc/cron
# This permit to save crontab (only /etc and /usr/local/etc are saved)
mkdir -p ${WORLDDIR}/etc/cron
rm -rf ${WORLDDIR}/var/cron
ln -s ../etc/cron ${WORLDDIR}/var/cron

