#!/usr/bin/env python
# extract specific fields from JSON
# used with router-query.sh
import json
import argparse

parser = argparse.ArgumentParser(description='Extract data from a json string.  Assume a single argument')
parser.add_argument('--js', metavar='<js>', type=str, default='{}', help='Specify the json to parse')

args = parser.parse_args()

jsarg = args.js

results = json.loads(jsarg)
if u'external_fixed_ips' in results:
  if u'ip_address' in results[u'external_fixed_ips'][0]:
    print results[u'external_fixed_ips'][0][u'ip_address']
