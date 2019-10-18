#!/bin/sh

# Send TR metrics for Graphite

if [ $# -ne 1 ]; then
	echo "Syntax: $0 destination_IP_address"
	exit 1
fi

SERVERIP=$1
SERVERPORT=2003
HOSTNAME="test.tr.`hostname`"
INTERVAL=30
COUNT=200

while [ $COUNT -ne 0 ]
do
	TIMESTAMP=`date +%s`
	STATUS=`eb-mon -s -o dev/wbm0 2>/dev/null`
	echo $STATUS

	if [ $? -ne 0 ]; then
		LOCK="U"
		OFFSET="0"
	else
		LOCK=$(echo $STATUS | cut -d" " -f2)
		case $LOCK in
			"TRACKING") LOCK=100;;
			*) LOCK=0;;
		esac
		OFFSET=$(echo $STATUS | cut -d" " -f1)
	fi

	echo "$HOSTNAME.lock $LOCK $TIMESTAMP" | nc $SERVERIP $SERVERPORT
	echo "$HOSTNAME.offset $OFFSET $TIMESTAMP" | nc $SERVERIP $SERVERPORT

	COUNT=`expr $COUNT - 1`
	if [ $COUNT -ne 0 ]; then
		sleep $INTERVAL
	fi
done
