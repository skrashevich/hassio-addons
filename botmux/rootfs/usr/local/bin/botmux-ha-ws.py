#!/usr/bin/env python3
"""Home Assistant WebSocket helper for add-on (Supervisor token auth)."""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

try:
    import websocket
except ImportError as exc:  # pragma: no cover
    print(f"websocket-client is required: {exc}", file=sys.stderr)
    sys.exit(2)

WS_URL = os.environ.get("BOTMUX_HA_WS_URL", "ws://supervisor/core/api/websocket")
REST_URL = os.environ.get("BOTMUX_HA_REST_URL", "http://supervisor/core/api")
TOKEN = os.environ.get("SUPERVISOR_TOKEN", "")
FLOW_IDS_FILE = Path(os.environ.get("BOTMUX_FLOW_IDS_FILE", "/config/botmux/.ha_config_flow_ids"))


def ws_call(message: dict, timeout: float = 60.0):
    if not TOKEN:
        raise RuntimeError("SUPERVISOR_TOKEN is not set")

    ws = websocket.create_connection(WS_URL, timeout=timeout)
    try:
        auth_required = json.loads(ws.recv())
        if auth_required.get("type") != "auth_required":
            raise RuntimeError(f"unexpected websocket greeting: {auth_required}")

        ws.send(json.dumps({"access_token": TOKEN}))
        auth_ok = json.loads(ws.recv())
        if auth_ok.get("type") != "auth_ok":
            raise RuntimeError(f"websocket auth failed: {auth_ok}")

        msg_id = int(time.time() * 1000) % 1_000_000
        message = {**message, "id": msg_id}
        ws.send(json.dumps(message))

        deadline = time.time() + timeout
        while time.time() < deadline:
            raw = ws.recv()
            if not raw:
                continue
            payload = json.loads(raw)
            if payload.get("id") == msg_id:
                if not payload.get("success", True):
                    raise RuntimeError(json.dumps(payload.get("error", payload)))
                return payload.get("result", payload)
        raise RuntimeError("websocket call timed out")
    finally:
        ws.close()


def rest_request(method: str, path: str) -> bool:
    req = urllib.request.Request(
        f"{REST_URL}{path}",
        method=method,
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30):
            return True
    except urllib.error.HTTPError as err:
        if err.code in (404, 405):
            return False
        raise RuntimeError(f"{method} {path} failed: HTTP {err.code}") from err


def load_tracked_flow_ids() -> list[str]:
    if not FLOW_IDS_FILE.exists():
        return []
    try:
        data = json.loads(FLOW_IDS_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if isinstance(data, list):
        return [str(item) for item in data if item]
    return []


def save_tracked_flow_ids(flow_ids: list[str]) -> None:
    FLOW_IDS_FILE.parent.mkdir(parents=True, exist_ok=True)
    unique = []
    for flow_id in flow_ids:
        if flow_id and flow_id not in unique:
            unique.append(flow_id)
    FLOW_IDS_FILE.write_text(json.dumps(unique), encoding="utf-8")


def track_flow_id(flow_id: str) -> None:
    flow_ids = load_tracked_flow_ids()
    if flow_id not in flow_ids:
        flow_ids.append(flow_id)
    save_tracked_flow_ids(flow_ids)


def clear_tracked_flow_ids() -> None:
    if FLOW_IDS_FILE.exists():
        FLOW_IDS_FILE.unlink()


def disable_entry(entry_id: str) -> None:
    ws_call(
        {
            "type": "config_entries/disable",
            "entry_id": entry_id,
            "disabled_by": "user",
        }
    )


def enable_entry(entry_id: str) -> None:
    ws_call(
        {
            "type": "config_entries/disable",
            "entry_id": entry_id,
            "disabled_by": None,
        }
    )


def abort_flow_id(flow_id: str) -> bool:
    return rest_request("DELETE", f"/config/config_entries/flow/{flow_id}")


def abort_flows(handler: str) -> int:
    aborted = 0
    seen: set[str] = set()

    for flow_id in load_tracked_flow_ids():
        if flow_id in seen:
            continue
        seen.add(flow_id)
        if abort_flow_id(flow_id):
            aborted += 1

    # HA hides user/reconfigure flows from flow/progress; tracked IDs cover those.
    flows = ws_call({"type": "config_entries/flow/progress"})
    if isinstance(flows, list):
        for flow in flows:
            if flow.get("handler") != handler:
                continue
            flow_id = flow.get("flow_id")
            if not flow_id or flow_id in seen:
                continue
            seen.add(flow_id)
            if abort_flow_id(flow_id):
                aborted += 1

    clear_tracked_flow_ids()
    return aborted


def main() -> int:
    if len(sys.argv) < 2:
        print(
            f"usage: {sys.argv[0]} disable|enable ENTRY_ID | abort-flows HANDLER | track-flow FLOW_ID | clear-flows",
            file=sys.stderr,
        )
        return 1

    action = sys.argv[1]
    if action == "abort-flows":
        if len(sys.argv) != 3:
            print(f"usage: {sys.argv[0]} abort-flows HANDLER", file=sys.stderr)
            return 1
        print(abort_flows(sys.argv[2]))
        return 0

    if action == "track-flow":
        if len(sys.argv) != 3:
            print(f"usage: {sys.argv[0]} track-flow FLOW_ID", file=sys.stderr)
            return 1
        track_flow_id(sys.argv[2])
        return 0

    if action == "clear-flows":
        clear_tracked_flow_ids()
        return 0

    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} disable|enable ENTRY_ID", file=sys.stderr)
        return 1

    entry_id = sys.argv[2]
    if action == "disable":
        disable_entry(entry_id)
    elif action == "enable":
        enable_entry(entry_id)
    else:
        print(f"unknown action: {action}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
