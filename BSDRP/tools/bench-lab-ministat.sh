#!/bin/sh
# This script prepare the result from bench-lab.sh to be used by ministat and/or gnuplot
# 
set -eu

# An usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

data_2_ministat () {
	# Convert raw data file from bench-lab.sh for list
	# $1 : Input file
	# $2 : Prefix of the output file
	local LINES=`wc -l $1`
	LINES=`echo ${LINES} | cut -d ' ' -f1`
	# Remove the first 15 lines (garbage or not good result) and the 10 last lines (bad result too)
	head -n `expr ${LINES} - 10` $1 | tail -n `expr ${LINES} - 10 - 15` > /tmp/clean.1.data
	# Filter the output (still filtering "0 pps" lines in case of) and kept only the numbers:
	# example of good line:
	# 290.703575 main_thread [1441] 729113 pps (730571 pkts in 1002000 usec)
	grep -E 'main_thread[[:space:]]\[[[:digit:]]+\][[:space:]][1-9].*pps' /tmp/clean.1.data | cut -d ' ' -f 4 > /tmp/clean.2.data
	#Now we calculate the median value of this run with ministat
	echo `ministat -n /tmp/clean.2.data | tail -n -1 | tr -s ' ' | cut -d ' ' -f 5` >> ${LAB_RESULTS}/$2
	rm /tmp/clean.1.data /tmp/clean.2.data || die "ERROR: can't delete clean.X.data"
	return 0
}

data_2_gnuplot () {
	# Now we will generate .dat file with name like: forwarding.dat
	# and contents like:
	# revision  pps
	# revision  pps
	# this file can be used for gnuplot
	if [ -n "${CFG_LIST}" ]; then
		# For each CFG detected previously
		for CFG_TYPE in ${CFG_LIST}; do
			echo "# revision	pps" > ${LAB_RESULTS}/${CFG_TYPE}.data
			# For each file regarding the CFG (one file by revision)
			# But don't forget to exclude the allready existing CFG_TYPE.plot file from the result
			for DATA in `ls -1 ${LAB_RESULTS} | grep "[[:punct:]]${CFG_TYPE}$"`; do
				local REV=`basename ${DATA}`
				REV=`echo ${REV} | cut -d '.' -f 1`
				# Get the median value regarding all test iteration
				local PPS=`ministat -n ${LAB_RESULTS}/${DATA} | tail -n -1 | tr -s ' ' | cut -d ' ' -f 5` 
				echo "${REV}	${PPS}" >> ${LAB_RESULTS}/${CFG_TYPE}.data
			done
		done	
	else
		echo "TODO: plot.dat when different configuration sets are not used"	
	fi
	return 0
}

## main

SVN=''
CFG=''
CFG_LIST=''

[ $# -ne 1 ] && die "usage: $0 benchs-directory"
[ -d $1 ] || die "usage: $0 benchs-directory"

LAB_RESULTS="$1"
# Info: /tmp/benchs/bench.1.1.4.receiver

INFO_LIST=`ls -1 ${LAB_RESULTS}/*.info`
[ -z "${INFO_LIST}" ] && die "ERROR: No report files found in ${LAB_RESULTS}"

echo "Summaring results..."
for INFO in ${INFO_LIST}; do
	# Get svn rev number
	#  Image: /tmp/BSDRP-244900-upgrade-amd64-serial.img
	#  Image: /monpool/benchs-images/BSDRP-244900-upgrade-amd64-serial.img.xz
	#  => 244900 
	SVN=`grep 'Image: ' ${INFO} | cut -d ':' -f 2`
	# =>  /monpool/benchs-images/BSDRP-244900-upgrade-amd64-serial.img.xz
	SVN=`basename ${SVN} | cut -d '-' -f 2`
	# => 244900
	# Get CFG file name
	#  CFG: /tmp/bench-configs/forwarding
	#  => forwarding
	if grep -q 'CFG: ' ${INFO}; then
		CFG=`grep 'CFG: ' ${INFO} | sed 's/CFG: //g'`
		CFG=`basename ${CFG}`
		MINISTAT_FILE="${SVN}.${CFG}"
		# If not already, add the configuration type to the list of detected configuration
		echo ${CFG_LIST} | grep -w -q ${CFG} || CFG_LIST="${CFG_LIST} ${CFG}"
	else
		MINISTAT_FILE="${SVN}"
	fi
	# Now need to generate ministat input file for each different REPORT
	#   if report is: /tmp/benchs/bench.1.1.info
	#   => list all file like /tmp/benchs/bench.1.1.*.receiver
	DATA_LIST=`echo ${INFO} | sed 's/info/*/g'`
	DATA_LIST=`ls -1 ${DATA_LIST} | grep receiver`
	# clean allready existing ministat
	[ -f ${LAB_RESULTS}/${MINISTAT_FILE} ] && rm ${LAB_RESULTS}/${MINISTAT_FILE}
	for DATA in ${DATA_LIST}; do
		data_2_ministat ${DATA} ${MINISTAT_FILE}
	done # for DATA
done # for REPORT
echo "Gnuplot generation..."
data_2_gnuplot

echo "Done"
exit
