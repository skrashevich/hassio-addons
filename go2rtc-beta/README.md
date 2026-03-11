[![go2rtc](https://badgen.net/github/release/skrashevich/go2rtc)](https://github.com/skrashevich/go2rtc) [![go2rtc](https://badgen.net/github/stars/skrashevich/go2rtc)](https://github.com/skrashevich/go2rtc/stargazers)

![amd64][amd64-shield]
![arm64][arm64-shield]
![armv7][armv7-shield]

# go2rtc Beta

Ultimate camera streaming application with support for RTSP, WebRTC, HomeKit, FFmpeg, RTMP, and much more. This is the **beta** build from the [`beta` branch](https://github.com/skrashevich/go2rtc/tree/beta) of [skrashevich/go2rtc](https://github.com/skrashevich/go2rtc).

## Features

- RTSP, RTMP, WebRTC, HomeKit, FFmpeg, MJPEG, HLS and more
- Built-in WebUI on port 1984
- Hardware acceleration support (Intel VA-API)
- Low latency streaming

## Ports

| Port | Description |
|------|-------------|
| 1984/tcp | WebUI / HTTP API |
| 8554/tcp | RTSP server |
| 8555/tcp | WebRTC / PCMU+PCMA TCP |
| 8555/udp | WebRTC / PCMU+PCMA UDP |

## Configuration

After installation, a default `go2rtc.yaml` config file will be created at `/config/go2rtc.yaml`. Edit it to add your camera streams.

[Documentation](https://github.com/skrashevich/go2rtc)

[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
