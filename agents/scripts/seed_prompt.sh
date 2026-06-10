#!/usr/bin/env bash
set -euo pipefail

# Seed prompt injector (one-shot).
# Intended to be run on a schedule by seed_prompt_loop.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
SEED_CONFIG_FILE="${TURNLOOP_SEED_CONFIG_FILE:-${REPO_ROOT}/agents/config/seed_config.env}"
INBOX_DIR="${TURNLOOP_INBOX_DIR:-${REPO_ROOT}/agents/ideas/inbox}"
STATE_DIR="${TURNLOOP_STATE_DIR:-${REPO_ROOT}/agents/.tmp}"
LOCK_FILE="${TURNLOOP_SEED_LOCK_FILE:-${STATE_DIR}/seed_prompt.lock}"
LAST_SEED_EPOCH_FILE="${TURNLOOP_LAST_SEED_EPOCH_FILE:-${STATE_DIR}/last_seed_epoch.txt}"
SEED_INDEX_FILE="${TURNLOOP_SEED_INDEX_FILE:-${STATE_DIR}/seed_prompt_index.txt}"
SEED_RESULT_FILE="${TURNLOOP_SEED_RESULT_FILE:-${STATE_DIR}/last_seed_result.txt}"
USAGE_FILE_DEFAULT="${STATE_DIR}/usage_remaining_pct.txt"

DEFAULT_PROMPTS_DIR="${REPO_ROOT}/agents/prompts/seed"
DEFAULT_INTERVAL_SECS="${SEED_PROMPT_SLEEP_SECS:-21600}"
DEFAULT_USAGE_SOURCE="${TURNLOOP_USAGE_SOURCE:-codex}"
DEFAULT_USAGE_THRESHOLD=10
DEFAULT_USAGE_FAILURE_BEHAVIOR="skip"
DEFAULT_USAGE_PROBE_TIMEOUT_SECS="${SEED_USAGE_PROBE_TIMEOUT_SECS:-15}"

SEED_PROMPTS_DIR=""
SEED_INTERVAL_SECS=""
SEED_MIN_INTERVAL_SECS=""
SEED_USAGE_SOURCE=""
SEED_USAGE_MIN_REMAINING_PCT=""
SEED_USAGE_FAILURE_BEHAVIOR=""
SEED_USAGE_PROBE_TIMEOUT_SECS=""
SEED_USAGE_FILE=""
SEED_USAGE_CMD=""

mkdir -p "$INBOX_DIR" "$STATE_DIR"

log() {
  local ts
  ts="$(date '+%F %T')"
  printf '[%s] %s\n' "$ts" "$1"
}

log_err() {
  local ts
  ts="$(date '+%F %T')"
  printf '[%s] %s\n' "$ts" "$1" >&2
}

resolve_repo_path() {
  local raw_path="${1:-}"
  if [ -z "$raw_path" ]; then
    printf '\n'
    return 0
  fi
  if [[ "$raw_path" = /* ]]; then
    printf '%s\n' "$raw_path"
    return 0
  fi
  printf '%s\n' "${REPO_ROOT}/${raw_path}"
}

sanitize_positive_int() {
  local value="${1:-}"
  local fallback="${2:-1}"
  if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
    printf '%s\n' "$value"
    return 0
  fi
  printf '%s\n' "$fallback"
}

sanitize_nonnegative_int() {
  local value="${1:-}"
  local fallback="${2:-0}"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$value"
    return 0
  fi
  printf '%s\n' "$fallback"
}

sanitize_percentage() {
  local value="${1:-}"
  local fallback="${2:-10}"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    if [ "$value" -gt 100 ]; then
      printf '100\n'
      return 0
    fi
    printf '%s\n' "$value"
    return 0
  fi
  printf '%s\n' "$fallback"
}

sanitize_usage_failure_behavior() {
  case "${1:-}" in
    continue)
      printf 'continue\n'
      ;;
    skip|*)
      printf 'skip\n'
      ;;
  esac
}

load_seed_config() {
  SEED_PROMPTS_DIR=""
  SEED_INTERVAL_SECS=""
  SEED_MIN_INTERVAL_SECS=""
  SEED_USAGE_SOURCE=""
  SEED_USAGE_MIN_REMAINING_PCT=""
  SEED_USAGE_FAILURE_BEHAVIOR=""
  SEED_USAGE_PROBE_TIMEOUT_SECS=""
  SEED_USAGE_FILE=""
  SEED_USAGE_CMD=""

  if [ -f "$SEED_CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    if ! source "$SEED_CONFIG_FILE"; then
      log "WARN: failed to parse seed config file: $SEED_CONFIG_FILE; using sanitized defaults"
    fi
  fi

  SEED_PROMPTS_DIR="${TURNLOOP_SEED_PROMPTS_DIR:-${TURNLOOP_PROMPTS_DIR:-${SEED_PROMPTS_DIR:-$DEFAULT_PROMPTS_DIR}}}"
  SEED_INTERVAL_SECS="${TURNLOOP_SEED_INTERVAL_SECS:-${SEED_INTERVAL_SECS:-$DEFAULT_INTERVAL_SECS}}"
  SEED_MIN_INTERVAL_SECS="${TURNLOOP_SEED_MIN_INTERVAL_SECS:-${SEED_MIN_INTERVAL_SECS:-$SEED_INTERVAL_SECS}}"
  SEED_USAGE_SOURCE="${TURNLOOP_SEED_USAGE_SOURCE:-${SEED_USAGE_SOURCE:-$DEFAULT_USAGE_SOURCE}}"
  SEED_USAGE_MIN_REMAINING_PCT="${TURNLOOP_SEED_USAGE_MIN_REMAINING_PCT:-${SEED_USAGE_MIN_REMAINING_PCT:-$DEFAULT_USAGE_THRESHOLD}}"
  SEED_USAGE_FAILURE_BEHAVIOR="${TURNLOOP_SEED_USAGE_FAILURE_BEHAVIOR:-${SEED_USAGE_FAILURE_BEHAVIOR:-$DEFAULT_USAGE_FAILURE_BEHAVIOR}}"
  SEED_USAGE_PROBE_TIMEOUT_SECS="${TURNLOOP_SEED_USAGE_PROBE_TIMEOUT_SECS:-${SEED_USAGE_PROBE_TIMEOUT_SECS:-$DEFAULT_USAGE_PROBE_TIMEOUT_SECS}}"
  SEED_USAGE_FILE="${TURNLOOP_SEED_USAGE_FILE:-${SEED_USAGE_FILE:-${TURNLOOP_USAGE_FILE:-$USAGE_FILE_DEFAULT}}}"
  SEED_USAGE_CMD="${TURNLOOP_SEED_USAGE_CMD:-${SEED_USAGE_CMD:-${TURNLOOP_USAGE_CMD:-}}}"

  SEED_PROMPTS_DIR="$(resolve_repo_path "$SEED_PROMPTS_DIR")"
  SEED_USAGE_FILE="$(resolve_repo_path "$SEED_USAGE_FILE")"
  SEED_INTERVAL_SECS="$(sanitize_positive_int "$SEED_INTERVAL_SECS" "$DEFAULT_INTERVAL_SECS")"
  SEED_MIN_INTERVAL_SECS="$(sanitize_nonnegative_int "$SEED_MIN_INTERVAL_SECS" "$SEED_INTERVAL_SECS")"
  SEED_USAGE_MIN_REMAINING_PCT="$(sanitize_percentage "$SEED_USAGE_MIN_REMAINING_PCT" "$DEFAULT_USAGE_THRESHOLD")"
  SEED_USAGE_FAILURE_BEHAVIOR="$(sanitize_usage_failure_behavior "$SEED_USAGE_FAILURE_BEHAVIOR")"
  SEED_USAGE_PROBE_TIMEOUT_SECS="$(sanitize_positive_int "$SEED_USAGE_PROBE_TIMEOUT_SECS" "$DEFAULT_USAGE_PROBE_TIMEOUT_SECS")"
}

acquire_lock() {
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    log "Another seed_prompt.sh invocation is already running; skipping"
    return 1
  fi
}

is_int() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

record_seed_result() {
  local result="${1:-error}"
  mkdir -p "$(dirname "$SEED_RESULT_FILE")"
  printf '%s\n' "$result" > "$SEED_RESULT_FILE"
}

enforce_min_interval() {
  if ! is_int "$SEED_MIN_INTERVAL_SECS" || [ "$SEED_MIN_INTERVAL_SECS" -le 0 ]; then
    return 0
  fi
  local now_epoch
  now_epoch="$(date +%s)"
  local last_epoch=""
  if [ -f "$LAST_SEED_EPOCH_FILE" ]; then
    last_epoch="$(tr -d '\r' < "$LAST_SEED_EPOCH_FILE" || true)"
  fi
  if is_int "$last_epoch"; then
    local elapsed=$((now_epoch - last_epoch))
    if [ "$elapsed" -lt "$SEED_MIN_INTERVAL_SECS" ]; then
      local wait_for=$((SEED_MIN_INTERVAL_SECS - elapsed))
      log "Last seed was ${elapsed}s ago; waiting ${wait_for}s more before next seed"
      record_seed_result "too_early"
      return 10
    fi
  fi
}

record_seed_timestamp() {
  date +%s > "$LAST_SEED_EPOCH_FILE"
}

record_seed_index() {
  local index="$1"
  printf '%s\n' "$index" > "$SEED_INDEX_FILE"
}

normalize_pct() {
  local raw="${1:-}"
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

read_usage_file_pct() {
  if [ ! -f "$SEED_USAGE_FILE" ]; then
    return 1
  fi
  local raw=""
  raw="$(head -n 1 "$SEED_USAGE_FILE" 2>/dev/null || true)"
  normalize_pct "$raw" || return 1
}

write_usage_file_pct() {
  local pct="${1:-}"
  if ! normalize_pct "$pct" >/dev/null 2>&1; then
    return 1
  fi
  mkdir -p "$(dirname "$SEED_USAGE_FILE")"
  printf '%s\n' "$pct" > "$SEED_USAGE_FILE"
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
  STATE_DIR="$STATE_DIR" SEED_USAGE_PROBE_TIMEOUT_SECS="$SEED_USAGE_PROBE_TIMEOUT_SECS" python3 - <<'PY'
import json
import math
import os
import select
import subprocess
import sys
import time

debug = os.environ.get("TURNLOOP_USAGE_DEBUG") == "on"
state_dir = os.environ.get("STATE_DIR", "")
captured = []
try:
    probe_timeout = float(os.environ.get("SEED_USAGE_PROBE_TIMEOUT_SECS", "15"))
except ValueError:
    probe_timeout = 15.0
if probe_timeout <= 0:
    probe_timeout = 15.0

env = os.environ.copy()
for key in ("CODEX_THREAD_ID", "CODEX_SESSION_ID", "CODEX_CI"):
    env.pop(key, None)

proc = subprocess.Popen(
    ["codex", "app-server"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1,
    env=env,
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

def read_until(target_id: str, timeout_secs: float):
    assert proc.stdout is not None
    deadline = time.monotonic() + timeout_secs
    while time.monotonic() < deadline:
        remaining = deadline - time.monotonic()
        wait_for = min(0.25, max(remaining, 0.0))
        ready, _, _ = select.select([proc.stdout], [], [], wait_for)
        if not ready:
            continue
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
    return None

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
    if read_until("1", probe_timeout) is None:
        write_debug()
        raise SystemExit(1)

    send({"id": "2", "method": "account/rateLimits/read", "params": None})
    response = read_until("2", probe_timeout)
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

probe_codex_remaining_pct() {
  local raw=""
  local normalized=""
  raw="$(app_server_weekly_remaining_pct || true)"
  normalized="$(normalize_pct "$raw" || true)"
  if [ -z "$normalized" ]; then
    if normalized="$(read_usage_file_pct 2>/dev/null || true)"; then
      if [ -n "$normalized" ]; then
        printf '%s' "$normalized"
        return 0
      fi
    fi
    raw="$(tmux_weekly_remaining_pct || true)"
    normalized="$(normalize_pct "$raw" || true)"
    if [ -z "$normalized" ]; then
      return 1
    fi
  fi
  write_usage_file_pct "$normalized" || true
  printf '%s' "$normalized"
}

get_remaining_pct() {
  local raw=""

  if [ -n "${TURNLOOP_USAGE_REMAINING_PCT:-}" ]; then
    raw="$TURNLOOP_USAGE_REMAINING_PCT"
    normalize_pct "$raw" || return 1
    return 0
  fi

  case "$SEED_USAGE_SOURCE" in
    file)
      read_usage_file_pct || return 1
      return 0
      ;;
    cmd)
      if [ -n "$SEED_USAGE_CMD" ]; then
        raw="$(bash -lc "$SEED_USAGE_CMD" 2>/dev/null | head -n 1 || true)"
      fi
      ;;
    codex)
      raw="$(probe_codex_remaining_pct || true)"
      ;;
    auto)
      if [ -f "$SEED_USAGE_FILE" ]; then
        read_usage_file_pct || return 1
        return 0
      elif [ -n "$SEED_USAGE_CMD" ]; then
        raw="$(bash -lc "$SEED_USAGE_CMD" 2>/dev/null | head -n 1 || true)"
      else
        raw="$(probe_codex_remaining_pct || true)"
      fi
      ;;
    none|off|disabled)
      raw=""
      ;;
    *)
      raw=""
      ;;
  esac

  normalize_pct "$raw" || return 1
}

list_prompt_entries() {
  local entries=""
  if [ ! -d "$SEED_PROMPTS_DIR" ]; then
    return 1
  fi

  while IFS= read -r path; do
    local base idx
    base="$(basename "$path")"
    if [[ "$base" =~ ^([0-9]+)([-_].+)?\.md$ ]]; then
      idx="${BASH_REMATCH[1]}"
      entries+="${idx}"$'\t'"${path}"$'\n'
    fi
  done < <(find "$SEED_PROMPTS_DIR" -maxdepth 1 -type f -name '*.md' -print 2>/dev/null)

  if [ -z "$entries" ]; then
    return 1
  fi

  printf '%s' "$entries" | sort -n -k1,1
}

prompt_file_for_index() {
  local target_index="$1"
  list_prompt_entries | awk -F'\t' -v idx="$target_index" '$1 == idx {print $2; exit}'
}

select_next_prompt() {
  local last_index="0"
  if [ -f "$SEED_INDEX_FILE" ]; then
    last_index="$(tr -d '\r' < "$SEED_INDEX_FILE" || true)"
  fi
  if ! is_int "$last_index"; then
    last_index="0"
  fi

  local next_index=1
  if [ "$last_index" -gt 0 ]; then
    next_index=$((last_index + 1))
  fi

  local prompt_path
  prompt_path="$(prompt_file_for_index "$next_index")"
  if [ -z "$prompt_path" ]; then
    next_index=1
    prompt_path="$(prompt_file_for_index "$next_index")"
  fi

  if [ -z "$prompt_path" ]; then
    log_err "ERROR: no valid seed prompts found in ${SEED_PROMPTS_DIR}; expected a file numbered 1"
    return 1
  fi

  printf '%s\t%s\n' "$next_index" "$prompt_path"
}

read_prompt_file() {
  local prompt_file="$1"
  if [ ! -f "$prompt_file" ]; then
    log_err "ERROR: missing seed prompt file: ${prompt_file}"
    return 1
  fi
  if [ ! -s "$prompt_file" ]; then
    log_err "ERROR: empty seed prompt file: ${prompt_file}"
    return 1
  fi
  cat "$prompt_file"
}

prompt_slug_from_path() {
  local prompt_index="$1"
  local prompt_path="$2"
  local base slug
  base="$(basename "$prompt_path" .md)"
  slug="$base"
  slug="${slug#"${prompt_index}"}"
  slug="${slug#-}"
  slug="${slug#_}"
  slug="$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  if [ -z "$slug" ]; then
    slug="prompt-${prompt_index}"
  fi
  printf '%s\n' "$slug"
}

emit_prompt_artifact() {
  local prompt_index="$1"
  local prompt_path="$2"
  local prompt_body="$3"
  local stamp slug file_path

  stamp="$(date '+%m-%d-%y-%H-%M-%S')"
  slug="$(prompt_slug_from_path "$prompt_index" "$prompt_path")"
  file_path="${INBOX_DIR}/${slug}-prompt-${stamp}.md"
  printf '%s\n' "$prompt_body" > "$file_path"
  printf '%s\n' "$file_path"
}

main() {
  load_seed_config
  mkdir -p "$INBOX_DIR" "$STATE_DIR"

  if ! acquire_lock; then
    record_seed_result "error"
    return 1
  fi

  local interval_rc=0
  enforce_min_interval || interval_rc=$?
  if [ "$interval_rc" -eq 10 ]; then
    return 0
  fi
  if [ "$interval_rc" -ne 0 ]; then
    return 1
  fi

  local remaining_pct=""
  remaining_pct="$(get_remaining_pct || true)"

  if [ -z "$remaining_pct" ]; then
    if [ "$SEED_USAGE_FAILURE_BEHAVIOR" = "continue" ]; then
      log "WARN: usage remaining unknown; continuing because SEED_USAGE_FAILURE_BEHAVIOR=continue"
    else
      record_seed_result "usage_unknown"
      log "WARN: usage remaining unknown; skipping seed tick"
      return 0
    fi
  fi

  if [ -n "$remaining_pct" ] && [ "$remaining_pct" -lt "$SEED_USAGE_MIN_REMAINING_PCT" ]; then
    record_seed_result "usage_below_threshold"
    log "Usage remaining ${remaining_pct}% < ${SEED_USAGE_MIN_REMAINING_PCT}% — skipping seed prompt"
    return 0
  fi

  local selection prompt_index prompt_path prompt_body file_path
  selection="$(select_next_prompt)" || return 1
  prompt_index="${selection%%$'\t'*}"
  prompt_path="${selection#*$'\t'}"
  prompt_body="$(read_prompt_file "$prompt_path")" || return 1
  file_path="$(emit_prompt_artifact "$prompt_index" "$prompt_path" "$prompt_body")"

  record_seed_timestamp
  record_seed_index "$prompt_index"
  record_seed_result "seeded"

  if [ -n "$remaining_pct" ]; then
    log "Seeded prompt: $(basename "$file_path") (prompt ${prompt_index}, usage remaining ${remaining_pct}%)"
  else
    log "Seeded prompt: $(basename "$file_path") (prompt ${prompt_index}, usage remaining unknown; continued)"
  fi
  return 0
}

if main "$@"; then
  exit 0
fi

record_seed_result "error"
exit 1
