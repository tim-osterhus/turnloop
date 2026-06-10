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
cd "$WORK_ROOT"

INBOX_DIR="${TURNLOOP_INBOX_DIR:-agents/ideas/inbox}"
PROCESSED_DIR="${TURNLOOP_PROCESSED_DIR:-agents/ideas/processed}"
STAGING_DIR="${TURNLOOP_STAGING_DIR:-agents/ideas/staging}"
SPECS_DIR="${TURNLOOP_SPECS_DIR:-agents/ideas/specs}"
NONVIABLE_DIR="${TURNLOOP_NONVIABLE_DIR:-agents/ideas/nonviable}"
STATUS="${TURNLOOP_RESEARCH_STATUS_FILE:-agents/research_status.md}"
HISTORY="${TURNLOOP_RESEARCH_HISTORY_FILE:-agents/research_historylog.md}"
PENDING="${TURNLOOP_PENDING_FILE:-agents/work/taskspending.md}"
TMP_DIR="${TURNLOOP_TMP_DIR:-agents/.tmp}"
LOG_DIR="${TURNLOOP_LOG_DIR:-agents/logs}"
AUTONOMY_COMPLETE_MARKER="${TURNLOOP_AUTONOMY_COMPLETE_MARKER:-agents/AUTONOMY_COMPLETE}"

ENTRY_RESEARCH="${TURNLOOP_ENTRY_RESEARCH:-agents/entrypoints/_research.md}"
ENTRY_MANAGE="${TURNLOOP_ENTRY_MANAGE:-agents/entrypoints/_manage.md}"
ENTRY_MECHANIC="${TURNLOOP_ENTRY_MECHANIC:-agents/entrypoints/_mechanic.md}"
MODEL_CONFIG_FILE="${TURNLOOP_MODEL_CONFIG_FILE:-${REPO_ROOT}/agents/entrypoints/model_config.env}"
RUNTIME_CONFIG_FILE="${TURNLOOP_RUNTIME_CONFIG_FILE:-${REPO_ROOT}/agents/config/runtime_config.env}"
LOOP_CONFIG_FILE="${TURNLOOP_LOOP_CONFIG_FILE:-${REPO_ROOT}/agents/config/loop_config.env}"

DAEMON_MODE="${TURNLOOP_DAEMON_MODE:-true}"
POLL_SECS=""
RESEARCH_DELAY_SECS=""
MANAGE_DELAY_SECS=""
RESEARCH_MECHANIC_MAX_ATTEMPTS=""
RESEARCH_MECHANIC_ON_BLOCKED=""
RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS=""
RUNNER=""
RUNNER_MODEL=""
RESEARCH_RUNNER=""
RESEARCH_MODEL=""
RESEARCH_EFFORT=""
RESEARCH_FALLBACK_RUNNER=""
RESEARCH_FALLBACK_MODEL=""
MANAGE_RUNNER=""
MANAGE_MODEL=""
MANAGE_EFFORT=""
MANAGE_FALLBACK_RUNNER=""
MANAGE_FALLBACK_MODEL=""
MECHANIC_RUNNER=""
MECHANIC_MODEL=""
MECHANIC_EFFORT=""
MECHANIC_FALLBACK_RUNNER=""
MECHANIC_FALLBACK_MODEL=""
MECHANIC_AB_MODE=""
MECHANIC_MODEL_ALT=""

mkdir -p "$TMP_DIR" "$INBOX_DIR" "$PROCESSED_DIR" "$STAGING_DIR" "$SPECS_DIR" "$LOG_DIR"
mkdir -p "$NONVIABLE_DIR"
mkdir -p "$(dirname "$PENDING")"
[ -f "$PENDING" ] || : > "$PENDING"

MECHANIC_COUNT_FILE="${TMP_DIR}/mechanic_count.txt"
MECHANIC_AB_FILE="${TMP_DIR}/mechanic_ab_toggle.txt"
RUNTIME_STATE_DIR="${TMP_DIR}/runtime"

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
  RESEARCH_ENTRY_RESEARCH=""
  RESEARCH_ENTRY_MANAGE=""
  RESEARCH_ENTRY_MECHANIC=""
  RESEARCH_POLL_SECS=""
  RESEARCH_PROMOTE_DELAY_SECS=""
  RESEARCH_RESEARCH_DELAY_SECS=""
  RESEARCH_MANAGE_DELAY_SECS=""
  RESEARCH_MECHANIC_MAX_ATTEMPTS=""
  RESEARCH_MECHANIC_ON_BLOCKED=""
  RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS=""

  if [ -f "$LOOP_CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    if ! source "$LOOP_CONFIG_FILE"; then
      log "WARN: failed to parse loop config file: $LOOP_CONFIG_FILE; using sanitized defaults"
    fi
  fi

  ENTRY_RESEARCH="$(resolve_repo_path "${TURNLOOP_RESEARCH_ENTRY_RESEARCH:-${TURNLOOP_ENTRY_RESEARCH:-${RESEARCH_ENTRY_RESEARCH:-agents/entrypoints/_research.md}}}")"
  ENTRY_MANAGE="$(resolve_repo_path "${TURNLOOP_RESEARCH_ENTRY_MANAGE:-${TURNLOOP_ENTRY_MANAGE:-${RESEARCH_ENTRY_MANAGE:-agents/entrypoints/_manage.md}}}")"
  ENTRY_MECHANIC="$(resolve_repo_path "${TURNLOOP_RESEARCH_ENTRY_MECHANIC:-${TURNLOOP_ENTRY_MECHANIC:-${RESEARCH_ENTRY_MECHANIC:-agents/entrypoints/_mechanic.md}}}")"

  local promote_default
  promote_default="$(turnloop_runtime_sanitize_int "${TURNLOOP_RESEARCH_PROMOTE_DELAY_SECS:-${TURNLOOP_PROMOTE_DELAY_SECS:-${RESEARCH_PROMOTE_DELAY_SECS:-180}}}" 180)"
  POLL_SECS="$(turnloop_runtime_sanitize_int "${TURNLOOP_RESEARCH_POLL_SECS:-${TURNLOOP_POLL_SECS:-${RESEARCH_POLL_SECS:-120}}}" 120)"
  RESEARCH_DELAY_SECS="$(turnloop_runtime_sanitize_int "${TURNLOOP_RESEARCH_INBOX_DELAY_SECS:-${RESEARCH_RESEARCH_DELAY_SECS:-$promote_default}}" "$promote_default")"
  MANAGE_DELAY_SECS="$(turnloop_runtime_sanitize_int "${TURNLOOP_RESEARCH_STAGING_DELAY_SECS:-${RESEARCH_MANAGE_DELAY_SECS:-$promote_default}}" "$promote_default")"
  RESEARCH_MECHANIC_MAX_ATTEMPTS="$(turnloop_runtime_sanitize_nonneg_int "${TURNLOOP_RESEARCH_MECHANIC_MAX_ATTEMPTS:-${RESEARCH_MECHANIC_MAX_ATTEMPTS:-2}}" 2)"
  RESEARCH_MECHANIC_ON_BLOCKED="$(turnloop_runtime_sanitize_bool "${TURNLOOP_RESEARCH_MECHANIC_ON_BLOCKED:-${RESEARCH_MECHANIC_ON_BLOCKED:-true}}" true)"
  RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS="$(turnloop_runtime_sanitize_bool "${TURNLOOP_RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS:-${RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS:-true}}" true)"
}

reload_model_config() {
  RUNNER="${TURNLOOP_RUNNER:-codex}"
  RUNNER_MODEL="${TURNLOOP_MODEL:-gpt-5.2-codex}"

  RESEARCH_RUNNER="${TURNLOOP_RESEARCH_RUNNER:-}"
  RESEARCH_MODEL="${TURNLOOP_RESEARCH_MODEL:-}"
  RESEARCH_EFFORT="${TURNLOOP_RESEARCH_EFFORT:-}"
  RESEARCH_FALLBACK_RUNNER="${TURNLOOP_RESEARCH_FALLBACK_RUNNER:-}"
  RESEARCH_FALLBACK_MODEL="${TURNLOOP_RESEARCH_FALLBACK_MODEL:-}"

  MANAGE_RUNNER="${TURNLOOP_MANAGE_RUNNER:-}"
  MANAGE_MODEL="${TURNLOOP_MANAGE_MODEL:-}"
  MANAGE_EFFORT="${TURNLOOP_MANAGE_EFFORT:-}"
  MANAGE_FALLBACK_RUNNER="${TURNLOOP_MANAGE_FALLBACK_RUNNER:-}"
  MANAGE_FALLBACK_MODEL="${TURNLOOP_MANAGE_FALLBACK_MODEL:-}"

  MECHANIC_RUNNER="${TURNLOOP_MECHANIC_RUNNER:-}"
  MECHANIC_MODEL="${TURNLOOP_MECHANIC_MODEL:-}"
  MECHANIC_EFFORT="${TURNLOOP_MECHANIC_EFFORT:-}"
  MECHANIC_FALLBACK_RUNNER="${TURNLOOP_MECHANIC_FALLBACK_RUNNER:-}"
  MECHANIC_FALLBACK_MODEL="${TURNLOOP_MECHANIC_FALLBACK_MODEL:-}"
  MECHANIC_AB_MODE="${TURNLOOP_MECHANIC_AB:-}"
  MECHANIC_MODEL_ALT="${TURNLOOP_MECHANIC_MODEL_ALT:-}"

  if [ -f "$MODEL_CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    if ! source "$MODEL_CONFIG_FILE"; then
      log "WARN: failed to parse model config file: $MODEL_CONFIG_FILE; using defaults/env values"
    fi
  fi

  RESEARCH_RUNNER="${RESEARCH_RUNNER:-$RUNNER}"
  RESEARCH_MODEL="${RESEARCH_MODEL:-gpt-5.4}"
  RESEARCH_EFFORT="${RESEARCH_EFFORT:-xhigh}"
  RESEARCH_FALLBACK_RUNNER="${RESEARCH_FALLBACK_RUNNER:-codex}"
  RESEARCH_FALLBACK_MODEL="${RESEARCH_FALLBACK_MODEL:-gpt-5.4}"

  MANAGE_RUNNER="${MANAGE_RUNNER:-$RUNNER}"
  MANAGE_MODEL="${MANAGE_MODEL:-$RUNNER_MODEL}"
  MANAGE_EFFORT="${MANAGE_EFFORT:-high}"
  MANAGE_FALLBACK_RUNNER="${MANAGE_FALLBACK_RUNNER:-codex}"
  MANAGE_FALLBACK_MODEL="${MANAGE_FALLBACK_MODEL:-gpt-5.4}"

  MECHANIC_RUNNER="${MECHANIC_RUNNER:-$RUNNER}"
  MECHANIC_MODEL="${MECHANIC_MODEL:-gpt-5.3-codex-spark}"
  MECHANIC_EFFORT="${MECHANIC_EFFORT:-xhigh}"
  MECHANIC_FALLBACK_RUNNER="${MECHANIC_FALLBACK_RUNNER:-codex}"
  MECHANIC_FALLBACK_MODEL="${MECHANIC_FALLBACK_MODEL:-gpt-5.3-codex}"
  MECHANIC_AB_MODE="${MECHANIC_AB_MODE:-off}"
  MECHANIC_MODEL_ALT="${MECHANIC_MODEL_ALT:-gpt-5.3-codex}"
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
  if gemini --model "$model" --approval-mode yolo --output-format json "$instruction" >"$stdout_file" 2>"$stderr_file"; then
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

is_valid_research_status() {
  case "${1:-}" in
    "### IDLE"|"### BLOCKED"|"### RESEARCH_RUNNING"|"### MANAGE_RUNNING")
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
  [ "$after_snapshot" != "$before_snapshot" ] && is_valid_research_status "$after_status"
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
  codex_log="${LOG_DIR}/research_${entry_name}.log"
  instruction="Open ${entry} and follow instructions."
  if [ "$entry" = "$ENTRY_MANAGE" ] && [ -n "${TURNLOOP_STAGING_SPEC:-}" ]; then
    instruction="${instruction} Use the already-selected staging spec at ${TURNLOOP_STAGING_SPEC} for this run."
  fi
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

reset_mechanic_count() {
  printf '0\n' > "$MECHANIC_COUNT_FILE"
}

inc_mechanic_count() {
  local count=0
  if [ -f "$MECHANIC_COUNT_FILE" ]; then
    count="$(tr -d '\r' < "$MECHANIC_COUNT_FILE" || echo 0)"
  fi
  count=$((count + 1))
  printf '%s\n' "$count" > "$MECHANIC_COUNT_FILE"
  printf '%s\n' "$count"
}

oldest_eligible_file() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    return 1
  fi
  find "$dir" -maxdepth 1 -type f ! -name .gitkeep -printf '%T@ %p\n' 2>/dev/null | sort -n | head -n1 | cut -d' ' -f2-
}

move_offending_to_nonviable() {
  local stage="$1"
  local src=""
  case "$stage" in
    research) src="$(oldest_eligible_file "$INBOX_DIR")" ;;
    manage) src="$(oldest_eligible_file "$STAGING_DIR")" ;;
  esac
  if [ -z "$src" ]; then
    echo "WARN: no offending file found for stage $stage" >&2
    return 1
  fi
  if ! mv "$src" "$NONVIABLE_DIR/"; then
    echo "WARN: failed to move $src to $NONVIABLE_DIR" >&2
    return 1
  fi
}

handle_mechanic() {
  local stage="$1"
  reload_loop_config
  if [ "$RESEARCH_MECHANIC_MAX_ATTEMPTS" -le 0 ]; then
    log "Mechanic attempts are disabled; moving offending item out of rotation"
    move_offending_to_nonviable "$stage" || true
    write_status "### IDLE"
    reset_mechanic_count
    return 0
  fi
  reload_model_config
  local mechanic_model
  mechanic_model="$(select_model "$MECHANIC_MODEL" "$MECHANIC_MODEL_ALT" "$MECHANIC_AB_MODE" "$MECHANIC_AB_FILE")"
  turnloop_runtime_touch "mechanic_entrypoint" "_mechanic.md stage=${stage}" "$(get_status)"
  log "Starting entrypoint: _mechanic.md (stage=${stage})"
  run_entrypoint "$ENTRY_MECHANIC" "$MECHANIC_RUNNER" "$mechanic_model" "$MECHANIC_EFFORT" "$MECHANIC_FALLBACK_RUNNER" "$MECHANIC_FALLBACK_MODEL" || true
  log "Finished entrypoint: _mechanic.md ($(entrypoint_finish_summary))"
  turnloop_runtime_touch "mechanic_complete" "_mechanic.md $(entrypoint_finish_summary)" "$(get_status)"
  if [ "$(get_status)" = "### BLOCKED" ]; then
    local count
    count="$(inc_mechanic_count)"
    if [ "$count" -ge "$RESEARCH_MECHANIC_MAX_ATTEMPTS" ]; then
      move_offending_to_nonviable "$stage" || true
      write_status "### IDLE"
      reset_mechanic_count
    fi
  else
    reset_mechanic_count
  fi
}

has_inbox_work() {
  find "$INBOX_DIR" -maxdepth 1 -type f ! -name .gitkeep -print -quit 2>/dev/null | grep -q .
}

has_staging_work() {
  find "$STAGING_DIR" -maxdepth 1 -type f ! -name .gitkeep -print -quit 2>/dev/null | grep -q .
}

if ! turnloop_runtime_is_sourced && [ "${TURNLOOP_RUNTIME_CHILD:-0}" != "1" ]; then
  turnloop_runtime_supervise "research" "${SCRIPT_DIR}/research_loop.sh" "$REPO_ROOT" "$WORK_ROOT" "$RUNTIME_CONFIG_FILE" "$RUNTIME_STATE_DIR" "$@"
  exit $?
fi

if ! turnloop_runtime_is_sourced; then
  turnloop_runtime_init_worker \
    "research" \
    "${SCRIPT_DIR}/research_loop.sh" \
    "$REPO_ROOT" \
    "$WORK_ROOT" \
    "$RUNTIME_CONFIG_FILE" \
    "$RUNTIME_STATE_DIR" \
    "${SCRIPT_DIR}/research_loop.sh" \
    "$RUNTIME_CONFIG_FILE" \
    "$LOOP_CONFIG_FILE" \
    "$MODEL_CONFIG_FILE"
  trap 'turnloop_runtime_on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
fi

while true; do
  reload_loop_config
  turnloop_runtime_touch "loop_tick" "status=$(get_status)" "$(get_status)"
  if [ -f "$AUTONOMY_COMPLETE_MARKER" ]; then
    turnloop_runtime_touch "autonomy_complete" "marker detected; exiting" "$(get_status)"
    exit 0
  fi

  if has_inbox_work; then
    reload_loop_config
    log "Inbox has work; waiting ${RESEARCH_DELAY_SECS}s before research"
    runtime_wait "$RESEARCH_DELAY_SECS" "research_delay" "inbox has work"
    turnloop_runtime_touch "research_entrypoint" "_research.md" "$(get_status)"
    log "Starting entrypoint: _research.md"
    reload_model_config
    run_entrypoint "$ENTRY_RESEARCH" "$RESEARCH_RUNNER" "$RESEARCH_MODEL" "$RESEARCH_EFFORT" "$RESEARCH_FALLBACK_RUNNER" "$RESEARCH_FALLBACK_MODEL" || true
    log "Finished entrypoint: _research.md ($(entrypoint_finish_summary))"
    turnloop_runtime_touch "research_complete" "_research.md $(entrypoint_finish_summary)" "$(get_status)"
    case "$(get_status)" in
      "### IDLE")
        ;;
      "### BLOCKED")
        if [ "${RESEARCH_MECHANIC_ON_BLOCKED:-true}" = "true" ]; then
          handle_mechanic "research"
        else
          log "Mechanic-on-blocked is disabled for research; resetting status to idle"
          write_status "### IDLE"
        fi
        ;;
      *)
        if [ "${RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS:-true}" = "true" ]; then
          handle_mechanic "research"
        else
          log "Unexpected research status with mechanic-on-unexpected disabled; resetting status to idle"
          write_status "### IDLE"
        fi
        ;;
    esac
  fi

  if has_staging_work; then
    reload_loop_config
    log "Staging has work; waiting ${MANAGE_DELAY_SECS}s before manage"
    runtime_wait "$MANAGE_DELAY_SECS" "manage_delay" "staging has work"
    staging_spec="$(oldest_eligible_file "$STAGING_DIR")"
    if [ -z "$staging_spec" ]; then
      log "Staging selection failed: no staging spec found"
      write_status "### BLOCKED"
      if [ "${RESEARCH_MECHANIC_ON_BLOCKED:-true}" = "true" ]; then
        handle_mechanic "manage"
      else
        write_status "### IDLE"
      fi
    fi
    if [ -n "$staging_spec" ]; then
      turnloop_runtime_touch "manage_entrypoint" "_manage.md using ${staging_spec}" "$(get_status)"
      log "Starting entrypoint: _manage.md"
      reload_model_config
      TURNLOOP_STAGING_SPEC="$staging_spec" run_entrypoint "$ENTRY_MANAGE" "$MANAGE_RUNNER" "$MANAGE_MODEL" "$MANAGE_EFFORT" "$MANAGE_FALLBACK_RUNNER" "$MANAGE_FALLBACK_MODEL" || true
      log "Finished entrypoint: _manage.md ($(entrypoint_finish_summary))"
      turnloop_runtime_touch "manage_complete" "_manage.md $(entrypoint_finish_summary)" "$(get_status)"
      case "$(get_status)" in
        "### IDLE")
          ;;
        "### BLOCKED")
          if [ "${RESEARCH_MECHANIC_ON_BLOCKED:-true}" = "true" ]; then
            handle_mechanic "manage"
          else
            log "Mechanic-on-blocked is disabled for manage; resetting status to idle"
            write_status "### IDLE"
          fi
          ;;
        *)
          if [ "${RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS:-true}" = "true" ]; then
            handle_mechanic "manage"
          else
            log "Unexpected manage status with mechanic-on-unexpected disabled; resetting status to idle"
            write_status "### IDLE"
          fi
          ;;
      esac
    fi
  fi

  if [ "$DAEMON_MODE" = "true" ]; then
    runtime_wait "$POLL_SECS" "idle_poll" "waiting for inbox or staging work"
    continue
  fi
  exit 0

done
