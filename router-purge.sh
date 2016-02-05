#!/bin/bash
# https://github.com/trystack/trystack-utils
# Name:        router-purge.sh
# Written by:  Kambiz Aghaiepour
# Purpose:     clear gateway on routers if set longer than THRESHOLD
#
# This script should be run hourly via CRON
# router-query.sh will manage the data stored in ROUTERDB
# 
#
####
#  ROUTERDB format:
#   each router is stored on a single line as:
#     "$routerid,$routerip,$seconds_since_epoch"
####
# Future improvement(s)
#   * argument parsing
#   * python port
#################################################

source /root/keystonerc_trystack

ROUTERDB=/root/routerdb
HOURS=12
THRESHOLD=$(expr 60 \* 60 \* $HOURS)
CURDATE=$(date +%s)

function gw_purge() {
  id=$1
  ip=$2
  alloctime=$3

  if [ "$(expr $CURDATE - $alloctime)" -gt $THRESHOLD ]; then
    neutron router-gateway-clear $id 1>/dev/null 2>&1
  fi
}

for routerentry in $(cat $ROUTERDB) ; do
  routerid=$(echo $routerentry | awk -F, '{ print $1 }')
  routerip=$(echo $routerentry | awk -F, '{ print $2 }')
  routertime=$(echo $routerentry | awk -F, '{ print $3 }')

  gw_purge $routerid $routerip $routertime
done

