# syntax = docker/dockerfile:1.4
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BOTMUX_VERSION=v0.1.6
ARG BUILD_ARCH

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    nginx \
    py3-pip \
    sqlite \
    tzdata

RUN pip3 install --no-cache-dir --break-system-packages websocket-client \
    && mkdir -p /run/nginx /etc/nginx/http.d

RUN set -eux; \
    case "${BUILD_ARCH}" in \
      amd64) BOTMUX_ARCH="amd64" ;; \
      aarch64) BOTMUX_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${BUILD_ARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/bin/botmux \
      "https://github.com/skrashevich/botmux/releases/download/${BOTMUX_VERSION}/botmux-linux-${BOTMUX_ARCH}"; \
    chmod +x /usr/bin/botmux

ADD --link https://github.com/hassio-addons/bashio/archive/v0.16.3.tar.gz /tmp/bashio.tar.gz
RUN mkdir -p /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    && rm -rf /usr/lib/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -sf /usr/lib/bashio/bashio /usr/bin/bashio

COPY rootfs /
RUN chmod +x /usr/local/bin/botmux-ha-ws.py \
    && chmod +x /usr/local/bin/botmux-ensure-ingress-api-key.sh \
    && chmod +x /etc/cont-init.d/*.sh \
    && chmod +x /etc/services.d/*/run
