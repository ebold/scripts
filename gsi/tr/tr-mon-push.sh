#!/bin/bash

# Send TR monitoring data to a Graphite server

# Check argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 server_IP_address"
	exit 1
fi

# Graphite server IP address and port
SERVERIP=$1
SERVERPORT=2003

# snooper name (used as metric path)
TRNOMEN=ZT00ZM0

# directory with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
TRDATA=tr

# data files
LATEN=laten
EARLYN=earlyn
OVERFLOWN=overflown
ACTIONN=actionn

# collect interval
INTERVAL=30
COUNT=200

# main stuff
while [ $COUNT -ne 0 ]; do

    # update timestamp
    TIMESTAMP=`date +%s`

    for i in `seq 1 2`; do

        NOMEN=${TRNOMEN}${i}

	# get metrics value
        LATECNT=$(cat $MONDATA/$TRDATA/$i/$LATEN)
	EARLYCNT=$(cat $MONDATA/$TRDATA/$i/$EARLYN)
	OVERFLOWCNT=$(cat $MONDATA/$TRDATA/$i/$OVERFLOWN)
	ACTIONCNT=$(cat $MONDATA/$TRDATA/$i/$ACTIONN)

	# send metric path, metric value and timestamp to the Graphite server
	echo "$NOMEN.late $LATECNT $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
	echo "$NOMEN.early $EARLYCNT $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
	echo "$NOMEN.overflow $OVERFLOWCNT $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
	echo "$NOMEN.action $ACTIONCNT $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT

    done

	COUNT=`expr $COUNT - 1`
	if [ $COUNT -ne 0 ]; then
	    sleep $INTERVAL
	fi
done
