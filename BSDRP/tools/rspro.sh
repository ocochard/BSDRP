#!/bin/sh
#
# Build script for booting RouterStation Pro with TFTP and / on NFS
# Based on Adrian Chadd' scripts (New BSD license):
# http://code.google.com/p/freebsd-wifi-build/

set -eu
# Image type can be:
# MFS: Boot from TFTP a unique file that contain kernel+root fs in RAM
# NFS: Boot from TFTP a kernel, that try to mount the root fs with NFS
# USB: Prepare a kernel (to be burn as new firmware) that will use a Root fs on USB
# FIRMWARE: Generate a firmware to be installed on the device
IMAGE_TYPE="MFS"

# User modifiable variables
RSPRO_BASE_DIR="/rspro_${IMAGE_TYPE}"

# MFS/NFS only:

NFS_SRV_IP="192.168.100.2"
RSPRO_MAC="00:15:6d:c8:82:75"
RSPRO_IP="192.168.100.49"

# Script variables
SRCROOT="/usr/src"
MAKEOBJDIRPREFIX="${RSPRO_BASE_DIR}/obj"
MAKE_JOBS=$(( 2 * $(sysctl -n kern.smp.cpus) + 1 ))
BOARD="AR71XX"
TARGET="mips"
export SRCROOT
export MAKEOBJDIRPREFIX
NFSROOT=${RSPRO_BASE_DIR}/nfsroot
TFTPBOOT=${RSPRO_BASE_DIR}/tftpboot

if [ ! -d ${RSPRO_BASE_DIR} ]; then 
	mkdir -p ${NFSROOT}
	mkdir ${TFTPBOOT}
	mkdir ${MAKEOBJDIRPREFIX}
fi

MAKEFLAGS_FULL="TARGET=${TARGET}	\
		TARGET_ARCH=mipseb	\
		TARGET_CPUTYPE=mips32	\
		-j ${MAKE_JOBS} NO_CLEAN=1 	\
		CROSS_BUILD_TESTING=YES	\
		__MAKE_CONF=/dev/null \
		SRCCONF=/dev/null"

MAKEFLAGS_SMALL="TARGET=mips	\
		TARGET_ARCH=mipseb	\
		TARGET_CPUTYPE=mips32	\
		-j ${MAKE_JOBS} NO_CLEAN=1 	\
		CROSS_BUILD_TESTING=YES	\
		__MAKE_CONF=/dev/null \
		SRCCONF=/dev/null \
        -DWITHOUT_ACCT	\
		-DWITHOUT_ACPI \
		-DWITHOUT_AMD \
        -DWITHOUT_APM	\
        -DWITHOUT_ASSERT_DEBUG	\
        -DWITHOUT_ATM	\
        -DWITHOUT_AUDIT	\
        -DWITHOUT_AUTHPF	\
        -DWITHOUT_BIND	\
        -DWITHOUT_BIND_DNSSEC	\
        -DWITHOUT_BIND_ETC	\
        -DWITHOUT_BIND_LIBS_LWRES	\
        -DWITHOUT_BIND_MTREE	\
        -DWITHOUT_BIND_NAMED	\
        -DWITHOUT_BIND_UTILS	\
        -DWITHOUT_BLUETOOTH	\
        -DWITHOUT_BSNMP	\
        -DWITHOUT_CALENDAR	\
        -DWITHOUT_CTM	\
        -DWITHOUT_CVS	\
        -DWITHOUT_DICT	\
        -DWITHOUT_EXAMPLES	\
        -DWITHOUT_FLOPPY	\
		-DWITHOUT_FORTH	\
        -DWITHOUT_FREEBSD_UPDATE	\
        -DWITHOUT_GAMES	\
        -DWITHOUT_GCOV	\
        -DWITHOUT_GDB	\
        -DWITHOUT_GPIB	\
		-DWITHOUT_GROFF \
        -DWITHOUT_HTML	\
		-DWITHOUT_INFO	\
        -DWITHOUT_IPFILTER	\
		-DWITHOUT_IPFW	\
        -DWITHOUT_IPX	\
        -DWITHOUT_IPX_SUPPORT	\
        -DWITHOUT_JAIL	\
        -DWITHOUT_KERBEROS	\
        -DWITHOUT_KERBEROS_SUPPORT	\
        -DWITHOUT_LEGACY_CONSOLE	\
        -DWITHOUT_LIB32	\
        -DWITHOUT_LOCALES	\
        -DWITHOUT_LOCATE	\
        -DWITHOUT_LPR	\
		-DWITHOUT_MAIL \
		-DWITHOUT_MAILWRAPPER	\
        -DWITHOUT_MAN	\
        -DWITHOUT_MAN_UTILS	\
        -DWITHOUT_NCP	\
        -DWITHOUT_NDIS	\
		-DWITHOUT_NETGRAPH_SUPPORT	\
		-DWITHOUT_NETGRAPH	\
        -DWITHOUT_NETCAT	\
        -DWITHOUT_NIS	\
        -DWITHOUT_NLS	\
        -DWITHOUT_NLS_CATALOGS	\
        -DWITHOUT_NS_CACHING	\
		-DWITHOUT_PAM	\
		-DWITHOUT_PAM_SUPPORT	\
		-DWITHOUT_PKGTOOLS	\
		-DWITHOUT_PMC	\
        -DWITHOUT_PORTSNAP	\
        -DWITHOUT_PROFILE	\
        -DWITHOUT_QUOTAS	\
        -DWITHOUT_RCMDS	\
		-DWITHOUT_RCS	\
        -DWITHOUT_RESCUE	\
        -DWITHOUT_ROUTED	\
        -DWITHOUT_SENDMAIL	\
        -DWITHOUT_SHAREDOCS	\
        -DWITHOUT_SSP	\
		-DWITHOUT_SYSCONS	\
        -DWITHOUT_SYSINSTALL	\
        -DWITHOUT_WIRELESS	\
        -DWITHOUT_WIRELESS_SUPPORT	\
        -DWITHOUT_WPA_SUPPLICANT_EAPOL	\
        -DWITHOUT_ZFS"

INSTALLFLAGS_SMALL="-DWITHOUT_CLANG \
		-DWITHOUT_CPP \
		-DWITHOUT_CXX \
		-DWITHOUT_GCC \
		-DWITHOUT_KERNEL_SYMBOLS \
		-DWITHOUT_SYSCONS \
		-DWITHOUT_TOOLCHAIN"

case "${IMAGE_TYPE}" in
		"MFS")
			MAKEFLAGS=${MAKEFLAGS_SMALL}
			INSTALLFLAGS=${INSTALLFLAGS_SMALL}
			;;
		"NFS")
			MAKEFLAGS=${MAKEFLAGS_FULL}
			INSTALLFLAGS=""
			;;
		"USB")
            MAKEFLAGS=${MAKEFLAGS_FULL}
            INSTALLFLAGS=""
            ;;
		"FIRMWARE")
			MAKEFLAGS=${MAKEFLAGS_SMALL}
			INSTALLFLAGS=${INSTALLFLAGS_SMALL}
			;;
		*)
			echo "Not a valid image type"
			exit 1
	esac

patch_kernel () {
	echo "TO DO: patching kernel with the SD drivers fix"	
}

buildworld () {
	echo "Build world"
	cd ${SRCROOT}
	make ${MAKEFLAGS} -j2 NO_CLEAN=1 __MAKE_CONF=/dev/null SRCCONF=/dev/null buildworld
}

kernel_config () {
	echo "Kernel configuration"
	cd ${SRCROOT}/sys/${TARGET}/conf/
	cp ${BOARD} ${BOARD}.${IMAGE_TYPE}
	#Remove debug feature
	sed -i "" '/DEBUG=-g/d' ${BOARD}.${IMAGE_TYPE}
	sed -i "" '/DDB/d' ${BOARD}.${IMAGE_TYPE}
	sed -i "" '/KDB/d' ${BOARD}.${IMAGE_TYPE}
	sed -i "" '/DEADLKRES/d' ${BOARD}.${IMAGE_TYPE}
	sed -i "" '/INVARIANT/d' ${BOARD}.${IMAGE_TYPE}
	sed -i "" '/WITNESS/d' ${BOARD}.${IMAGE_TYPE}
	#Remove ROOTDEVNAME, will be set later
	sed -i "" '/ROOTDEVNAME/d' ${BOARD}.${IMAGE_TYPE}
	#Add Redboot and geom UZIP modules
	# GEOM modules
	echo "device	geom_redboot" >> ${BOARD}.${IMAGE_TYPE}
	echo "device	geom_uzip" >> ${BOARD}.${IMAGE_TYPE}
	echo "options	GEOM_UZIP" >> ${BOARD}.${IMAGE_TYPE}
	case "${IMAGE_TYPE}" in
		"MFS")
			sed -i "" '/BOOTP/d' ${BOARD}.${IMAGE_TYPE}
			sed -i "" '/NFS_ROOT/d' ${BOARD}.${IMAGE_TYPE}
			#options         ROOTDEVNAME=\"ufs:redboot/rootfs.uzip\"
			echo "options	ROOTDEVNAME=\\\"ufs:md0.uzip\\\"" >> ${BOARD}.${IMAGE_TYPE}
			echo "options	MD_ROOT" >> ${BOARD}.${IMAGE_TYPE}
			echo "#number of kilobytes reserved for the root filesystem" >> ${BOARD}.${IMAGE_TYPE}
			echo "options	MD_ROOT_SIZE=\"13312\"" >> ${BOARD}.${IMAGE_TYPE}
			echo "makeoptions	MODULES_OVERRIDE=\"\"" >> ${BOARD}.${IMAGE_TYPE} 
			;;
		"NFS")
			echo "options	ROOTDEVNAME=\\\"nfs:${NFS_SRV_IP}:${NFSROOT}\\\""  >> ${BOARD}.${IMAGE_TYPE}
			;;
		"USB")
            echo "options   ROOTDEVNAME=\\\"ufs:da0s1a\\\""  >> ${BOARD}.${IMAGE_TYPE}
            ;;
		"FIRMWARE")
			sed -i "" '/BOOTP/d' ${BOARD}.${IMAGE_TYPE}
			sed -i "" '/NFS_ROOT/d' ${BOARD}.${IMAGE_TYPE}
			echo "options	ROOTDEVNAME=\\\"ufs:redboot/rootfs.uzip\\\"" >> ${BOARD}.${IMAGE_TYPE}
			echo "makeoptions	MODULES_OVERRIDE=\"\"" >> ${BOARD}.${IMAGE_TYPE}
			;;
		*)
			echo "Not a valid image type"
			exit 1
	esac
}

buildkernel () {
	echo "Build kernel"
	cd ${SRCROOT}
	make ${MAKEFLAGS} KERNCONF="${BOARD}.${IMAGE_TYPE}" buildkernel
}

installworld () {
	echo "Install world"
	if [ -f ${TFTPBOOT}/kernel.empty ]; then
        rm ${TFTPBOOT}/kernel.empty
    fi

	cd ${SRCROOT}
	make DESTDIR=${NFSROOT} KERNCONF="${BOARD}.${IMAGE_TYPE}" ${MAKEFLAGS} ${INSTALLFLAGS} installkernel
	make DESTDIR=${NFSROOT} ${MAKEFLAGS} ${INSTALLFLAGS} installworld
	make DESTDIR=${NFSROOT} ${MAKEFLAGS} ${INSTALLFLAGS} distribution
	mv ${NFSROOT}/boot/kernel/kernel ${TFTPBOOT}
}

align_kernel () {
	echo "Zip and align the kernel"
	# Gzip and align the kernel
	cat ${TFTPBOOT}kernel | gzip -9 | dd if=/dev/stdin of=${TFTPBOOT}/${BOARD}.${IMAGE_TYPE}.kernel.gz bs=64k conv=sync
	rm ${NFSROOT}/boot/kernel/kernel
}

reduce_world () {
	echo "Reduce world"
	# Kill all .a's that are installed with TOOLCHAIN
    find ${NFSROOT} -name \*.a | xargs rm

}

tftpd_tftpd () {
	TFTP="tftp	dgram	udp wait	root	/usr/libexec/tftpd	tftpd -l -s ${TFTPBOOT}"
	if ! grep -q ${TFTP} /etc/inetd.conf; then
		echo "${TFTP}" >> /etc/inetd.conf
	fi
	/etc/rc.d/inetd onerestart
}

patch_rootfs_mfs () {
	echo "*** Customizing root filesystem for MFS use"
	echo "md0.uzip	/	ufs	ro	0	0" > ${NFSROOT}/etc/fstab
	touch ${NFSROOT}/etc/diskless
	echo "root_rw_mount=NO" >> ${NFSROOT}/etc/defaults/rc.conf
	cat <<EOF > ${NFSROOT}/etc/rc.conf
hostname="rspro.bsdrp.net"
#Prevent to update motd
update_motd=NO
#No keymap
keymap="NO"
#No blanktime (suppress blanktimevidcontrol not found message)
blanktime="NO"
#Disable sendmail
sendmail_enable="NONE"
EOF
	if [ ! -f ${NFSROOT}/etc/make.conf ]; then
		echo 'TARGET_BIG_ENDIAN=true' >> ${NFSROOT}/etc/make.conf
		echo 'WITHOUT_X11=yes' >> ${NFSROOT}/etc/make.conf
	fi
}

make_mfs () {
	echo "*** Running makefs to build compressed image .. "
	# The size of the -s option is found with a simple "du"
	makefs -t ffs -B be -o version=1,bsize=4096,fsize=512 -s 43261952 -f 1000 ${RSPRO_BASE_DIR}/rspro.rootfs ${NFSROOT} || exit 1

	echo "*** Running mkuzip to create a compressed filesystem .. "
	mkuzip -s 16384 ${RSPRO_BASE_DIR}/rspro.rootfs || exit 1
}

get_mfs_size()
{
    kernel=$1
    set 0 0 # reset variables
    # $1 takes the offset of the MFS filesystem
    set `strings -at d $kernel | grep "MFS Filesystem goes here"`
    mfs_start=$1
    set 0 0 # reset variables
    set `strings -at d $kernel | grep "MFS Filesystem had better"`
    mfs_end=$1
    mfs_size="$((${mfs_end} - ${mfs_start}))"
    mfs_ofs=$((${mfs_start}))
    echo "start: $mfs_start ; end: $mfs_end; size: $mfs_size"
    echo "offset for mfs in kernel: $mfs_ofs"
}

include_mfs2kernel () {
	echo "Include the MFS root file into the kernel"
	# get the kernel MFS size
	# this sets mfs_ofs, mfs_end, mfs_start, mfs_size
	if [ -f ${TFTPBOOT}/kernel.empty ]; then
		get_mfs_size ${TFTPBOOT}/kernel.empty
	else
		get_mfs_size ${TFTPBOOT}/kernel
		cp ${TFTPBOOT}/kernel ${TFTPBOOT}/kernel.empty
	fi
	# add it to the kernel
	echo "*** copying the mfsroot into the kernel image"
	dd if=${RSPRO_BASE_DIR}/rspro.rootfs.uzip ibs=8192 iseek=0 of=${TFTPBOOT}/kernel obs=${mfs_ofs} oseek=1 conv=notrunc
}

nfsd_config () {
	NFS="${NFSROOT} -maproot=root ${CLIENT_IP}"
	if ! grep -q ${NFS} /etc/exports; then
		echo "${NFS}" >> /etc/exports
	fi
	/etc/rc.d/nfsd onerestart
	echo "TO DO, need to test the showmount -e output"
	showmount -e	
}


dhcpd_config () {
	# Need to calucale all IP givens
	echo "DHCP configuration"
	echo "Edit your /usr/local/etc/dhcpd.conf"
	echo "And use this example:"
		cat <<EOF
#DHCPd configuration file for RouterStation Pro
option root-path "${NFS_SRV_IP}:${NFSROOT}";
subnet 192.168.100.0 netmask 255.255.255.0 {
	range 192.168.100.48 192.168.100.50;
	option domain-name-servers 8.8.8.8, 4.4.4.4;
	option routers 192.168.100.254;
	option broadcast-address 192.168.100.255;
	default-lease-time 600;
	max-lease-time 7200;
}
host client1 {
   hardware ethernet ${RSPRO_MAC}; #mac address of the RSPRO board
   fixed-address ${RSPRO_IP};
}
EOF
}

#patch_kernel
kernel_config
buildworld
buildkernel
installworld
reduce_world
patch_rootfs_mfs
make_mfs
include_mfs2kernel
#zip_align_kernel
#tftpd_config
#nfsd_config
#dhcpd_config
echo "Boot RouterStation Pro, and hit Ctrl+C during boot sequence"
echo "Then enter:"
echo "ip -h ${NFS_SRV_IP} -l ${RSPRO_IP}"
echo "And for TFTP downloading a gzipped kernel:"
echo "load -d kernel.gz"
echo "Or for TFTP downloading a kernel (including MFS):"
echo "load kernel"
echo "Then, start the downloaded kernel:"
echo "exec"

