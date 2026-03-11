# syntax = docker/dockerfile:1.4
ARG BUILD_FROM

# Build go2rtc from skrashevich/go2rtc:beta
FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS build
ARG TARGETOS
ARG TARGETARCH

ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}

WORKDIR /build

RUN apk add git

RUN git clone --branch beta --depth 1 https://github.com/skrashevich/go2rtc.git .

RUN --mount=type=cache,target=/root/.cache/go-build go mod download

RUN --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=0 go build -ldflags "-s -w" -trimpath


# Download CDN dependencies for offline web UI
FROM alpine AS download-cdn
RUN apk add --no-cache wget git
RUN git clone --branch beta --depth 1 https://github.com/skrashevich/go2rtc.git /src
RUN sh /src/docker/download_cdn.sh /src/www


# Final image
FROM alpine:3.21

ARG S6_OVERLAY_VERSION=3.1.6.2
ARG BUILD_ARCH=amd64

RUN apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        ffmpeg \
        jq \
        tini \
        tzdata \
        xz \
    \
    && S6_ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "i386" ]; then S6_ARCH="i686"; \
    elif [ "${BUILD_ARCH}" = "amd64" ]; then S6_ARCH="x86_64"; \
    elif [ "${BUILD_ARCH}" = "armv7" ]; then S6_ARCH="arm"; \
    elif [ "${BUILD_ARCH}" = "aarch64" ]; then S6_ARCH="aarch64"; fi \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        | tar -C / -Jxpf - \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" \
        | tar -C / -Jxpf - \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" \
        | tar -C / -Jxpf - \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" \
        | tar -C / -Jxpf - \
    \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d

COPY --from=build /build/go2rtc /usr/local/bin/go2rtc
COPY --from=download-cdn /src/www /var/www/go2rtc

ADD --link https://github.com/hassio-addons/bashio/archive/v0.14.3.tar.gz /tmp/bashio.tar.gz
RUN mkdir -p /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

ENV CONFIG_PATH=/data/options.json

LABEL \
  io.hass.version="beta" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64|armv7"

COPY --chmod=755 <<-EOT /run.sh
#!/usr/bin/with-contenv bashio

LOG_LEVEL=$(bashio::config 'log_level' 'info')

# Generate go2rtc config if not exists
if [ ! -f /config/go2rtc.yaml ]; then
  cat > /config/go2rtc.yaml <<-YAML
api:
  listen: ":1984"

log:
  level: ${LOG_LEVEL}

rtsp:
  listen: ":8554"

webrtc:
  listen: ":8555"
YAML
fi

exec /usr/local/bin/go2rtc -config /config/go2rtc.yaml
EOT

EXPOSE 1984 8554 8555
VOLUME /config
WORKDIR /config
CMD [ "/run.sh" ]
