#!/bin/sh
#
# Author: Kambiz Aghaiepour
#
#  Given two files that are the output of:
#    rpm -qa
#  from two different hosts, this script compares 
#  the installed packages and reports the differences.
#
#  The arguments passed should be files in the current directory,
#  e.g. :
#    compare-rpm-qa.sh host1-rpm-qa host2-rpm-qa
#
#  Two new files are generated in the current directory:
#
#     only-host1-rpm-qa  (contains packages only in host1-rpm-qa)
#     only-host2-rpm-qa  (contains packages only in host2-rpm-qa)
#
#  In addition to the generated files, the script also produces
#  stdout for packages that are installed on BOTH systems (or appear
#  in both files), AND that the package versions between the two
#  do not much.  (In other words identical packages are not printed).
#
######################################################

file1=$1
file2=$2
onlyfile1=only-$file1
onlyfile2=only-$file2

rm -f $onlyfile1 $onlyfile2

tmpfile1=$(mktemp /tmp/rpmqa1-XXXXXX)
sort < $file1 > $tmpfile1

tmpfile2=$(mktemp /tmp/rpmqa2-XXXXXX)
sort < $file2 > $tmpfile2

# make sure things are sane ...

for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile1) ; do 

  # ignore the kernel package.  This is special and usually can have
  # multiple versions installed.

  if [ "$pkg" != "kernel" ]; then
    # Assume that the version starts where the rpm -qa name starts with "-[0-9]"
    # and ensure packages only appear once in the list.
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1) -gt 1 ]; then 
      echo $pkg appears more than once in $file1
    fi
  fi
done

for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile2) ; do 
    # Assume that the version starts where the rpm -qa name starts with "-[0-9]"
    # and ensure packages only appear once in the list.
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2) -gt 1 ]; then 
      echo $pkg appears more than once in $file2
    fi
  fi
done

# now look for things in file1 that are not in file2

# loop through the package names in file1
for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile1) ; do
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2) -ne 1 ]; then 
      # if not found in file2 ...
      echo $pkg >> $onlyfile1
    fi
  fi
done

# now look for things in file2 that are not in file1

# loop through the package names in file2
for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile2) ; do
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1) -ne 1 ]; then 
      # if not found in file2 ...
      echo $pkg >> $onlyfile2
    fi
  fi
done

# finally compare the ones that appear in both
for pkg in $(cat $tmpfile1 $tmpfile2 | sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' | sort -u) ; do
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1) -eq 1 -a $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2) -eq 1 ]; then 
      pkg1=$(egrep "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1)
      pkg2=$(egrep "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2)
      if [ "$pkg1" != "$pkg2" ]; then
        echo $pkg1 $pkg2
      fi
    fi
  fi
done


rm -f $tmpfile1 $tmpfile2

