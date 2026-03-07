#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
WORK_ROOT="${TURNLOOP_WORK_ROOT:-$REPO_ROOT}"
cd "$WORK_ROOT"

INBOX_DIR="${TURNLOOP_INBOX_DIR:-agents/ideas/inbox}"
PROCESSED_DIR="${TURNLOOP_PROCESSED_DIR:-agents/ideas/processed}"
STAGING_DIR="${TURNLOOP_STAGING_DIR:-agents/ideas/staging}"
SPECS_DIR="${TURNLOOP_SPECS_DIR:-agents/ideas/specs}"
NONVIABLE_DIR="${TURNLOOP_NONVIABLE_DIR:-agents/ideas/nonviable}"
STATUS="${TURNLOOP_RESEARCH_STATUS_FILE:-agents/research_status.md}"
HISTORY="${TURNLOOP_HISTORY_FILE:-agents/historylog.md}"
TMP_DIR="${TURNLOOP_TMP_DIR:-agents/.tmp}"
LOG_DIR="${TURNLOOP_LOG_DIR:-agents/logs}"
AUTONOMY_COMPLETE_MARKER="${TURNLOOP_AUTONOMY_COMPLETE_MARKER:-agents/AUTONOMY_COMPLETE}"

ENTRY_RESEARCH="${TURNLOOP_ENTRY_RESEARCH:-agents/entrypoints/_research.md}"
ENTRY_MANAGE="${TURNLOOP_ENTRY_MANAGE:-agents/entrypoints/_manage.md}"
ENTRY_MECHANIC="${TURNLOOP_ENTRY_MECHANIC:-agents/entrypoints/_mechanic.md}"
VALIDATE_SPEC_SCRIPT="${TURNLOOP_VALIDATE_SPEC_SCRIPT:-${SCRIPT_DIR}/validate_spec.sh}"

RUNNER="${TURNLOOP_RUNNER:-codex}"
RUNNER_MODEL="${TURNLOOP_MODEL:-gpt-5.2-codex}"
DAEMON_MODE="${TURNLOOP_DAEMON_MODE:-true}"
POLL_SECS="${TURNLOOP_POLL_SECS:-120}"
PROMOTE_DELAY_SECS="${TURNLOOP_PROMOTE_DELAY_SECS:-180}"

RESEARCH_RUNNER="${TURNLOOP_RESEARCH_RUNNER:-$RUNNER}"
RESEARCH_MODEL="${TURNLOOP_RESEARCH_MODEL:-gpt-5.4}"
RESEARCH_EFFORT="${TURNLOOP_RESEARCH_EFFORT:-xhigh}"
RESEARCH_FALLBACK_RUNNER="${TURNLOOP_RESEARCH_FALLBACK_RUNNER:-codex}"
RESEARCH_FALLBACK_MODEL="${TURNLOOP_RESEARCH_FALLBACK_MODEL:-gpt-5.4}"

MANAGE_RUNNER="${TURNLOOP_MANAGE_RUNNER:-gemini}"
MANAGE_MODEL="${TURNLOOP_MANAGE_MODEL:-gemini-3-flash-preview}"
MANAGE_EFFORT="${TURNLOOP_MANAGE_EFFORT:-high}"
MANAGE_FALLBACK_RUNNER="${TURNLOOP_MANAGE_FALLBACK_RUNNER:-codex}"
MANAGE_FALLBACK_MODEL="${TURNLOOP_MANAGE_FALLBACK_MODEL:-gpt-5.4}"

MECHANIC_RUNNER="${TURNLOOP_MECHANIC_RUNNER:-$RUNNER}"
MECHANIC_MODEL="${TURNLOOP_MECHANIC_MODEL:-gpt-5.3-codex}"
MECHANIC_EFFORT="${TURNLOOP_MECHANIC_EFFORT:-xhigh}"
MECHANIC_FALLBACK_RUNNER="${TURNLOOP_MECHANIC_FALLBACK_RUNNER:-codex}"
MECHANIC_FALLBACK_MODEL="${TURNLOOP_MECHANIC_FALLBACK_MODEL:-gpt-5.3-codex}"

MECHANIC_AB_MODE="${TURNLOOP_MECHANIC_AB:-off}"   # off | alt | ab
MECHANIC_MODEL_ALT="${TURNLOOP_MECHANIC_MODEL_ALT:-gpt-5.3-codex-spark}"

mkdir -p "$TMP_DIR" "$INBOX_DIR" "$PROCESSED_DIR" "$STAGING_DIR" "$SPECS_DIR" "$LOG_DIR"
mkdir -p "$NONVIABLE_DIR"

MECHANIC_COUNT_FILE="${TMP_DIR}/mechanic_count.txt"
MECHANIC_AB_FILE="${TMP_DIR}/mechanic_ab_toggle.txt"

log() {
  local ts
  ts="$(date '+%F %T')"
  printf '[%s] %s\n' "$ts" "$1"
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
      "$runner" exec --model "$model" --dangerously-bypass-approvals-and-sandbox --ephemeral --color never \
      -c "model_reasoning_effort=\"${effort}\"" "$instruction" \
      >> "$log_file" 2>&1
    return $?
  fi
  if [ "$runner" = "claude" ]; then
    "$runner" -p "$instruction" --model "$model" --output-format text --dangerously-skip-permissions >> "$log_file" 2>&1
    return $?
  fi
  if [ "$runner" = "gemini" ]; then
    run_gemini_entrypoint "$instruction" "$model" "$log_file"
    return $?
  fi

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

run_entrypoint() {
  local entry="$1"
  local runner="$2"
  local model="$3"
  local effort="$4"
  local fallback_runner="$5"
  local fallback_model="$6"
  local entry_name codex_log instruction
  entry_name="$(basename "$entry" .md)"
  codex_log="${LOG_DIR}/research_${entry_name}.log"
  instruction="Open ${entry} and follow instructions."
  if [ "$entry" = "$ENTRY_MANAGE" ] && [ -n "${TURNLOOP_STAGING_SPEC:-}" ]; then
    instruction="${instruction} Use the already-selected staging spec at ${TURNLOOP_STAGING_SPEC} for this run."
  fi
  local rc=0
  invoke_runner "$runner" "$instruction" "$model" "$effort" "$codex_log"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    return 0
  fi
  if [ "$runner" = "gemini" ] && [ "$rc" -eq 11 ] && [ -n "$fallback_runner" ] && [ -n "$fallback_model" ]; then
    log "Gemini model ${model} hit capacity/quota limits; falling back to ${fallback_runner}:${fallback_model}"
    invoke_runner "$fallback_runner" "$instruction" "$fallback_model" "$effort" "$codex_log" || {
      write_status "### BLOCKED"
      return 1
    }
    return 0
  fi
  write_status "### BLOCKED"
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

oldest_file() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    return 1
  fi
  find "$dir" -maxdepth 1 -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | head -n1 | cut -d' ' -f2-
}

move_offending_to_nonviable() {
  local stage="$1"
  local src=""
  case "$stage" in
    research) src="$(oldest_file "$INBOX_DIR")" ;;
    manage) src="$(oldest_file "$STAGING_DIR")" ;;
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
  local mechanic_model
  mechanic_model="$(select_model "$MECHANIC_MODEL" "$MECHANIC_MODEL_ALT" "$MECHANIC_AB_MODE" "$MECHANIC_AB_FILE")"
  log "Starting entrypoint: _mechanic.md (stage=${stage})"
  run_entrypoint "$ENTRY_MECHANIC" "$MECHANIC_RUNNER" "$mechanic_model" "$MECHANIC_EFFORT" "$MECHANIC_FALLBACK_RUNNER" "$MECHANIC_FALLBACK_MODEL" || true
  log "Finished entrypoint: _mechanic.md (status=$(get_status))"
  if [ "$(get_status)" = "### BLOCKED" ]; then
    local count
    count="$(inc_mechanic_count)"
    if [ "$count" -ge 2 ]; then
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

while true; do
  if [ -f "$AUTONOMY_COMPLETE_MARKER" ]; then
    exit 0
  fi

  if has_inbox_work; then
    log "Inbox has work; waiting ${PROMOTE_DELAY_SECS}s before research"
    sleep "$PROMOTE_DELAY_SECS"
    log "Starting entrypoint: _research.md"
    run_entrypoint "$ENTRY_RESEARCH" "$RESEARCH_RUNNER" "$RESEARCH_MODEL" "$RESEARCH_EFFORT" "$RESEARCH_FALLBACK_RUNNER" "$RESEARCH_FALLBACK_MODEL" || true
    log "Finished entrypoint: _research.md (status=$(get_status))"
    case "$(get_status)" in
      "### IDLE")
        ;;
      "### BLOCKED")
        handle_mechanic "research"
        ;;
      *)
        handle_mechanic "research"
        ;;
    esac
  fi

  if has_staging_work; then
    log "Staging has work; waiting ${PROMOTE_DELAY_SECS}s before manage"
    sleep "$PROMOTE_DELAY_SECS"
    staging_spec="$(oldest_file "$STAGING_DIR")"
    manage_ready="false"
    if [ -z "$staging_spec" ]; then
      log "Staging validation failed: no staging spec found"
      write_status "### BLOCKED"
      handle_mechanic "manage"
    else
      log "Validating staging spec: $staging_spec"
      if ! "$VALIDATE_SPEC_SCRIPT" "$staging_spec"; then
        log "Staging validation failed for $staging_spec"
        write_status "### BLOCKED"
        handle_mechanic "manage"
      else
        manage_ready="true"
      fi
    fi
    if [ "$manage_ready" = "true" ]; then
      log "Starting entrypoint: _manage.md"
      TURNLOOP_STAGING_SPEC="$staging_spec" run_entrypoint "$ENTRY_MANAGE" "$MANAGE_RUNNER" "$MANAGE_MODEL" "$MANAGE_EFFORT" "$MANAGE_FALLBACK_RUNNER" "$MANAGE_FALLBACK_MODEL" || true
      log "Finished entrypoint: _manage.md (status=$(get_status))"
      case "$(get_status)" in
        "### IDLE")
          ;;
        "### BLOCKED")
          handle_mechanic "manage"
          ;;
        *)
          handle_mechanic "manage"
          ;;
      esac
    fi
  fi

  if [ "$DAEMON_MODE" = "true" ]; then
    sleep "$POLL_SECS"
    continue
  fi
  exit 0

done
