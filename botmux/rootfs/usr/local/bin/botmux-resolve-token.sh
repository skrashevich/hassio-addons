#!/usr/bin/with-contenv bashio
# Resolve Telegram bot token: add-on option overrides Home Assistant integration.
# shellcheck disable=SC2034
TOKEN_SOURCE=""

HA_CONFIG_ENTRIES_STORAGE=""
TOKEN_CACHE_FILE="/config/botmux/.telegram_bot_token"

botmux_ha_config_entries_storage() {
  local path
  for path in \
    "/homeassistant/.storage/core.config_entries" \
    "/config/.storage/core.config_entries"; do
    if [[ -f "${path}" && -r "${path}" ]]; then
      printf '%s' "${path}"
      return 0
    fi
  done
  return 1
}

botmux_ha_api() {
  local method=$1
  local path=$2
  local body=${3:-}

  if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
    return 1
  fi

  local args=(-fsS -X "${method}")
  args+=(-H "Authorization: Bearer ${SUPERVISOR_TOKEN}")
  args+=(-H "Content-Type: application/json")
  if [[ -n "${body}" ]]; then
    args+=(-d "${body}")
  fi
  curl "${args[@]}" "http://supervisor/core/api${path}" 2>/dev/null
}

botmux_token_from_storage_file() {
  local storage=$1
  local count token

  if [[ ! -f "${storage}" || ! -r "${storage}" ]]; then
    return 1
  fi

  set +e
  count="$(jq '[.data.entries[] | select(.domain == "telegram_bot" and (((.data.api_key // "") | length > 0) or ((.unique_id // "") | test(":"))))] | length' "${storage}" 2>/dev/null)"
  set -e
  if [[ -z "${count}" || "${count}" == "0" ]]; then
    return 1
  fi
  if [[ "${count}" -gt 1 ]]; then
    bashio::log.warning "Several telegram_bot integrations found; using the first token"
  fi

  set +e
  token="$(jq -r '.data.entries[] | select(.domain == "telegram_bot") | .data.api_key // empty' "${storage}" 2>/dev/null | head -1)"
  if [[ -z "${token}" || "${token}" == "null" ]]; then
    token="$(jq -r '.data.entries[] | select(.domain == "telegram_bot") | .unique_id // empty' "${storage}" 2>/dev/null | head -1)"
  fi
  set -e

  if [[ -z "${token}" || "${token}" == "null" || "${token}" != *:* ]]; then
    return 1
  fi

  printf '%s' "${token}"
  return 0
}

botmux_token_from_homeassistant_storage() {
  local storage
  storage="$(botmux_ha_config_entries_storage)" || return 1
  botmux_token_from_storage_file "${storage}"
}

botmux_token_from_homeassistant_api() {
  local entries count token

  entries="$(botmux_ha_api GET "/config/config_entries/entry")" || return 1

  set +e
  count="$(jq '[.[] | select(.domain == "telegram_bot" and (((.data.api_key // "") | length > 0) or ((.unique_id // "") | test(":"))))] | length' <<< "${entries}")"
  token="$(jq -r '[.[] | select(.domain == "telegram_bot")][0].data.api_key // empty' <<< "${entries}")"
  if [[ -z "${token}" || "${token}" == "null" ]]; then
    token="$(jq -r '[.[] | select(.domain == "telegram_bot")][0].unique_id // empty' <<< "${entries}")"
  fi
  set -e

  if [[ -z "${count}" || "${count}" == "0" ]]; then
    return 1
  fi
  if [[ -z "${token}" || "${token}" == "null" || "${token}" != *:* ]]; then
    return 1
  fi

  printf '%s' "${token}"
  return 0
}

botmux_cache_token() {
  local token=$1
  mkdir -p "$(dirname "${TOKEN_CACHE_FILE}")"
  umask 077
  printf '%s' "${token}" > "${TOKEN_CACHE_FILE}"
  chmod 600 "${TOKEN_CACHE_FILE}"
}

botmux_try_resolve_telegram_token_once() {
  local config_path=${1:-/data/options.json}
  local option_token token

  option_token="$(jq --raw-output '.telegram_bot_token // empty' "${config_path}")"
  if [[ -n "${option_token}" ]]; then
    TOKEN="${option_token}"
    TOKEN_SOURCE="addon_option"
    botmux_cache_token "${TOKEN}"
    return 0
  fi

  if [[ -f "${TOKEN_CACHE_FILE}" ]]; then
    token="$(tr -d '[:space:]' < "${TOKEN_CACHE_FILE}")"
    if [[ -n "${token}" ]]; then
      TOKEN="${token}"
      TOKEN_SOURCE="cache"
      return 0
    fi
  fi

  if token="$(botmux_token_from_homeassistant_storage)"; then
    TOKEN="${token}"
    TOKEN_SOURCE="homeassistant_storage"
    botmux_cache_token "${TOKEN}"
    return 0
  fi

  if token="$(botmux_token_from_homeassistant_api)"; then
    TOKEN="${token}"
    TOKEN_SOURCE="homeassistant_api"
    botmux_cache_token "${TOKEN}"
    return 0
  fi

  TOKEN=""
  TOKEN_SOURCE=""
  return 1
}

# Sets TOKEN and TOKEN_SOURCE. Optional max_attempts: retry every 5s (default 1).
botmux_resolve_telegram_token() {
  local config_path=${1:-/data/options.json}
  local max_attempts=${2:-1}
  local attempt

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    if botmux_try_resolve_telegram_token_once "${config_path}"; then
      if [[ "${TOKEN_SOURCE}" == homeassistant_* ]]; then
        bashio::log.info "Using telegram_bot token from Home Assistant (${TOKEN_SOURCE})"
      fi
      return 0
    fi

    if [[ "${max_attempts}" -gt 1 && "${attempt}" -lt "${max_attempts}" ]]; then
      if [[ $((attempt % 6)) -eq 1 ]]; then
        bashio::log.notice "Waiting for telegram_bot token (${attempt}/${max_attempts})..."
      fi
      sleep 5
    fi
  done

  TOKEN=""
  TOKEN_SOURCE=""
  return 1
}
