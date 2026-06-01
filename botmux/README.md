# BotMux

[BotMux](https://github.com/skrashevich/botmux) is a web panel for managing Telegram bots. With the Home Assistant OS add-on, it automatically sets up this chain:

```text
Telegram ←long poll→ BotMux ←long poll (/tgapi)→ Home Assistant
```

Only BotMux polls `api.telegram.org`. The **Telegram bot** integration in HA receives updates by polling BotMux (`http://botmux:8080/tgapi`), with no public HTTPS and no manual proxy setup in the UI.

## Features

- Ingress UI in Home Assistant
- SQLite database at `/config/botmux/botdata.db`
- **Full auto-configuration** of the `telegram_bot` integration when a token is available
- Home Assistant API access via Supervisor (`homeassistant_api`)

## Add-on configuration

```yaml
port: 8080
db_path: /config/botmux/botdata.db
telegram_bot_token: ""
demo_mode: false
homeassistant_auto_configure: true
```

**Bot token** is resolved in this order:

1. `telegram_bot_token` in add-on settings (if set — takes priority).
2. Otherwise `api_key` from an existing **Telegram bot** integration in Home Assistant.
3. Cache at `/config/botmux/.telegram_bot_token` after the first successful read.

You can leave the token field empty in the add-on if the integration is already configured in HA.

1. Start the add-on.
2. Wait for `homeassistant-setup: configuration finished` in the logs.

The script automatically:

- enables **Long Poll** in BotMux and disables reverse proxy to the HA webhook;
- clears the webhook in Telegram (`deleteWebhook`);
- creates or **reconfigures** the **Telegram bot** integration in HA for **Polling** with API endpoint `http://botmux:8080/tgapi`.

State is stored at `/config/botmux/ha_integration.state.json`. To force a reconfigure after changing the token or port — delete this file and restart the add-on.

After the first start, open Ingress — you are signed in automatically with your Home Assistant account. For direct access on port `8080` (without Ingress), BotMux login is still required (`admin` / `admin` by default; change the password in settings).

## Disable auto-configuration

```yaml
homeassistant_auto_configure: false
```

Then configure BotMux and HA manually (see [BotMux documentation](https://botmux.mintlify.app/)): Long Poll in the UI, Polling in HA, and `http://botmux:8080/tgapi`.

## Migrating from the cloud API (important)

When **reconfiguring** the **Telegram bot** integration in the UI, if the endpoint changes from `https://api.telegram.org` to BotMux while the integration is **loaded**, Home Assistant calls **`logOut`** on the cloud — that blocks the same token for ~10 minutes.

The add-on auto-configuration is safer:

1. **Disables** the `telegram_bot` integration in HA (unload, without `logOut`).
2. Reconfigures the endpoint to `http://<add-on-hostname>:8080/tgapi` via config flow.
3. **Enables** the integration again.

Manual order in the UI: **disable** the integration → change API endpoint → **enable** again.

## Ingress (Web UI in Home Assistant)

BotMux serves absolute paths (`/api/...`). The add-on runs **nginx** on `port` (8080) with `sub_filter` on the `X-Ingress-Path` header so the UI works under URLs like `/api/hassio/ingress/...`. `/tgapi` for HA goes through the same nginx to internal BotMux (8090).

**Single sign-on:** Supervisor passes `X-Remote-User-Id`, `X-Remote-User-Name`, and `X-Remote-User-Display-Name` for the already authenticated HA user. Nginx trusts these only from the internal hassio network and injects the internal BotMux API key — no separate login form or password change on first Ingress access. Direct access on `:8080` from outside the container still requires BotMux login (`admin` / `admin` by default — change the password in settings if you use that path).

## Important

- One token — one poller to Telegram; do not connect the same bot directly to `api.telegram.org` from HA.
- **Broadcast** (send-only) does not need BotMux.
- Manual reverse proxy to the HA webhook is not used when auto-configuration is enabled.

## Links

- Upstream: https://github.com/skrashevich/botmux
- Docker image: `ghcr.io/skrashevich/botmux`
