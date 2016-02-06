#!/bin/bash
# https://github.com/trystack/trystack-utils
#
# Name:        fip-query.sh
# Written by:  Kambiz Aghaiepour
# Purpose:     Track the FIPs allocated in a flat file
#              Excludes specific tenant IDs.  This preserves
#              the "special" cases such as services, or rdo-ci.
#
# This script should be run frequently via CRON, and another
# script will use the data stored in FIPDB to release FIPs from
# projects/tenants
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

FIPLIST=$(mktemp /tmp/fiplistXXXXXX)
FIPDB=/root/fipdb
FIPDB_ARCHIVE=/root/fipdb.d

function cleanup () {
  rm -f $FIPLIST
}

function fiplist () {
  neutron floatingip-list | egrep -v '^\+|fixed_ip_address' | awk -F\| '{ print $2","$4 }' | sed 's/ //g' > $FIPLIST
}

function fipdbupdate () {
  if [ ! -r $FIPLIST ]; then
    return 1
  fi
  FIPDBTEMP=$(mktemp /tmp/fibdbXXXXXX)
  if [ ! -e $FIPDB ]; then
    touch $FIPDB
  fi
  for fip in $(cat $FIPLIST) ; do

     fipid=$(echo $fip | awk -F, '{ print $1 }')
     fipip=$(echo $fip | awk -F, '{ print $2 }')

     if egrep -q "^$fipid,$fipip" $FIPDB ; then
       if [ -z $(egrep "^$fipid,$fipip" $FIPDB | awk -F, '{ print $4 }') ]; then
         append=",$(neutron floatingip-show $fipid | grep tenant | awk '{ print $4 }')"
       else
         append=""
       fi
       echo $(egrep "^$fipid" $FIPDB)$append >> $FIPDBTEMP
     else

# Here we exclude tenants we don't want to cull resources from
# 4c1419ed8a5645fc81140a794da591f1 == excluded tenant #1
# f68e039b76a6462aa4a622d9308c0bfd == excluded tenant #2
# 974209cea9c3402e977120b5d02d500b == excluded tenant #3
# 1741d223007940d5883c10d2293df015 == excluded tenant #4

exclude_tenant1='4c1419ed8a5645fc81140a794da591f1'
exclude_tenant2='f68e039b76a6462aa4a622d9308c0bfd'
exclude_tenant3='974209cea9c3402e977120b5d02d500b'
exclude_tenant4='1741d223007940d5883c10d2293df015'

       if [ -n "$(neutron floatingip-show $fipid | grep tenant_id | egrep -v \
         "$exclude_tenant1|$exclude_tenant2|$exclude_tenant3|$exclude_tenant4")" ] ; then
         echo $fipid,$fipip,$(date +%s) >> $FIPDBTEMP
       fi

     fi
  done
  # Compare current FIP DB with existing one
  # Create new structure and FIP DB if needed
  if cmp -s $FIPDBTEMP $FIPDB ; then
    :
  else
    if [ ! -d $FIPDB_ARCHIVE ]; then
      mkdir $FIPDB_ARCHIVE
    fi
    cp -p $FIPDB $FIPDB_ARCHIVE/fipdb.$(date -d "$(stat ${FIPDB} | egrep ^Modify |  sed 's/^Modify: //g')" +%s)
    cat $FIPDBTEMP > $FIPDB
  fi

  echo rm -f $FIPDBTEMP
}

source /root/keystonerc_trystack
fiplist
fipdbupdate
cleanup

exit 0
