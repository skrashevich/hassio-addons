#!/usr/bin/with-contenv bashio
set -euo pipefail

PORT="$(bashio::config 'port' 8080)"
SERVER_TEMPLATE="/etc/nginx/templates/server.conf.gtpl"
AUTH_TEMPLATE="/etc/nginx/templates/ingress-auth.conf.gtpl"
SERVER_OUTPUT="/etc/nginx/http.d/server.conf"
AUTH_OUTPUT="/etc/nginx/http.d/ingress-auth.conf"
KEY_FILE="/config/botmux/.ingress_api_key"

mkdir -p /etc/nginx/http.d /run/nginx "$(dirname "${KEY_FILE}")"

if [[ ! -f "${KEY_FILE}" ]]; then
  umask 077
  printf 'bmx_%s' "$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')" > "${KEY_FILE}"
fi

INGRESS_API_KEY="$(tr -d '\n' < "${KEY_FILE}")"
sed -e "s/{{ .port }}/${PORT}/g" "${SERVER_TEMPLATE}" > "${SERVER_OUTPUT}"
sed -e "s|{{ .ingress_api_key }}|${INGRESS_API_KEY}|g" "${AUTH_TEMPLATE}" > "${AUTH_OUTPUT}"
