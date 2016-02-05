#!/bin/sh
# https://github.com/trystack/trystack-utils
# purge cinder volumes every 48hours

# 48hours in seconds == 172800
TTL=172800

for cindervol in $(cinder list --all-tenants | grep available | awk '{ print $2 }') ; do
  if [ "$(cinder show $cindervol | grep attachments | awk '{ print $4 }')" == "[]" ]; then 
    if [ $(expr $(date +%s) - $(date -d "$(cinder show $cindervol | grep created_at | awk '{ print $4 }')" +%s)) -gt $TTL ]; then
      for snap in $(cinder snapshot-list --all-tenants | sed '1,3d' | sed '$,$d' | grep $cindervol | awk '{ print $2 }') ; do 
        cinder snapshot-delete $snap
      done
      cinder delete $cindervol
    fi
  fi
done
