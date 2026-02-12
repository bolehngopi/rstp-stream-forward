#!/bin/sh
set -euo pipefail

: "${RTSP_URL:?RTSP_URL is required}"
: "${YOUTUBE_STREAM_KEY:?YOUTUBE_STREAM_KEY is required}"

RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${YOUTUBE_STREAM_KEY}"
PRESET=${VIDEO_PRESET:-"ultrafast"}
THREADS=${FFMPEG_THREADS:-"1"}
RESOLUTION=${VIDEO_RESOLUTION:-""}

# Scale filter if resolution is set
if [ -n "${RESOLUTION}" ]; then
  SCALE_ARGS="-vf scale=${RESOLUTION}"
else
  SCALE_ARGS=""
fi

exec ffmpeg \
  -rtsp_transport tcp \
  -use_wallclock_as_timestamps 1 \
  -fflags +genpts \
  -i "${RTSP_URL}" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -map 0:v:0 \
  -map 1:a:0 \
  -c:v libx264 \
  -preset "${PRESET}" \
  -tune zerolatency \
  -profile:v high \
  -level 4.1 \
  -pix_fmt yuv420p \
  -threads "${THREADS}" \
  ${SCALE_ARGS} \
  -r 25 \
  -g 50 \
  -b:v 2500k \
  -maxrate 2500k \
  -bufsize 5000k \
  -c:a aac \
  -b:a 128k \
  -shortest \
  -f flv \
  "${RTMP_URL}"
