# syntax = docker/dockerfile:1.4
ARG BUILD_FROM

FROM ${BUILD_FROM}


ENV CONFIG_PATH=/data/options.json
LABEL \
  io.hass.version="2.1.11" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"