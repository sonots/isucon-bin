#!/bin/bash
grep uri $1 | /home/isucon/bin/lltsv -k uri,reqtime -K | ruby /home/isucon/bin/http_stat.rb | /home/isucon/bin/lltsv -k sum,count,mean,path -K | sort -r -n
