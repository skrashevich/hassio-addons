# Shelley

Shelley is a web-based coding agent that can run inside Home Assistant OS as an add-on.

This add-on wraps the upstream project:

- https://github.com/boldsoftware/shelley

## Features

- Ingress UI inside Home Assistant
- Persistent SQLite database in `/config/shelley`
- Optional API keys for Anthropic, OpenAI, Gemini, and Fireworks
- Access to Home Assistant Supervisor API and Docker API for host management workflows

## Configuration

Example configuration:

```yaml
port: 9000
db_path: /config/shelley/shelley.db
config_path: /config/shelley/shelley.json
default_model: ""
system_prompt: ""
working_dir: /config
debug: false
require_header: ""
anthropic_api_key: ""
openai_api_key: ""
gemini_api_key: ""
fireworks_api_key: ""
```

Notes:

- `config_path` points to Shelley `shelley.json` config (optional).
- `system_prompt` overrides Shelley system prompt instructions for new conversations.
- `working_dir` is where shell and git operations start.
- API keys are optional but needed for cloud LLM providers.
