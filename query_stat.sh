#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
grep query $1 | grep -v uri | $SCRIPT_DIR/lltsv -k query,elapsed -K | ruby $SCRIPT_DIR/query_stat.rb | $SCRIPT_DIR/lltsv -k sum,count,mean,query -K | sort -r -n
