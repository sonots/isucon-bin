#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
grep uri $1 | $SCRIPT_DIR/lltsv -k uri,reqtime -K | ruby $SCRIPT_DIR/http_stat.rb | $SCRIPT_DIR/lltsv -k sum,count,mean,path -K | sort -r -n
