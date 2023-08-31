# syntax = docker/dockerfile:1.4
ARG BUILD_FROM

FROM ${BUILD_FROM}
RUN <<EOT
curl -J -L -o /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/v0.14.3.tar.gz"
mkdir -p /tmp/bashio
tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio
mv /tmp/bashio/lib /usr/lib/bashio
ln -s /usr/lib/bashio/bashio /usr/bin/bashio
EOT

ENV CONFIG_PATH=/data/options.json
LABEL \
  io.hass.version="2.1.11" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"