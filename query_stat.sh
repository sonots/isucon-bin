#!/bin/bash
grep query $1 | grep -v uri | /home/isucon/bin/lltsv -k query,elapsed -K | ruby /home/isucon/bin/query_stat.rb | /home/isucon/bin/lltsv -k sum,count,mean,query -K | sort -r -n
