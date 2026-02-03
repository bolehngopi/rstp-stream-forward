FROM jrottenberg/ffmpeg:6.1-alpine

LABEL org.opencontainers.image.source="https://github.com/bolehngopi/rstp-stream-forward"

COPY entrypoint.sh /usr/local/bin/stream-forward
RUN chmod +x /usr/local/bin/stream-forward

ENV RTMP_BASE_URL="rtmp://a.rtmp.youtube.com/live2" \
    ENABLE_AUDIO=1

ENTRYPOINT ["/usr/local/bin/stream-forward"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD sh -c "pgrep -f ffmpeg >/dev/null || exit 1"
