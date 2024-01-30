# syntax = docker/dockerfile:1.4
ARG BUILD_FROM

FROM skrashevich/double-take:1.13.11.8

ARG S6_OVERLAY_VERSION=3.1.6.2
ARG BUILD_ARCH=amd64
RUN \
    apt-get update \
    \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq\
        tzdata \
        xz-utils \
    \
    && S6_ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "i386" ]; then S6_ARCH="i686"; \
    elif [ "${BUILD_ARCH}" = "amd64" ]; then S6_ARCH="x86_64"; \
    elif [ "${BUILD_ARCH}" = "armv7" ]; then S6_ARCH="arm"; fi \
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

# Copy root filesystem
ADD --link rootfs /

ENV CONFIG_PATH=/data/options.json
LABEL \
  io.hass.version="1.13.11.8" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64|armv7"

ADD --link https://github.com/hassio-addons/bashio/archive/v0.14.3.tar.gz /tmp/bashio.tar.gz
RUN mkdir -p /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

COPY --chmod=755 <<-EOT /run.sh
#!/usr/bin/with-contenv bashio

export STORAGE_PATH=$(bashio::config 'STORAGE_PATH')
export CONFIG_PATH=$(bashio::config 'CONFIG_PATH')
export SECRETS_PATH=$(bashio::config 'SECRETS_PATH')
export MEDIA_PATH=$(bashio::config 'MEDIA_PATH')
export IPFILTER=$(cat /data/options.json | jq '.IPFILTER')

cd /double-take && /bin/bash ./entrypoint.sh
EOT
RUN chmod a+x /run.sh
WORKDIR /double-take
CMD [ "/run.sh" ]
