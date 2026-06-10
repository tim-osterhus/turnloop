#!/usr/bin/env bash
set -Eeuo pipefail

# Long-lived scheduler for seed_prompt.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
WORK_ROOT="${TURNLOOP_WORK_ROOT:-$REPO_ROOT}"
if [[ "$WORK_ROOT" != /* ]]; then
  WORK_ROOT="${REPO_ROOT}/${WORK_ROOT}"
fi
STATE_DIR="${TURNLOOP_STATE_DIR:-${WORK_ROOT}/agents/.tmp}"
LAST_SEED_EPOCH_FILE="${TURNLOOP_LAST_SEED_EPOCH_FILE:-${STATE_DIR}/last_seed_epoch.txt}"
NEXT_RETRY_EPOCH_FILE="${TURNLOOP_NEXT_SEED_RETRY_EPOCH_FILE:-${STATE_DIR}/next_seed_retry_epoch.txt}"
SEED_SCRIPT="${SCRIPT_DIR}/seed_prompt.sh"
SEED_CONFIG_FILE="${TURNLOOP_SEED_CONFIG_FILE:-${REPO_ROOT}/agents/config/seed_config.env}"
RUNTIME_CONFIG_FILE="${TURNLOOP_RUNTIME_CONFIG_FILE:-${REPO_ROOT}/agents/config/runtime_config.env}"
RUNTIME_STATE_DIR="${WORK_ROOT}/agents/.tmp/runtime"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/loop_runtime.sh"

mkdir -p "$STATE_DIR"

load_seed_loop_config() {
  SEED_INTERVAL_SECS=""
  SEED_MIN_INTERVAL_SECS=""
  SEED_USAGE_UNKNOWN_RETRY_SECS=""
  SEED_USAGE_LOW_RETRY_SECS=""
  SEED_ERROR_RETRY_SECS=""
  if [ -f "$SEED_CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    if ! source "$SEED_CONFIG_FILE"; then
      log "WARN: failed to parse seed config file: $SEED_CONFIG_FILE; using sanitized defaults"
    fi
  fi
  local interval="${TURNLOOP_SEED_INTERVAL_SECS:-${SEED_INTERVAL_SECS:-${SEED_PROMPT_SLEEP_SECS:-21600}}}"
  local min_interval="${TURNLOOP_SEED_MIN_INTERVAL_SECS:-${SEED_MIN_INTERVAL_SECS:-$interval}}"
  local usage_unknown_retry="${TURNLOOP_SEED_USAGE_UNKNOWN_RETRY_SECS:-${SEED_USAGE_UNKNOWN_RETRY_SECS:-300}}"
  local usage_low_retry="${TURNLOOP_SEED_USAGE_LOW_RETRY_SECS:-${SEED_USAGE_LOW_RETRY_SECS:-3600}}"
  local error_retry="${TURNLOOP_SEED_ERROR_RETRY_SECS:-${SEED_ERROR_RETRY_SECS:-300}}"
  SEED_INTERVAL_SECS="$(turnloop_runtime_sanitize_int "$interval" 21600)"
  SEED_MIN_INTERVAL_SECS="$(turnloop_runtime_sanitize_int "$min_interval" "$SEED_INTERVAL_SECS")"
  SEED_USAGE_UNKNOWN_RETRY_SECS="$(turnloop_runtime_sanitize_int "$usage_unknown_retry" 300)"
  SEED_USAGE_LOW_RETRY_SECS="$(turnloop_runtime_sanitize_int "$usage_low_retry" 3600)"
  SEED_ERROR_RETRY_SECS="$(turnloop_runtime_sanitize_int "$error_retry" 300)"
}

wait_until_next_tick() {
  local last_seed
  local retry_epoch
  local now_epoch
  local normal_due_epoch
  local next_due_epoch
  local remaining
  local slice

  while true; do
    load_seed_loop_config
    last_seed=""
    retry_epoch=""
    if [ -f "$LAST_SEED_EPOCH_FILE" ]; then
      last_seed="$(tr -d '\r' < "$LAST_SEED_EPOCH_FILE" || true)"
    fi
    if [ -f "$NEXT_RETRY_EPOCH_FILE" ]; then
      retry_epoch="$(tr -d '\r' < "$NEXT_RETRY_EPOCH_FILE" || true)"
    fi
    normal_due_epoch=0
    if [[ "$last_seed" =~ ^[0-9]+$ ]]; then
      local normal_delay="$SEED_INTERVAL_SECS"
      if [ "$SEED_MIN_INTERVAL_SECS" -gt "$normal_delay" ]; then
        normal_delay="$SEED_MIN_INTERVAL_SECS"
      fi
      normal_due_epoch=$((last_seed + normal_delay))
    fi
    now_epoch="$(date +%s)"
    next_due_epoch=0
    if [ "$normal_due_epoch" -gt "$now_epoch" ]; then
      next_due_epoch="$normal_due_epoch"
    elif [[ "$retry_epoch" =~ ^[0-9]+$ ]] && [ "$retry_epoch" -gt "$now_epoch" ]; then
      next_due_epoch="$retry_epoch"
    fi
    if [ "$next_due_epoch" -le 0 ]; then
      return 0
    fi
    remaining=$((next_due_epoch - now_epoch))
    slice="${RUNTIME_SLEEP_SLICE_SECS:-15}"
    if [ "$slice" -gt "$remaining" ]; then
      slice="$remaining"
    fi
    turnloop_runtime_wait "$slice" "seed_sleep" "waiting ${remaining}s until next seed tick"
  done
}

clear_retry_epoch() {
  rm -f "$NEXT_RETRY_EPOCH_FILE"
}

set_retry_epoch() {
  local delay_secs="${1:-0}"
  local retry_epoch
  retry_epoch=$(( $(date +%s) + delay_secs ))
  printf '%s\n' "$retry_epoch" > "$NEXT_RETRY_EPOCH_FILE"
}

read_seed_result() {
  local result_file="$1"
  if [ ! -f "$result_file" ]; then
    return 1
  fi
  head -n 1 "$result_file" 2>/dev/null | tr -d '\r'
}

run_seed_script() {
  local result_file
  local seed_result

  result_file="$(mktemp "${STATE_DIR}/seed-result.XXXXXX")"
  SEED_RUN_RC=0
  TURNLOOP_SEED_RESULT_FILE="$result_file" bash "$SEED_SCRIPT" || SEED_RUN_RC=$?
  seed_result="$(read_seed_result "$result_file" || true)"
  rm -f "$result_file"

  if [ -n "$seed_result" ]; then
    SEED_RUN_OUTCOME="$seed_result"
    return 0
  fi
  if [ "$SEED_RUN_RC" -ne 0 ]; then
    SEED_RUN_OUTCOME="error"
    return 0
  fi
  SEED_RUN_OUTCOME="error"
  return 0
}

log() {
  local ts
  ts="$(date '+%F %T')"
  printf '[%s] %s\n' "$ts" "$1"
}

if ! turnloop_runtime_is_sourced && [ "${TURNLOOP_RUNTIME_CHILD:-0}" != "1" ]; then
  turnloop_runtime_supervise "seed" "${SCRIPT_DIR}/seed_prompt_loop.sh" "$REPO_ROOT" "$WORK_ROOT" "$RUNTIME_CONFIG_FILE" "$RUNTIME_STATE_DIR" "$@"
  exit $?
fi

if ! turnloop_runtime_is_sourced; then
  turnloop_runtime_init_worker \
    "seed" \
    "${SCRIPT_DIR}/seed_prompt_loop.sh" \
    "$REPO_ROOT" \
    "$WORK_ROOT" \
    "$RUNTIME_CONFIG_FILE" \
    "$RUNTIME_STATE_DIR" \
    "${SCRIPT_DIR}/seed_prompt_loop.sh" \
    "$RUNTIME_CONFIG_FILE" \
    "$SEED_SCRIPT"
  trap 'turnloop_runtime_on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
fi

while true; do
  wait_until_next_tick
  load_seed_loop_config
  turnloop_runtime_touch "seed_tick" "about to run seed_prompt.sh"
  log "Seed prompt loop tick"
  turnloop_runtime_touch "seed_script" "running seed_prompt.sh (interval=${SEED_INTERVAL_SECS}s)"
  SEED_RUN_RC=0
  SEED_RUN_OUTCOME="error"
  run_seed_script
  case "$SEED_RUN_OUTCOME" in
    seeded|too_early)
      clear_retry_epoch
      ;;
    usage_unknown)
      set_retry_epoch "$SEED_USAGE_UNKNOWN_RETRY_SECS"
      ;;
    usage_below_threshold)
      set_retry_epoch "$SEED_USAGE_LOW_RETRY_SECS"
      ;;
    error|*)
      set_retry_epoch "$SEED_ERROR_RETRY_SECS"
      ;;
  esac
  turnloop_runtime_touch "seed_result" "seed_prompt.sh rc=${SEED_RUN_RC}; outcome=${SEED_RUN_OUTCOME}"
done
