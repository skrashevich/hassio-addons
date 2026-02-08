# syntax = docker/dockerfile:1.4
ARG BUILD_FROM

# Stage 1: Build shelley from source
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git nodejs npm tar
RUN npm install -g pnpm

ARG BUILD_ARCH
ARG SHELLEY_REPO=https://github.com/skrashevich/shelley.git
ARG SHELLEY_BRANCH=main

RUN git clone --depth 1 --branch ${SHELLEY_BRANCH} ${SHELLEY_REPO} /src
WORKDIR /src

RUN cd ui && pnpm install --frozen-lockfile --silent && pnpm run --silent build

RUN for dir in templates/*/; do \
        name=$(basename "$dir"); \
        tar -czf "templates/$name.tar.gz" -C "templates/$name" --exclude='.DS_Store' .; \
    done

RUN set -eux; \
    case "${BUILD_ARCH}" in \
      amd64) export GOARCH=amd64 ;; \
      aarch64) export GOARCH=arm64 ;; \
      *) echo "Unsupported architecture: ${BUILD_ARCH}" && exit 1 ;; \
    esac; \
    CGO_ENABLED=0 GOOS=linux go build -o /usr/bin/shelley ./cmd/shelley

# Stage 2: Final image
FROM ${BUILD_FROM}

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

COPY --from=builder /usr/bin/shelley /usr/bin/shelley

ADD --link https://github.com/hassio-addons/bashio/archive/v0.16.3.tar.gz /tmp/bashio.tar.gz
RUN mkdir -p /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    && rm -rf /usr/lib/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -sf /usr/lib/bashio/bashio /usr/bin/bashio

COPY rootfs /
