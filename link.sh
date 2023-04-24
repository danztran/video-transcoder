main() {
  video=$1
  video_base=`basename $video`
  video_dist="dist/${video_base%.*}"
  stats=`find $video_dist -type f -name "stat" -exec ls {} +`
  if [ -f dist/$video_base ]; then
    echo "> raw
  http://localhost:9090/$video
"
  fi

  for stat in ${stats[@]}; do
    dir=`dirname $stat`
    echo \> ${dir#*\/}
    cat $stat | grep dist | sed 's|^|  |g'
    echo
  done
}

main $@
