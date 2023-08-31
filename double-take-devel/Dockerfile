# syntax = docker/dockerfile:1.4
ARG BUILD_FROM

FROM ${BUILD_FROM}


ENV CONFIG_PATH=/data/options.json
LABEL \
  io.hass.version="1.13.11.2" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"

COPY --chmod=755 <<EOT >/init.sh
#!/usr/bin/env bash
set -e

export STORAGE_PATH=$(bashio::config 'STORAGE_PATH')
export CONFIG_PATH=$(bashio::config 'CONFIG_PATH')
export SECRETS_PATH=$(bashio::config 'SECRETS_PATH')
export MEDIA_PATH=$(bashio::config 'MEDIA_PATH')

cd /double-take && /bin/bash ./entrypoint.sh
EOT
ENTRYPOINT ["/bin/bash", "/init.sh"]