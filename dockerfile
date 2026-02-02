FROM jrottenberg/ffmpeg:6.1-alpine

ENTRYPOINT ["sh", "-c"]
CMD ["ffmpeg \
  -rtsp_transport tcp \
  -use_wallclock_as_timestamps 1 \
  -fflags +genpts \
  -i \"$RTSP_URL\" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -map 0:v:0 \
  -map 1:a:0 \
  -c:v libx264 \
  -preset veryfast \
  -tune zerolatency \
  -profile:v high \
  -level 4.1 \
  -pix_fmt yuv420p \
  -r 25 \
  -g 50 \
  -b:v 2500k \
  -maxrate 2500k \
  -bufsize 5000k \
  -c:a aac \
  -b:a 128k \
  -shortest \
  -f flv \
  \"rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_STREAM_KEY\""]
