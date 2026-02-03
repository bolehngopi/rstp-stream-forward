# RTSP Stream Forward

Forward multiple RTSP camera feeds to YouTube Live using a tiny ffmpeg-based container. Each container instance ingests a camera stream, optionally injects silent audio, and pushes to an RTMP endpoint with tunable encoding parameters.

## Features

- Minimal Alpine-based image with ffmpeg 6.1
- Configurable via environment variables (URLs, bitrate, frame rate, presets, etc.)
- Optional audio injection to satisfy platforms that require audio tracks
- Health check that restarts ffmpeg if it exits unexpectedly
- Docker Compose sample for running multiple cameras

## Prerequisites

- Docker 24+ (or compatible runtime)
- Optional: GPU drivers and runtime (`--gpus all`) if you plan to use hardware encoders
- YouTube Live stream keys (or another RTMP endpoint)

## Building

```bash
docker build -t rtsp-to-youtube .
```

## Running a Single Stream

```bash
docker run \
  --name cam1-forwarder \
  -e RTSP_URL=rtsp://user:pass@camera-host:8554/stream \
  -e YOUTUBE_STREAM_KEY=xxxx-xxxx-xxxx-xxxx \
  rtsp-to-youtube
```

### Environment Variables

| Name                 | Required | Default                           | Description                                                      |
| -------------------- | -------- | --------------------------------- | ---------------------------------------------------------------- |
| `RTSP_URL`           | yes      | —                                 | Camera RTSP URL                                                  |
| `YOUTUBE_STREAM_KEY` | yes      | —                                 | Key appended to `RTMP_BASE_URL` (ignored if `RTMP_URL` provided) |
| `RTMP_BASE_URL`      | no       | `rtmp://a.rtmp.youtube.com/live2` | Base RTMP endpoint                                               |
| `RTMP_URL`           | no       | derived                           | Full RTMP URL to bypass base/key split                           |
| `ENABLE_AUDIO`       | no       | `1`                               | Set `0` to skip synthetic audio                                  |
| `VIDEO_PRESET`       | no       | `veryfast`                        | x264 preset                                                      |
| `VIDEO_TUNE`         | no       | `zerolatency`                     | x264 tune                                                        |
| `VIDEO_PROFILE`      | no       | `high`                            | H.264 profile                                                    |
| `VIDEO_LEVEL`        | no       | `4.1`                             | H.264 level                                                      |
| `PIX_FMT`            | no       | `yuv420p`                         | Output pixel format                                              |
| `FRAME_RATE`         | no       | `25`                              | FPS                                                              |
| `GOP_SIZE`           | no       | `50`                              | Keyframe interval                                                |
| `VIDEO_BITRATE`      | no       | `2500k`                           | Target bitrate                                                   |
| `VIDEO_MAXRATE`      | no       | `2500k`                           | VBV maxrate                                                      |
| `VIDEO_BUFSIZE`      | no       | `5000k`                           | VBV buffer                                                       |
| `AUDIO_BITRATE`      | no       | `128k`                            | AAC bitrate                                                      |
| `AUDIO_SAMPLE_RATE`  | no       | `44100`                           | Audio sample rate                                                |
| `AUDIO_LAYOUT`       | no       | `stereo`                          | Audio channel layout                                             |
| `FFMPEG_LOGLEVEL`    | no       | `info`                            | ffmpeg log level                                                 |
| `EXTRA_FFMPEG_ARGS`  | no       | —                                 | Additional raw arguments appended before `-f flv`                |

## Docker Compose (Multiple Cameras)

1. Copy `docker-compose.yaml` and replace each camera's `RTSP_URL`/`YOUTUBE_STREAM_KEY` with environment references, e.g.
   ```yaml
   environment:
     RTSP_URL: ${CAM1_RTSP_URL}
     YOUTUBE_STREAM_KEY: ${CAM1_YOUTUBE_KEY}
   ```
2. Create a `.env` file alongside the compose file with the sensitive values.
3. Start everything:
   ```bash
   docker compose up -d
   ```

## Customizing ffmpeg

- **Bitrate / resolution**: change `VIDEO_BITRATE`, add `EXTRA_FFMPEG_ARGS="-vf scale=1280:-2"` to downscale.
- **Hardware encoding**: set `EXTRA_FFMPEG_ARGS="-c:v h264_nvenc"` (or `h264_vaapi`, etc.) and pass the device into the container. Adjust pixel format and presets per encoder.
- **Remux only**: if the camera already streams compatible H.264, set `EXTRA_FFMPEG_ARGS="-c:v copy"` to avoid re-encoding and dramatically cut CPU usage.

## Health & Monitoring

- The Dockerfile defines a basic `HEALTHCHECK` to ensure the ffmpeg process stays alive.
- Use `docker logs <container>` to inspect ffmpeg output; increase verbosity with `FFMPEG_LOGLEVEL=debug` when troubleshooting.
- Track resource usage with `docker stats` or your orchestration platform. Lower presets or enable hardware encoding if CPU stays high.

## Security Notes

- Never commit real RTSP credentials or YouTube keys. Store them in `.env`, Docker secrets, or your orchestrator's secret manager.
- Restrict RTSP endpoints to trusted networks.

## Troubleshooting

| Symptom                   | Likely Cause          | Fix                                                           |
| ------------------------- | --------------------- | ------------------------------------------------------------- |
| Stream offline on YouTube | Wrong key or firewall | Regenerate key, ensure port 1935 outbound is open             |
| High CPU usage            | Software re-encoding  | Use `-c:v copy`, lower bitrate/preset, or use hardware encode |
| Audio required warning    | `ENABLE_AUDIO=0`      | Re-enable audio or provide real audio source                  |
| ffmpeg exits quickly      | Bad RTSP URL          | Verify credentials and network reachability                   |

## License

MIT
