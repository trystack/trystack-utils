#!/bin/bash
# https://github.com/trystack/trystack-utils
# Name:        router-query.sh
# Written by:  Kambiz Aghaiepour
# Purpose:     Track the routers in a flat file
#              Excludes specific tenant IDs.  This allows for
#              exclusion of certain tenants for culling if wanted.
#
# This script should be run frequently via CRON, and another
# script will use the data stored in ROUTERDB to release IPs from
# projects/tenants
#
####
#  ROUTERDB format:
#   each router is stored on a single line as:
#     "$routerid,$externalip,$seconds_since_epoch"
####
# Future improvement(s)
#   * argument parsing
#   * python port
#   * variablize the exclusion list
#################################################

ROUTERLIST=$(mktemp /tmp/routerlistXXXXXX)
ROUTERDB=/root/routerdb
ROUTERDB_ARCHIVE=/root/routerdb.d
HELPER=/root/router-query-json.py

# 4c1419ed8a5645fc81140a794da591f1 == excluded tenant #1
# f68e039b76a6462aa4a622d9308c0bfd == excluded tenant #2
# 974209cea9c3402e977120b5d02d500b == excluded tenant #3
# 1741d223007940d5883c10d2293df015 == excluded tenant #4

# possibly find a better way to do this...
# Note this is just a query, so if they're spared, it means no chance of accidentally clearing gateways on these...
SPARE_TENANTS='4c1419ed8a5645fc81140a794da591f1|f68e039b76a6462aa4a622d9308c0bfd|974209cea9c3402e977120b5d02d500b|1741d223007940d5883c10d2293df015'

function cleanup () {
  rm -f $ROUTERLIST
}

function routerlist () {
  for router in $(neutron router-list | egrep -v '^\+|external_gateway_info|null' | awk '{ print $2 }') ; do 
    if [ -n "$(neutron router-show $router | grep tenant | egrep -v "$SPARE_TENANTS")" ]; then
      # if we are here, we care to store the router info
      externalip=$($HELPER --js "$(neutron router-show $router | grep external_gateway_info | awk -F\| '{ print $3 }')")
      if [ -n "$externalip" ]; then
        echo $router,$externalip >> $ROUTERLIST
      fi
    fi
  done
}

function routerdbupdate () {
  if [ ! -r $ROUTERLIST ]; then
    return 1
  fi
  ROUTERDBTEMP=$(mktemp /tmp/routerdbXXXXXX)
  if [ ! -e $ROUTERDB ]; then
    touch $ROUTERDB
  fi
  for router in $(cat $ROUTERLIST) ; do

     routerid=$(echo $router | awk -F, '{ print $1 }')
     routerip=$(echo $router | awk -F, '{ print $2 }')

     if egrep -q "^$routerid,$routerip" $ROUTERDB ; then
       if [ -z $(egrep "^$routerid,$routerip" $ROUTERDB | awk -F, '{ print $4 }') ]; then 
         append=",$(neutron router-show $routerid | grep tenant | awk '{ print $4 }')"
       else
         append=""
       fi
       echo $(egrep "^$routerid" $ROUTERDB)$append >> $ROUTERDBTEMP
     else
       tenantid=$(neutron router-show $routerid | grep tenant | awk '{ print $4 }')
       echo $routerid,$routerip,$(date +%s),$tenantid >> $ROUTERDBTEMP
     fi
  done

  if cmp -s $ROUTERDBTEMP ${ROUTERDB} ; then
    :
  else
    if [ ! -d $ROUTERDB_ARCHIVE ]; then
      mkdir $ROUTERDB_ARCHIVE
    fi
    cp -p ${ROUTERDB} $ROUTERDB_ARCHIVE/routerdb.$(date -d "$(stat ${ROUTERDB} | egrep ^Modify |  sed 's/^Modify: //g')" +%s)
    cat $ROUTERDBTEMP > $ROUTERDB
  fi
    
  rm -f $ROUTERDBTEMP
}

source /root/keystonerc_trystack
routerlist
routerdbupdate
cleanup
