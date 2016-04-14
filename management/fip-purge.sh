#!/bin/bash
#
# Name:        fip-purge.sh
# Written by:  Kambiz Aghaiepour
# Purpose:     Purge fips allocated for longer than THRESHOLD
#
# This script should be run hourly via CRON
# Another script will manage the data stored in FIPDB
# 
#
####
#  FIPDB format:
#   each FIP is stored on a single line as:
#     "$fipid,$fipip,$seconds_since_epoch"
####
# Future improvement(s)
#   * argument parsing
#   * python port
#################################################

source /root/keystonerc_trystack

FIPDB=/root/fipdb
HOURS=12
THRESHOLD=$(expr 60 \* 60 \* $HOURS)
CURDATE=$(date +%s)

# example egrep regext match to spare
SPARELIST="kambiz|student"

function fip_purge() {
  id=$1
  ip=$2
  alloctime=$3

  if [ "$(expr $CURDATE - $alloctime)" -gt $THRESHOLD ]; then
    # proceed with disassociation and release
    # First determine port ID for fip
    port_id=$(neutron floatingip-show $id | grep port_id | awk -F\| '{ print $3 }' | sed 's/ //g')

    # if there is a port_id, then we have to disassociate the fip from a guest
    if [ -n "$port_id" ]; then
      device_id=$(neutron port-show $port_id | grep device_id | awk -F\| '{ print $3 }' | sed 's/ //g')
      # at this point, the device_id is the VM from which to disassociate
      nova floating-ip-disassociate $device_id $ip 1>/dev/null 2>&1
    fi
    neutron floatingip-delete $id 1>/dev/null 2>&1
  fi
}

for fipentry in $(cat $FIPDB) ; do
  fipid=$(echo $fipentry | awk -F, '{ print $1 }')
  fipip=$(echo $fipentry | awk -F, '{ print $2 }')
  fiptime=$(echo $fipentry | awk -F, '{ print $3 }')

  owner_id=$(neutron floatingip-show $fipid | grep tenant_id | awk -F\| '{ print $3 }' | sed 's/ //g')
  owner_name=$(keystone tenant-get $owner_id 2>/dev/null | grep name | awk -F\| '{ print $3 }' | sed 's/ //g')

  if [ "$(echo $owner_name | egrep "$SPARELIST")" ]; then
    # spare the FIP ...
    :
  else
    fip_purge $fipid $fipip $fiptime
  fi
done

