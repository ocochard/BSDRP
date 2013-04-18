#!/bin/sh
#Remove the first 15 lines and the last 10 lines (garbage):

#f='bench.1.2.1.receiver'; g=`wc -l $f`; h=`echo $g | cut -d ' ' -f1`; head -n `expr $h - 10 ` $f | tail -n `expr $h - 15 `

#Filter the output (still filtering "0 pps" lines… in case of):

#grep -E '^main[[:space:]]\[[[:digit:]]+\][[:space:]][1-9].*pps$'

#Keeping the number:

#cut -d ' ' -f 3

#Putting the output on ministat, and get the median result

#ministat -n /tmp/mini | tail -n -1 | tr -s ' ' | cut -d ' ' -f 5

set -eu
LAB_RESULTS="/tmp/benchs"
# Info: /tmp/benchs/bench.1.1.4.receiver

# An usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

data_2_ministat () {
	# Convert raw data file from bench-lab.sh for list
	# $1 : Input file
	# $2 : Prefix of the file
	local LINES=`wc -l $1`
	LINES=`echo ${LINES} | cut -d ' ' -f1`
	# Remove the first 15 lines (garbage or not good result) and the 10 last lines (bad result too)
	head -n `expr ${LINES} - 10` $1 | tail -n `expr ${LINES} - 10 - 15` > /tmp/clean.1.data
	# Filter the output (still filtering "0 pps" lines… in case of) and kept only the numbers:
	grep -E '^main[[:space:]]\[[[:digit:]]+\][[:space:]][1-9].*pps$' /tmp/clean.1.data | cut -d ' ' -f 3 > /tmp/clean.2.data
	#Now we calculate the median value of this run with ministat
	echo `ministat -n /tmp/clean.2.data | tail -n -1 | tr -s ' ' | cut -d ' ' -f 5` >> ${LAB_RESULTS}/$2
	#rm /tmp/clean.1.data /tmp/clean.2.data
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
			echo "# revision	pps" > ${CFG_TYPE}.plot
			# For each file regarding the CFG (one file by revision)
			# But don't forget to exclude the allready existing CFG_TYPE.plot file from the result
			for DATA in `ls -1 ${LAB_RESULTS} | grep "[[:punct:]]${CFG_TYPE}"`; do
				local REV=`basename ${DATA}`
				REV=`echo ${REV} | cut -d '.' -f 1`
				# Get the median value regarding all test iteration
				local PPS=`ministat -n ${DATA} | tail -n -1 | tr -s ' ' | cut -d ' ' -f 5` 
				echo "${REV}	${PPS}" >> ${CFG_TYPE}.plot
			done
		done	
	else
		echo "TODO: plot.dat"	
	fi
	return 0
}

## main

SVN=''
CFG=''
CFG_LIST=''

INFO_LIST=`ls -1 ${LAB_RESULTS}/*.info`
[ -z "${INFO_LIST}" ] && die "No report files?"

for INFO in ${INFO_LIST}; do
	# Get svn rev number
	#  Image: /tmp/BSDRP-244900-upgrade-amd64-serial.img
	#  => 244900 
	SVN=`grep 'Image: ' ${INFO} | cut -d '-' -f 2`
	# Get CFG file name
	#  CFG: /tmp/bench-configs/forwarding
	#  => forwarding
	if grep -q 'CFG: ' ${INFO}; then
		CFG=`grep 'CFG: ' ${INFO} | sed 's/CFG: //g'`
		CFG=`basename ${CFG}`
		MINISTAT_FILE="${SVN}.${CFG}"
		# If not already, add the configuration type to the list of detected configuration
		echo ${CFG_LIST} | grep -q ${CFG} || CFG_LIST="${CFG_LIST} ${CFG}"
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

data_2_gnuplot

echo "Done"
exit
