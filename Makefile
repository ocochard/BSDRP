# BSD Router Project
# https://bsdrp.net

# Cf the help target at the end of the file for targets descriptions

###############################################################################
# Poudriere configurations files are in poudriere.etc/poudriere.d/
# - First build a "builder" jail (BSDRPj), which is a reduced FreeBSD but that
#   still needs to have compilers tools to build packages.
#   - List of WITHOUT in BSDRPj-src.conf
#   - Custom kernel configuration file (amd64 here)
# - Second, from this builder jail, we generate packages:
#   - ports list in BSDRP-pkglist
#   - ports options in BSDRPj-make.conf
# - Third, generate a nanobsd-like, uefi compliant firmware image
#   - No need of compiler tools, more WITHOUT_added in image-BSDRPj-src.conf
#   - But some unwanted files are still here, so adding list of them
#     in excluded.files
#   - Avoid extracting unwanted files from package using a pkg.conf
#     in BSDRP/Files/usr/local/etc/pkg.conf
#   - And a post customization script in post-script.sh that:
#     - Replace BSDRP_VERSION in boot menu
#     - Create some symlinks
#     - Customize fstab
#     - Generate mtree
###############################################################################

poudriere_basefs != grep '^BASEFS=' /usr/local/etc/poudriere.conf | cut -d '=' -f 2 || echo ""
.if empty(poudriere_basefs)
.error "Could not determine BASEFS from poudriere.conf"
.endif

poudriere_images_dir := ${poudriere_basefs}/data/images
poudriere_jail_dir := ${poudriere_basefs}/jails/BSDRPj

.if ${USER} != "root"
sudo ?= sudo
.else
sudo =
.endif

# Define the path to the variables file
# Here we assign ${.PARSEDIR} to ${SRC_DIR} in place of ${.CURDIR} to get the directory relative to the Makefile
# We will call this Makefile recursively (so executed from the object directory).
# XXXX But don't need to find the same solution about .OBJDIR (avoiding creating a sub .OBJDIR inside the existing .OBJDIR) ?
SRC_DIR := ${.PARSEDIR}
# Loading FreeBSD_* and ports_* variables
vars_file := ${SRC_DIR}/Makefile.vars
.if exists(${vars_file})
.include "${vars_file}"
.else
.error "Variables file '${vars_file}' not found."
.endif

# Load existing patches files (used to trigged targets if modified)
patches_dir := ${SRC_DIR}/BSDRP/patches
FreeBSD_patches != find $(patches_dir) -name 'freebsd.*.patch'
ports_patches != find $(patches_dir) -name 'ports.*.patch'
ports_shar != find $(patches_dir) -name 'ports.*.shar'
src_FreeBSD_dir := ${.OBJDIR}/FreeBSD
src_ports_dir := ${.OBJDIR}/ports
.for required in FreeBSD_patches ports_patches ports_shar
.if !defined(${required}) || empty(${required})
.error "No ${required:tl} files found in ${patches_dir}"
.endif
.endfor

# MACHINE_ARCH could be aarch64, but the source sys directory is arm64 :-(
src_arch = ${MACHINE_ARCH:S/aarch64/arm64/}
kernel = ${.OBJDIR}/FreeBSD/sys/${src_arch}/conf/${src_arch}

VERSION != cat ${SRC_DIR}/BSDRP/Files/etc/version
BSDRP_IMG_FULL = ${poudriere_images_dir}/BSDRP-${VERSION}-full-${MACHINE_ARCH}.img
BSDRP_IMG_UPGRADE = ${poudriere_images_dir}/BSDRP-${VERSION}-upgrade-${MACHINE_ARCH}.img
BSDRP_IMG_DEBUG = ${poudriere_images_dir}/BSDRP-${VERSION}-debug-${MACHINE_ARCH}.tar
BSDRP_IMG_MTREE = ${poudriere_images_dir}/BSDRP-${VERSION}-${MACHINE_ARCH}.mtree
IMAGES := ${BSDRP_IMG_FULL} ${BSDRP_IMG_UPGRADE} ${BSDRP_IMG_MTREE} ${BSDRP_IMG_DEBUG}
COMPRESSED_IMAGES := ${BSDRP_IMG_FULL}.xz ${BSDRP_IMG_UPGRADE}.xz ${BSDRP_IMG_MTREE}.xz ${BSDRP_IMG_DEBUG}.xz
CHECKSUM_IMAGES := ${COMPRESSED_IMAGES:%=%.sha256}

.PHONY: all check-requirements clean clean-all upstream-sync help

all: check-requirements ${IMAGES}

check-requirements:
	@which git > /dev/null || { echo "Error: git is not installed."; exit 1; }
	@which xz > /dev/null || { echo "Error: xz is not installed."; exit 1; }
	@which poudriere > /dev/null || { echo "Error: poudriere is not installed."; exit 1; }
.if ${USER} != "root"
	@which ${sudo} > /dev/null || { echo "Error: sudo is not installed."; exit 1; }
.endif
	@grep -q mtree /usr/local/share/poudriere/image.sh || { echo "Error: Need https://github.com/freebsd/poudriere/pull/1200"; exit 1; }
	@grep -q 'pmbr=' /usr/local/share/poudriere/image_firmware.sh || { echo "Error: Need https://github.com/freebsd/poudriere/pull/1205"; exit 1; }

# Sources management

${src_FreeBSD_dir}:
	@echo "Git clone FreeBSD..."
	@git clone -b ${FreeBSD_branch} --single-branch "${FreeBSD_repo}".git ${src_FreeBSD_dir}

${src_ports_dir}:
	@echo "Git clone FreeBSD ports tree..."
	@git clone -b ${ports_branch} --single-branch "${ports_repo}".git ${src_ports_dir}

.for repo in FreeBSD ports
cleanup-src-${repo}:
	@echo "==> Cleaning ${repo} sources..."
	@git -C ${src_${repo}_dir} checkout .
	@git -C ${src_${repo}_dir} clean -fd
	@rm -f patch-src-${repo}
	@rm -f patch-sources
	@touch ${.TARGET}

update-src-${repo}: ${vars_file} ${src_${repo}_dir}
	@rm -f ${.OBJDIR}/cleanup-src-${repo}
	@${MAKE} -f ${MAKEFILE} cleanup-src-${repo}
	@echo "==> Updating ${repo} at hash ${${repo}_hash}..."
	@git -C ${src_${repo}_dir} checkout ${${repo}_branch}
	@git -C ${src_${repo}_dir} pull
	@git -C ${src_${repo}_dir} checkout ${${repo}_hash}
	@echo "Git commit count:"
	@git -C ${src_${repo}_dir} rev-list HEAD --count
	@touch ${.TARGET}

patch-src-${repo}: update-src-${repo}
	# XXX Need to be replaced with a generic call (catch each patch mods)
	# in a for loop, allowing to patch only when changed
.if !defined(${repo}_patches) || empty(${repo}_patches)
	@echo "WARNING: No patches found for ${repo} in ${patches_dir}"
.else
	@echo "==> Applying ${repo} patches..."
	# All patches are in git diff format (so -p0)
	@for patch in ${${repo}_patches}; do \
		echo "Processing $${patch}..."; \
		patch -p0 -NE -d ${.OBJDIR}/${repo} -i $${patch} || exit 1; \
	done
.endif
	@touch ${.TARGET}

sync-${repo}: ${src_${repo}_dir}
	@rm -f ${.OBJDIR}/cleanup-src-${repo}
	@${MAKE} -f ${MAKEFILE} cleanup-src-${repo}
	@echo "Sync ${repo} sources with upstream..."
	@git -C ${src_${repo}_dir} pull
	@new_hash=$$(git -C ${src_${repo}_dir} rev-parse --short HEAD) && \
	sed -i '' "s/${repo}_hash?=.*/${repo}_hash?=$$new_hash/" ${vars_file} && \
	rm -f ${.OBJDIR}/patch-src-${repo} && \
	echo "Updating previous ${repo} hash ${${repo}_hash} to $${new_hash}"
.endfor # repo

patch-sources: patch-src-FreeBSD patch-src-ports add-src-ports ${kernel}
	@touch ${.TARGET}

add-src-ports: update-src-ports
.if !defined(ports_shar) || empty(ports_shar)
	@echo "WARNING: No ports_shar variable defined or empty, skipping ports addition"
.else
	# XXX Need to be replaced with a generic call (to be triggered for only shar files mods)
	@echo "Add extrat ports into FreeBSD port tree sources..."
	@for shar in ${ports_shar}; do \
		echo "Processing $${shar}..."; \
		(cd "${.OBJDIR}/ports" && sh $${shar} || exit 1); \
	done
.endif
	@touch ${.TARGET}

${kernel}: ${SRC_DIR}/BSDRP/kernels/${src_arch}
	@echo "Install kernel for arch ${MACHINE_ARCH} (${src_arch})"
	@cp ${SRC_DIR}/BSDRP/kernels/${src_arch} ${.OBJDIR}/FreeBSD/sys/${src_arch}/conf/

build-builder-jail: patch-sources ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.common
	@echo "Build the builder jail and kernel..."
	# All jail-src.conf need to end by MODULES_OVERRIDE section because this is arch dependends
	@cp ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.common ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf
	@if [ -f ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.${src_arch} ]; then \
		cat ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.${src_arch} >> ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf; \
	else \
		echo "" >> ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf; \
	fi
	@jail_action=$$(${sudo} poudriere -e ${SRC_DIR}/poudriere.etc jail -ln | grep -q BSDRPj && echo "u" || echo "c") && \
	${sudo} poudriere -e ${SRC_DIR}/poudriere.etc jail -$${jail_action} -j BSDRPj -b -m src=${.OBJDIR}/FreeBSD -K ${src_arch}
	@touch ${.TARGET}

build-ports-tree: patch-sources
	@ports_action=$$(${sudo} poudriere -e ${SRC_DIR}/poudriere.etc ports -ln | grep -q BSDRPp && echo "u" || echo "c") && \
	${sudo} poudriere -e ${SRC_DIR}/poudriere.etc ports -$${ports_action} -p BSDRPp -m null -M ${.OBJDIR}/ports
	@touch ${.TARGET}

build-packages: build-builder-jail build-ports-tree
	@echo "Build packages..."
	@cp ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.common ${.OBJDIR}/pkglist || exit 1
	@if [ -f ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${src_arch} ]; then \
		cat ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${src_arch} >> ${.OBJDIR}/pkglist || exit 1; \
	fi
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc bulk -j BSDRPj -p BSDRPp -f ${.OBJDIR}/pkglist || { \
		echo "Error: Package build failed"; \
		exit 1; \
	}
	@touch ${.TARGET}

${BSDRP_IMG_FULL} ${BSDRP_IMG_UPGRADE} ${BSDRP_IMG_MTREE} ${BSDRP_IMG_DEBUG}: build-packages
	@echo "Build image..."
	@${sudo} rm -f ${IMAGES} ${CHECKSUM_IMAGES} ${COMPRESSED_IMAGES}
	# Replace version in brand-bsdrp.lua
	@sed -i "" -e s"/BSDRP_VERSION/${VERSION}/" ${SRC_DIR}/BSDRP/Files/boot/lua/brand-bsdrp.lua
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc image -t firmware -s 4g \
		-j BSDRPj -p BSDRPp -n BSDRP -h router.bsdrp.net \
		-c ${SRC_DIR}/BSDRP/Files/ \
		-f ${.OBJDIR}/pkglist \
		-X ${SRC_DIR}/poudriere.etc/poudriere.d/excluded.files \
		-A ${SRC_DIR}/poudriere.etc/poudriere.d/post-script.sh
	# Restore brand-bsdrp.lua
	@git -C ${SRC_DIR}/BSDRP/Files/boot/lua checkout brand-bsdrp.lua
	@test -f ${poudriere_images_dir}/BSDRP.img || { echo "Error: ${poudriere_images_dir}/BSDRP.img was not created"; exit 1; }
	@${sudo} tar cf ${BSDRP_IMG_DEBUG} -C ${poudriere_jail_dir}/usr/lib debug
	@${sudo} mv ${poudriere_images_dir}/BSDRP.img ${BSDRP_IMG_FULL}
	@${sudo} mv ${poudriere_images_dir}/BSDRP-upgrade.img ${BSDRP_IMG_UPGRADE}
	@${sudo} mv ${poudriere_images_dir}/BSDRP.mtree ${BSDRP_IMG_MTREE}

upstream-sync: sync-FreeBSD sync-ports

clean: clean-images

clean-all: clean-jail clean-ports-tree clean-images clean-src
	@rm -f ${.OBJDIR}/*

clean-jail: clean-packages
	@echo "Deleting builder jail..."
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc jail -y -d -j BSDRPj || echo Missing builder jail
	# Older obj dir is often the main root cause of build issue
	@${sudo} rm -rf /usr/obj/usr/local/poudriere/jails/BSDRPj || echo Missing obj directory
	@rm -f ${.OBJDIR}/build-builder-jail

clean-ports-tree: clean-packages
	@echo "Deleting port-tree..."
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc ports -y -d -p BSDRPp || echo Missing port tree
	@rm -f ${.OBJDIR}/build-ports-tree

clean-packages:
	@echo "Deleting all existing packages..."
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc distclean -y -a -p BSDRPp || echo Missing port tree
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc logclean -y -a -j BSDRPj -p BSDRPp || echo Missing port tree or jail
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc pkgclean -y -A -j BSDRPj -p BSDRPp || echo Missing port tree or jail
	@rm -f ${.OBJDIR}/build-packages

clean-images:
	@${sudo} rm -f ${IMAGES} ${CHECKSUM_IMAGES} ${COMPRESSED_IMAGES}

clean-src:
	@rm -rf ${src_FreeBSD_dir}
	@rm -rf ${src_ports_dir}
	@rm -f ${.OBJDIR}/patch-src-FreeBSD
	@rm -f ${.OBJDIR}/patch-src-ports
	@rm -f ${.OBJDIR}/add-src-ports

release: all
	@${MAKE} -f ${MAKEFILE} compress-images checksum-images

compress-images: ${IMAGES}
	@echo "Compressing image files using $$(nproc) threads..."
	@for img in ${IMAGES}; do \
		${sudo} xz -9 -T0 -vf $${img} || exit 1; \
	done

COMPRESSED_IMAGES := ${BSDRP_IMG_FULL}.xz ${BSDRP_IMG_UPGRADE}.xz ${BSDRP_IMG_MTREE}.xz ${BSDRP_IMG_DEBUG}.xz
checksum-images: ${COMPRESSED_IMAGES}
	@echo "Computing checksums of generated files..."
	# Run in the images directory to prevent full path in the output
	@for img in ${COMPRESSED_IMAGES}; do \
		(cd ${poudriere_images_dir} && sha256 $$(basename $${img}) | ${sudo} tee $${img}.sha256); \
	done

help:
	@echo "Available targets:"
	@echo " all             - Build images (default)"
	@echo " clean           - Clean existing images only"
	@echo " clean-packages  - Clean all existing packages"
	@echo " clean-jail      - Clean existing builder jail"
	@echo "                   Sometimes previous FreeBSD obj tree prevent clean upgrade"
	@echo " clean-all       - Clean everything"
	@echo " upstream-sync   - Fetch latest sources (FreeBSD and ports tree)"
	@echo "                   And update hashes in Makefile.vars"
	@echo " compress-images - Compress generated files"
	@echo " checksum-images - Compute checksums of generated files"
	@echo " release         - Build, compress then generate checksums of images"
