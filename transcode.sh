#!/bin/bash

main() {
  video="$1"
  profiles=( "${@:2}" )
  for profile in ${profiles[@]}; do
    transcode $video $profile
  done
}

next2_profile() {
  bitrate="2M"
  maxrate="2M"
  minrate="500k"
  bufsize="1M"
  fps="30"
  libx="libx264"
  crf="30"
  preset="veryfast"
  threads="0"
}

next_profile() {
  bitrate="2M"
  maxrate="2M"
  minrate="500k"
  bufsize="1M"
  fps="30"
  libx="libx264"
  crf="30"
  preset="medium"
  threads="1"
}

current_profile() {
  bitrate="2M"
  maxrate="2M"
  minrate="300k"
  bufsize="1M"
  fps="30"
  libx="libx264"
  crf="30"
  preset="medium"
  threads="1"
}

transcode() {
  eval "${profile}_profile"
  video_base=`basename $video`
  name="dist/${video_base%.*}/$profile"
  rm -rf $name

  mkdir -p "$name/mp4"
  name_mp4="$name/mp4/master.mp4"
  mkdir -p "$name/dash"
  name_dash="$name/dash/master.mpd"
  mkdir -p "$name/hls"
  name_hls="$name/hls/master.m3u8"

  next2_convert() {
    begin_mp4=`date +%s`
    ffmpeg -y -i $video -f lavfi -t 1 -i anullsrc=cl=mono -crf $crf -b:v $bitrate -b:a 128k -f mp4 -r $fps -ar 44100 -c:v $libx -maxrate $maxrate -minrate $minrate -c:a aac -bufsize $bufsize -threads $threads -preset $preset $name_mp4
    end_mp4=`date +%s`

    begin_dash=`date +%s`
    ffmpeg -y -i "$name_mp4" -profile:v main -level 3.0 -f dash "$name_dash"
    end_dash=`date +%s`

    begin_hls=`date +%s`
    ffmpeg -y -i "$name_mp4" -profile:v main -level 3.0 -f hls -hls_list_size 0 "$name_hls"
    end_hls=`date +%s`
  }

  next_convert() {
    begin_mp4=`date +%s`
    ffmpeg -y -i $video -f lavfi -t 1 -i anullsrc=cl=mono -crf $crf -b:v $bitrate -b:a 128k -f mp4 -r $fps -ar 44100 -c:v $libx -maxrate $maxrate -minrate $minrate -c:a aac -bufsize $bufsize -threads $threads -preset $preset $name_mp4
    end_mp4=`date +%s`

    begin_dash=`date +%s`
    ffmpeg -y -i "$name_mp4" -profile:v main -level 3.0 -f dash "$name_dash"
    end_dash=`date +%s`

    begin_hls=`date +%s`
    ffmpeg -y -i "$name_mp4" -profile:v main -level 3.0 -f hls -hls_list_size 0 "$name_hls"
    end_hls=`date +%s`
  }

  current_convert() {
    begin_mp4=`date +%s`
    ffmpeg -y -i $video -f lavfi -t 1 -i anullsrc=cl=mono -crf $crf -b:v $bitrate -b:a 128k -f mp4 -r $fps -ar 44100 -c:v $libx -maxrate $maxrate -minrate $minrate -c:a aac -bufsize $bufsize -threads $threads -preset $preset -hls_list_size 0 $name_mp4
    end_mp4=`date +%s`

    begin_dash=`date +%s`
    ffmpeg -y -i $name_mp4 -map 0 -map 0 -map 0 -b:v:0 300k -b:v:1 800k -b:v:2 1200k -ar:a:1 22050 -adaptation_sets "id=0,streams=v id=1,streams=a" -f dash -c:v $libx -c:a aac -threads 1 -preset veryfast -hls_list_size 0 "$name_dash"
    end_dash=`date +%s`

    begin_hls=`date +%s`
    ffmpeg -y -i $name_mp4 -map 0 -map 0 -map 0 -b:v:0 300k -b:v:1 800k -b:v:2 1200k -ar:a:1 22050 -adaptation_sets "id=0,streams=v id=1,streams=a" -hls_playlist true -hls_time 4 -g 25 -sc_threshold 0 -f hls -master_pl_name master.m3u8 -f hls -c:v $libx -c:a aac -threads 1 -preset veryfast -hls_list_size 0 "$name_hls"
    end_hls=`date +%s`
  }

  eval "${profile}_convert"

  dur_mp4=`expr $end_mp4 - $begin_mp4`
  size_mp4=`du -sm $name/mp4 | awk '{ print $1 }'`
  dur_dash=`expr $end_dash - $begin_dash`
  size_dash=`du -sm $name/dash | awk '{ print $1 }'`
  dur_hls=`expr $end_hls - $begin_hls`
  size_hls=`du -sm $name/hls | awk '{ print $1 }'`

  total_dur=`expr $dur_mp4 + $dur_dash + $dur_hls`
  total_size=`du -sm $name | awk '{ print $1 }'`

  echo "
bitrate=$bitrate
maxrate=$maxrate
minrate=$minrate
bufsize=$bufsize
fps=$fps
libx=$libx
preset=$preset
threads=$threads

mp4: ${dur_mp4}s
dash: ${dur_dash}s
hls: ${dur_hls}s
total: `expr $dur_mp4 + $dur_dash + $dur_hls`s

`(cd $name && du -m -d 1)`

dash: http://localhost:9090/$name_dash
hls: http://localhost:9090/$name_hls
mp4: http://localhost:9090/$name_mp4
  " > "$name/stat"
  echo "$video profile:$profile mp4:${dur_mp4}s:${size_mp4}M dash:${dur_dash}s:${size_dash}M hls:${dur_hls}s:${size_hls}M total:${total_dur}s:${total_size}M" > "$name/stat.short"

  cat "$name/stat"
}

main $@
