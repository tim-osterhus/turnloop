#!/usr/bin/env bash
set -euo pipefail

# Seed prompt injector (one-shot).
# Intended to be run on a schedule (e.g., every 6 hours) by an external cron.
# Uses a weekly-usage percentage from an explicit override/file when available.
# Codex TUI probing is only a fallback because the status surface can change.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
INBOX_DIR="${REPO_ROOT}/agents/ideas/inbox"
STATE_DIR="${REPO_ROOT}/agents/.tmp"
TOGGLE_FILE="${STATE_DIR}/seed_prompt_toggle.txt"
USAGE_FILE_DEFAULT="${STATE_DIR}/usage_remaining_pct.txt"
USAGE_SOURCE="${TURNLOOP_USAGE_SOURCE:-codex}"
PROMPTS_DIR="${TURNLOOP_PROMPTS_DIR:-${REPO_ROOT}/agents/prompts}"
PROMPT_A_FILE="${TURNLOOP_SELF_PROMPT_FILE:-${PROMPTS_DIR}/self_prompt.md}"
PROMPT_B_FILE="${TURNLOOP_GAME_PROMPT_FILE:-${PROMPTS_DIR}/game_prompt.md}"

MIN_REMAINING_PCT=10

mkdir -p "$INBOX_DIR" "$STATE_DIR"

log() {
  local ts
  ts="$(date '+%F %T')"
  printf '[%s] %s\n' "$ts" "$1"
}

read_prompt_file() {
  local prompt_file="$1"
  local prompt_label="$2"
  if [ ! -f "$prompt_file" ]; then
    log "ERROR: missing ${prompt_label} seed prompt file: ${prompt_file}"
    return 1
  fi
  if [ ! -s "$prompt_file" ]; then
    log "ERROR: empty ${prompt_label} seed prompt file: ${prompt_file}"
    return 1
  fi
  cat "$prompt_file"
}

PROMPT_A="$(read_prompt_file "$PROMPT_A_FILE" "Turnloop")" || exit 1
PROMPT_B="$(read_prompt_file "$PROMPT_B_FILE" "Corebound")" || exit 1

normalize_pct() {
  local raw="$1"
  raw="${raw//%/}"
  raw="${raw//[[:space:]]/}"
  if [[ "$raw" =~ ^[0-9]+$ ]]; then
    if [ "$raw" -gt 100 ]; then
      raw=100
    fi
    printf '%s' "$raw"
    return 0
  fi
  return 1
}

strip_ansi() {
  sed -r 's/\x1b\[[0-9;]*[A-Za-z]//g'
}

parse_weekly_pct() {
  awk '
    BEGIN { IGNORECASE=1 }
    /(Weekly limit|weekly remaining|weekly usage)/ && !seen {
      for (i=1; i<=NF; i++) {
        if ($i ~ /^[0-9]+%$/) { gsub(/%/,"",$i); print $i; seen=1; exit }
      }
    }
  '
}

app_server_weekly_remaining_pct() {
  if ! command -v python3 >/dev/null 2>&1; then
    return 1
  fi
  STATE_DIR="$STATE_DIR" python3 - <<'PY'
import json
import math
import os
import subprocess
import sys

debug = os.environ.get("TURNLOOP_USAGE_DEBUG") == "on"
state_dir = os.environ.get("STATE_DIR", "")
captured = []

proc = subprocess.Popen(
    ["codex", "app-server"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1,
)

def write_debug() -> None:
    if not debug or not state_dir:
        return
    path = os.path.join(state_dir, "last_codex_rate_limits_raw_app_server.jsonl")
    with open(path, "w", encoding="utf-8") as fh:
        fh.writelines(captured)
    print(f"DEBUG: app-server rate-limit output saved to {path}", file=sys.stderr)

def send(obj: dict) -> None:
    assert proc.stdin is not None
    proc.stdin.write(json.dumps(obj) + "\n")
    proc.stdin.flush()

def read_until(target_id: str):
    assert proc.stdout is not None
    while True:
        line = proc.stdout.readline()
        if not line:
            return None
        captured.append(line)
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if str(obj.get("id")) == target_id:
            return obj

try:
    send(
        {
            "id": "1",
            "method": "initialize",
            "params": {
                "clientInfo": {
                    "name": "turnloop-seed-probe",
                    "version": "1.0.0",
                },
                "capabilities": None,
            },
        }
    )
    if read_until("1") is None:
        write_debug()
        raise SystemExit(1)

    send({"id": "2", "method": "account/rateLimits/read", "params": None})
    response = read_until("2")
    write_debug()
    if response is None:
        raise SystemExit(1)

    result = response.get("result") or {}
    rate_limits = result.get("rateLimits") or {}
    secondary = rate_limits.get("secondary") or {}
    used = secondary.get("usedPercent")
    if used is None:
        raise SystemExit(1)

    remaining = max(0, min(100, int(math.floor(100.0 - float(used) + 1e-9))))
    print(remaining)
    raise SystemExit(0)
finally:
    if proc.stdin is not None:
        proc.stdin.close()
    if proc.stdout is not None:
        proc.stdout.close()
    try:
        proc.terminate()
    except ProcessLookupError:
        pass
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait(timeout=5)
PY
}

tmux_weekly_remaining_pct() {
  if ! command -v tmux >/dev/null 2>&1; then
    return 1
  fi
  local session="turnloop_usage_tmp_$RANDOM"
  local capture="" status_capture=""

  if ! tmux new-session -d -s "$session" -c "$REPO_ROOT" "bash" >/dev/null 2>&1; then
    return 1
  fi

  tmux send-keys -t "${session}:0.0" \
    "env -u CODEX_THREAD_ID -u CODEX_SESSION_ID -u CODEX_CI codex --no-alt-screen" C-m >/dev/null 2>&1

  # Fixed waits to allow the TUI to fully initialize.
  sleep 20
  if ! tmux has-session -t "$session" >/dev/null 2>&1; then
    return 1
  fi
  capture="$(tmux capture-pane -t "${session}:0.0" -p -S -200 2>/dev/null || true)"
  if printf '%s' "$capture" | grep -qi "Do you trust the contents of this directory"; then
    tmux send-keys -t "${session}:0.0" "1" C-m >/dev/null 2>&1
    sleep 20
  fi

  tmux send-keys -t "${session}:0.0" "/status" C-m >/dev/null 2>&1

  sleep 20
  if ! tmux has-session -t "$session" >/dev/null 2>&1; then
    return 1
  fi
  status_capture="$(tmux capture-pane -t "${session}:0.0" -p -S -600 2>/dev/null || true)"

  tmux send-keys -t "${session}:0.0" "/exit" C-m >/dev/null 2>&1 || true
  sleep 20
  sleep 0.5
  tmux kill-session -t "$session" >/dev/null 2>&1 || true

  if [ "${TURNLOOP_USAGE_DEBUG:-off}" = "on" ]; then
    local debug_file="${STATE_DIR}/last_codex_status_raw_tmux.txt"
    printf '%s\n' "$status_capture" > "$debug_file"
    echo "DEBUG: tmux /status output saved to ${debug_file}" >&2
  fi

  printf '%s' "$status_capture" | strip_ansi | parse_weekly_pct
}

codex_weekly_remaining_pct() {
  if ! command -v codex >/dev/null 2>&1; then
    return 1
  fi
  app_server_weekly_remaining_pct || tmux_weekly_remaining_pct
}

get_remaining_pct() {
  local raw=""

  if [ -n "${TURNLOOP_USAGE_REMAINING_PCT:-}" ]; then
    raw="$TURNLOOP_USAGE_REMAINING_PCT"
  elif [ -n "${TURNLOOP_USAGE_FILE:-}" ] && [ -f "$TURNLOOP_USAGE_FILE" ]; then
    raw="$(head -n 1 "$TURNLOOP_USAGE_FILE" 2>/dev/null || true)"
  elif [ -f "$USAGE_FILE_DEFAULT" ]; then
    raw="$(head -n 1 "$USAGE_FILE_DEFAULT" 2>/dev/null || true)"
  elif [ -n "${TURNLOOP_USAGE_CMD:-}" ]; then
    raw="$(bash -lc "$TURNLOOP_USAGE_CMD" 2>/dev/null | head -n 1 || true)"
  elif [ "$USAGE_SOURCE" = "codex" ]; then
    raw="$(codex_weekly_remaining_pct || true)"
  fi

  normalize_pct "$raw" || return 1
}

remaining_pct="$(get_remaining_pct || true)"
if [ -z "$remaining_pct" ]; then
  log "WARN: usage remaining unknown; set TURNLOOP_USAGE_REMAINING_PCT or ${USAGE_FILE_DEFAULT} (or TURNLOOP_USAGE_SOURCE=codex to attempt /status). Skipping seed prompt."
  exit 0
fi

if [ "$remaining_pct" -lt "$MIN_REMAINING_PCT" ]; then
  log "Usage remaining ${remaining_pct}% < ${MIN_REMAINING_PCT}% — skipping seed prompt"
  exit 0
fi

last="A"
if [ -f "$TOGGLE_FILE" ]; then
  last="$(tr -d '\r' < "$TOGGLE_FILE" || echo B)"
fi

next="A"
if [ "$last" = "A" ]; then
  next="B"
fi

stamp="$(date '+%m-%d-%y-%H')"
if [ "$next" = "A" ]; then
  file_path="${INBOX_DIR}/turnloop-prompt-${stamp}.md"
  printf '%s\n' "$PROMPT_A" > "$file_path"
else
  file_path="${INBOX_DIR}/corebound-prompt-${stamp}.md"
  printf '%s\n' "$PROMPT_B" > "$file_path"
fi

printf '%s\n' "$next" > "$TOGGLE_FILE"
log "Seeded prompt: $(basename "$file_path") (usage remaining ${remaining_pct}%)"
