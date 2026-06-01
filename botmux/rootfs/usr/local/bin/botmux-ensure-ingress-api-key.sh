#!/usr/bin/with-contenv bashio
# Register (or refresh) an internal API key used for Home Assistant Ingress SSO.
set -euo pipefail

CONFIG_PATH="/data/options.json"
DB_PATH="$(jq --raw-output '.db_path // "/config/botmux/botdata.db"' "${CONFIG_PATH}")"
KEY_FILE="/config/botmux/.ingress_api_key"
KEY_NAME="home-assistant-ingress"

botmux_random_hex() {
  od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
}

mkdir -p "$(dirname "${DB_PATH}")" "$(dirname "${KEY_FILE}")"

if [[ ! -f "${KEY_FILE}" ]]; then
  KEY="bmx_$(botmux_random_hex)"
  umask 077
  printf '%s' "${KEY}" > "${KEY_FILE}"
  bashio::log.info "Created Home Assistant ingress API key at ${KEY_FILE}"
fi

KEY="$(tr -d '\n' < "${KEY_FILE}")"
if [[ -z "${KEY}" ]]; then
  bashio::log.warning "Ingress API key file is empty: ${KEY_FILE}"
  exit 1
fi

if [[ ! -f "${DB_PATH}" ]]; then
  bashio::log.debug "Database not ready yet (${DB_PATH}); ingress API key registration deferred"
  exit 0
fi

KEY_HASH="$(printf '%s' "${KEY}" | sha256sum | awk '{print $1}')"

ADMIN_ID="$(sqlite3 "${DB_PATH}" "SELECT id FROM auth_users WHERE username='admin' LIMIT 1;" 2>/dev/null || true)"
if [[ -z "${ADMIN_ID}" ]]; then
  bashio::log.debug "Admin user not ready yet; ingress API key registration deferred"
  exit 0
fi

EXISTING_ID="$(sqlite3 "${DB_PATH}" "SELECT id FROM api_keys WHERE name='${KEY_NAME}' LIMIT 1;" 2>/dev/null || true)"
CREATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ -n "${EXISTING_ID}" ]]; then
  current_hash="$(sqlite3 "${DB_PATH}" "SELECT key_hash FROM api_keys WHERE id=${EXISTING_ID};" 2>/dev/null || true)"
  if [[ "${current_hash}" == "${KEY_HASH}" ]]; then
    must_change="$(sqlite3 "${DB_PATH}" "SELECT must_change_password FROM auth_users WHERE id=${ADMIN_ID};" 2>/dev/null || echo 0)"
    if [[ "${must_change}" == "1" ]]; then
      sqlite3 "${DB_PATH}" "UPDATE auth_users SET must_change_password=0 WHERE id=${ADMIN_ID};"
      bashio::log.info "Disabled BotMux first-login password prompt for Ingress SSO (direct :8080 login still uses admin password)"
    fi
    exit 0
  fi
  sqlite3 "${DB_PATH}" "UPDATE api_keys SET key_hash='${KEY_HASH}', user_id=${ADMIN_ID}, enabled=1 WHERE id=${EXISTING_ID};"
  bashio::log.info "Home Assistant ingress SSO API key updated in BotMux database"
else
  sqlite3 "${DB_PATH}" "INSERT INTO api_keys (user_id, key_hash, name, created_at, enabled) VALUES (${ADMIN_ID}, '${KEY_HASH}', '${KEY_NAME}', '${CREATED_AT}', 1);"
  bashio::log.info "Home Assistant ingress SSO API key registered in BotMux database"
fi

# Ingress users authenticate via Home Assistant; skip BotMux first-login password gate.
must_change="$(sqlite3 "${DB_PATH}" "SELECT must_change_password FROM auth_users WHERE id=${ADMIN_ID};" 2>/dev/null || echo 0)"
if [[ "${must_change}" == "1" ]]; then
  sqlite3 "${DB_PATH}" "UPDATE auth_users SET must_change_password=0 WHERE id=${ADMIN_ID};"
  bashio::log.info "Disabled BotMux first-login password prompt for Ingress SSO (direct :8080 login still uses admin password)"
fi
