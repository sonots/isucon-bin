#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
grep template $1 | $SCRIPT_DIR/lltsv -k template,elapsed -K | ruby $SCRIPT_DIR/template_stat.rb | $SCRIPT_DIR/lltsv -k sum,count,mean,template -K | sort -r -n
