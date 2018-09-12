#!/bin/sh
#
# Copyright (c) 2005 Poul-Henning Kamp.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $FreeBSD: head/tools/tools/nanobsd/nanobsd.sh 326756 2017-12-11 02:44:10Z imp $
#

set -e

nanobsd_sh=$(realpath "$0")
topdir=$(dirname "${nanobsd_sh}")
. "${topdir}/defaults.sh"

#######################################################################
# Parse arguments

do_clean=true
do_kernel=true
do_installkernel=true
do_world=true
do_installworld=true
do_image=true
do_copyout_partition=true
do_native_xtools=false
do_prep_image=true

# Pull in legacy stuff for now automatically
. "${topdir}/legacy.sh"

set +e
if [ $? -ne 0 ] ; then
	usage
	exit 2
fi
set -e

while getopts "BKXWbc:fhiIknqvw" FLAG; do
	case "${FLAG}" in
	B)
		do_installworld=false
		do_installkernel=false
		;;
	K)
		do_installkernel=false
		;;
	X)
		do_native_xtools=true
		;;
	W)
		do_installworld=false
		;;
	b)
		do_world=false
		do_kernel=false
		;;
	c)
		# Make config file path available to the config file
		# itself so that it can access additional files relative
		# to its own location.
		NANO_CONFIG="${OPTARG}"
		. "${OPTARG}"
		;;
	f)
		do_copyout_partition=false
		;;
	h)
		usage
		;;
	i)
		do_image=false
		;;
	k)
		do_kernel=false
		;;
	n)
		do_clean=false
		;;
	q)
		PPLEVEL=$(($PPLEVEL - 1))
		;;
	v)
		PPLEVEL=$(($PPLEVEL + 1))
		;;
	w)
		do_world=false
		;;
	I)
		do_world=false
		do_kernel=false
		do_installworld=false
		do_installkernel=false
		do_prep_image=false
		do_image=true
		;;
	*)
		break
		;;
	esac
done

# Should be useless for nanobsd usage, but cleanup arg list
shift $((OPTIND-1))

if [ $# -gt 0 ] ; then
	echo "$0: Extraneous arguments supplied"
	usage
fi

#######################################################################
# And then it is as simple as that...

# File descriptor 3 is used for logging output, see pprint
exec 3>&1
set_defaults_and_export

if [ ! -d "${NANO_TOOLS}" ]; then
	echo "NANO_TOOLS directory does not exist" 1>&2
	exit 1
fi

if ! $do_clean; then
	NANO_PMAKE="${NANO_PMAKE} -DNO_CLEAN"
fi

pprint 1 "NanoBSD image ${NANO_NAME} build starting"

run_early_customize

if $do_world ; then
	if $do_clean ; then
		clean_build
	else
		pprint 2 "Using existing build tree (as instructed)"
	fi
	make_conf_build
	build_world
else
	pprint 2 "Skipping buildworld (as instructed)"
fi

if $do_kernel ; then
	if ! $do_world ; then
		make_conf_build
	fi
	build_kernel
else
	pprint 2 "Skipping buildkernel (as instructed)"
fi

if $do_installworld ; then
    clean_world
    make_conf_install
    install_world
    install_etc
else
    pprint 2 "Skipping installworld (as instructed)"
fi

if ${do_native_xtools} ; then
	native_xtools
fi
if ${do_prep_image} ; then
	setup_nanobsd_etc
fi
if $do_installkernel ; then
	install_kernel
else
	pprint 2 "Skipping installkernel (as instructed)"
fi

if $do_prep_image ; then
	run_customize
	setup_nanobsd
	prune_usr
	run_late_customize
	fixup_before_diskimage
else
	pprint 2 "Skipping image prep (as instructed)"
fi
if $do_image ; then
	create_diskimage
else
	pprint 2 "Skipping image build (as instructed)"
fi
last_orders

pprint 1 "NanoBSD image ${NANO_NAME} completed"
