#!/bin/bash

MAX_W=3840
MAX_H=2160

for f in *.m??
do
  VIDEO_FLAG='-c:v copy '
  video=$(ffprobe -v error -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=codec_name "$f")

  v_bit_depth=$(ffprobe -v error -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=bits_per_raw_sample "$f")
  DEPTH_FLAG=''

  fps=$(ffprobe -v error -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate "$f" | bc)
  FPS_FLAG=''

  resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$f")
  width=$(ffprobe -v error -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=width "$f")
  height=$(ffprobe -v error -select_streams v:0 -of default=noprint_wrappers=1:nokey=1 -show_entries stream=height "$f")
  RESOLUTION_FLAG=''

  audio=$(ffprobe -v error -select_streams a:0 -of default=nw=1:nk=1 -show_entries stream=codec_name "$f")
  AUDIO_FLAG='-c:a copy '

  SKIP=0
  EXT=$(file -b "$f")
  MP4="ISO Media, MP4 Base Media v1 [IS0 14496-12:2003]"

  echo Filename: $f
  if [ "$video" != "hevc" ] ; then
    echo "Video codec: $video -> h256"
    VIDEO_FLAG='-c:v libx265 -x265-params crf=25 '
    SKIP=$((SKIP+1))
  else
    echo "Video codec: $video"
  fi

  if [ "$v_bit_depth" != 'N/A' ] && [ "$v_bit_depth" -gt '8' ] ; then
    echo "Video bit depth: $v_bit_depth -> 8"
    DEPTH_FLAG='-pix_fmt yuv420p '
    SKIP=$((SKIP+1))
  else
    echo "Video bit depth: $v_bit_depth"
  fi

  if [ "$fps" -gt 30 ] ; then
    echo "fps: $fps -> 30"
    FPS_FLAG='-r 30 '
    SKIP=$((SKIP+1))
  else
    echo "fps: $fps"
  fi

  if [ "$width" -gt "$MAX_W" ] || [ "$height" -gt "$MAX_H" ] ; then
    echo "Resolution: $resolution -> '$MAX_W'x'$MAX_H'"
    RESOLUTION_FLAG='-vf scale=3840:2160 '
    SKIP=$((SKIP+1))
  else
    echo "Resolution: $resolution"
  fi

  if [ "$audio" == "aac" ] || [ "$audio" == "ac3" ] ; then
    echo "Audio codec: $audio"
  else
    echo "Audio codec: $audio -> ac3"
    AUDIO_FLAG='-c:a ac3 '
    SKIP=$((SKIP+1))
  fi

  if [ "$SKIP" -eq 0 ] && [ "$EXT" != "$MP4" ] ; then
    SKIP=$((SKIP+1))
  fi

  if [ "$SKIP" -ne 0 ] ; then
    echo "ffmpeg -i $f $VIDEO_FLAG$RESOLUTION_FLAG$FPS_FLAG$DEPTH_FLAG$AUDIO_FLAG progress/${f%*\)*}) - 2160p.mp4"
  else
    echo "SKIPPING"
  fi

  if [ "$1" != "-d" ] ; then
    mkdir progress
    mkdir -p completed/"${f%*\)*})"/
    if [ "$SKIP" -ne 0 ] ; then
      ffmpeg -i "$f" $VIDEO_FLAG$RESOLUTION_FLAG$FPS_FLAG$DEPTH_FLAG$AUDIO_FLAG progress/"${f%*\)*}) - 2160p.mp4"
      mv progress/"${f%*\)*}) - 2160p.mp4" completed/"${f%*\)*})"/. &
    else #skip, make hardlink
      ln "$f" completed/"${f%*\)*})"/"$f"
    fi
  else
    echo "DRY RUN"
  fi
  echo "----------------------------------------------"
done

wait
