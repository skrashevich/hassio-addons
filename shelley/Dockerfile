# syntax = docker/dockerfile:1.4
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG SHELLEY_VERSION=v0.188.951060362
ARG BUILD_ARCH

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    docker-cli \
    git \
    jq \
    lsof \
    openssh-client \
    sqlite

RUN set -eux; \
    case "${BUILD_ARCH}" in \
      amd64) SHELLEY_ARCH="amd64" ;; \
      aarch64) SHELLEY_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${BUILD_ARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/bin/shelley "https://github.com/boldsoftware/shelley/releases/download/${SHELLEY_VERSION}/shelley_linux_${SHELLEY_ARCH}"; \
    chmod +x /usr/bin/shelley

ADD --link https://github.com/hassio-addons/bashio/archive/v0.16.3.tar.gz /tmp/bashio.tar.gz
RUN mkdir -p /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

COPY rootfs /

