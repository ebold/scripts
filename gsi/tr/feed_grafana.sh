#!/bin/bash

# This script is used to launch the push scripts that
# send GMT monitoring data to Grafana running on the tsl019 host.

GRAFANA_HOST=tsl019.acc.gsi.de

# Terminate running scripts
killall push-dm-mon.sh
killall push-prod-lm-mon.sh
killall push-gw-mon.sh
killall push-tr-mon.sh
killall push-diag-mon.sh
killall push-uni-mon.sh

# Start scripts
push-dm-mon.sh $GRAFANA_HOST &
push-prod-lm-mon.sh $GRAFANA_HOST &
push-gw-mon.sh $GRAFANA_HOST &
push-tr-mon.sh $GRAFANA_HOST &
push-diag-mon.sh $GRAFANA_HOST &
push-uni-mon.sh $GRAFANA_HOST &
