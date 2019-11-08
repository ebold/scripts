#!/bin/bash

# This is an optional script to present the monitoring data in graphs.
# It sends monitoring data prepared by gateways to a Graphite host
# using the UDP protocol.

# Check argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 server_IP_address"
	exit 1
fi

# Graphite host IP address and port
SERVERIP=$1
SERVERPORT=2003

# device name (used as metric path)
NODEGW0=scuxl0223
NODEGW1=scuxl0228
NODEGW2=scuxl0068

# directory with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
GWDATA=gw
GW0=unipz
GW1=milsis
GW2=milesr
GW_ARRAY=()

# data files
OFFSET=offset
SYNC=status
STALLMAX=stallmax
STALLACT=stallact
RATE10S=rate10s
RATE1M=rate1m
RATE1H=rate1h
LATE=late
NOBEAM=nobeam

# polling interval
INTERVAL=30

# arrays with monitoring data files
IDX=0
MONDATA_DIR=$MONDATA/$GWDATA
MONDATA_FILES=()

# check if files with monitoring data exist
for i in `seq 0 1 2`; do
	GW=GW$i
	GWNODE=NODEGW$i
	GW_ARRAY[$i]="${!GW}:${!GWNODE}"

	FILE_PATH=$MONDATA_DIR/${!GW}/$OFFSET
	if [ -f $FILE_PATH ]; then
		MONDATA_FILES[IDX]=$FILE_PATH
	else
		echo "File not found: $FILE_PATH"
	fi

	IDX=`expr $IDX + 1`

	FILE_PATH=$MONDATA_DIR/${!GW}/$SYNC
	if [ -f $FILE_PATH ]; then
		MONDATA_FILES[IDX]=$FILE_PATH
	else
		echo "File not found: $FILE_PATH"
	fi

	IDX=`expr $IDX + 1`

	FILE_PATH=$MONDATA_DIR/${!GW}/$STALLMAX
	if [ -f $FILE_PATH ]; then
		MONDATA_FILES[IDX]=$FILE_PATH
	else
		echo "File not found: $FILE_PATH"
	fi

	IDX=`expr $IDX + 1`

	FILE_PATH=$MONDATA_DIR/${!GW}/$STALLACT
	if [ -f $FILE_PATH ]; then
		MONDATA_FILES[IDX]=$FILE_PATH
	else
		echo "File not found: $FILE_PATH"
	fi

	IDX=`expr $IDX + 1`

	FILE_PATH=$MONDATA_DIR/${!GW}/$RATE10S
	if [ -f $FILE_PATH ]; then
		MONDATA_FILES[IDX]=$FILE_PATH
	else
		echo "File not found: $FILE_PATH"
	fi

	IDX=`expr $IDX + 1`

	FILE_PATH=$MONDATA_DIR/${!GW}/$RATE1M
	if [ -f $FILE_PATH ]; then
		MONDATA_FILES[IDX]=$FILE_PATH
	else
		echo "File not found: $FILE_PATH"
	fi

	IDX=`expr $IDX + 1`

	FILE_PATH=$MONDATA_DIR/${!GW}/$RATE1H
	if [ -f $FILE_PATH ]; then
		MONDATA_FILES[IDX]=$FILE_PATH
	else
		echo "File not found: $FILE_PATH"
	fi
done

# exit here if no file with monitoring data is found
if [ ${#MONDATA_FILES[*]} -eq 0 ]; then
	echo "No files with monitoring data found in $MONDATA_DIR. Exit!"
	exit 1
fi

#echo ${MONDATA_FILES[*]}

# main stuff
while true; do

	# update timestamp
	TIMESTAMP=`date +%s`

	# read each file with monitoring data and send it to Graphite host
	for MONDATA_FILE in "${MONDATA_FILES[@]}"; do

		GW_AND_FILE=${MONDATA_FILE#${MONDATA_DIR}/}   # get 'unipz/offset' from full path
		GW_NAME=${GW_AND_FILE%%/*}                    # get 'unipz'
		METRIC_NAME=${GW_AND_FILE##*/}                # get 'offset'

		# read monitoring data
		METRIC_VAL=$(tail -1 $MONDATA_DIR/$GW_NAME/$METRIC_NAME)

		# convert WR sync status to numeric value
		if [ "$METRIC_NAME" == "$SYNC" ]; then
			case $METRIC_VAL in
				"TRACKING") NUM_VAL=100;;
				"NO SYNC")  NUM_VAL=20;;
				*)  NUM_VAL=0;;
			esac
			METRIC_VAL=$NUM_VAL
		fi

		# if metric value is available then send it
		if [ "$METRIC_VAL" != "" ]; then

			GW_NODE="any"
			for gw in "${GW_ARRAY[@]}"; do             # 'unipz:scuxlXYZ'
				if [ "$GW_NAME" == "${gw%%:*}" ]; then # check 'unipz' part
					GW_NODE=${gw##*:}                  # get 'scuxlXYZ'
					break
				fi
			done

			# send metric key, metric value and timestamp to the Graphite host
			METRIC_KEY=${GWDATA}.$GW_NAME.${GW_NODE}.${METRIC_NAME}
			echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
		fi
	done

	sleep $INTERVAL
done