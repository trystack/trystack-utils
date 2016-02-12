#!/bin/bash
#
# Written by: Kambiz Aghaiepour
# calculate the guests on which to run ospurge against.
#
# Prerequisites: https://github.com/openstack/ospurge
# Package deps:  screen
#
# tenants_to_clean is a string match for the tenants on which we operate
# You probably _really_ want to set this otherwise you will nuke things
# for tenants you might never want to purge.
# 
# THRESHOLD is the number of days of inactivity that triggers
# purging.
#
tenants_to_clean=facebook

source /root/keystonerc_trystack

# 2 days i.e.:  expr 48 \* 60 \* 60
THRESHOLD=172800

function check_project() {
  rm -f screenlog.0
  screen -L -D -m nova list --tenant $1
  # the output of the following sed is non-empty means
  # tenant has guests.  So just return.
  if [ "$(sed '1,/^| ID/d' screenlog.0  | egrep -v '^\+--')" ]; then
    # echo === INFO : tenant $1 has running guests
    rm -f screenlog.0
    return
  fi
  rm -f screenlog.0
  # now find out how recently the tenant had a guest thats deleted.
  screen -L -D -m nova list --tenant $1 --deleted --fields status,updated  
  latest=1970-01-01
  for t in $(cat screenlog.0 | grep DELETED | awk '{ print $6 }') ; do 
    if [ $(date -d $t +%s) -gt $(date -d $latest +%s) ]; then 
      latest=$t 
    fi 
  done
  # echo === INFO : tenant $1 last had a vm on $latest
  if [ $(expr $(date +%s) - $(date -d $latest +%s)) -gt $THRESHOLD ]; then
#    echo $1
    ospurge --dont-delete-project --cleanup-project $1
  fi
  rm -f screenlog.0
}

projectfile=$(mktemp /tmp/projectListXXXXXXX)
cd /root
rm -f screenlog.0
screen -L -D -m openstack project list
sed '1,/^| ID/d' screenlog.0  | egrep -v '^\+--' | grep $tenants_to_clean | awk '{ print $2 }' > $projectfile

for project in $(cat $projectfile) ; do
  check_project $project
done

rm -f screenlog.0 $projectfile
