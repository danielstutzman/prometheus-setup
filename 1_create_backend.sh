#!/bin/bash -ex

INSTANCE_IP=`tugboat droplets | grep 'monitoring ' | egrep -oh "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" || true`
echo INSTANCE_IP=$INSTANCE_IP

if [ "$INSTANCE_IP" == "" ]; then
  echo "Creating new instance..."
  # Run tugboat keys to find the 2006244 ID number
  tugboat create monitoring -k 2006244 -s 512MB -r nyc1 -i ubuntu-14-04-x64
  tugboat wait -n monitoring
fi
