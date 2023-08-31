# syntax = docker/dockerfile:1.4
ARG BUILD_FROM

FROM skrashevich/double-take:beta


ENV CONFIG_PATH=/data/options.json
LABEL \
  io.hass.version="1.13.11.2" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"

ADD --link https://github.com/hassio-addons/bashio/archive/v0.14.3.tar.gz /tmp/bashio.tar.gz
RUN mkdir -p /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

COPY --chmod=755 <<-EOT /init.sh
#!/usr/bin/env bashio

export STORAGE_PATH=$(bashio::config 'STORAGE_PATH')
export CONFIG_PATH=$(bashio::config 'CONFIG_PATH')
export SECRETS_PATH=$(bashio::config 'SECRETS_PATH')
export MEDIA_PATH=$(bashio::config 'MEDIA_PATH')

cd /double-take && /bin/bash ./entrypoint.sh
EOT
ENTRYPOINT ["/bin/bash", "/init.sh"]