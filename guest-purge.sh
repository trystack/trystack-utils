#!/bin/bash
# https://github.com/trystack/trystack-utils
#
# Name:        guest-purge.sh
# Written by:  Kambiz Aghaiepour
# Purpose:     Purge guests older than THRESHOLD
#
# This script should be run hourly via CRON
# 
#
####
# Future improvement(s)
#   * argument parsing
#   * python port
#################################################

source /root/keystonerc_trystack

HOURS=24
THRESHOLD=$(expr 60 \* 60 \* $HOURS)
CURDATE=$(date +%s)

function guest_purge() {
  id=$1
  createdon=$(date -d $(nova show $id | grep created | awk '{ print $4 }') +%s)
  if [ "$(expr $CURDATE - $createdon)" -gt "$THRESHOLD" ]; then
    nova delete $id 1>/dev/null 2>&1
  fi
}

for tenant in $(keystone tenant-list | grep facebook | awk '{ print $2 }') ; do
  for guest in $(nova list --tenant $tenant --all-tenants --field id | egrep -v '^\+|^\| ID' | awk '{ print $2 }') ; do
    guest_purge $guest
  done
done

