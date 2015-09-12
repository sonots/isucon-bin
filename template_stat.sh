#!/bin/bash
grep template $1 | /home/isucon/bin/lltsv -k template,elapsed -K | ruby /home/isucon/bin/template_stat.rb | /home/isucon/bin/lltsv -k sum,count,mean,template -K | sort -r -n
