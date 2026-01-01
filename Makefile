# BSD Router Project
# https://bsdrp.net

# Cf the help target at the end of the file for targets descriptions

###############################################################################
# BSD MAKEFILE BEGINNER'S GUIDE:
#
# *** IMPORTANT: This is a BSD Make Makefile (used on FreeBSD), NOT GNU Make! ***
# BSD Make and GNU Make have different syntax. This file will NOT work with
# GNU Make (the default on Linux). On FreeBSD, run "make" (which is BSD Make).
#
# A Makefile is a build automation script that defines "targets" (things to build)
# and their dependencies. Make executes commands to build targets only when needed.
#
# Basic syntax:
#   target: dependency1 dependency2
#   	command to run (must be indented with a TAB, not spaces)
#
# Variables (BSD Make syntax):
#   VAR = value      - Recursive assignment (evaluated each time it's used)
#   VAR := value     - Immediate assignment (evaluated once when defined)
#   VAR ?= value     - Conditional assignment (only if not already set)
#   VAR != command   - Assignment from command output (evaluated when defined)
#   ${VAR}           - Variable expansion (use the value of VAR)
#                      Note: BSD Make prefers ${VAR}, GNU Make uses $(VAR)
#
# Special variables (BSD Make specific - these DON'T exist in GNU Make):
#   ${.CURDIR}       - Current working directory where make was invoked
#   ${.PARSEDIR}     - Directory containing the Makefile being parsed
#   ${.OBJDIR}       - Directory for object files (build artifacts)
#   ${.PARSEFILE}    - Name of the Makefile being parsed
#   ${.TARGET}       - Name of the current target being built
#
# Directives (BSD Make syntax - different from GNU Make!):
#   .if condition    - Conditional block (GNU Make uses "ifdef" or "ifeq")
#   .endif           - End of conditional block
#   .for var in list - Loop over a list (GNU Make uses "foreach")
#   .endfor          - End of loop
#   .include "file"  - Include another Makefile (GNU Make uses "include")
#   .error "message" - Stop with error message
#
# BSD Make functions:
#   empty(VAR)       - Check if variable is empty
#   exists(file)     - Check if file exists
#   defined(VAR)     - Check if variable is defined
#
# Special prefixes in commands (same in both BSD and GNU Make):
#   @command         - Don't print the command before executing (silent)
#   -command         - Ignore errors from this command
#
# .PHONY: Declares targets that don't create files with the same name
#         (e.g., "clean", "all", "help" are actions, not files)
#
# Key differences from GNU Make:
# - BSD: .if/.endif         vs GNU: ifdef/ifndef/ifeq/ifneq
# - BSD: .for/.endfor       vs GNU: $(foreach ...)
# - BSD: ${VAR}             vs GNU: $(VAR) [both work in both, but conventions differ]
# - BSD: .include "file"    vs GNU: include file
# - BSD: VAR != command     vs GNU: VAR := $(shell command)
###############################################################################
# Poudriere configuration files are in poudriere.etc/poudriere.d/
# - First build a "builder" jail (BSDRPj), which is a reduced FreeBSD but
#   still needs to have compiler tools to build packages.
#   - List of WITHOUT in BSDRPj-src.conf
#   - Custom kernel configuration file (amd64 here)
# - Second, from this builder jail, we generate packages:
#   - ports list in BSDRP-pkglist
#   - ports options in BSDRPj-make.conf
# - Third, generate a nanobsd-like, uefi compliant firmware image
#   - No need for compiler tools, more WITHOUT_ options added in image-BSDRPj-src.conf
#   - But some unwanted files are still present, so add a list of them
#     in excluded.files
#   - Avoid extracting unwanted files from package using a pkg.conf
#     in BSDRP/Files/usr/local/etc/pkg.conf
#   - And a post customization script in post-script.sh that:
#     - Replace BSDRP_VERSION in boot menu
#     - Create some symlinks
#     - Customize fstab
#     - Generate mtree
###############################################################################

###############################################################################
# SECTION: Variable Definitions
# Variables store values used throughout the Makefile
###############################################################################

# The != operator runs a shell command and stores its output in the variable
# This extracts the BASEFS path from poudriere's configuration file
poudriere_basefs != grep '^BASEFS=' /usr/local/etc/poudriere.conf | cut -d '=' -f 2 || echo ""

# .if/.endif is Make's conditional statement (like if/endif in shell scripts)
# empty() checks if a variable has no value
.if empty(poudriere_basefs)
.error "Could not determine BASEFS from poudriere.conf"
.endif

# := is immediate assignment (evaluated once when defined)
# ${var} expands the variable's value
poudriere_images_dir := ${poudriere_basefs}/data/images
poudriere_jail_dir := ${poudriere_basefs}/jails/BSDRPj

# Conditionally set sudo variable based on whether we're running as root
# ${USER} is an environment variable
.if ${USER} != "root"
# ?= means "assign only if not already set" (allows override from command line)
sudo ?= sudo
.else
# = without ? means unconditional assignment to empty string
sudo =
.endif

# Define the path to the variables file
# Here we assign ${.PARSEDIR} to ${SRC_DIR} in place of ${.CURDIR} to get the directory relative to the Makefile
# We will call this Makefile recursively (so executed from the object directory).
# Use a fixed OBJ_DIR path to avoid nested obj directories when Make recurses
# (BSD Make would otherwise create /usr/obj/... paths when run from within obj/)
SRC_DIR := ${.PARSEDIR}
OBJ_DIR := ${SRC_DIR}/obj

# Load FreeBSD_* and ports_* variables from an external file
vars_file := ${SRC_DIR}/Makefile.vars

# exists() checks if a file exists
.if exists(${vars_file})
# .include loads variables and rules from another Makefile (like "source" in shell)
.include "${vars_file}"
.else
.error "Variables file '${vars_file}' not found."
.endif

# Load existing patch files (used to trigger targets if modified)
patches_dir := ${SRC_DIR}/BSDRP/patches

# Use != to run shell commands and capture their output into variables
FreeBSD_patches != find "${patches_dir}" -name 'freebsd.*.patch'
ports_patches != find "${patches_dir}" -name 'ports.*.patch'
ports_shar != find "${patches_dir}" -name 'ports.*.shar'
overlay_files != find "${SRC_DIR}/BSDRP/Files"
# Use OBJ_DIR for all build artifacts to avoid nested obj directories when Make recurses
src_FreeBSD_dir := ${OBJ_DIR}/FreeBSD
src_ports_dir := ${OBJ_DIR}/ports

# Validate that required patch files exist in the repository at parse time
# This ensures the repository has the necessary patches before attempting to build
# .for loops iterate over a list (like "for" in shell scripts)
.for required in FreeBSD_patches ports_patches ports_shar
# defined() checks if a variable exists, !defined() means "not defined"
# The || operator means "OR" (if either condition is true, execute the block)
.if !defined(${required}) || empty(${required})
# ${required:tl} means "apply the :tl modifier" which converts to lowercase
# Variable modifiers transform variable values: :tl=tolower, :tu=toupper, :S/old/new/=substitute
.error "No ${required:tl} files found in ${patches_dir}"
.endif
.endfor

# MACHINE_ARCH could be aarch64, but the source sys directory is arm64 :-(
# The :S modifier does string substitution: :S/pattern/replacement/
src_arch = ${MACHINE_ARCH:S/aarch64/arm64/}
kernel = ${OBJ_DIR}/FreeBSD/sys/${src_arch}/conf/${src_arch}

# Read version from file using != operator
VERSION != cat ${SRC_DIR}/BSDRP/Files/etc/version

# Define output image file paths
BSDRP_IMG_FULL = ${poudriere_images_dir}/BSDRP-${VERSION}-full-${MACHINE_ARCH}.img
BSDRP_IMG_UPGRADE = ${poudriere_images_dir}/BSDRP-${VERSION}-upgrade-${MACHINE_ARCH}.img
BSDRP_IMG_DEBUG = ${poudriere_images_dir}/BSDRP-${VERSION}-debug-${MACHINE_ARCH}.tar
BSDRP_IMG_MTREE = ${poudriere_images_dir}/BSDRP-${VERSION}-${MACHINE_ARCH}.mtree
IMAGES := ${BSDRP_IMG_FULL} ${BSDRP_IMG_UPGRADE} ${BSDRP_IMG_MTREE} ${BSDRP_IMG_DEBUG}
COMPRESSED_IMAGES := ${BSDRP_IMG_FULL}.xz ${BSDRP_IMG_UPGRADE}.xz ${BSDRP_IMG_MTREE}.xz ${BSDRP_IMG_DEBUG}.xz
# The %= modifier applies a suffix to each item in a list
CHECKSUM_IMAGES := ${COMPRESSED_IMAGES:%=%.sha256}

# Define MAKEFILE for recursive make calls
MAKEFILE := ${.PARSEDIR}/${.PARSEFILE}

# Declare we don't use suffix rules (old-style implicit rules like .c.o)
.SUFFIXES:

# Declare main target (what gets built when you just type "make")
.MAIN: all

# Declare phony targets (targets that don't create files with matching names)
# .PHONY is important for targets like "clean" or "all" that are actions, not files
# Without .PHONY, if a file named "clean" exists, "make clean" would do nothing!
.PHONY: all check-requirements clean clean-all upstream-sync help \
	cleanup-src-FreeBSD cleanup-src-ports \
	update-src-FreeBSD update-src-ports \
	patch-src-FreeBSD patch-src-ports \
	sync-FreeBSD sync-ports \
	add-src-ports patch-sources \
	build-builder-jail build-ports-tree build-packages \
	clean-jail clean-ports-tree clean-packages clean-images clean-src \
	release compress-images checksum-images

###############################################################################
# SECTION: Target Definitions
# Targets define what to build and how to build it
# Syntax: target: dependency1 dependency2
#         	command (must start with TAB)
#
# Make only rebuilds a target if:
# 1. The target file doesn't exist, OR
# 2. Any dependency is newer than the target, OR
# 3. The target is .PHONY (always rebuild)
###############################################################################

# The "all" target is the default (defined by .MAIN: all above)
# It depends on check-requirements and ${IMAGES}
# If dependencies are satisfied, this target has no commands to run
all: check-requirements ${IMAGES}

# Target with no dependencies and multiple commands
# Each command starts with @ (silent - don't print the command)
# The || operator means "or" - if left side fails, run right side
check-requirements:
	@which git > /dev/null || { echo "Error: git is not installed."; exit 1; }
	@which xz > /dev/null || { echo "Error: xz is not installed."; exit 1; }
	@which poudriere > /dev/null || { echo "Error: poudriere is not installed."; exit 1; }
.if ${USER} != "root"
	@which ${sudo} > /dev/null || { echo "Error: sudo is not installed."; exit 1; }
.endif
	@grep -q mtree /usr/local/share/poudriere/image.sh || { echo "Error: Need https://github.com/freebsd/poudriere/pull/1200"; exit 1; }
	@grep -q 'pmbr=' /usr/local/share/poudriere/image_firmware.sh || { echo "Error: Need https://github.com/freebsd/poudriere/pull/1205"; exit 1; }

###############################################################################
# SECTION: Sources Management
# These targets handle git repositories and applying patches
#
# INCREMENTAL BUILD BEHAVIOR:
# - Sources are only updated/cleaned if the git hash in Makefile.vars changes
# - Patches are only re-applied if patch files are modified or sources updated
# - Shar files are only re-applied if .shar files are modified
# - This allows fast incremental builds when nothing has changed
#
# Each target creates a "sentinel file" (empty file with the target's name)
# in ${.OBJDIR}. Make uses these files' timestamps to track dependencies.
# If a dependency is newer than the sentinel, the target re-runs.
###############################################################################

# Targets that are file/directory paths: Make checks if the file exists
# If the directory doesn't exist, Make runs the commands to create it
${src_FreeBSD_dir}:
	@echo "Git clone FreeBSD..."
	@git clone -b ${FreeBSD_branch} --single-branch "${FreeBSD_repo}".git ${src_FreeBSD_dir}

${src_ports_dir}:
	@echo "Git clone FreeBSD ports tree..."
	@git clone -b ${ports_branch} --single-branch "${ports_repo}".git ${src_ports_dir}

# .for loop creates multiple similar targets with different values
# This loop creates: cleanup-src-FreeBSD and cleanup-src-ports
# ${repo} gets substituted with each value in the list
.for repo in FreeBSD ports
cleanup-src-${repo}:
	@echo "==> Cleaning ${repo} sources..."
	@git -C ${src_${repo}_dir} checkout .
	@git -C ${src_${repo}_dir} clean -fd
	@rm -f patch-src-${repo}
	@rm -f patch-sources
	# touch creates an empty file with the target's name (${.TARGET})
	# This "sentinel file" marks that this target has been completed
	# Make can check the file's timestamp to see if dependencies are newer
	@touch ${.TARGET}

update-src-${repo}: ${vars_file} ${src_${repo}_dir}
	# Only cleanup if the git hash has changed from what's currently checked out
	@current_hash=$$(git -C ${src_${repo}_dir} rev-parse --short HEAD 2>/dev/null || echo "none"); \
	if [ "$$current_hash" != "${${repo}_hash}" ]; then \
		echo "==> Hash changed from $$current_hash to ${${repo}_hash}, cleaning ${repo} sources..."; \
		rm -f ${OBJ_DIR}/cleanup-src-${repo} ${OBJ_DIR}/patch-src-${repo}; \
		${MAKE} -f ${MAKEFILE} cleanup-src-${repo}; \
		echo "==> Updating ${repo} at hash ${${repo}_hash}..."; \
		git -C ${src_${repo}_dir} checkout ${${repo}_branch}; \
		git -C ${src_${repo}_dir} pull; \
		git -C ${src_${repo}_dir} checkout ${${repo}_hash}; \
		echo "Git commit count:"; \
		git -C ${src_${repo}_dir} rev-list HEAD --count; \
	else \
		echo "==> ${repo} already at hash ${${repo}_hash}, skipping update"; \
	fi
	@touch ${.TARGET}

patch-src-${repo}: update-src-${repo}
	# Apply patches based on git diff check, not timestamp comparison
	# This avoids false triggers from patch files with future timestamps
.if !defined(${repo}_patches) || empty(${repo}_patches)
	@echo "WARNING: No patches found for ${repo} in ${patches_dir}"
.else
	# If patches already applied (git diff shows changes), skip patching
	# git apply is more robust than patch: creates dirs, better conflict detection
	# NOTE: If you update a patch file, run "make cleanup-src-${repo}" first
	@if git -C ${OBJ_DIR}/${repo} diff --quiet HEAD; then \
		echo "==> Applying ${repo} patches..."; \
		for patch in ${${repo}_patches}; do \
			echo "Processing $${patch}..."; \
			git -C ${OBJ_DIR}/${repo} apply -p0 --whitespace=nowarn $${patch} || exit 1; \
		done; \
	else \
		echo "==> ${repo} patches already applied (git tree modified), skipping"; \
	fi
.endif
	@touch ${.TARGET}

sync-${repo}: ${src_${repo}_dir}
	@rm -f ${OBJ_DIR}/cleanup-src-${repo}
	@${MAKE} -f ${MAKEFILE} cleanup-src-${repo}
	@echo "Sync ${repo} sources with upstream..."
	@git -C ${src_${repo}_dir} pull
	@new_hash=$$(git -C ${src_${repo}_dir} rev-parse --short HEAD) && \
	sed -i '' "s/${repo}_hash?=.*/${repo}_hash?=$$new_hash/" ${vars_file} && \
	rm -f ${OBJ_DIR}/patch-src-${repo} && \
	echo "Updating previous ${repo} hash ${${repo}_hash} to $${new_hash}"
.endfor # repo

patch-sources: patch-src-FreeBSD patch-src-ports add-src-ports ${kernel}
	@touch ${.TARGET}

add-src-ports: update-src-ports ${ports_shar}
.if !defined(ports_shar) || empty(ports_shar)
	@echo "WARNING: No ports_shar variable defined or empty, skipping ports addition"
.else
	@echo "Add extra ports into FreeBSD port tree sources..."
	@for shar in ${ports_shar}; do \
		echo "Processing $${shar}..."; \
		(cd "${OBJ_DIR}/ports" && sh $${shar} || exit 1); \
	done
.endif
	@touch ${.TARGET}

${kernel}: ${SRC_DIR}/BSDRP/kernels/${src_arch}
	@echo "Install kernel for arch ${MACHINE_ARCH} (${src_arch})"
	@cp ${SRC_DIR}/BSDRP/kernels/${src_arch} ${OBJ_DIR}/FreeBSD/sys/${src_arch}/conf/

build-builder-jail: patch-sources ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.common
	@echo "Build the builder jail and kernel..."
	# All jail-src.conf need to end by MODULES_OVERRIDE section because this is arch dependends
	@cp ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.common ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf
	@if [ -f ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.${src_arch} ]; then \
		cat ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf.${src_arch} >> ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf; \
	else \
		echo "" >> ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRPj-src.conf; \
	fi
	# Determine if jail exists: use update (u) if it exists, otherwise create (c)
	# This allows the same target to handle both initial creation and updates
	@JAIL_ACTION=$$(${sudo} poudriere -e ${SRC_DIR}/poudriere.etc jail -ln | grep -q BSDRPj && echo "u" || echo "c"); \
	echo "debug: $${JAIL_ACTION}"; \
	${sudo} poudriere -e ${SRC_DIR}/poudriere.etc jail -$${JAIL_ACTION} -j BSDRPj -b -m src=${OBJ_DIR}/FreeBSD -K ${src_arch} > ${OBJ_DIR}/build.jail.log; \
	if [ $$? -ne 0 ]; then \
		echo "ERROR: Jail build failed. Last 50 lines of log:"; \
		tail -n 50 ${OBJ_DIR}/build.jail.log; \
		exit 1; \
	fi
	@touch ${.TARGET}

build-ports-tree: patch-sources
	# Determine if ports tree exists: update or create as needed
	@ports_action=$$(${sudo} poudriere -e ${SRC_DIR}/poudriere.etc ports -ln | grep -q BSDRPp && echo "u" || echo "c") && \
	${sudo} poudriere -e ${SRC_DIR}/poudriere.etc ports -$${ports_action} -p BSDRPp -m null -M ${OBJ_DIR}/ports
	@touch ${.TARGET}

build-packages: build-builder-jail build-ports-tree ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.common
	@echo "Build packages..."
	@cp ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.common ${OBJ_DIR}/pkglist || exit 1
	@if [ -f ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${src_arch} ]; then \
		cat ${SRC_DIR}/poudriere.etc/poudriere.d/BSDRP-pkglist.${src_arch} >> ${OBJ_DIR}/pkglist || exit 1; \
	fi
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc bulk -j BSDRPj -p BSDRPp -f ${OBJ_DIR}/pkglist || { \
		echo "Error: Package build failed"; \
		exit 1; \
	}
	@touch ${.TARGET}

${BSDRP_IMG_FULL} ${BSDRP_IMG_UPGRADE} ${BSDRP_IMG_MTREE} ${BSDRP_IMG_DEBUG}: build-packages ${SRC_DIR}/poudriere.etc/poudriere.d/post-script.sh ${overlay_files}
	@echo "Build image..."
	# Only remove old images and compressed files, don't remove if they're already current
	# The poudriere image command will overwrite them anyway
	@${sudo} rm -f ${CHECKSUM_IMAGES} ${COMPRESSED_IMAGES}
	# Replace version in brand-bsdrp.lua
	@sed -i '' -e s"/BSDRP_VERSION/${VERSION}/" ${SRC_DIR}/BSDRP/Files/boot/lua/brand-bsdrp.lua
	# Image size of 4g still too big to upgrade previous 4g nanobsd image, need to reduce
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc image -t firmware -s 3.95g \
		-j BSDRPj -p BSDRPp -n BSDRP -h router.bsdrp.net \
		-c ${SRC_DIR}/BSDRP/Files/ \
		-f ${OBJ_DIR}/pkglist \
		-X ${SRC_DIR}/poudriere.etc/poudriere.d/excluded.files \
		-A ${SRC_DIR}/poudriere.etc/poudriere.d/post-script.sh
	# Restore brand-bsdrp.lua
	@git -C ${SRC_DIR}/BSDRP/Files/boot/lua checkout brand-bsdrp.lua
	@test -f ${poudriere_images_dir}/BSDRP.img || { echo "Error: ${poudriere_images_dir}/BSDRP.img was not created"; exit 1; }
	@${sudo} tar cf ${BSDRP_IMG_DEBUG} -C ${poudriere_jail_dir}/usr/lib debug
	@${sudo} mv ${poudriere_images_dir}/BSDRP.img ${BSDRP_IMG_FULL}
	@${sudo} mv ${poudriere_images_dir}/BSDRP-upgrade.img ${BSDRP_IMG_UPGRADE}
	@${sudo} mv ${poudriere_images_dir}/BSDRP.mtree ${BSDRP_IMG_MTREE}
	@echo "Uncompressed image availables as:"
	@echo "- ${BSDRP_IMG_FULL}"
	@echo "- ${BSDRP_IMG_UPGRADE}"
	@echo "- ${BSDRP_IMG_MTREE}"

upstream-sync: sync-FreeBSD sync-ports
	@new_version=$$(git -C ${src_FreeBSD_dir} rev-list --count HEAD) && \
	echo n$$new_version > ${SRC_DIR}/BSDRP/Files/etc/version

clean: clean-images

clean-all: clean-jail clean-ports-tree clean-images clean-src
	@rm -f ${OBJ_DIR}/*

clean-jail: clean-packages
	@echo "Deleting builder jail..."
	# XXX Do not clean if no builder jail ?
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc jail -y -d -j BSDRPj || echo Missing builder jail
	# Older obj dir is often the main root cause of build issue
	# XXX How to dynamicaly retreive this directory ?
	@${sudo} rm -rf /usr/obj/usr/local/poudriere/jails/BSDRPj || echo Missing obj directory
	@rm -f ${OBJ_DIR}/build-builder-jail

clean-ports-tree: clean-packages
	@echo "Deleting port-tree..."
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc ports -y -d -p BSDRPp || echo Missing port tree
	@rm -f ${OBJ_DIR}/build-ports-tree

clean-packages:
	@echo "Deleting all existing packages..."
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc distclean -y -a -p BSDRPp || echo Missing port tree
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc logclean -y -a -j BSDRPj -p BSDRPp || echo Missing port tree or jail
	@${sudo} poudriere -e ${SRC_DIR}/poudriere.etc pkgclean -y -A -j BSDRPj -p BSDRPp || echo Missing port tree or jail
	@rm -f ${OBJ_DIR}/build-packages

clean-images:
	@${sudo} rm -f ${IMAGES} ${CHECKSUM_IMAGES} ${COMPRESSED_IMAGES}

clean-src:
	@rm -rf ${src_FreeBSD_dir}
	@rm -rf ${src_ports_dir}
	@rm -f ${OBJ_DIR}/patch-src-FreeBSD
	@rm -f ${OBJ_DIR}/patch-src-ports
	@rm -f ${OBJ_DIR}/add-src-ports

release: all
	@${MAKE} -f ${MAKEFILE} compress-images checksum-images

compress-images: ${IMAGES}
	@echo "Compressing image files using $$(nproc) threads..."
	@for img in ${IMAGES}; do \
		${sudo} xz -9 -T0 --memlimit=85% -vf $${img} || exit 1; \
	done

checksum-images: ${COMPRESSED_IMAGES}
	@echo "Computing checksums of generated files..."
	# Run in the images directory to prevent full path in the output
	@for img in ${COMPRESSED_IMAGES}; do \
		(cd ${poudriere_images_dir} && sha256 $$(basename $${img}) | ${sudo} tee $${img}.sha256); \
	done

help:
	@echo "Available targets:"
	@echo " all                 - Build images (default)"
	@echo " clean               - Clean existing images only"
	@echo " clean-packages      - Clean all existing packages"
	@echo " clean-jail          - Clean existing builder jail and obj dirs"
	@echo " clean-src           - Clean source trees"
	@echo "                       Sometimes previous FreeBSD obj tree prevents clean upgrade"
	@echo " clean-all           - Clean everything"
	@echo " upstream-sync       - Fetch latest sources (FreeBSD and ports tree)"
	@echo "                       and update hashes in Makefile.vars"
	@echo " cleanup-src-FreeBSD - Clean FreeBSD sources to re-apply patches"
	@echo " cleanup-src-ports   - Clean ports sources to re-apply patches"
	@echo " compress-images     - Compress generated files"
	@echo " checksum-images     - Compute checksums of generated files"
	@echo " release             - Build, compress, then generate checksums of images"
