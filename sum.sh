#!/bin/bash

main() {
  data=`./analytic.sh`
  profiles=( `echo "$data" | grep profile | awk '{print $2}' | sort | uniq | awk -F ':' '{print $2}'` )
  for profile in ${profiles[@]}; do
    echo \> $profile
    totals=( `echo "$data" | grep "profile:$profile" | awk '{print $6}'` )

    total_dur=0
    total_size=0
    for total in ${totals[@]}; do
      ext=( `echo $total | awk -F ':' '{print $2; print $3}'` )

      dur=`echo ${ext[0]} | sed 's|.$||'`
      (( total_dur += dur ))

      size=`echo ${ext[1]} | sed 's|.$||'`
      total_size=`echo "$total_size + $size" | bc`
    done

    echo "total duration: ${total_dur}s"
    echo "total size: ${total_size}M"
  done
}

main $@
