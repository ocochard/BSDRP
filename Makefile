# BSD Router Project
# https://bsdrp.net

# The common user-driven targets are:
#
# clean           - Clean existing images only
# clean-packages  - Clean all existing packages
# clean-jail      - Clean existing builder jail (sometime FreeBSD current
#                   need a fresh start because incompatible with previous
#                   existing obj tree)
# clean-all       - Clean all: FreeBSD sources, port tree sources, jail,
#                   packages, images
# upstream-sync   - Fetch latest FreeBSD and port tree sources
#                   and update hashes in Makefile.vars

###############################################################################
# Poudriere configurations files are in poudriere.etc/poudriere.d/
# - First build a "builder" jail (BSDRPj), which is a reduced FreeBSD but that
#   still needs to have compilers tools to build packages.
#   - List of WITHOUT in BSDRPj-src.conf
#   - Custom kernel configuration file (amd64 here)
# - Second, from this builder jail, we generate packages:
#   - ports list in BSDRP-pkglist
#   - ports options in BSDRPj-make.conf
# - Third and last, we generate a nanobsd-like, uefi compliant firmware image
#   - No need of compiler tools, more WITHOUT_added in image-BSDRPj-src.conf
#   - But FreeBSD some unwanted files are still here, so adding list of them
#     in excluded.files
#   - All avoiding extracting unwanted files from package using a pkg.conf
#     in BSDRP/Files/usr/local/etc/pkg.conf
#   - And a post customization script in post-script.sh
###############################################################################

poudriere_images_dir = /usr/local/poudriere/data/images
bsdrp_image = ${poudriere_images_dir}/BSDRP.img
bsdrp_update_image = ${poudriere_images_dir}/BSDRP-update.img

.if ${USER} != "root"
sudo ?= sudo
.else
sudo =
.endif

# Define the path to the variables file
# This loads all FreeBSD_* and ports_* variables
vars_file = Makefile.vars
.if exists(${vars_file})
.include "${vars_file}"
.else
.error "Variables file '${vars_file}' not found."
.endif

# Load existing patches files (used to trigged target if modified)
patches_dir = ${.CURDIR}/BSDRP/patches
FreeBSD_patches != find $(patches_dir) -name 'freebsd.*.patch'
ports_patches != find $(patches_dir) -name 'ports.*.patch'
ports_shar != find $(patches_dir) -name 'ports.*.shar'
src_FreeBSD_dir = ${.OBJDIR}/FreeBSD
src_ports_dir = ${.OBJDIR}/ports
.for required in FreeBSD_patches ports_patches ports_shar
.if !defined(${required}) || empty(${required})
.error "No ${required:tl} files found in ${patches_dir}"
.endif
.endfor

# MACHINE_ARCH could be aarch64, but the source sys directory is arm64 :-(
src_arch = ${MACHINE_ARCH:S/aarch64/arm64/}
kernel = ${.OBJDIR}/FreeBSD/sys/${src_arch}/conf/${src_arch}

.PHONY: all check-requirements clean clean-all upstream-sync

all: check-requirements ${bsdrp_image} ${bsdrp_update_image}

check-requirements:
	@which git > /dev/null || { echo "Error: git is not installed."; exit 1; }
.if ${USER} != "root"
	@which ${sudo} > /dev/null || { echo "Error: sudo is not installed."; exit 1; }
.endif

# Sources management

${src_FreeBSD_dir}:
	@echo "Git clone FreeBSD..."
	@git clone -b ${FreeBSD_branch} --single-branch "${FreeBSD_repo}".git ${src_FreeBSD_dir}

${src_ports_dir}:
	@echo "Git clone FreeBSD ports tree..."
	@git clone -b ${ports_branch} --single-branch "${ports_repo}".git ${src_ports_dir}

.for src in FreeBSD ports
cleanup-src-${src}:
	@echo "==> Cleaning ${src} sources..."
	@git -C ${src_${src}_dir} checkout .
	@git -C ${src_${src}_dir} clean -fd
	@rm -f patch-src-${src}
	@rm -f patch-sources
	@touch ${.TARGET}

update-src-${src}: ${vars_file} ${src_${src}_dir} cleanup-src-${src}
	@echo "==> Updating ${src} at hash ${${src}_hash}..."
	@git -C ${src_${src}_dir} checkout ${${src}_branch}
	@git -C ${src_${src}_dir} pull
	@git -C ${src_${src}_dir} checkout ${${src}_hash}
	@echo "Git commit count:"
	@git -C ${src_${src}_dir} rev-list HEAD --count
	@touch ${.TARGET}

patch-src-${src}: update-src-${src}
	# XXX Need to be replaced with a generic call (catch each patch mods)
	# in a for loop, allowing to patch only when changed
	#@echo "DEBUG:  ${src}_patches = ${${src}_patches}"
.if !defined(${src}_patches) || empty(${src}_patches)
	@echo "WARNING: No patches found for ${src} in ${patches_dir}"
.else
	@echo "==> Applying ${src} patches..."
	# All patches are in git diff format (so -p0)
	@for patch in ${${src}_patches}; do \
		echo "Processing $${patch}..."; \
		patch -p0 -NE -d  ${.OBJDIR}/${src} -i $${patch} || exit 1; \
	done
.endif
	@touch ${.TARGET}

.endfor # src

patch-sources: patch-src-FreeBSD patch-src-ports add-src-ports ${kernel}
	@touch ${.TARGET}

add-src-ports: update-src-ports
.if !defined(ports_shar) || empty(ports_shar)
	@echo "WARNING: No ports_shar variable defined or empty, skipping ports addition"
.else
	# XXX Need to be replaced with a generic call (catch each shar file mods)
	@echo "Add extrat ports into FreeBSD port tree sources..."
	@for shar in ${ports_shar}; do \
		echo "Processing $${shar}..."; \
		(cd "${.OBJDIR}/ports" && sh $${shar} || exit 1); \
	done
.endif
	@touch ${.TARGET}

${kernel}: ${.CURDIR}/BSDRP/kernels/${src_arch}
	@echo "Install kernel for arch ${MACHINE_ARCH} (${src_arch})"
	@cp ${.CURDIR}/BSDRP/kernels/${src_arch} ${.OBJDIR}/FreeBSD/sys/${src_arch}/conf/

build-builder-jail: patch-sources ${.CURDIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.common
	@echo "Build the builder jail and kernel..."
	# All jail-src.conf need to end by MODULES_OVERRIDE section because this is arch dependends
	@cp ${.CURDIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.common ${.CURDIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf
	@if [ -f ${.CURDIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.${src_arch} ]; then \
		cat ${.CURDIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.${src_arch} >> ${.CURDIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf; \
	else \
		echo "" >> ${.CURDIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf; \
	fi
	@jail_action=$$(${sudo} poudriere -e ${.CURDIR}/poudriere.etc jail -ln | grep -q BSDRPj && echo "u" || echo "c") && \
	${sudo} poudriere -e ${.CURDIR}/poudriere.etc jail -$${jail_action} -j BSDRPj -b -m src=${.OBJDIR}/FreeBSD -K ${src_arch}
	@touch ${.TARGET}

build-ports-tree: patch-sources
	@ports_action=$$(${sudo} poudriere -e ${.CURDIR}/poudriere.etc ports -ln | grep -q BSDRPp && echo "u" || echo "c") && \
	${sudo} poudriere -e ${.CURDIR}/poudriere.etc ports -$${ports_action} -p BSDRPp -m null -M ${.OBJDIR}/ports
	@touch ${.TARGET}

build-packages: build-builder-jail build-ports-tree
	@echo "Build packages..."
	# Some packages are architecture dependends
	@cp ${.CURDIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.common ${.OBJDIR}/pkglist
	@if [ -f ${.CURDIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${src_arch} ]; then \
		cat ${.CURDIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${src_arch} >> ${.OBJDIR}/pkglist; \
	fi
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc bulk -j BSDRPj -p BSDRPp -f ${.OBJDIR}/pkglist
	@touch ${.TARGET}

${bsdrp_image} ${bsdrp_update_image}: build-packages
	@echo "Build image..."
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc image -t firmware -s 4g \
		-j BSDRPj -p BSDRPp -n BSDRP -h router.bsdrp.net \
		-c ${.CURDIR}/BSDRP/Files/ \
		-f ${.OBJDIR}/pkglist \
		-X ${.CURDIR}/poudriere.etc/poudriere.d/excluded.files \
		-A ${.CURDIR}/poudriere.etc/poudriere.d/post-script.sh

upstream-sync: sync-FreeBSD sync-ports

.for src in FreeBSD ports
sync-${src}: ${src_${src}_dir} cleanup-src-${src}
	@echo "Sync ${src} sources with upstream..."
	@git -C ${src_${src}_dir} stash
	@git -C ${src_${src}_dir} pull
	@new_hash=$$(git -C ${src_${src}_dir} rev-parse --short HEAD) && \
	sed -i '' "s/${src}_hash?=.*/${src}_hash?=$$new_hash/" ${.CURDIR}/${vars_file} && \
	rm -f ${.OBJDIR}/patch-src-${src} && \
	echo "Updating previous ${src} hash ${${src}_hash} to $${new_hash}"
.endfor

clean: clean-images

clean-all: clean-jail clean-ports-tree clean-images clean-src
	@rm -f ${.OBJDIR}/*

clean-jail: clean-packages
	@echo "Deleting builder jail..."
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc jail -y -d -j BSDRPj || echo Missing builder jail
	# Older obj dir is often the main root cause of build issue
	@${sudo} rm -rf /usr/obj/usr/local/poudriere/jails/BSDRPj || echo Missing obj directory
	@rm -f ${.OBJDIR}/build-builder-jail

clean-ports-tree: clean-packages
	@echo "Deleting port-tree..."
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc ports -y -d -p BSDRPp || echo Missing port tree
	@rm -f ${.OBJDIR}/build-ports-tree

clean-packages:
	@echo "Deleting all existing packages..."
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc distclean -y -a -p BSDRPp || echo Missing port tree
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc logclean -y -a -j BSDRPj -p BSDRPp || echo Missing port tree or jail
	@${sudo} poudriere -e ${.CURDIR}/poudriere.etc pkgclean -y -A -j BSDRPj -p BSDRPp || echo Missing port tree or jail
	@rm -f ${.OBJDIR}/build-packages

clean-images:
	@${sudo} rm -f ${bsdrp_image}
	@${sudo} rm -f ${bsdrp_update_image}

clean-src:
	@rm -rf ${src_FreeBSD_dir}
	@rm -rf ${src_ports_dir}
	@rm -f ${.OBJDIR}/patch-src-FreeBSD
	@rm -f ${.OBJDIR}/patch-src-ports
	@rm -f ${.OBJDIR}/add-src-ports
