#!/bin/bash

# This script is used to launch the push scripts that
# send GMT monitoring data to Grafana running on the tsl019 host.

N_USER_ARGUMENTS=1

usage() {
  echo "Usage: $0 grafana_host"
  echo "where:"
  echo "  grafana_host   - domain name or IP address of a Grafana host"
  echo
}

# Check command line arguments
if [ $# -ne $N_USER_ARGUMENTS ]; then
  usage
  exit 1
fi

GRAFANA_HOST=$1

# Terminate running scripts
killall push-dm-mon.sh
killall push-nw-mon.sh
killall push-gw-mon.sh
killall push-tr-mon.sh
killall push-diag-mon.sh
killall push-uni-mon.sh

# Start scripts
push-dm-mon.sh $GRAFANA_HOST &
push-nw-mon.sh $GRAFANA_HOST &
push-gw-mon.sh $GRAFANA_HOST &
push-tr-mon.sh $GRAFANA_HOST &
push-diag-mon.sh $GRAFANA_HOST &
push-uni-mon.sh $GRAFANA_HOST &
