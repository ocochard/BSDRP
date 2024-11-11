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

.if ${USER} != "root"
SUDO ?= sudo
.else
SUDO =
.endif

# Define the path to the variables file
# This loads all FREEBSD_* and PORTS_* variables
VARS_FILE = Makefile.vars
.if exists(${VARS_FILE})
.include "${VARS_FILE}"
.else
.error "Variables file '${VARS_FILE}' not found."
.endif

POUDRIERE_IMAGES_DIR = /usr/local/poudriere/data/images
BSDRP_IMAGE = ${POUDRIERE_IMAGES_DIR}/BSDRP.img
BSDRP_UPDATE_IMAGE = ${POUDRIERE_IMAGES_DIR}/BSDRP-update.img

# Load existing patches files (used to trigged target if modified)
PATCHES_DIR = ${.CURDIR}/BSDRP/patches
FREEBSD_PATCHES != find $(PATCHES_DIR) -name 'freebsd.*.patch'
.if empty(FREEBSD_PATCHES)
.error "No FreeBSD patches found"
.endif
PORTS_PATCHES != find $(PATCHES_DIR) -name 'ports.*.patch'
.if empty(PORTS_PATCHES)
.error "No ports patches found"
.endif
PORTS_SHAR != find $(PATCHES_DIR) -name 'ports.*.shar'
.if empty(PORTS_SHAR)
.error "No new ports shar files found"
.endif

# MACHINE_ARCH could be aarch64, but the source sys directory is arm64 :-(
SRC_ARCH = ${MACHINE_ARCH:S/aarch64/arm64/}
#logfile="/tmp/BSDRP.build.log"

.PHONY: upstream-sync sync-fbsd sync-ports

all: check-requirements ${BSDRP_IMAGE} ${BSDRP_UPDATE_IMAGE}

check-requirements:
	# Check if git installed and sudo requiered
	@which git > /dev/null || { echo "Error: git is not installed."; exit 1; }
.if ${USER} != "root"
	@which ${SUDO} > /dev/null || { echo "Error: sudo is not installed."; exit 1; }
.endif

update-src: update-src-fbsd update-src-ports
	# Update all sources (manually triggeretd only)
	@echo "Update FreeBSD and ports tree sources"
	@echo "XXX"

update-src-fbsd: ${VARS_FILE} fetch-src-fbsd
	# Update only if VARS_FILE was updated since last run
	@echo "Update FreeBSD src at hash ${FREEBSD_HASH}"
	# revert back to previous revision
	@git -C ${.OBJDIR}/FreeBSD checkout main
	@git -C ${.OBJDIR}/FreeBSD pull
	@git -C ${.OBJDIR}/FreeBSD checkout ${FREEBSD_HASH}
	@echo "Git commit count:"
	@git -C ${.OBJDIR}/FreeBSD rev-list HEAD --count
	@touch ${.TARGET}

update-src-ports: ${VARS_FILE} fetch-src-ports
	# Update only if VARS_FILE was updated since last run
	@echo "Update FreeBSD port tree at hash ${PORTS_HASH}"
	# revert back to previous revision
	@git -C ${.OBJDIR}/ports pull
	@git -C ${.OBJDIR}/ports checkout ${PORTS_HASH}
	@echo "Git commit count:"
	@git -C ${.OBJDIR}/ports rev-list HEAD --count
	@touch ${.TARGET}

fetch-src-fbsd:
	@echo "Git clone FreeBSD..."
	@git clone -b ${FREEBSD_BRANCH} --single-branch "${FREEBSD_REPO}".git ${.OBJDIR}/FreeBSD
	@touch ${.TARGET}

fetch-src-ports:
	@echo "git clone FreeBSD ports tree..."
	@git clone -b ${PORTS_BRANCH} --single-branch "${PORTS_REPO}".git ${.OBJDIR}/ports
	@touch ${.TARGET}

patch-sources: patch-src-freebsd patch-src-ports add-src-ports install-kernel
	@echo "Patch FreeBSD and ports sources..."
	touch ${.TARGET}

patch-src-freebsd: update-src-fbsd
	# XXX Need to be replaced with a generic call (catch each patch mods)
	# in a for loop, allowing to patch only when changed
	@echo "Patch FreeBSD sources"
	@echo "List of patches: ${FREEBSD_PATCHES}"
	# Need to start with a fresh cleanup tree
	# XXX Before simple update too ?
	git -C ${.OBJDIR}/FreeBSD checkout .
	git -C ${.OBJDIR}/FreeBSD clean -fd
	# All patches are in git diff format (so -p0)
	@for patch in ${FREEBSD_PATCHES}; do \
		patch -p0 -NE -d  ${.OBJDIR}/FreeBSD -i $${patch} || exit 1; \
	done
	touch ${.TARGET}

patch-src-ports: update-src-ports
	# XXX Need to be replaced with a generic call (catch each patch mods)
	@echo "Patch FreeBSD port tree sources..."
	# Need to start with a fresh cleanup tree
	# XXX Need to be moved in its own target and Before simple update too ?
	git -C ${.OBJDIR}/ports checkout .
	git -C ${.OBJDIR}/ports clean -fd
	@for patch in ${PORTS_PATCHES}; do \
		patch -p0 -NE -d  ${.OBJDIR}/ports -i $${patch} || exit 1; \
	done
	touch ${.TARGET}

add-src-ports: update-src-ports
	# XXX Need to be replaced with a generic call (catch each shar file mods)
	@echo "Add extrat ports into FreeBSD port tree sources..."
	@for shar in ${PORTS_SHAR}; do \
		(cd "${.OBJDIR}/ports" && sh $${shar} || exit 1); \
	done
	touch ${.TARGET}

install-kernel: ${.CURDIR}/BSDRP/kernels/${SRC_ARCH}
	@echo "Install kernel for arch ${MACHINE_ARCH} (${SRC_ARCH})"
	cp ${.CURDIR}/BSDRP/kernels/${SRC_ARCH} ${.OBJDIR}/FreeBSD/sys/${SRC_ARCH}/conf/
	touch ${.TARGET}

build-builder-jail: patch-sources
	# XXX need to use only one line with -c|-u
	# MACHINE_ARCH: aarch64 or amd64
	@if ! ${SUDO} poudriere -e ${.CURDIR}/poudriere.etc jail -ln | grep -q BSDRPj; then \
		${SUDO} poudriere -e ${.CURDIR}/poudriere.etc jail -c -j BSDRPj -b -m src=${.OBJDIR}/FreeBSD -K ${SRC_ARCH}; \
	else \
		${SUDO} poudriere -e ${.CURDIR}/poudriere.etc jail -u -j BSDRPj -b -m src=${.OBJDIR}/FreeBSD -K ${SRC_ARCH}; \
	fi
	touch ${.TARGET}

build-ports-tree: patch-sources
	# XXX need to use only one line with -c|-u
	@if ! ${SUDO} poudriere -e ${.CURDIR}/poudriere.etc ports -ln | grep -q BSDRPp; then \
		${SUDO} poudriere -e ${.CURDIR}/poudriere.etc ports -c -p BSDRPp -m null -M ${.OBJDIR}/ports; \
	else \
		${SUDO} poudriere -e ${.CURDIR}/poudriere.etc ports -u -p BSDRPp -m null -M ${.OBJDIR}/ports; \
	fi
	touch ${.TARGET}

build-packages: build-builder-jail build-ports-tree
	# Some packages are architecture dependends
	cp ${.CURDIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.common ${.OBJDIR}/pkglist
	@if [ -f ${.CURDIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${SRC_ARCH} ]; then \
		cat ${.CURDIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${SRC_ARCH} >> ${.OBJDIR}/pkglist; \
  fi
	@${SUDO} poudriere -e ${.CURDIR}/poudriere.etc bulk -j BSDRPj -p BSDRPp -f ${.OBJDIR}/pkglist
	touch ${.TARGET}

${BSDRP_IMAGE} ${BSDRP_UPDATE_IMAGE}: build-packages
	@echo "XXX ${SUDO} poudriere image"
	@${SUDO} poudriere -e ${.CURDIR}/poudriere.etc image -t firmware -s 4g \
		-j BSDRPj -p BSDRPp -n BSDRP -h router.bsdrp.net \
		-c ${.CURDIR}/BSDRP/Files/ \
		-f ${.OBJDIR}/pkglist \
		-X ${.CURDIR}/poudriere.etc/poudriere.d/excluded.files \
		-A ${.CURDIR}/poudriere.etc/poudriere.d/post-script.sh

upstream-sync: sync-fbsd sync-ports

sync-fbsd: fetch-src-fbsd
	@git -C ${.OBJDIR}/FreeBSD stash
	@git -C ${.OBJDIR}/FreeBSD pull
	NEW_FBSD_HASH=$$(git -C ${.OBJDIR}/FreeBSD rev-parse --short HEAD) && \
	sed -i '' "s/FREEBSD_HASH?=.*/FREEBSD_HASH?=$$NEW_FBSD_HASH/" ${.CURDIR}/${VARS_FILE} \
	@rm -f patch-src-freebsd

sync-ports: fetch-src-ports
	@git -C ${.OBJDIR}/ports stash
	@git -C ${.OBJDIR}/ports pull
	NEW_PORTS_HASH=$$(git -C ${.OBJDIR}/ports rev-parse --short HEAD) && \
	sed -i '' "s/PORTS_HASH?=.*/PORTS_HASH?=$$NEW_PORTS_HASH/" ${.CURDIR}/${VARS_FILE}
	@rm -f patch-src-ports

clean:
	@echo "delete stuff"
	rm -f ${.OBJDIR}/*
	rm -f ${BSDRP_IMAGE}
	rm -f ${BSDRP_UPDATE_IMAGE}

clean-all:
	rm -rf ${.OBJDIR}/*

.PHONY: all check-requirements clean clean-all update-src
