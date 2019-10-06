#! /bin/bash 
 
 
input_date="2019-10-01T02:35:47Z"
# correct time = 10:37 PM monday

# build_time=$(date -d "$input_date" +"%s" )
# build_time=$(date -j -f "%a %b %d %T %Z %Y" "`input_date`" "+%s")
# echo $build_time
date -d 'Fri Dec  8 00:12:50 UTC 2017' +"%s"
# "+DATE: %Y-%m-%d%nTIME: %H:%M:%S"
