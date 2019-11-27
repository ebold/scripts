#!/bin/bash

# This is an optional script used to present the WR switch statistics in graphs.
# It calculates the TX and RX frame rate in 30 seconds interval and sends then
# to a Graphite host using the UDP protocol.

# Check argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 Graphite_host (host.domain or IP address)"
	exit 1
fi

# load common functions
COMMON_SCRIPT="push-common.sh"
if [ -f $COMMON_SCRIPT ]; then
	source $COMMON_SCRIPT
else
	echo "Missing $COMMON_SCRIPT. Exit!"
	exit 1
fi

# Graphite host and port
SERVERIP=$1
SERVERPORT=2003

# SNMP options to get TX/RX frame counts
SNMP_OPTIONS="-Oe -Oq -c public -v 2c -m ALL -M +/common/usr/timing/htdocs/cgi-bin/admin/snmpd"

# WRS in timing network
WRS1="nwt0029m66:192.168.20.42:user:1"   # device:ip:net:layer
WRS2="nwt0043m66:192.168.20.56:user:2"
WRS3="nwt0027m66:192.168.20.40:user:3"
WRS4="nwt0074m66:192.168.20.74:user:4"
WRS_ALL=("$WRS1" "$WRS2" "$WRS3" "$WRS4")

# directory with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
WRS=icinga/wrs
MONDATA_DIR=$MONDATA/$WRS
TMP_FILE=$MONDATA_DIR/wrs_frames

# intervals
INTERVAL_SEND=30
INTERVAL_POLL=30

# setup
setup() {
	if [ ${#WRS_ALL[*]} -eq 0 ]; then
		echo "No WR switch is specified. Exit!"
		exit 1
	else
		if [ ! -d $MONDATA_DIR ]; then
			echo "Creating directory: $MONDATA_DIR"
			mkdir -p $MONDATA_DIR
		fi
		echo "WR switches under monitoring (TX/RX frame rate):"
		for wrs in "${WRS_ALL[@]}"; do
			IFS=':' read -r -a wrs_v <<< $wrs
			# clear existing files with frame counts
			echo -n "" > $MONDATA_DIR/${wrs_v[0]}_TX_Frames
			echo -n "" > $MONDATA_DIR/${wrs_v[0]}_RX_Frames

			# print short info
			echo "wrs=${wrs_v[0]} ip=${wrs_v[1]} net=${wrs_v[2]} layer=${wrs_v[3]}"
		done
		echo "Sending TX/RX frame rate to $SERVERIP:$SERVERPORT every $INTERVAL_SEND seconds."
	fi
}

# look for rate files and send their content to Graphite
send_port_stats() {
	local RATE_FILES=$(ls $MONDATA_DIR/*Rates)
	for filepath in ${RATE_FILES[@]}; do
		while read -r line; do
			if [ "$line" != "" ]; then
				IFS=' ' read -r -a line_v <<< $line
				if [ ${line_v[1]} -ne 0 ]; then
					attr=${filepath##${MONDATA_DIR}/} # strip longest match from front of $filepath
					IFS='_' read -r -a relpath_v <<< $attr
					WRS_DEV=${attr_v[0]}

					for wrs in ${WRS_ALL[@]}; do
						IFS=':' read -r -a wrs_v <<< $wrs

						if [ "$WRS_DEV" == "${wrs_v[0]}" ]; then
							WRS_IP_ADDR=${wrs_v[1]}
							WRS_NETWORK=${wrs_v[2]}
							WRS_LAYER=${wrs_v[3]}

							# set metric key: wrs.network.layer.device.port.direction
							METRIC_KEY="wrs.${WRS_NETWORK}.${WRS_LAYER}.${WRS_DEV}.${line_v[0]}.${attr_v[1]}"
							# send metric to Graphite host
							echo "$METRIC_KEY ${line_v[1]} $1" | nc $SERVERIP -u $SERVERPORT
						fi
					done
				fi
			fi
		done < $filepath
	done
}

# evaluate frame rate and optionally send them to Graphite
do_almost_all() {
	for wrs in ${WRS_ALL[@]}; do

		IFS=':' read -r -a wrs_v <<< $wrs
		WRS_DEV=${wrs_v[0]}
		WRS_IP_ADDR=${wrs_v[1]}
		WRS_NETWORK=${wrs_v[2]}
		WRS_LAYER=${wrs_v[3]}

		# files to store TX/RX frame counts
		TX_FRAMES=$MONDATA_DIR/${WRS_DEV}_TX_Frames
		RX_FRAMES=$MONDATA_DIR/${WRS_DEV}_RX_Frames

		for filepath in $TX_FRAMES $RX_FRAMES; do

			local PREV=()
			local IDX=0

			# read previous frame count
			if [ -f $filepath ]; then
				while IFS= read -r line; do        # line format: port frames, i.e., 1 0
					if [ "$line" != "" ]; then
						PREV[$IDX]=$line
						IDX=`expr $IDX + 1`
					fi
				done < $filepath
				#echo "PREV: ${PREV[@]}"
			fi
			N_PREV=$IDX

			# get frame count
			DIRECTION="XX"
			if [[ "$filepath" == *"TX"* ]]; then # numerical position of 1st character of $TX_FRAMES in $filepath (0 if no match)
				DIRECTION="TX"
				OID="WR-SWITCH-MIB::wrsPstatsTXFrames"

			elif [[ "$filepath" == *"RX"* ]]; then
				DIRECTION="RX"
				OID="WR-SWITCH-MIB::wrsPstatsRXFrames"
			else
				echo "nor TX neither RX!"
				continue
			fi

			# send SNMP query
			ts=$(date +%s)
			snmpwalk $SNMP_OPTIONS $WRS_IP_ADDR $OID > $TMP_FILE

			local CURRENT=()
			IDX=0
			echo -n "" > $filepath

			if [ -f $TMP_FILE ]; then
				while IFS= read -r line; do          # line: WR-SWITCH-MIB::wrsPstatsRXFrames.1 0
					if [ "$line" != "" ]; then
						CURRENT[$IDX]="${line##*.}"      # get '1 0' part from line
						echo "${CURRENT[$IDX]}" >> $filepath
						IDX=`expr $IDX + 1`
					fi
				done < $TMP_FILE
				#echo "CURRENT: ${CURRENT[@]}"
			fi

			local RATES=()
			N_CURRENT=$IDX

			# calculate frame rate
			if [ $N_PREV -eq 0 ] && [ $N_CURRENT -eq 0 ]; then
				echo "Cannot get frame count."
				continue
			elif [ $N_PREV -eq $N_CURRENT ]; then
				IDX=0
				while [ $IDX -lt $N_CURRENT ]; do
					IFS=' ' read -r -a last_v <<< "${PREV[$IDX]}"
					IFS=' ' read -r -a curr_v <<< "${CURRENT[$IDX]}"
					rate=$(expr ${curr_v[1]} - ${last_v[1]})
					RATES[$IDX]="${curr_v[0]}:$rate"

					# set metric key: wrs.network.layer.device.port.direction
					METRIC_KEY="wrs.${WRS_NETWORK}.${WRS_LAYER}.${WRS_DEV}.${curr_v[0]}.${DIRECTION}"

					if [ "$1" == "send" ]; then
						if [ $rate -ne 0 ]; then
							# send metric to Graphite host
							echo "$METRIC_KEY $rate $ts" | nc $SERVERIP -u $SERVERPORT
						fi
					elif [ "$1" == "test" ]; then
						# output for debug
						echo "$METRIC_KEY $rate $ts"
					fi

					IDX=`expr $IDX + 1`
				done

				# save to file
				if [ ${#RATES[@]} -ne 0 ]; then
					#echo "${RATES[@]}"
					# frame rate is stored in nwt01234m66_TX_30s_Rates file
					RATE_FILE=$MONDATA_DIR/${WRS_DEV}_${DIRECTION}_${INTERVAL_POLL}s_Rates
					echo -n "" > $RATE_FILE
					for rate in ${RATES[@]}; do
						echo "$rate" >> $RATE_FILE
					done
				fi
			else
				echo "Cannot calculate frame rate: last=$N_PREV now=$N_CURRENT"
				continue
			fi

		done
	done
}


# main stuff

# setup
setup

while true; do

	# do all (required argument: send | test)
	do_almost_all "send"

	# make pause
	sleep $INTERVAL_SEND

done
