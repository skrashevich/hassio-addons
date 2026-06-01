#!/usr/bin/with-contenv bashio
# Quick token probe during cont-init; BotMux service waits again before start.
set -euo pipefail

CONFIG_PATH="/data/options.json"

# shellcheck source=/usr/local/bin/botmux-resolve-token.sh
source /usr/local/bin/botmux-resolve-token.sh

if botmux_resolve_telegram_token "${CONFIG_PATH}" 6; then
  bashio::log.info "Telegram token resolved during init (${TOKEN_SOURCE})"
else
  bashio::log.notice "Telegram token not available yet; BotMux will retry on start"
fi
