#!/bin/sh
set -euo pipefail

: "${RTSP_URL:?RTSP_URL is required}"
: "${YOUTUBE_STREAM_KEY:?YOUTUBE_STREAM_KEY is required}"

RTMP_BASE_URL=${RTMP_BASE_URL:-"rtmp://a.rtmp.youtube.com/live2"}
RTMP_URL=${RTMP_URL:-"${RTMP_BASE_URL}/${YOUTUBE_STREAM_KEY}"}

VIDEO_PRESET=${VIDEO_PRESET:-"ultrafast"}
VIDEO_TUNE=${VIDEO_TUNE:-"zerolatency"}
VIDEO_PROFILE=${VIDEO_PROFILE:-"high"}
VIDEO_LEVEL=${VIDEO_LEVEL:-"4.1"}
PIX_FMT=${PIX_FMT:-"yuv420p"}
FRAME_RATE=${FRAME_RATE:-"25"}
GOP_SIZE=${GOP_SIZE:-"50"}
VIDEO_BITRATE=${VIDEO_BITRATE:-"2500k"}
VIDEO_MAXRATE=${VIDEO_MAXRATE:-"2500k"}
VIDEO_BUFSIZE=${VIDEO_BUFSIZE:-"5000k"}
AUDIO_BITRATE=${AUDIO_BITRATE:-"128k"}
AUDIO_SAMPLE_RATE=${AUDIO_SAMPLE_RATE:-"44100"}
AUDIO_LAYOUT=${AUDIO_LAYOUT:-"stereo"}
FFMPEG_LOGLEVEL=${FFMPEG_LOGLEVEL:-"info"}
THREAD_QUEUE_SIZE=${THREAD_QUEUE_SIZE:-"1024"}
RTSP_RW_TIMEOUT_US=${RTSP_RW_TIMEOUT_US:-"15000000"}

if [ -n "${VIDEO_FILTER:-}" ]; then
  VIDEO_FILTER_ARGS="-vf ${VIDEO_FILTER}"
else
  VIDEO_FILTER_ARGS=""
fi

RTSP_TIMEOUT_ARGS=""
if ffmpeg -hide_banner -h demuxer=rtsp 2>/dev/null | grep -Eq '(^|[[:space:]])-?timeout([[:space:]]|$)'; then
  RTSP_TIMEOUT_ARGS="-timeout ${RTSP_RW_TIMEOUT_US}"
elif ffmpeg -hide_banner -h full 2>/dev/null | grep -Eq '(^|[[:space:]])-rw_timeout([[:space:]]|$)'; then
  RTSP_TIMEOUT_ARGS="-rw_timeout ${RTSP_RW_TIMEOUT_US}"
fi

if [ "${ENABLE_AUDIO:-1}" -eq 1 ]; then
  AUDIO_INPUT_ARGS="-f lavfi -i anullsrc=channel_layout=${AUDIO_LAYOUT}:sample_rate=${AUDIO_SAMPLE_RATE}"
  AUDIO_MAP_ARGS="-map 1:a:0 -c:a aac -b:a ${AUDIO_BITRATE}"
else
  AUDIO_INPUT_ARGS=""
  AUDIO_MAP_ARGS=""
fi

exec ffmpeg \
  -loglevel "${FFMPEG_LOGLEVEL}" \
  -nostdin \
  -rtsp_transport tcp \
  ${RTSP_TIMEOUT_ARGS} \
  -thread_queue_size "${THREAD_QUEUE_SIZE}" \
  -use_wallclock_as_timestamps 1 \
  -fflags +genpts+discardcorrupt \
  -err_detect ignore_err \
  -i "${RTSP_URL}" \
  ${AUDIO_INPUT_ARGS} \
  -map 0:v:0 \
  ${AUDIO_MAP_ARGS} \
  -c:v libx264 \
  -preset "${VIDEO_PRESET}" \
  -tune "${VIDEO_TUNE}" \
  -profile:v "${VIDEO_PROFILE}" \
  -level "${VIDEO_LEVEL}" \
  -pix_fmt "${PIX_FMT}" \
  -r "${FRAME_RATE}" \
  -g "${GOP_SIZE}" \
  -b:v "${VIDEO_BITRATE}" \
  -maxrate "${VIDEO_MAXRATE}" \
  -bufsize "${VIDEO_BUFSIZE}" \
  ${VIDEO_FILTER_ARGS} \
  -shortest \
  ${EXTRA_FFMPEG_ARGS:-} \
  -f flv \
  "${RTMP_URL}"
