#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$SOURCE_PATH" && "$SOURCE_PATH" != /dev/fd/* && "$SOURCE_PATH" != /proc/*/fd/* ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd -P)"
else
  SCRIPT_DIR="$(cd "${PWD}/agents/scripts" && pwd -P)"
fi
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
WORK_ROOT="${TURNLOOP_WORK_ROOT:-$REPO_ROOT}"
if [[ "$WORK_ROOT" != /* ]]; then
  WORK_ROOT="${REPO_ROOT}/${WORK_ROOT}"
fi
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/loop_runtime.sh"
cd "$REPO_ROOT"

TASK="${WORK_ROOT}/agents/work/task.md"
PENDING="${WORK_ROOT}/agents/work/taskspending.md"
BACKLOG="${WORK_ROOT}/agents/work/tasksbacklog.md"
BACKBURNER="${WORK_ROOT}/agents/work/tasksbackburner.md"
ARCHIVE="${WORK_ROOT}/agents/work/tasksarchive.md"
STATUS="${WORK_ROOT}/agents/orchestrate_status.md"
HISTORY="${WORK_ROOT}/agents/orchestrate_historylog.md"
PROMPTS_DIR="${WORK_ROOT}/agents/work/prompts"
FINISHED_DIR="${WORK_ROOT}/agents/work/finished"
TMP_DIR="${WORK_ROOT}/agents/.tmp"
LOG_DIR="${WORK_ROOT}/agents/logs"
AUTONOMY_COMPLETE_MARKER="agents/AUTONOMY_COMPLETE"

MODEL_CONFIG_FILE="${TURNLOOP_MODEL_CONFIG_FILE:-${REPO_ROOT}/agents/entrypoints/model_config.env}"
RUNTIME_CONFIG_FILE="${TURNLOOP_RUNTIME_CONFIG_FILE:-${REPO_ROOT}/agents/config/runtime_config.env}"
LOOP_CONFIG_FILE="${TURNLOOP_LOOP_CONFIG_FILE:-${REPO_ROOT}/agents/config/loop_config.env}"

DAEMON_MODE="${TURNLOOP_DAEMON_MODE:-true}"
ENTRY_START=""
ENTRY_CHECK=""
ENTRY_TROUBLE=""
ENTRY_UPDATE=""
IDLE_POLL_SECS=""
PENDING_TRANSFER_DELAY_SECS=""
BACKLOG_PROMOTE_DELAY_SECS=""
ORCH_QUICKFIX_MAX_ATTEMPTS=""
ORCH_UPDATE_MAX_ATTEMPTS=""
ORCH_TROUBLESHOOT_MAX_ATTEMPTS=""
ORCH_TROUBLESHOOT_ON_BLOCKED=""
ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS=""
RUNNER=""
RUNNER_MODEL=""
START_RUNNER=""
START_MODEL=""
START_EFFORT=""
START_FALLBACK_RUNNER=""
START_FALLBACK_MODEL=""
CHECK_RUNNER=""
CHECK_MODEL=""
CHECK_EFFORT=""
CHECK_FALLBACK_RUNNER=""
CHECK_FALLBACK_MODEL=""
TROUBLE_RUNNER=""
TROUBLE_MODEL=""
TROUBLE_EFFORT=""
TROUBLE_FALLBACK_RUNNER=""
TROUBLE_FALLBACK_MODEL=""
UPDATE_RUNNER=""
UPDATE_MODEL=""
UPDATE_EFFORT=""
UPDATE_FALLBACK_RUNNER=""
UPDATE_FALLBACK_MODEL=""
TROUBLE_AB_MODE=""
UPDATE_AB_MODE=""
TROUBLE_MODEL_ALT=""
UPDATE_MODEL_ALT=""

TROUBLE_COUNT_FILE="${TMP_DIR}/troubleshoot_count.txt"
QUICKFIX_COUNT_FILE="${TMP_DIR}/quickfix_count.txt"
CURRENT_TASK_ID_FILE="${TMP_DIR}/current_task_id.txt"
UPDATE_BLOCKED_COUNT_FILE="${TMP_DIR}/update_blocked_count.txt"
TROUBLE_AB_FILE="${TMP_DIR}/troubleshoot_ab_toggle.txt"
UPDATE_AB_FILE="${TMP_DIR}/update_ab_toggle.txt"
RUNTIME_STATE_DIR="${TMP_DIR}/runtime"
TASK_CARD_HEADING_PATTERN='^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] — '

mkdir -p "$TMP_DIR" "$PROMPTS_DIR" "$FINISHED_DIR" "$LOG_DIR"
mkdir -p "$(dirname "$PENDING")"

log() {
  local ts
  ts="$(turnloop_runtime_timestamp)"
  printf '[%s] %s\n' "$ts" "$1"
}

resolve_repo_path() {
  local raw_path="${1:-}"
  local fallback="${2:-}"
  if [ -z "$raw_path" ]; then
    raw_path="$fallback"
  fi
  if [[ "$raw_path" = /* ]]; then
    printf '%s\n' "$raw_path"
    return 0
  fi
  printf '%s\n' "${REPO_ROOT}/${raw_path}"
}

reload_loop_config() {
  ORCH_ENTRY_START=""
  ORCH_ENTRY_CHECK=""
  ORCH_ENTRY_TROUBLE=""
  ORCH_ENTRY_UPDATE=""
  ORCH_IDLE_POLL_SECS=""
  ORCH_PROMOTE_DELAY_SECS=""
  ORCH_PENDING_TRANSFER_DELAY_SECS=""
  ORCH_BACKLOG_PROMOTE_DELAY_SECS=""
  ORCH_QUICKFIX_MAX_ATTEMPTS=""
  ORCH_UPDATE_MAX_ATTEMPTS=""
  ORCH_TROUBLESHOOT_MAX_ATTEMPTS=""
  ORCH_TROUBLESHOOT_ON_BLOCKED=""
  ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS=""

  if [ -f "$LOOP_CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    if ! source "$LOOP_CONFIG_FILE"; then
      log "WARN: failed to parse loop config file: $LOOP_CONFIG_FILE; using sanitized defaults"
    fi
  fi

  ENTRY_START="$(resolve_repo_path "${TURNLOOP_ORCH_ENTRY_START:-${TURNLOOP_ENTRY_START:-${ORCH_ENTRY_START:-agents/entrypoints/_start.md}}}")"
  ENTRY_CHECK="$(resolve_repo_path "${TURNLOOP_ORCH_ENTRY_CHECK:-${TURNLOOP_ENTRY_CHECK:-${ORCH_ENTRY_CHECK:-agents/entrypoints/_check.md}}}")"
  ENTRY_TROUBLE="$(resolve_repo_path "${TURNLOOP_ORCH_ENTRY_TROUBLE:-${TURNLOOP_ENTRY_TROUBLE:-${ORCH_ENTRY_TROUBLE:-agents/entrypoints/_troubleshoot.md}}}")"
  ENTRY_UPDATE="$(resolve_repo_path "${TURNLOOP_ORCH_ENTRY_UPDATE:-${TURNLOOP_ENTRY_UPDATE:-${ORCH_ENTRY_UPDATE:-agents/entrypoints/_update.md}}}")"

  local promote_default
  promote_default="$(turnloop_runtime_sanitize_int "${TURNLOOP_ORCH_PROMOTE_DELAY_SECS:-${TURNLOOP_PROMOTE_DELAY_SECS:-${ORCH_PROMOTE_DELAY_SECS:-180}}}" 180)"
  IDLE_POLL_SECS="$(turnloop_runtime_sanitize_int "${TURNLOOP_ORCH_IDLE_POLL_SECS:-${TURNLOOP_IDLE_POLL_SECS:-${ORCH_IDLE_POLL_SECS:-120}}}" 120)"
  PENDING_TRANSFER_DELAY_SECS="$(turnloop_runtime_sanitize_int "${TURNLOOP_ORCH_PENDING_TRANSFER_DELAY_SECS:-${TURNLOOP_PENDING_TRANSFER_DELAY_SECS:-${ORCH_PENDING_TRANSFER_DELAY_SECS:-60}}}" 60)"
  BACKLOG_PROMOTE_DELAY_SECS="$(turnloop_runtime_sanitize_int "${TURNLOOP_ORCH_BACKLOG_PROMOTE_DELAY_SECS:-${TURNLOOP_BACKLOG_PROMOTE_DELAY_SECS:-${ORCH_BACKLOG_PROMOTE_DELAY_SECS:-$promote_default}}}" "$promote_default")"

  ORCH_QUICKFIX_MAX_ATTEMPTS="$(turnloop_runtime_sanitize_nonneg_int "${TURNLOOP_ORCH_QUICKFIX_MAX_ATTEMPTS:-${ORCH_QUICKFIX_MAX_ATTEMPTS:-2}}" 2)"
  ORCH_UPDATE_MAX_ATTEMPTS="$(turnloop_runtime_sanitize_nonneg_int "${TURNLOOP_ORCH_UPDATE_MAX_ATTEMPTS:-${ORCH_UPDATE_MAX_ATTEMPTS:-2}}" 2)"
  ORCH_TROUBLESHOOT_MAX_ATTEMPTS="$(turnloop_runtime_sanitize_nonneg_int "${TURNLOOP_ORCH_TROUBLESHOOT_MAX_ATTEMPTS:-${ORCH_TROUBLESHOOT_MAX_ATTEMPTS:-2}}" 2)"
  ORCH_TROUBLESHOOT_ON_BLOCKED="$(turnloop_runtime_sanitize_bool "${TURNLOOP_ORCH_TROUBLESHOOT_ON_BLOCKED:-${ORCH_TROUBLESHOOT_ON_BLOCKED:-true}}" true)"
  ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS="$(turnloop_runtime_sanitize_bool "${TURNLOOP_ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS:-${ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS:-true}}" true)"
}

reload_model_config() {
  RUNNER="${TURNLOOP_RUNNER:-codex}"
  RUNNER_MODEL="${TURNLOOP_MODEL:-gpt-5.2-codex}"

  START_RUNNER="${TURNLOOP_START_RUNNER:-}"
  START_MODEL="${TURNLOOP_START_MODEL:-}"
  START_EFFORT="${TURNLOOP_START_EFFORT:-}"
  START_FALLBACK_RUNNER="${TURNLOOP_START_FALLBACK_RUNNER:-}"
  START_FALLBACK_MODEL="${TURNLOOP_START_FALLBACK_MODEL:-}"

  CHECK_RUNNER="${TURNLOOP_CHECK_RUNNER:-}"
  CHECK_MODEL="${TURNLOOP_CHECK_MODEL:-}"
  CHECK_EFFORT="${TURNLOOP_CHECK_EFFORT:-}"
  CHECK_FALLBACK_RUNNER="${TURNLOOP_CHECK_FALLBACK_RUNNER:-}"
  CHECK_FALLBACK_MODEL="${TURNLOOP_CHECK_FALLBACK_MODEL:-}"

  TROUBLE_RUNNER="${TURNLOOP_TROUBLE_RUNNER:-}"
  TROUBLE_MODEL="${TURNLOOP_TROUBLE_MODEL:-}"
  TROUBLE_EFFORT="${TURNLOOP_TROUBLE_EFFORT:-}"
  TROUBLE_FALLBACK_RUNNER="${TURNLOOP_TROUBLE_FALLBACK_RUNNER:-}"
  TROUBLE_FALLBACK_MODEL="${TURNLOOP_TROUBLE_FALLBACK_MODEL:-}"

  UPDATE_RUNNER="${TURNLOOP_UPDATE_RUNNER:-}"
  UPDATE_MODEL="${TURNLOOP_UPDATE_MODEL:-}"
  UPDATE_EFFORT="${TURNLOOP_UPDATE_EFFORT:-}"
  UPDATE_FALLBACK_RUNNER="${TURNLOOP_UPDATE_FALLBACK_RUNNER:-}"
  UPDATE_FALLBACK_MODEL="${TURNLOOP_UPDATE_FALLBACK_MODEL:-}"

  TROUBLE_AB_MODE="${TURNLOOP_TROUBLE_AB:-}"
  UPDATE_AB_MODE="${TURNLOOP_UPDATE_AB:-}"
  TROUBLE_MODEL_ALT="${TURNLOOP_TROUBLE_MODEL_ALT:-}"
  UPDATE_MODEL_ALT="${TURNLOOP_UPDATE_MODEL_ALT:-}"

  if [ -f "$MODEL_CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    if ! source "$MODEL_CONFIG_FILE"; then
      log "WARN: failed to parse model config file: $MODEL_CONFIG_FILE; using defaults/env values"
    fi
  fi

  START_RUNNER="${START_RUNNER:-codex}"
  START_MODEL="${START_MODEL:-gpt-5.4}"
  START_EFFORT="${START_EFFORT:-medium}"
  START_FALLBACK_RUNNER="${START_FALLBACK_RUNNER:-codex}"
  START_FALLBACK_MODEL="${START_FALLBACK_MODEL:-gpt-5.3-codex-spark}"

  CHECK_RUNNER="${CHECK_RUNNER:-$RUNNER}"
  CHECK_MODEL="${CHECK_MODEL:-gpt-5.4}"
  CHECK_EFFORT="${CHECK_EFFORT:-xhigh}"
  CHECK_FALLBACK_RUNNER="${CHECK_FALLBACK_RUNNER:-codex}"
  CHECK_FALLBACK_MODEL="${CHECK_FALLBACK_MODEL:-gpt-5.4}"

  TROUBLE_RUNNER="${TROUBLE_RUNNER:-$RUNNER}"
  TROUBLE_MODEL="${TROUBLE_MODEL:-gpt-5.4}"
  TROUBLE_EFFORT="${TROUBLE_EFFORT:-xhigh}"
  TROUBLE_FALLBACK_RUNNER="${TROUBLE_FALLBACK_RUNNER:-codex}"
  TROUBLE_FALLBACK_MODEL="${TROUBLE_FALLBACK_MODEL:-gpt-5.3-codex}"

  UPDATE_RUNNER="${UPDATE_RUNNER:-$RUNNER}"
  UPDATE_MODEL="${UPDATE_MODEL:-gpt-5.3-codex-spark}"
  UPDATE_EFFORT="${UPDATE_EFFORT:-high}"
  UPDATE_FALLBACK_RUNNER="${UPDATE_FALLBACK_RUNNER:-codex}"
  UPDATE_FALLBACK_MODEL="${UPDATE_FALLBACK_MODEL:-gpt-5.2-codex}"

  TROUBLE_AB_MODE="${TROUBLE_AB_MODE:-off}"
  UPDATE_AB_MODE="${UPDATE_AB_MODE:-off}"
  TROUBLE_MODEL_ALT="${TROUBLE_MODEL_ALT:-gpt-5.3-codex}"
  UPDATE_MODEL_ALT="${UPDATE_MODEL_ALT:-gpt-5.2-codex}"
}

append_file_to_log() {
  local src="$1"
  local dest="$2"
  if [ -s "$src" ]; then
    cat "$src" >> "$dest"
    if [ "$(tail -c 1 "$src" 2>/dev/null || true)" != "" ]; then
      printf '\n' >> "$dest"
    fi
  fi
}

gemini_extract_error_text() {
  local stdout_file="$1"
  local stderr_file="$2"
  python3 - "$stdout_file" "$stderr_file" <<'PY'
import json
import pathlib
import sys

stdout_path = pathlib.Path(sys.argv[1])
stderr_path = pathlib.Path(sys.argv[2])
parts = []
if stdout_path.exists() and stdout_path.stat().st_size:
    try:
        data = json.loads(stdout_path.read_text())
    except Exception:
        parts.append(stdout_path.read_text())
    else:
        err = data.get("error") or {}
        if isinstance(err, dict):
            for key in ("type", "message", "code"):
                value = err.get(key)
                if value not in (None, ""):
                    parts.append(str(value))
if stderr_path.exists() and stderr_path.stat().st_size:
    parts.append(stderr_path.read_text())
print(" ".join(parts).strip())
PY
}

gemini_is_capacity_error() {
  local stdout_file="$1"
  local stderr_file="$2"
  local error_text
  error_text="$(gemini_extract_error_text "$stdout_file" "$stderr_file" | tr '[:upper:]' '[:lower:]')"
  case "$error_text" in
    *"resource_exhausted"*|*"rate limit"*|*"quota"*|*"capacity"*|*"too many requests"*|*"429"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

run_gemini_entrypoint() {
  local instruction="$1"
  local model="$2"
  local log_file="$3"
  local stdout_file stderr_file
  stdout_file="$(mktemp "${TMP_DIR}/gemini_${model//[^A-Za-z0-9_.-]/_}_stdout_XXXXXX.json")"
  stderr_file="$(mktemp "${TMP_DIR}/gemini_${model//[^A-Za-z0-9_.-]/_}_stderr_XXXXXX.log")"
  if env TURNLOOP_REPO_ROOT="$REPO_ROOT" TURNLOOP_WORK_ROOT="$WORK_ROOT" \
    gemini --model "$model" --approval-mode yolo --output-format json "$instruction" >"$stdout_file" 2>"$stderr_file"; then
    append_file_to_log "$stdout_file" "$log_file"
    append_file_to_log "$stderr_file" "$log_file"
    rm -f "$stdout_file" "$stderr_file"
    return 0
  fi
  append_file_to_log "$stdout_file" "$log_file"
  append_file_to_log "$stderr_file" "$log_file"
  if gemini_is_capacity_error "$stdout_file" "$stderr_file"; then
    rm -f "$stdout_file" "$stderr_file"
    return 11
  fi
  rm -f "$stdout_file" "$stderr_file"
  return 1
}

invoke_runner() {
  local runner="$1"
  local instruction="$2"
  local model="$3"
  local effort="$4"
  local log_file="$5"
  if ! command -v "$runner" >/dev/null 2>&1; then
    echo "Missing runner: $runner" >&2
    return 1
  fi

  if [ "$runner" = "codex" ]; then
    env -u CODEX_THREAD_ID -u CODEX_SESSION_ID \
      TURNLOOP_REPO_ROOT="$REPO_ROOT" TURNLOOP_WORK_ROOT="$WORK_ROOT" \
      "$runner" exec --model "$model" --dangerously-bypass-approvals-and-sandbox --ephemeral --color never \
      -c "model_reasoning_effort=\"${effort}\"" "$instruction" \
      >> "$log_file" 2>&1
    return $?
  fi
  if [ "$runner" = "claude" ]; then
    env TURNLOOP_REPO_ROOT="$REPO_ROOT" TURNLOOP_WORK_ROOT="$WORK_ROOT" \
      "$runner" -p "$instruction" --model "$model" --output-format text --dangerously-skip-permissions >> "$log_file" 2>&1
    return $?
  fi
  if [ "$runner" = "gemini" ]; then
    run_gemini_entrypoint "$instruction" "$model" "$log_file"
    return $?
  fi

  env TURNLOOP_REPO_ROOT="$REPO_ROOT" TURNLOOP_WORK_ROOT="$WORK_ROOT" \
    "$runner" "$instruction" >> "$log_file" 2>&1
}

select_model() {
  local primary="$1"
  local alt="$2"
  local mode="$3"
  local toggle_file="$4"
  case "$mode" in
    alt)
      printf '%s' "$alt"
      return 0
      ;;
    ab)
      local last=""
      if [ -f "$toggle_file" ]; then
        last="$(tr -d '\r' < "$toggle_file" || true)"
      fi
      local chosen="$primary"
      if [ "$last" = "$primary" ]; then
        chosen="$alt"
      fi
      printf '%s\n' "$chosen" > "$toggle_file"
      printf '%s' "$chosen"
      return 0
      ;;
    *)
      printf '%s' "$primary"
      return 0
      ;;
  esac
}

write_status() {
  local marker="$1"
  printf '%s\n' "$marker" > "$STATUS"
}

get_status() {
  if [ -f "$STATUS" ]; then
    tr -d '\r' < "$STATUS" | tail -n 1
  else
    echo "### IDLE"
  fi
}

runtime_wait() {
  local seconds="$1"
  local phase="$2"
  local detail="${3:-}"
  turnloop_runtime_wait "$seconds" "$phase" "$detail" "$(get_status)"
}

set_last_entrypoint_metrics() {
  TURNLOOP_LAST_ENTRYPOINT_RC="${1:-0}"
  TURNLOOP_LAST_ENTRYPOINT_ELAPSED_MS="${2:-0}"
  TURNLOOP_LAST_ENTRYPOINT_NOTE="${3:-}"
}

entrypoint_finish_summary() {
  local summary
  summary="status=$(get_status); rc=${TURNLOOP_LAST_ENTRYPOINT_RC:-0}; elapsed=$(turnloop_runtime_format_elapsed_ms "${TURNLOOP_LAST_ENTRYPOINT_ELAPSED_MS:-0}")"
  if [ -n "${TURNLOOP_LAST_ENTRYPOINT_NOTE:-}" ]; then
    summary="${summary}; ${TURNLOOP_LAST_ENTRYPOINT_NOTE}"
  fi
  printf '%s\n' "$summary"
}

capture_status_snapshot() {
  python3 - "$STATUS" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
if not path.exists():
    print("0|||")
    raise SystemExit(0)

stat = path.stat()
last_line = ""
for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
    last_line = line.rstrip("\r")
print(f"1|{stat.st_mtime_ns}|{stat.st_size}|{last_line}")
PY
}

status_snapshot_value() {
  local snapshot="$1"
  IFS='|' read -r _ _ _ marker <<< "$snapshot"
  printf '%s\n' "$marker"
}

task_slot_is_placeholder() {
  if ! [ -f "$TASK" ]; then
    return 1
  fi

  if rg -q '^## No active task$' "$TASK" 2>/dev/null; then
    return 0
  fi

  if rg -q '^## Task$' "$TASK" 2>/dev/null && \
     rg -q '^No active task\.$' "$TASK" 2>/dev/null; then
    return 0
  fi

  if rg -q '^## Active task slot$' "$TASK" 2>/dev/null && \
     rg -q '^No active task is currently assigned\.$' "$TASK" 2>/dev/null; then
    return 0
  fi

  return 1
}

get_task_id() {
  local title
  if task_slot_is_placeholder; then
    return 0
  fi
  title="$(rg -m1 '^## ' "$TASK" 2>/dev/null | sed 's/^## //')"
  printf '%s\n' "$title"
}

has_active_task_card() {
  local title
  title="$(get_task_id)"
  [ -n "$title" ]
}

queue_has_task_cards() {
  local queue_file="$1"
  [ -f "$queue_file" ] && rg -q "$TASK_CARD_HEADING_PATTERN" "$queue_file" 2>/dev/null
}

reset_task_slot() {
  cat > "$TASK" <<'EOF'
## No active task
No active task.
EOF
}

reset_queue_file() {
  local queue_file="$1"
  local header="$2"
  printf '%s\n' "$header" > "$queue_file"
}

reset_pending_queue() {
  reset_queue_file "$PENDING" "# Tasks Pending"
}

reset_backlog_queue() {
  reset_queue_file "$BACKLOG" "# Tasks Backlog"
}

normalize_work_files() {
  [ -s "$TASK" ] || reset_task_slot
  [ -s "$PENDING" ] || reset_pending_queue
  [ -s "$BACKLOG" ] || reset_backlog_queue
}

extract_task_cards() {
  local src="$1"
  local dest="$2"
  : > "$dest"
  if ! [ -f "$src" ]; then
    return 0
  fi
  awk -v heading_re="$TASK_CARD_HEADING_PATTERN" '
    BEGIN {copy=0}
    $0 ~ heading_re { copy=1 }
    copy { print }
  ' "$src" > "$dest"
}

backlog_has_tasks() {
  queue_has_task_cards "$BACKLOG"
}

pending_has_tasks() {
  queue_has_task_cards "$PENDING"
}

transfer_pending_to_backlog() {
  local claimed="$TMP_DIR/pending_claim.md"
  local existing="$TMP_DIR/backlog_existing.md"
  local merged="$TMP_DIR/backlog_merged.md"
  if ! pending_has_tasks; then
    reset_pending_queue
    return 1
  fi

  extract_task_cards "$PENDING" "$claimed"
  reset_pending_queue
  if ! [ -s "$claimed" ]; then
    reset_backlog_queue
    rm -f "$existing" "$merged"
    return 1
  fi

  extract_task_cards "$BACKLOG" "$existing"
  : > "$merged"
  append_file_to_log "$existing" "$merged"
  append_file_to_log "$claimed" "$merged"
  write_queue_from_cards "$BACKLOG" "# Tasks Backlog" "$merged"
  rm -f "$claimed" "$existing" "$merged"
  return 0
}

hydrate_backlog_from_pending() {
  reload_loop_config
  if backlog_has_tasks; then
    return 0
  fi
  if ! pending_has_tasks; then
    return 1
  fi

  log "Pending queue has tasks; waiting ${PENDING_TRANSFER_DELAY_SECS}s before backlog transfer"
  runtime_wait "$PENDING_TRANSFER_DELAY_SECS" "pending_transfer_delay" "pending queue has tasks"
  if ! pending_has_tasks; then
    return 1
  fi
  transfer_pending_to_backlog || return 1
  turnloop_runtime_touch "pending_transferred" "moved taskspending.md contents into tasksbacklog.md" "$(get_status)"
  return 0
}

reset_troubleshoot_count() {
  printf '0\n' > "$TROUBLE_COUNT_FILE"
  printf '0\n' > "$QUICKFIX_COUNT_FILE"
  printf '0\n' > "$UPDATE_BLOCKED_COUNT_FILE"
  get_task_id > "$CURRENT_TASK_ID_FILE" || true
}

inc_troubleshoot_count() {
  local count=0
  if [ -f "$TROUBLE_COUNT_FILE" ]; then
    count="$(tr -d '\r' < "$TROUBLE_COUNT_FILE" || echo 0)"
  fi
  count=$((count + 1))
  printf '%s\n' "$count" > "$TROUBLE_COUNT_FILE"
  printf '%s\n' "$count"
}

inc_quickfix_count() {
  local count=0
  if [ -f "$QUICKFIX_COUNT_FILE" ]; then
    count="$(tr -d '\r' < "$QUICKFIX_COUNT_FILE" || echo 0)"
  fi
  count=$((count + 1))
  printf '%s\n' "$count" > "$QUICKFIX_COUNT_FILE"
  printf '%s\n' "$count"
}

get_quickfix_count() {
  if [ -f "$QUICKFIX_COUNT_FILE" ]; then
    tr -d '\r' < "$QUICKFIX_COUNT_FILE" || echo 0
  else
    echo 0
  fi
}

run_quickfix_cycle() {
  while true; do
    reload_loop_config
    if [ "$(get_status)" != "### QUICKFIX_NEEDED" ] || [ "$(get_quickfix_count)" -ge "$ORCH_QUICKFIX_MAX_ATTEMPTS" ]; then
      break
    fi
    inc_quickfix_count >/dev/null
    turnloop_runtime_touch "quickfix_start" "_start.md quickfix attempt $(get_quickfix_count)" "$(get_status)"
    log "Starting entrypoint: _start.md (quickfix attempt $(get_quickfix_count))"
    reload_model_config
    run_entrypoint "$ENTRY_START" "$START_RUNNER" "$START_MODEL" "$START_EFFORT" "$START_FALLBACK_RUNNER" "$START_FALLBACK_MODEL" || true
    log "Finished entrypoint: _start.md ($(entrypoint_finish_summary))"
    turnloop_runtime_touch "quickfix_start_complete" "_start.md quickfix attempt $(get_quickfix_count); $(entrypoint_finish_summary)" "$(get_status)"
    if [ "$(get_status)" != "### BUILDER_COMPLETE" ]; then
      break
    fi
    turnloop_runtime_touch "quickfix_check" "_check.md quickfix attempt $(get_quickfix_count)" "$(get_status)"
    log "Starting entrypoint: _check.md (quickfix attempt $(get_quickfix_count))"
    reload_model_config
    run_entrypoint "$ENTRY_CHECK" "$CHECK_RUNNER" "$CHECK_MODEL" "$CHECK_EFFORT" "$CHECK_FALLBACK_RUNNER" "$CHECK_FALLBACK_MODEL" || true
    log "Finished entrypoint: _check.md ($(entrypoint_finish_summary))"
    turnloop_runtime_touch "quickfix_check_complete" "_check.md quickfix attempt $(get_quickfix_count); $(entrypoint_finish_summary)" "$(get_status)"
  done
}

inc_update_blocked_count() {
  local count=0
  if [ -f "$UPDATE_BLOCKED_COUNT_FILE" ]; then
    count="$(tr -d '\r' < "$UPDATE_BLOCKED_COUNT_FILE" || echo 0)"
  fi
  count=$((count + 1))
  printf '%s\n' "$count" > "$UPDATE_BLOCKED_COUNT_FILE"
  printf '%s\n' "$count"
}

exit_after_single_cycle_if_needed() {
  if [ "$DAEMON_MODE" != "true" ]; then
    exit 0
  fi
}

run_update_cycle() {
  local attempt=0
  reload_loop_config
  if [ "$ORCH_UPDATE_MAX_ATTEMPTS" -le 0 ]; then
    log "Update attempts are disabled; skipping _update.md for this cycle"
    return 1
  fi
  while [ "$attempt" -lt "$ORCH_UPDATE_MAX_ATTEMPTS" ]; do
    attempt=$((attempt + 1))
    reload_loop_config
    reload_model_config
    local update_model
    update_model="$(select_model "$UPDATE_MODEL" "$UPDATE_MODEL_ALT" "$UPDATE_AB_MODE" "$UPDATE_AB_FILE")"
    turnloop_runtime_touch "update_entrypoint" "_update.md attempt ${attempt}" "$(get_status)"
    log "Starting entrypoint: _update.md (attempt ${attempt})"
    run_entrypoint "$ENTRY_UPDATE" "$UPDATE_RUNNER" "$update_model" "$UPDATE_EFFORT" "$UPDATE_FALLBACK_RUNNER" "$UPDATE_FALLBACK_MODEL" || true
    log "Finished entrypoint: _update.md ($(entrypoint_finish_summary))"
    turnloop_runtime_touch "update_complete" "_update.md attempt ${attempt}; $(entrypoint_finish_summary)" "$(get_status)"
    if [ "$(get_status)" = "### UPDATE_COMPLETE" ]; then
      return 0
    fi
    inc_update_blocked_count >/dev/null
    if [ "$attempt" -lt "$ORCH_UPDATE_MAX_ATTEMPTS" ]; then
      log "Updater blocked; retrying _update.md"
      continue
    fi
  done
  log "Updater blocked ${ORCH_UPDATE_MAX_ATTEMPTS} time(s); skipping _update.md for this cycle"
  return 1
}

same_task_as_last() {
  local current
  current="$(get_task_id)"
  if [ -f "$CURRENT_TASK_ID_FILE" ]; then
    [ "$(tr -d '\r' < "$CURRENT_TASK_ID_FILE")" = "$current" ]
  else
    return 1
  fi
}

promote_next_task() {
  local tmp_card="$TMP_DIR/next_task.md"
  local tmp_rest="$TMP_DIR/backlog_rest.md"

  : > "$tmp_card"
  : > "$tmp_rest"

  awk -v card="$tmp_card" -v rest="$tmp_rest" -v heading_re="$TASK_CARD_HEADING_PATTERN" '
    BEGIN {capture=0; in_card=0; found=0}
    $0 ~ heading_re {
      capture=1
      if (!found) { in_card=1; found=1 }
      else if (in_card) { in_card=0 }
    }
    capture {
      if (in_card) print > card;
      else print > rest;
    }
  ' "$BACKLOG"

  if [ ! -s "$tmp_card" ]; then
    reset_backlog_queue
    return 1
  fi

  mv "$tmp_card" "$TASK"
  write_queue_from_cards "$BACKLOG" "# Tasks Backlog" "$tmp_rest"
  reset_troubleshoot_count
  return 0
}

append_archive() {
  if ! has_active_task_card; then
    return 0
  fi
  local title
  title="$(get_task_id)"
  if [ -n "$title" ] && rg -Fq "$title" "$ARCHIVE" 2>/dev/null; then
    return 0
  fi
  if [ ! -s "$ARCHIVE" ]; then
    printf '# Tasks Archive\n\n' >> "$ARCHIVE"
  fi
  printf '## %s\n\n' "${title:-Task}" >> "$ARCHIVE"
  awk '
    BEGIN {skipped_title=0; body_started=0}
    {
      if (!skipped_title && $0 ~ /^## /) {
        skipped_title=1
        next
      }
      if (skipped_title && !body_started && $0 == "") {
        next
      }
      body_started=1
      print
    }
  ' "$TASK" >> "$ARCHIVE"
  printf '\n\n' >> "$ARCHIVE"
}

append_backburner() {
  if ! has_active_task_card; then
    return 0
  fi
  local title
  title="$(get_task_id)"
  if [ ! -s "$BACKBURNER" ]; then
    printf '# Tasks Backburner\n\n' >> "$BACKBURNER"
  fi
  printf '## %s (Auto-demoted)\n\n' "${title:-Task}" >> "$BACKBURNER"
  awk '
    BEGIN {skipped_title=0; body_started=0}
    {
      if (!skipped_title && $0 ~ /^## /) {
        skipped_title=1
        next
      }
      if (skipped_title && !body_started && $0 == "") {
        next
      }
      body_started=1
      print
    }
  ' "$TASK" >> "$BACKBURNER"
  printf '\n\n' >> "$BACKBURNER"
}

find_prompt_path() {
  rg -o 'agents/work/prompts/[^ )\n]+' "$TASK" 2>/dev/null | head -n 1 || true
}

move_prompt_to_finished() {
  local rel_path
  rel_path="$(find_prompt_path)"
  if [ -n "$rel_path" ] && [ -f "$WORK_ROOT/$rel_path" ]; then
    mv "$WORK_ROOT/$rel_path" "$FINISHED_DIR/"
  fi
}

prepare_update_cycle() {
  if has_active_task_card; then
    append_archive
    move_prompt_to_finished
    reset_task_slot
  fi
  write_status "### UPDATE_PENDING"
}

finish_update_cycle() {
  local status
  status="$(get_status)"
  case "$status" in
    "### QA_COMPLETE")
      prepare_update_cycle
      ;&
    "### UPDATE_PENDING")
      run_update_cycle || true
      status="$(get_status)"
      ;&
    "### UPDATE_COMPLETE")
      write_status "### IDLE"
      reset_troubleshoot_count
      exit_after_single_cycle_if_needed
      return 0
      ;;
  esac
  return 1
}

build_entrypoint_instruction() {
  local entry="$1"
  if [ "$WORK_ROOT" = "$REPO_ROOT" ]; then
    printf 'Open %s and follow instructions.' "$entry"
    return 0
  fi

  cat <<EOF
Open ${entry} and follow instructions.

Repo-root files stay anchored to: ${REPO_ROOT}
Active mutable workspace root: ${WORK_ROOT}

When the entrypoint or its referenced roles mention these repo-relative workspace files, use the workspace-root copies instead:
- agents/work/task.md -> ${TASK}
- agents/work/taskspending.md -> ${PENDING}
- agents/work/tasksbacklog.md -> ${BACKLOG}
- agents/work/tasksbackburner.md -> ${BACKBURNER}
- agents/work/tasksarchive.md -> ${ARCHIVE}
- agents/work/quickfix.md -> ${WORK_ROOT}/agents/work/quickfix.md
- agents/work/expectations.md -> ${WORK_ROOT}/agents/work/expectations.md
- agents/work/prompts/ -> ${PROMPTS_DIR}/
- agents/work/finished/ -> ${FINISHED_DIR}/
- agents/orchestrate_historylog.md -> ${HISTORY}
- agents/historylog.md (legacy reference) -> ${HISTORY}
- agents/orchestrate_status.md -> ${STATUS}
- agents/.tmp/ -> ${TMP_DIR}/
- agents/logs/ -> ${LOG_DIR}/

Keep entrypoint markdown, role docs, README, and repo code under the real checkout at ${REPO_ROOT}.
EOF
}

run_entrypoint() {
  local entry="$1"
  local runner="$2"
  local model="$3"
  local effort="$4"
  local fallback_runner="$5"
  local fallback_model="$6"
  local entry_name codex_log instruction initial_snapshot post_snapshot log_snapshot
  local started_ms elapsed_ms note codex_infra_retries codex_infra_delay
  entry_name="$(basename "$entry" .md)"
  codex_log="${LOG_DIR}/orchestrate_${entry_name}.log"
  instruction="$(build_entrypoint_instruction "$entry")"
  local rc=0
  started_ms="$(turnloop_runtime_now_ms)"
  initial_snapshot="$(capture_status_snapshot)"
  log_snapshot="$(turnloop_runtime_capture_file_snapshot "$codex_log")"
  invoke_runner "$runner" "$instruction" "$model" "$effort" "$codex_log"
  rc=$?
  post_snapshot="$(capture_status_snapshot)"
  if [ "$rc" -ne 0 ] && status_marker_written "$initial_snapshot" "$post_snapshot"; then
    elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
    note="preserved_status=$(status_snapshot_value "$post_snapshot")"
    set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
    log "Entrypoint ${entry_name}.md exited nonzero after setting $(status_snapshot_value "$post_snapshot"); preserving status"
    return 0
  fi
  codex_infra_retries=0
  while [ "$runner" = "codex" ] && [ "$rc" -ne 0 ] && \
    [ "${RUNTIME_CODEX_INFRA_RETRY_ENABLED:-true}" = "true" ] && \
    turnloop_runtime_codex_log_chunk_is_bare_enoent_fault "$codex_log" "$log_snapshot"; do
    if [ "$codex_infra_retries" -ge "${RUNTIME_CODEX_INFRA_RETRY_MAX_ATTEMPTS:-3}" ]; then
      break
    fi
    codex_infra_retries=$((codex_infra_retries + 1))
    codex_infra_delay="$(turnloop_runtime_codex_infra_backoff_secs "$codex_infra_retries")"
    log "Detected probable Codex startup infra failure for ${entry_name}.md; retry ${codex_infra_retries}/${RUNTIME_CODEX_INFRA_RETRY_MAX_ATTEMPTS:-3} in ${codex_infra_delay}s"
    runtime_wait "$codex_infra_delay" "codex_infra_backoff" "retrying probable codex startup failure"
    log_snapshot="$(turnloop_runtime_capture_file_snapshot "$codex_log")"
    invoke_runner "$runner" "$instruction" "$model" "$effort" "$codex_log"
    rc=$?
    post_snapshot="$(capture_status_snapshot)"
    if [ "$rc" -ne 0 ] && status_marker_written "$initial_snapshot" "$post_snapshot"; then
      elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
      note="codex_infra_retries=${codex_infra_retries}; preserved_status=$(status_snapshot_value "$post_snapshot")"
      set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
      log "Entrypoint ${entry_name}.md exited nonzero after Codex infra retry but set $(status_snapshot_value "$post_snapshot"); preserving status"
      return 0
    fi
    if [ "$rc" -eq 0 ]; then
      elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
      set_last_entrypoint_metrics "$rc" "$elapsed_ms" "codex_infra_retries=${codex_infra_retries}"
      return 0
    fi
  done
  while [ "$runner" = "codex" ] && [ "$rc" -ne 0 ] && turnloop_runtime_wait_for_connectivity_recovery "$(get_status)"; do
    log "Connectivity restored; retrying entrypoint: ${entry_name}.md"
    log_snapshot="$(turnloop_runtime_capture_file_snapshot "$codex_log")"
    invoke_runner "$runner" "$instruction" "$model" "$effort" "$codex_log"
    rc=$?
    post_snapshot="$(capture_status_snapshot)"
    if [ "$rc" -ne 0 ] && status_marker_written "$initial_snapshot" "$post_snapshot"; then
      elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
      note="retried_after_connectivity=true"
      if [ "$codex_infra_retries" -gt 0 ]; then
        note="${note}; codex_infra_retries=${codex_infra_retries}"
      fi
      note="${note}; preserved_status=$(status_snapshot_value "$post_snapshot")"
      set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
      log "Entrypoint ${entry_name}.md exited nonzero after retry but set $(status_snapshot_value "$post_snapshot"); preserving status"
      return 0
    fi
  done
  if [ "$rc" -eq 0 ]; then
    elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
    note=""
    if [ "$codex_infra_retries" -gt 0 ]; then
      note="codex_infra_retries=${codex_infra_retries}"
    fi
    set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
    return 0
  fi
  if [ "$runner" = "gemini" ] && [ "$rc" -eq 11 ] && [ -n "$fallback_runner" ] && [ -n "$fallback_model" ]; then
    log "Gemini model ${model} hit capacity/quota limits; falling back to ${fallback_runner}:${fallback_model}"
    invoke_runner "$fallback_runner" "$instruction" "$fallback_model" "$effort" "$codex_log"
    rc=$?
    post_snapshot="$(capture_status_snapshot)"
    if [ "$rc" -ne 0 ] && status_marker_written "$initial_snapshot" "$post_snapshot"; then
      elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
      note="fallback=${fallback_runner}:${fallback_model}; preserved_status=$(status_snapshot_value "$post_snapshot")"
      set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
      log "Entrypoint ${entry_name}.md fallback exited nonzero after setting $(status_snapshot_value "$post_snapshot"); preserving status"
      return 0
    fi
    if [ "$rc" -ne 0 ]; then
      write_status "### BLOCKED"
      elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
      note="fallback=${fallback_runner}:${fallback_model}"
      if [ "$codex_infra_retries" -gt 0 ]; then
        note="${note}; codex_infra_retries=${codex_infra_retries}"
      fi
      set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
      return 1
    fi
    elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
    note="fallback=${fallback_runner}:${fallback_model}"
    if [ "$codex_infra_retries" -gt 0 ]; then
      note="${note}; codex_infra_retries=${codex_infra_retries}"
    fi
    set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
    return 0
  fi
  write_status "### BLOCKED"
  elapsed_ms="$(turnloop_runtime_elapsed_ms "$started_ms")"
  note=""
  if [ "$codex_infra_retries" -gt 0 ]; then
    note="codex_infra_retries=${codex_infra_retries}"
  fi
  set_last_entrypoint_metrics "$rc" "$elapsed_ms" "$note"
  return 1
}

write_queue_from_cards() {
  local queue_file="$1"
  local header="$2"
  local cards_file="$3"
  reset_queue_file "$queue_file" "$header"
  if [ -s "$cards_file" ]; then
    printf '\n' >> "$queue_file"
    cat "$cards_file" >> "$queue_file"
    if [ "$(tail -c 1 "$cards_file" 2>/dev/null || true)" != "" ]; then
      printf '\n' >> "$queue_file"
    fi
  fi
}

is_valid_orchestrate_status() {
  case "${1:-}" in
    "### IDLE"|"### BLOCKED"|"### BUILDER_COMPLETE"|"### QUICKFIX_NEEDED"|"### QA_COMPLETE"|"### UPDATE_PENDING"|"### UPDATE_COMPLETE"|"### TROUBLESHOOT_COMPLETE")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

status_marker_written() {
  local before_snapshot="$1"
  local after_snapshot="$2"
  local after_status
  after_status="$(status_snapshot_value "$after_snapshot")"
  [ "$after_snapshot" != "$before_snapshot" ] && is_valid_orchestrate_status "$after_status"
}

handle_blocked() {
  local count
  reload_loop_config
  if [ "${ORCH_TROUBLESHOOT_ON_BLOCKED:-true}" != "true" ]; then
    log "Troubleshoot-on-blocked is disabled; resetting status to idle"
    write_status "### IDLE"
    return 0
  fi
  if [ "${ORCH_TROUBLESHOOT_MAX_ATTEMPTS:-0}" -le 0 ]; then
    log "Troubleshoot attempts are disabled; demoting active task without running _troubleshoot.md"
    append_backburner
    reset_task_slot
    write_status "### IDLE"
    reset_troubleshoot_count
    return 0
  fi
  reload_model_config
  local trouble_model
  trouble_model="$(select_model "$TROUBLE_MODEL" "$TROUBLE_MODEL_ALT" "$TROUBLE_AB_MODE" "$TROUBLE_AB_FILE")"
  turnloop_runtime_touch "troubleshoot_entrypoint" "_troubleshoot.md" "$(get_status)"
  log "Starting entrypoint: _troubleshoot.md"
  run_entrypoint "$ENTRY_TROUBLE" "$TROUBLE_RUNNER" "$trouble_model" "$TROUBLE_EFFORT" "$TROUBLE_FALLBACK_RUNNER" "$TROUBLE_FALLBACK_MODEL" || true
  log "Finished entrypoint: _troubleshoot.md ($(entrypoint_finish_summary))"
  turnloop_runtime_touch "troubleshoot_complete" "_troubleshoot.md $(entrypoint_finish_summary)" "$(get_status)"
  if [ "$(get_status)" = "### TROUBLESHOOT_COMPLETE" ]; then
    reset_troubleshoot_count
    write_status "### IDLE"
    return 0
  fi

  write_status "### BLOCKED"
  count="$(inc_troubleshoot_count)"
  if [ "$count" -ge "$ORCH_TROUBLESHOOT_MAX_ATTEMPTS" ]; then
    append_backburner
    reset_task_slot
    write_status "### IDLE"
    reset_troubleshoot_count
  fi
}

if ! turnloop_runtime_is_sourced && [ "${TURNLOOP_RUNTIME_CHILD:-0}" != "1" ]; then
  turnloop_runtime_supervise "orchestrate" "${SCRIPT_DIR}/orchestrate_loop.sh" "$REPO_ROOT" "$WORK_ROOT" "$RUNTIME_CONFIG_FILE" "$RUNTIME_STATE_DIR" "$@"
  exit $?
fi

if ! turnloop_runtime_is_sourced; then
  turnloop_runtime_init_worker \
    "orchestrate" \
    "${SCRIPT_DIR}/orchestrate_loop.sh" \
    "$REPO_ROOT" \
    "$WORK_ROOT" \
    "$RUNTIME_CONFIG_FILE" \
    "$RUNTIME_STATE_DIR" \
    "${SCRIPT_DIR}/orchestrate_loop.sh" \
    "$RUNTIME_CONFIG_FILE" \
    "$LOOP_CONFIG_FILE" \
    "$MODEL_CONFIG_FILE"
  trap 'turnloop_runtime_on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
fi

normalize_work_files

while true; do
  reload_loop_config
  normalize_work_files
  turnloop_runtime_touch "loop_tick" "status=$(get_status)" "$(get_status)"
  if [ -f "$AUTONOMY_COMPLETE_MARKER" ]; then
    turnloop_runtime_touch "autonomy_complete" "marker detected; exiting" "$(get_status)"
    exit 0
  fi

  case "$(get_status)" in
    "### QA_COMPLETE"|"### UPDATE_PENDING"|"### UPDATE_COMPLETE")
      finish_update_cycle && continue
      ;;
  esac

  if ! has_active_task_card; then
    if ! backlog_has_tasks; then
      hydrate_backlog_from_pending || true
    fi
    if backlog_has_tasks; then
      reload_loop_config
      log "Backlog has tasks; waiting ${BACKLOG_PROMOTE_DELAY_SECS}s before promote"
      runtime_wait "$BACKLOG_PROMOTE_DELAY_SECS" "promote_delay" "backlog has tasks"
    fi
    if ! promote_next_task; then
      write_status "### IDLE"
      turnloop_runtime_touch "idle_poll" "backlog and pending queues empty; waiting for work" "$(get_status)"
      if [ "$DAEMON_MODE" = "true" ]; then
        runtime_wait "$IDLE_POLL_SECS" "idle_poll" "backlog and pending queues empty; waiting for work"
        continue
      fi
      exit 0
    fi
    turnloop_runtime_touch "task_promoted" "promoted top backlog task into task slot" "$(get_status)"
  fi

  case "$(get_status)" in
    "### BUILDER_COMPLETE")
      ;;
    "### QA_COMPLETE"|"### UPDATE_PENDING"|"### UPDATE_COMPLETE")
      finish_update_cycle && continue
      ;;
    "### QUICKFIX_NEEDED")
      ;;
    "### BLOCKED")
      handle_blocked
      exit_after_single_cycle_if_needed
      continue
      ;;
    *)
      turnloop_runtime_touch "start_entrypoint" "_start.md" "$(get_status)"
      log "Starting entrypoint: _start.md"
      reload_model_config
      run_entrypoint "$ENTRY_START" "$START_RUNNER" "$START_MODEL" "$START_EFFORT" "$START_FALLBACK_RUNNER" "$START_FALLBACK_MODEL" || true
      log "Finished entrypoint: _start.md ($(entrypoint_finish_summary))"
      turnloop_runtime_touch "start_complete" "_start.md $(entrypoint_finish_summary)" "$(get_status)"
      case "$(get_status)" in
        "### BUILDER_COMPLETE")
          ;;
        "### BLOCKED")
          handle_blocked
          exit_after_single_cycle_if_needed
          continue
          ;;
        *)
          if [ "${ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS:-true}" = "true" ]; then
            handle_blocked
          else
            log "Unexpected builder status with troubleshoot-on-unexpected disabled; resetting to idle"
            write_status "### IDLE"
          fi
          exit_after_single_cycle_if_needed
          continue
          ;;
      esac
      ;;
  esac

  if [ "$(get_status)" = "### BUILDER_COMPLETE" ]; then
    turnloop_runtime_touch "check_entrypoint" "_check.md" "$(get_status)"
    log "Starting entrypoint: _check.md"
    reload_model_config
    run_entrypoint "$ENTRY_CHECK" "$CHECK_RUNNER" "$CHECK_MODEL" "$CHECK_EFFORT" "$CHECK_FALLBACK_RUNNER" "$CHECK_FALLBACK_MODEL" || true
    log "Finished entrypoint: _check.md ($(entrypoint_finish_summary))"
    turnloop_runtime_touch "check_complete" "_check.md $(entrypoint_finish_summary)" "$(get_status)"
  fi

  case "$(get_status)" in
    "### QA_COMPLETE")
      finish_update_cycle && continue
      ;;
    "### QUICKFIX_NEEDED")
      run_quickfix_cycle
      if [ "$(get_status)" = "### QUICKFIX_NEEDED" ] && [ "$(get_quickfix_count)" -ge "$ORCH_QUICKFIX_MAX_ATTEMPTS" ]; then
        append_backburner
        reset_task_slot
        write_status "### IDLE"
        reset_troubleshoot_count
        exit_after_single_cycle_if_needed
        continue
      fi
      if [ "$(get_status)" = "### QA_COMPLETE" ]; then
        finish_update_cycle && continue
      elif [ "$(get_status)" = "### BLOCKED" ]; then
        handle_blocked
        exit_after_single_cycle_if_needed
      fi
      ;;
    "### BLOCKED")
      handle_blocked
      exit_after_single_cycle_if_needed
      ;;
    *)
      if [ "${ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS:-true}" = "true" ]; then
        handle_blocked
      else
        log "Unexpected QA status with troubleshoot-on-unexpected disabled; resetting to idle"
        write_status "### IDLE"
      fi
      exit_after_single_cycle_if_needed
      ;;
  esac

done
