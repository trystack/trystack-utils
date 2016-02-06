#!/bin/sh
# https://github.com/trystack/trystack-utils
# Query floating IP DB for history of a floating IP across tenants
# This uses the existing floating IP structure of fip-query.sh

cd /root
IP=$1

usage() {
  if [ -z "$1" ]; then
    echo "=== You must specify IP address, quitting!"
    exit 1
  fi
}

usage $IP

source /root/keystonerc_admin

search_keystone() {
  if [ -z "$1" ]; then
    echo "        Result unknown."
    return 1
  fi
  t=$1
  tname=$(openstack project show $t | grep name | awk '{print $4}')
  tmail=$(openstack user show $tname | grep email | awk '{print $4}')
  echo "           Tenant: $t"
  echo "           User: $tname"
  echo "           E-Mail: $tmail"
  return 0
}

echo ========== current allocation
echo "  --- router gateway"
search_keystone $(grep ",$IP," routerdb | awk -F, '{ print $4 }')
echo "  --- fip allocation"
search_keystone $(grep ",$IP," fipdb | awk -F, '{ print $4 }')

echo ========== historic data
echo "  --- router gateway"
for f in $(ls -t routerdb.d/) ; do
  results=$(search_keystone $(grep ",$IP," routerdb.d/$f | awk -F, '{ print $4 }'))
  code=$?
  if [ $code -eq 0 ];  then
    echo "    ... $(date -d @$(echo $f | awk -F. '{ print $2 }'))"
    echo -e "$results"
  fi
done

echo "  --- fip allocation"
for f in $(ls -t fipdb.d/) ; do
  results=$(search_keystone $(grep ",$IP," fipdb.d/$f | awk -F, '{ print $4 }'))
  code=$?
  if [ $code -eq 0 ];  then
    echo "    ... $(date -d @$(echo $f | awk -F. '{ print $2 }'))"
    echo -e "$results"
  fi
done
