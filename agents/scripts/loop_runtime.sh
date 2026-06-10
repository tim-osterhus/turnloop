#!/usr/bin/env bash

turnloop_runtime_is_sourced() {
  [[ "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" != "$0" ]]
}

turnloop_runtime_log() {
  local loop_name="$1"
  shift || true
  local ts
  ts="$(turnloop_runtime_timestamp)"
  printf '[%s] [%s] %s\n' "$ts" "$loop_name" "$*"
}

turnloop_runtime_is_true() {
  case "${1:-}" in
    1|true|TRUE|True|yes|YES|Yes|on|ON|On)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

turnloop_runtime_sanitize_bool() {
  local value="${1:-}"
  local fallback="${2:-false}"
  if turnloop_runtime_is_true "$value"; then
    printf 'true\n'
    return 0
  fi
  case "$value" in
    0|false|FALSE|False|no|NO|No|off|OFF|Off)
      printf 'false\n'
      return 0
      ;;
    *)
      printf '%s\n' "$fallback"
      return 0
      ;;
  esac
}

turnloop_runtime_sanitize_int() {
  local value="${1:-}"
  local fallback="${2:-1}"
  if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
    printf '%s\n' "$value"
    return 0
  fi
  printf '%s\n' "$fallback"
}

turnloop_runtime_sanitize_nonneg_int() {
  local value="${1:-}"
  local fallback="${2:-0}"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$value"
    return 0
  fi
  printf '%s\n' "$fallback"
}

turnloop_runtime_timestamp() {
  local ts
  ts="$(date '+%F %T.%3N' 2>/dev/null || date '+%F %T')"
  case "$ts" in
    *N)
      ts="$(date '+%F %T')"
      ;;
  esac
  printf '%s\n' "$ts"
}

turnloop_runtime_now_ms() {
  local now
  now="$(date '+%s%3N' 2>/dev/null || true)"
  if [[ "$now" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$now"
    return 0
  fi

  python3 - <<'PY'
import time

print(int(time.time() * 1000))
PY
}

turnloop_runtime_elapsed_ms() {
  local started_ms="${1:-0}"
  local ended_ms
  ended_ms="$(turnloop_runtime_now_ms)"
  if ! [[ "$started_ms" =~ ^[0-9]+$ && "$ended_ms" =~ ^[0-9]+$ ]]; then
    printf '0\n'
    return 0
  fi
  if [ "$ended_ms" -lt "$started_ms" ]; then
    printf '0\n'
    return 0
  fi
  printf '%s\n' "$((ended_ms - started_ms))"
}

turnloop_runtime_format_elapsed_ms() {
  local elapsed_ms
  elapsed_ms="$(turnloop_runtime_sanitize_nonneg_int "${1:-0}" 0)"
  printf '%s.%03ds\n' "$((elapsed_ms / 1000))" "$((elapsed_ms % 1000))"
}

turnloop_runtime_capture_file_snapshot() {
  python3 - "$1" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
if not path.exists():
    print("0||0")
    raise SystemExit(0)

stat = path.stat()
print(f"1|{stat.st_mtime_ns}|{stat.st_size}")
PY
}

turnloop_runtime_file_snapshot_size() {
  local snapshot="$1"
  IFS='|' read -r _ _ size <<< "$snapshot"
  printf '%s\n' "${size:-0}"
}

turnloop_runtime_codex_log_chunk_is_bare_enoent_fault() {
  local log_file="$1"
  local snapshot="$2"
  python3 - "$log_file" "$(turnloop_runtime_file_snapshot_size "$snapshot")" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
start = int(sys.argv[2] or "0")

if not path.exists():
    raise SystemExit(1)

try:
    with path.open("rb") as handle:
        if start > 0:
            handle.seek(start)
        chunk = handle.read()
except OSError:
    raise SystemExit(1)

if not chunk:
    raise SystemExit(1)

text = chunk.decode("utf-8", errors="replace").replace("\r\n", "\n").replace("\r", "\n")
nonblank = [line.strip() for line in text.split("\n") if line.strip()]
if not nonblank:
    raise SystemExit(1)

target = "Error: No such file or directory (os error 2)"
raise SystemExit(0 if all(line == target for line in nonblank) else 1)
PY
}

turnloop_runtime_load_config() {
  local config_file="$1"
  local loop_name="${TURNLOOP_RUNTIME_LOOP_NAME:-runtime}"

  RUNTIME_RETRY_DELAY_SECS=3600
  RUNTIME_SLEEP_SLICE_SECS=15
  RUNTIME_REEXEC_ON_DRIFT=true
  RUNTIME_HEARTBEAT_ENABLED=true
  RUNTIME_REEXEC_EXIT_CODE=75
  RUNTIME_CONNECTIVITY_RETRY_ENABLED=true
  RUNTIME_CONNECTIVITY_CHECK_URL=https://api.openai.com/
  RUNTIME_CONNECTIVITY_CHECK_COMMAND=
  RUNTIME_CONNECTIVITY_CHECK_CONNECT_TIMEOUT_SECS=5
  RUNTIME_CONNECTIVITY_CHECK_MAX_TIME_SECS=10
  RUNTIME_CONNECTIVITY_BACKOFF_INITIAL_SECS=60
  RUNTIME_CONNECTIVITY_BACKOFF_SECOND_SECS=300
  RUNTIME_CONNECTIVITY_BACKOFF_STEADY_SECS=900
  RUNTIME_CODEX_INFRA_RETRY_ENABLED=true
  RUNTIME_CODEX_INFRA_RETRY_MAX_ATTEMPTS=3
  RUNTIME_CODEX_INFRA_BACKOFF_INITIAL_SECS=5
  RUNTIME_CODEX_INFRA_BACKOFF_SECOND_SECS=20
  RUNTIME_CODEX_INFRA_BACKOFF_STEADY_SECS=60

  if [ -f "$config_file" ]; then
    # shellcheck disable=SC1090
    if ! source "$config_file"; then
      turnloop_runtime_log "$loop_name" "WARN: failed to parse runtime config file: $config_file; using sanitized defaults"
    fi
  fi

  RUNTIME_RETRY_DELAY_SECS="$(turnloop_runtime_sanitize_int "${RUNTIME_RETRY_DELAY_SECS:-3600}" 3600)"
  RUNTIME_SLEEP_SLICE_SECS="$(turnloop_runtime_sanitize_int "${RUNTIME_SLEEP_SLICE_SECS:-15}" 15)"
  RUNTIME_REEXEC_EXIT_CODE="$(turnloop_runtime_sanitize_int "${RUNTIME_REEXEC_EXIT_CODE:-75}" 75)"
  RUNTIME_REEXEC_ON_DRIFT="$(turnloop_runtime_sanitize_bool "${RUNTIME_REEXEC_ON_DRIFT:-true}" true)"
  RUNTIME_HEARTBEAT_ENABLED="$(turnloop_runtime_sanitize_bool "${RUNTIME_HEARTBEAT_ENABLED:-true}" true)"
  RUNTIME_CONNECTIVITY_RETRY_ENABLED="$(turnloop_runtime_sanitize_bool "${RUNTIME_CONNECTIVITY_RETRY_ENABLED:-true}" true)"
  RUNTIME_CODEX_INFRA_RETRY_ENABLED="$(turnloop_runtime_sanitize_bool "${RUNTIME_CODEX_INFRA_RETRY_ENABLED:-true}" true)"
  RUNTIME_CODEX_INFRA_RETRY_MAX_ATTEMPTS="$(
    turnloop_runtime_sanitize_nonneg_int "${RUNTIME_CODEX_INFRA_RETRY_MAX_ATTEMPTS:-3}" 3
  )"
  RUNTIME_CONNECTIVITY_CHECK_CONNECT_TIMEOUT_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CONNECTIVITY_CHECK_CONNECT_TIMEOUT_SECS:-5}" 5
  )"
  RUNTIME_CONNECTIVITY_CHECK_MAX_TIME_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CONNECTIVITY_CHECK_MAX_TIME_SECS:-10}" 10
  )"
  RUNTIME_CONNECTIVITY_BACKOFF_INITIAL_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CONNECTIVITY_BACKOFF_INITIAL_SECS:-60}" 60
  )"
  RUNTIME_CONNECTIVITY_BACKOFF_SECOND_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CONNECTIVITY_BACKOFF_SECOND_SECS:-300}" 300
  )"
  RUNTIME_CONNECTIVITY_BACKOFF_STEADY_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CONNECTIVITY_BACKOFF_STEADY_SECS:-900}" 900
  )"
  RUNTIME_CODEX_INFRA_BACKOFF_INITIAL_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CODEX_INFRA_BACKOFF_INITIAL_SECS:-5}" 5
  )"
  RUNTIME_CODEX_INFRA_BACKOFF_SECOND_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CODEX_INFRA_BACKOFF_SECOND_SECS:-20}" 20
  )"
  RUNTIME_CODEX_INFRA_BACKOFF_STEADY_SECS="$(
    turnloop_runtime_sanitize_int "${RUNTIME_CODEX_INFRA_BACKOFF_STEADY_SECS:-60}" 60
  )"
}

turnloop_runtime_reload_config_if_available() {
  local config_file="${TURNLOOP_RUNTIME_CONFIG_FILE:-}"
  if [ -n "$config_file" ] && [ -f "$config_file" ]; then
    turnloop_runtime_load_config "$config_file"
  fi
}

turnloop_runtime_connectivity_probe() {
  local command_override="${RUNTIME_CONNECTIVITY_CHECK_COMMAND:-}"
  local url="${RUNTIME_CONNECTIVITY_CHECK_URL:-https://api.openai.com/}"
  local connect_timeout="${RUNTIME_CONNECTIVITY_CHECK_CONNECT_TIMEOUT_SECS:-5}"
  local max_time="${RUNTIME_CONNECTIVITY_CHECK_MAX_TIME_SECS:-10}"

  if [ -n "$command_override" ]; then
    bash -lc "$command_override" >/dev/null 2>&1
    return $?
  fi

  if command -v curl >/dev/null 2>&1; then
    curl \
      --silent \
      --show-error \
      --output /dev/null \
      --connect-timeout "$connect_timeout" \
      --max-time "$max_time" \
      "$url" >/dev/null 2>&1
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$url" "$max_time" <<'PY' >/dev/null 2>&1
import socket
import sys
import urllib.error
import urllib.request

url = sys.argv[1]
timeout = float(sys.argv[2])

try:
    with urllib.request.urlopen(url, timeout=timeout):
        pass
except urllib.error.HTTPError:
    raise SystemExit(0)
except (urllib.error.URLError, socket.timeout, TimeoutError):
    raise SystemExit(1)
raise SystemExit(0)
PY
    return $?
  fi

  return 2
}

turnloop_runtime_connectivity_backoff_secs() {
  local attempt="${1:-1}"
  if [ "$attempt" -le 1 ]; then
    printf '%s\n' "${RUNTIME_CONNECTIVITY_BACKOFF_INITIAL_SECS:-60}"
    return 0
  fi
  if [ "$attempt" -eq 2 ]; then
    printf '%s\n' "${RUNTIME_CONNECTIVITY_BACKOFF_SECOND_SECS:-300}"
    return 0
  fi
  printf '%s\n' "${RUNTIME_CONNECTIVITY_BACKOFF_STEADY_SECS:-900}"
}

turnloop_runtime_codex_infra_backoff_secs() {
  local attempt="${1:-1}"
  if [ "$attempt" -le 1 ]; then
    printf '%s\n' "${RUNTIME_CODEX_INFRA_BACKOFF_INITIAL_SECS:-5}"
    return 0
  fi
  if [ "$attempt" -eq 2 ]; then
    printf '%s\n' "${RUNTIME_CODEX_INFRA_BACKOFF_SECOND_SECS:-20}"
    return 0
  fi
  printf '%s\n' "${RUNTIME_CODEX_INFRA_BACKOFF_STEADY_SECS:-60}"
}

turnloop_runtime_wait_for_connectivity_recovery() {
  local status_value="${1:-${TURNLOOP_RUNTIME_LAST_STATUS:-}}"
  local failed_probes=0
  local delay

  if [ "${RUNTIME_CONNECTIVITY_RETRY_ENABLED:-true}" != "true" ]; then
    return 1
  fi

  turnloop_runtime_reload_config_if_available
  if turnloop_runtime_connectivity_probe; then
    return 1
  fi

  while true; do
    failed_probes=$((failed_probes + 1))
    delay="$(turnloop_runtime_connectivity_backoff_secs "$failed_probes")"
    turnloop_runtime_log "${TURNLOOP_RUNTIME_LOOP_NAME:-runtime}" \
      "Connectivity probe failed; waiting ${delay}s before retrying runner invocation"
    turnloop_runtime_wait \
      "$delay" \
      "connectivity_backoff" \
      "waiting ${delay}s for network/provider connectivity to return" \
      "$status_value"
    turnloop_runtime_reload_config_if_available
    if turnloop_runtime_connectivity_probe; then
      turnloop_runtime_log "${TURNLOOP_RUNTIME_LOOP_NAME:-runtime}" \
        "Connectivity restored after ${failed_probes} failed probe(s)"
      return 0
    fi
  done
}

turnloop_runtime_watch_hash() {
  python3 - "$@" <<'PY'
import hashlib
import pathlib
import sys

h = hashlib.sha256()
for raw_path in sys.argv[1:]:
    path = pathlib.Path(raw_path)
    h.update(str(path).encode("utf-8", "replace"))
    h.update(b"\0")
    if not path.exists():
        h.update(b"MISSING")
        h.update(b"\0")
        continue
    stat = path.stat()
    h.update(str(stat.st_mtime_ns).encode("utf-8"))
    h.update(b"\0")
    if path.is_file():
        with path.open("rb") as handle:
            while True:
                chunk = handle.read(65536)
                if not chunk:
                    break
                h.update(chunk)
print(h.hexdigest())
PY
}

turnloop_runtime_write_state() {
  local phase="${1:-unknown}"
  local detail="${2:-}"
  local status_value="${3:-${TURNLOOP_RUNTIME_LAST_STATUS:-}}"
  local mode="${4:-${TURNLOOP_RUNTIME_MODE:-worker}}"
  local state_file="${TURNLOOP_RUNTIME_STATE_FILE:-}"
  if [ -z "$state_file" ]; then
    return 0
  fi

  TURNLOOP_RUNTIME_LAST_STATUS="$status_value"

  if [ "${RUNTIME_HEARTBEAT_ENABLED:-true}" != "true" ]; then
    return 0
  fi

  local watch_hash
  watch_hash="$(turnloop_runtime_watch_hash "${TURNLOOP_RUNTIME_WATCH_FILES[@]}")"

  python3 - "$state_file" \
    "${TURNLOOP_RUNTIME_LOOP_NAME:-runtime}" \
    "$mode" \
    "${TURNLOOP_RUNTIME_PID:-$$}" \
    "${TURNLOOP_RUNTIME_STARTED_AT:-}" \
    "$phase" \
    "$detail" \
    "$status_value" \
    "${TURNLOOP_RUNTIME_SCRIPT_PATH:-}" \
    "${TURNLOOP_RUNTIME_CONFIG_FILE:-}" \
    "${TURNLOOP_RUNTIME_WORK_ROOT:-}" \
    "${TURNLOOP_RUNTIME_REPO_ROOT:-}" \
    "$watch_hash" \
    "${TURNLOOP_RUNTIME_RESTART_COUNT:-0}" \
    "${TURNLOOP_RUNTIME_SUPERVISOR_PID:-}" \
    "${TURNLOOP_RUNTIME_LAST_ERROR:-}" \
    <<'PY'
import json
import pathlib
import sys
from datetime import datetime, timezone

(
    state_path,
    loop_name,
    mode,
    pid,
    started_at,
    phase,
    detail,
    status_value,
    script_path,
    config_path,
    work_root,
    repo_root,
    watch_hash,
    restart_count,
    supervisor_pid,
    last_error,
) = sys.argv[1:]

path = pathlib.Path(state_path)
path.parent.mkdir(parents=True, exist_ok=True)
payload = {
    "loop": loop_name,
    "mode": mode,
    "pid": pid,
    "phase": phase,
    "detail": detail,
    "status": status_value,
    "started_at": started_at,
    "updated_at": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
    "script_path": script_path,
    "config_path": config_path,
    "work_root": work_root,
    "repo_root": repo_root,
    "watch_hash": watch_hash,
    "restart_count": int(restart_count or "0"),
    "supervisor_pid": supervisor_pid,
    "last_error": last_error,
}
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

turnloop_runtime_init_worker() {
  local loop_name="$1"
  local script_path="$2"
  local repo_root="$3"
  local work_root="$4"
  local runtime_config_file="$5"
  local state_dir="$6"
  shift 6

  TURNLOOP_RUNTIME_LOOP_NAME="$loop_name"
  TURNLOOP_RUNTIME_SCRIPT_PATH="$script_path"
  TURNLOOP_RUNTIME_REPO_ROOT="$repo_root"
  TURNLOOP_RUNTIME_WORK_ROOT="$work_root"
  TURNLOOP_RUNTIME_CONFIG_FILE="$runtime_config_file"
  TURNLOOP_RUNTIME_STATE_FILE="${state_dir}/${loop_name}.json"
  TURNLOOP_RUNTIME_MODE="worker"
  TURNLOOP_RUNTIME_PID="$$"
  TURNLOOP_RUNTIME_STARTED_AT="$(date -Iseconds)"
  TURNLOOP_RUNTIME_RESTART_COUNT="${TURNLOOP_RUNTIME_RESTART_COUNT:-0}"
  TURNLOOP_RUNTIME_WATCH_FILES=("$@")
  TURNLOOP_RUNTIME_LAST_ERROR=""

  mkdir -p "$state_dir"
  turnloop_runtime_load_config "$runtime_config_file"
  TURNLOOP_RUNTIME_BASELINE_HASH="$(turnloop_runtime_watch_hash "${TURNLOOP_RUNTIME_WATCH_FILES[@]}")"
  turnloop_runtime_write_state "boot" "worker started" ""
}

turnloop_runtime_request_reexec_if_needed() {
  local phase="${1:-runtime_drift}"
  local detail="${2:-watched files changed on disk}"
  local status_value="${3:-${TURNLOOP_RUNTIME_LAST_STATUS:-}}"

  if [ "${RUNTIME_REEXEC_ON_DRIFT:-true}" != "true" ]; then
    return 0
  fi

  local current_hash
  current_hash="$(turnloop_runtime_watch_hash "${TURNLOOP_RUNTIME_WATCH_FILES[@]}")"
  if [ "$current_hash" = "${TURNLOOP_RUNTIME_BASELINE_HASH:-}" ]; then
    return 0
  fi

  turnloop_runtime_write_state "$phase" "$detail" "$status_value"
  turnloop_runtime_log "${TURNLOOP_RUNTIME_LOOP_NAME:-runtime}" "Watched files changed on disk; requesting restart"
  exit "${RUNTIME_REEXEC_EXIT_CODE:-75}"
}

turnloop_runtime_touch() {
  local phase="${1:-running}"
  local detail="${2:-}"
  local status_value="${3:-${TURNLOOP_RUNTIME_LAST_STATUS:-}}"
  turnloop_runtime_request_reexec_if_needed "runtime_drift" "watched files changed before phase transition" "$status_value"
  turnloop_runtime_write_state "$phase" "$detail" "$status_value"
}

turnloop_runtime_wait() {
  local total_secs="${1:-0}"
  local phase="${2:-waiting}"
  local detail="${3:-}"
  local status_value="${4:-${TURNLOOP_RUNTIME_LAST_STATUS:-}}"
  local remaining
  remaining="$(turnloop_runtime_sanitize_nonneg_int "$total_secs" 0)"

  if [ "$remaining" -eq 0 ]; then
    turnloop_runtime_request_reexec_if_needed "runtime_drift" "watched files changed during ${phase}" "$status_value"
    turnloop_runtime_write_state "$phase" "$detail" "$status_value"
    return 0
  fi

  while [ "$remaining" -gt 0 ]; do
    turnloop_runtime_request_reexec_if_needed "runtime_drift" "watched files changed during ${phase}" "$status_value"
    turnloop_runtime_write_state "$phase" "$detail" "$status_value"

    local slice="${RUNTIME_SLEEP_SLICE_SECS:-15}"
    if [ "$slice" -gt "$remaining" ]; then
      slice="$remaining"
    fi
    sleep "$slice"
    remaining=$((remaining - slice))
  done
}

turnloop_runtime_on_error() {
  local rc="$1"
  local line_no="$2"
  local command="$3"
  TURNLOOP_RUNTIME_LAST_ERROR="rc=${rc} line=${line_no} command=${command}"
  turnloop_runtime_write_state "error" "$TURNLOOP_RUNTIME_LAST_ERROR" "${TURNLOOP_RUNTIME_LAST_STATUS:-}"
  turnloop_runtime_log "${TURNLOOP_RUNTIME_LOOP_NAME:-runtime}" "Unhandled error: ${TURNLOOP_RUNTIME_LAST_ERROR}"
}

turnloop_runtime_supervise() {
  local loop_name="$1"
  local script_path="$2"
  local repo_root="$3"
  local work_root="$4"
  local runtime_config_file="$5"
  local state_dir="$6"
  shift 6

  TURNLOOP_RUNTIME_LOOP_NAME="$loop_name"
  TURNLOOP_RUNTIME_SCRIPT_PATH="$script_path"
  TURNLOOP_RUNTIME_REPO_ROOT="$repo_root"
  TURNLOOP_RUNTIME_WORK_ROOT="$work_root"
  TURNLOOP_RUNTIME_CONFIG_FILE="$runtime_config_file"
  TURNLOOP_RUNTIME_STATE_FILE="${state_dir}/${loop_name}.json"
  TURNLOOP_RUNTIME_MODE="supervisor"
  TURNLOOP_RUNTIME_PID="$$"
  TURNLOOP_RUNTIME_STARTED_AT="$(date -Iseconds)"
  TURNLOOP_RUNTIME_SUPERVISOR_PID="$$"
  TURNLOOP_RUNTIME_WATCH_FILES=("$script_path" "$runtime_config_file")
  TURNLOOP_RUNTIME_RESTART_COUNT=0

  mkdir -p "$state_dir"

  while true; do
    turnloop_runtime_load_config "$runtime_config_file"
    turnloop_runtime_write_state "launching_worker" "starting loop worker" ""
    set +e
    env TURNLOOP_RUNTIME_CHILD=1 \
      TURNLOOP_RUNTIME_RESTART_COUNT="${TURNLOOP_RUNTIME_RESTART_COUNT}" \
      TURNLOOP_RUNTIME_SUPERVISOR_PID="$$" \
      bash "$script_path" "$@"
    local rc=$?
    set -e

    if [ "$rc" -eq 0 ]; then
      turnloop_runtime_write_state "stopped" "worker exited cleanly" ""
      return 0
    fi

    if [ "$rc" -eq "${RUNTIME_REEXEC_EXIT_CODE:-75}" ]; then
      TURNLOOP_RUNTIME_RESTART_COUNT=$((TURNLOOP_RUNTIME_RESTART_COUNT + 1))
      turnloop_runtime_write_state "restarting" "watched files changed; relaunching worker" ""
      continue
    fi

    turnloop_runtime_log "$loop_name" "Worker exited with rc=${rc}; retrying in ${RUNTIME_RETRY_DELAY_SECS}s"
    local remaining="${RUNTIME_RETRY_DELAY_SECS:-3600}"
    while [ "$remaining" -gt 0 ]; do
      turnloop_runtime_load_config "$runtime_config_file"
      turnloop_runtime_write_state "retry_backoff" "worker exited rc=${rc}; retry in ${remaining}s" ""
      local slice="${RUNTIME_SLEEP_SLICE_SECS:-15}"
      if [ "$slice" -gt "$remaining" ]; then
        slice="$remaining"
      fi
      sleep "$slice"
      remaining=$((remaining - slice))
    done
    TURNLOOP_RUNTIME_RESTART_COUNT=$((TURNLOOP_RUNTIME_RESTART_COUNT + 1))
  done
}
