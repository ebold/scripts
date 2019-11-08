#!/bin/bash

# This is an optional script used to present the data master and ECA statistics in graphs.
# The ECA statistics are obtained from several SCUs, which are located at the
# different layers/levels of the timing network.
# The UDP protocol is used to send statistics data to a Graphite host.

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
fi

# Graphite host and port
SERVERIP=$1
SERVERPORT=2003

# device name (used in metric path)
DM=ZT00ZZ1
LAYER1SCU="PRO.1.scuxl0338"
LAYER2SCU="PRO.2.scuxl0302"
LAYER3SCU="PRO.3.scuxl0283"
LAYER4SCU="INT.2.scuxl0404"
LAYER5SCU="INT.3.scuxl0363"
LAYER6SCU="DEV.2.scuxl0390"
LAYER7SCU="DEV.3.scuxl0382"

# directories with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
DMDATA=dm
CPU0DATA=cpu0
CPU1DATA=cpu1
CPU2DATA=cpu2
CPU3DATA=cpu3
CPUXDATA=total
WRDATA=wr
ECADATA=eca

CPUS=($CPU0DATA $CPU1DATA $CPU2DATA $CPU3DATA $CPUXDATA)

# files with statistics
RATE10S=rate10s
RATE1M=rate1m
RATE1H=rate1h

WRATE10S=wrate10s
WRATE1M=wrate1m
WRATE1H=wrate1h

DTMAX=dtmax
DTMIN=dtmin
DTAVE=dtave
NMESS=nmess
NLATE=nlate

STATUS=status    # WR sync status

RATES=($RATE10S)
WRATES=($WRATE10S)
ECA_STATS=($DTMAX $DTMIN $DTAVE $NMESS $NLATE)
LAYERS=(l1 l2 l3 l4 l5 l6 l7)
SCUS=("l1:$LAYER1SCU" "l2:$LAYER2SCU" "l3:$LAYER3SCU" "l4:$LAYER4SCU" \
	"l5:$LAYER5SCU" "l6:$LAYER6SCU" "l7:$LAYER7SCU")

# polling interval
INTERVAL=30

# arrays with port statistics files
IDX=0
MONDATA_DIR=$MONDATA/$DMDATA
MONDATA_FILES=()

# check if files ($MONDATA_DIR/cpu0/rate10s) with CPU statistics exist
for cpu in "${CPUS[@]}"; do

	for rate in "${RATES[@]}"; do
		FILE_PATH=$MONDATA_DIR/$cpu/$rate
		if [ -f $FILE_PATH ]; then
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`
	done

	for rate in "${WRATES[@]}"; do
		FILE_PATH=$MONDATA_DIR/$cpu/$rate
		if [ -f $FILE_PATH ]; then
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`
	done

done

# check if files ($MONDATA_DIR/wr/status) with WR sync status exist
FILE_PATH=$MONDATA_DIR/$WRDATA/$STATUS
if [ -f $FILE_PATH ]; then
	MONDATA_FILES[IDX]=$FILE_PATH
else
	echo "File not found: $FILE_PATH"
fi

IDX=`expr $IDX + 1`

# check if files ($MONDATA_DIR/eca/l1dtmax) with ECA statistics exist
for layer in "${LAYERS[@]}"; do

	for stat in "${ECA_STATS[@]}"; do
		FILE_PATH=$MONDATA_DIR/$ECADATA/${layer}$stat
		if [ -f $FILE_PATH ]; then
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`
	done
done

# exit here if no file with monitoring data is found
if [ ${#MONDATA_FILES[*]} -eq 0 ]; then
	echo "No files with monitoring data found in $MONDATA_DIR. Exit!"
	exit 1
else
	echo "List of files with monitoring data:"
	for file in "${MONDATA_FILES[@]}"; do
		echo $file
	done
	echo "Sending monitoring data to $SERVERIP:$SERVERPORT every $INTERVAL seconds."
fi

# main stuff
while true; do

	# update timestamp
	TIMESTAMP=`date +%s`

	# read each file with monitoring data and send it to Graphite host
	for MONDATA_FILE in "${MONDATA_FILES[@]}"; do

		# read monitoring data
		METRIC_VAL=$(tail -1 $MONDATA_FILE)

		# if metric value is available then send it
		if [ "$METRIC_VAL" != "" ]; then

			METRIC_ALL=${MONDATA_FILE#${MONDATA_DIR}/}        # get 'cpu?/rate*', 'eca/l1dtmax', 'wr/status' from full path
			METRIC_ALL_GRAPH=${METRIC_ALL////.}               # replace all matching '/' with '.' (Graphite compatible)
			METRIC_NAME=${METRIC_ALL_GRAPH##*.}               # get 'rate*', 'l1dtmax' or 'status'

			# check metric origin: CPU or ECA statistics
			if [ "${METRIC_ALL_GRAPH:0:4}" == "eca." ]; then
				LAYER_AND_ECA_METRIC=${METRIC_ALL_GRAPH##eca.}  # get 'l1dtmax' from 'eca.l1dtmax'
				LAYER=${LAYER_AND_ECA_METRIC:0:2}               # get 'l1' from 'l1dtmax'
				ECA_METRIC=${LAYER_AND_ECA_METRIC:2}            # get 'dtmax' from 'l1dtmax'

				# check which metric is it: ECA or CPU statistics
				if [ "$LAYER" != "" ] && [ "$ECA_METRIC" != "" ]; then
					for scu in "${SCUS[@]}"; do                     # scu = l1:PRO.1.scuxl0338
						if [ "$LAYER" == "${scu%%:*}" ]; then
							SCU=${scu##*:}
							METRIC_KEY=${DMDATA}.eca.${SCU}.$ECA_METRIC # build ECA metric key: dm.eca.PRO.1.scuxlXYZ.dtmax
							break
						fi
					done
				fi
			else
				METRIC_KEY=${DMDATA}.${DM}.$METRIC_ALL_GRAPH    # build metric key: dm.ZT00ZZ1.cpu*|total.rate*
			fi

			# convert WR sync status to numeric value
			if [ "$METRIC_NAME" == "$STATUS" ]; then
				METRIC_VAL=$(get_sync_numeric "$METRIC_VAL")
			fi

			# send metric key, metric value and timestamp to the Graphite host
			if [ "$METRIC_KEY" != "" ]; then
				echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
			fi
		fi
	done

	sleep $INTERVAL
done
