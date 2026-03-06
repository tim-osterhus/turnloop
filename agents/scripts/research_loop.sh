#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
cd "$REPO_ROOT"

INBOX_DIR="agents/ideas/inbox"
PROCESSED_DIR="agents/ideas/processed"
STAGING_DIR="agents/ideas/staging"
SPECS_DIR="agents/ideas/specs"
NONVIABLE_DIR="agents/ideas/nonviable"
STATUS="agents/research_status.md"
HISTORY="agents/historylog.md"
TMP_DIR="agents/.tmp"
LOG_DIR="agents/logs"
AUTONOMY_COMPLETE_MARKER="agents/AUTONOMY_COMPLETE"

ENTRY_RESEARCH="agents/entrypoints/_research.md"
ENTRY_MANAGE="agents/entrypoints/_manage.md"
ENTRY_MECHANIC="agents/entrypoints/_mechanic.md"

RUNNER="${TURNLOOP_RUNNER:-codex}"
RUNNER_MODEL="${TURNLOOP_MODEL:-gpt-5.2-codex}"
DAEMON_MODE="${TURNLOOP_DAEMON_MODE:-true}"
POLL_SECS="${TURNLOOP_POLL_SECS:-120}"
PROMOTE_DELAY_SECS="${TURNLOOP_PROMOTE_DELAY_SECS:-180}"

RESEARCH_MODEL="${TURNLOOP_RESEARCH_MODEL:-gpt-5.4}"
RESEARCH_EFFORT="${TURNLOOP_RESEARCH_EFFORT:-xhigh}"

MANAGE_MODEL="${TURNLOOP_MANAGE_MODEL:-gpt-5.4}"
MANAGE_EFFORT="${TURNLOOP_MANAGE_EFFORT:-high}"

MECHANIC_MODEL="${TURNLOOP_MECHANIC_MODEL:-gpt-5.3-codex}"
MECHANIC_EFFORT="${TURNLOOP_MECHANIC_EFFORT:-xhigh}"

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
  local model="$2"
  local effort="$3"
  local entry_name codex_log
  entry_name="$(basename "$entry" .md)"
  codex_log="${LOG_DIR}/research_${entry_name}.log"
  if ! command -v "$RUNNER" >/dev/null 2>&1; then
    echo "Missing runner: $RUNNER" >&2
    write_status "### BLOCKED"
    return 1
  fi

  if [ "$RUNNER" = "codex" ]; then
    env -u CODEX_THREAD_ID -u CODEX_SESSION_ID \
      "$RUNNER" exec --model "$model" --dangerously-bypass-approvals-and-sandbox --ephemeral --color never \
      -c "model_reasoning_effort=\"${effort}\"" "Open ${entry} and follow instructions." \
      >> "$codex_log" 2>&1 || { write_status "### BLOCKED"; return 1; }
  elif [ "$RUNNER" = "claude" ]; then
    "$RUNNER" -p "Open ${entry} and follow instructions." --model "$model" --output-format text --dangerously-skip-permissions || { write_status "### BLOCKED"; return 1; }
  else
    "$RUNNER" "Open ${entry} and follow instructions." || { write_status "### BLOCKED"; return 1; }
  fi
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
  run_entrypoint "$ENTRY_MECHANIC" "$mechanic_model" "$MECHANIC_EFFORT" || true
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
    run_entrypoint "$ENTRY_RESEARCH" "$RESEARCH_MODEL" "$RESEARCH_EFFORT" || true
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
    if [ -z "$staging_spec" ]; then
      log "Staging validation failed: no staging spec found"
      write_status "### BLOCKED"
      handle_mechanic "manage"
    else
      log "Validating staging spec: $staging_spec"
      if ! "${SCRIPT_DIR}/validate_spec.sh" "$staging_spec"; then
        log "Staging validation failed for $staging_spec"
        write_status "### BLOCKED"
        handle_mechanic "manage"
      else
        log "Starting entrypoint: _manage.md"
      run_entrypoint "$ENTRY_MANAGE" "$MANAGE_MODEL" "$MANAGE_EFFORT" || true
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
  fi

  if [ "$DAEMON_MODE" = "true" ]; then
    sleep "$POLL_SECS"
    continue
  fi
  exit 0

done
