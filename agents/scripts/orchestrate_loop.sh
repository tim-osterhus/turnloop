#!/usr/bin/env bash
set -euo pipefail

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
cd "$REPO_ROOT"

TASK="${WORK_ROOT}/agents/work/task.md"
BACKLOG="${WORK_ROOT}/agents/work/tasksbacklog.md"
BACKBURNER="${WORK_ROOT}/agents/work/tasksbackburner.md"
ARCHIVE="${WORK_ROOT}/agents/work/tasksarchive.md"
STATUS="${WORK_ROOT}/agents/orchestrate_status.md"
HISTORY="${WORK_ROOT}/agents/historylog.md"
PROMPTS_DIR="${WORK_ROOT}/agents/work/prompts"
FINISHED_DIR="${WORK_ROOT}/agents/work/finished"
TMP_DIR="${WORK_ROOT}/agents/.tmp"
LOG_DIR="${WORK_ROOT}/agents/logs"
AUTONOMY_COMPLETE_MARKER="agents/AUTONOMY_COMPLETE"

ENTRY_START="agents/entrypoints/_start.md"
ENTRY_CHECK="agents/entrypoints/_check.md"
ENTRY_TROUBLE="agents/entrypoints/_troubleshoot.md"
ENTRY_UPDATE="agents/entrypoints/_update.md"

RUNNER="${TURNLOOP_RUNNER:-codex}"
RUNNER_MODEL="${TURNLOOP_MODEL:-gpt-5.2-codex}"
DAEMON_MODE="${TURNLOOP_DAEMON_MODE:-true}"
IDLE_POLL_SECS="${TURNLOOP_IDLE_POLL_SECS:-120}"
PROMOTE_DELAY_SECS="${TURNLOOP_PROMOTE_DELAY_SECS:-180}"

START_RUNNER="${TURNLOOP_START_RUNNER:-$RUNNER}"
START_MODEL="${TURNLOOP_START_MODEL:-gpt-5.4}"
START_EFFORT="${TURNLOOP_START_EFFORT:-high}"
START_FALLBACK_RUNNER="${TURNLOOP_START_FALLBACK_RUNNER:-codex}"
START_FALLBACK_MODEL="${TURNLOOP_START_FALLBACK_MODEL:-gpt-5.4}"

CHECK_RUNNER="${TURNLOOP_CHECK_RUNNER:-$RUNNER}"
CHECK_MODEL="${TURNLOOP_CHECK_MODEL:-gpt-5.4}"
CHECK_EFFORT="${TURNLOOP_CHECK_EFFORT:-xhigh}"
CHECK_FALLBACK_RUNNER="${TURNLOOP_CHECK_FALLBACK_RUNNER:-codex}"
CHECK_FALLBACK_MODEL="${TURNLOOP_CHECK_FALLBACK_MODEL:-gpt-5.4}"

TROUBLE_RUNNER="${TURNLOOP_TROUBLE_RUNNER:-$RUNNER}"
TROUBLE_MODEL="${TURNLOOP_TROUBLE_MODEL:-gpt-5.3-codex}"
TROUBLE_EFFORT="${TURNLOOP_TROUBLE_EFFORT:-xhigh}"
TROUBLE_FALLBACK_RUNNER="${TURNLOOP_TROUBLE_FALLBACK_RUNNER:-codex}"
TROUBLE_FALLBACK_MODEL="${TURNLOOP_TROUBLE_FALLBACK_MODEL:-gpt-5.3-codex}"

UPDATE_RUNNER="${TURNLOOP_UPDATE_RUNNER:-$RUNNER}"
UPDATE_MODEL="${TURNLOOP_UPDATE_MODEL:-gpt-5.2-codex}"
UPDATE_EFFORT="${TURNLOOP_UPDATE_EFFORT:-high}"
UPDATE_FALLBACK_RUNNER="${TURNLOOP_UPDATE_FALLBACK_RUNNER:-codex}"
UPDATE_FALLBACK_MODEL="${TURNLOOP_UPDATE_FALLBACK_MODEL:-gpt-5.2-codex}"

TROUBLE_AB_MODE="${TURNLOOP_TROUBLE_AB:-off}"    # off | alt | ab
UPDATE_AB_MODE="${TURNLOOP_UPDATE_AB:-off}"      # off | alt | ab
TROUBLE_MODEL_ALT="${TURNLOOP_TROUBLE_MODEL_ALT:-gpt-5.3-codex-spark}"
UPDATE_MODEL_ALT="${TURNLOOP_UPDATE_MODEL_ALT:-gpt-5.3-codex-spark}"

TROUBLE_COUNT_FILE="${TMP_DIR}/troubleshoot_count.txt"
QUICKFIX_COUNT_FILE="${TMP_DIR}/quickfix_count.txt"
CURRENT_TASK_ID_FILE="${TMP_DIR}/current_task_id.txt"
UPDATE_BLOCKED_COUNT_FILE="${TMP_DIR}/update_blocked_count.txt"
TROUBLE_AB_FILE="${TMP_DIR}/troubleshoot_ab_toggle.txt"
UPDATE_AB_FILE="${TMP_DIR}/update_ab_toggle.txt"

mkdir -p "$TMP_DIR" "$PROMPTS_DIR" "$FINISHED_DIR" "$LOG_DIR"

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

get_task_id() {
  rg -m1 '^## ' "$TASK" 2>/dev/null | sed 's/^## //'
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
  while [ "$attempt" -lt 2 ]; do
    attempt=$((attempt + 1))
    local update_model
    update_model="$(select_model "$UPDATE_MODEL" "$UPDATE_MODEL_ALT" "$UPDATE_AB_MODE" "$UPDATE_AB_FILE")"
    log "Starting entrypoint: _update.md (attempt ${attempt})"
    run_entrypoint "$ENTRY_UPDATE" "$UPDATE_RUNNER" "$update_model" "$UPDATE_EFFORT" "$UPDATE_FALLBACK_RUNNER" "$UPDATE_FALLBACK_MODEL" || true
    log "Finished entrypoint: _update.md (status=$(get_status))"
    if [ "$(get_status)" = "### UPDATE_COMPLETE" ]; then
      return 0
    fi
    inc_update_blocked_count >/dev/null
    if [ "$attempt" -lt 2 ]; then
      log "Updater blocked; retrying _update.md"
      continue
    fi
  done
  log "Updater blocked twice; skipping _update.md for this cycle"
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

  awk -v card="$tmp_card" -v rest="$tmp_rest" '
    BEGIN {in_card=0; found=0}
    /^## / {
      if (!found) { in_card=1; found=1 }
      else if (in_card) { in_card=0 }
    }
    {
      if (in_card) print > card;
      else print > rest;
    }
  ' "$BACKLOG"

  if [ ! -s "$tmp_card" ]; then
    return 1
  fi

  mv "$tmp_card" "$TASK"
  mv "$tmp_rest" "$BACKLOG"
  reset_troubleshoot_count
  return 0
}

append_archive() {
  local title
  title="$(get_task_id)"
  if [ ! -s "$ARCHIVE" ]; then
    printf '# Tasks Archive\n\n' >> "$ARCHIVE"
  fi
  printf '## %s — %s\n\n' "$(date +%F)" "${title:-Task}" >> "$ARCHIVE"
  cat "$TASK" >> "$ARCHIVE"
  printf '\n\n' >> "$ARCHIVE"
}

append_backburner() {
  local title
  title="$(get_task_id)"
  if [ ! -s "$BACKBURNER" ]; then
    printf '# Tasks Backburner\n\n' >> "$BACKBURNER"
  fi
  printf '## %s — %s (Auto-demoted)\n\n' "$(date +%F)" "${title:-Task}" >> "$BACKBURNER"
  cat "$TASK" >> "$BACKBURNER"
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
- agents/work/tasksbacklog.md -> ${BACKLOG}
- agents/work/tasksbackburner.md -> ${BACKBURNER}
- agents/work/tasksarchive.md -> ${ARCHIVE}
- agents/work/quickfix.md -> ${WORK_ROOT}/agents/work/quickfix.md
- agents/work/expectations.md -> ${WORK_ROOT}/agents/work/expectations.md
- agents/work/prompts/ -> ${PROMPTS_DIR}/
- agents/work/finished/ -> ${FINISHED_DIR}/
- agents/historylog.md -> ${HISTORY}
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
  local entry_name codex_log instruction
  entry_name="$(basename "$entry" .md)"
  codex_log="${LOG_DIR}/orchestrate_${entry_name}.log"
  instruction="$(build_entrypoint_instruction "$entry")"
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

handle_blocked() {
  local count
  local trouble_model
  trouble_model="$(select_model "$TROUBLE_MODEL" "$TROUBLE_MODEL_ALT" "$TROUBLE_AB_MODE" "$TROUBLE_AB_FILE")"
  log "Starting entrypoint: _troubleshoot.md"
  run_entrypoint "$ENTRY_TROUBLE" "$TROUBLE_RUNNER" "$trouble_model" "$TROUBLE_EFFORT" "$TROUBLE_FALLBACK_RUNNER" "$TROUBLE_FALLBACK_MODEL" || true
  log "Finished entrypoint: _troubleshoot.md (status=$(get_status))"
  if [ "$(get_status)" = "### TROUBLESHOOT_COMPLETE" ]; then
    reset_troubleshoot_count
    write_status "### IDLE"
    return 0
  fi

  write_status "### BLOCKED"
  count="$(inc_troubleshoot_count)"
  if [ "$count" -ge 2 ]; then
    append_backburner
    : > "$TASK"
    write_status "### IDLE"
    reset_troubleshoot_count
  fi
}

while true; do
  if [ -f "$AUTONOMY_COMPLETE_MARKER" ]; then
    exit 0
  fi

  if [ ! -s "$TASK" ]; then
    if rg -q '^## ' "$BACKLOG" 2>/dev/null; then
      log "Backlog has tasks; waiting ${PROMOTE_DELAY_SECS}s before promote"
      sleep "$PROMOTE_DELAY_SECS"
    fi
    if ! promote_next_task; then
      write_status "### IDLE"
      if [ "$DAEMON_MODE" = "true" ]; then
        sleep "$IDLE_POLL_SECS"
        continue
      fi
      exit 0
    fi
  fi

  log "Starting entrypoint: _start.md"
  run_entrypoint "$ENTRY_START" "$START_RUNNER" "$START_MODEL" "$START_EFFORT" "$START_FALLBACK_RUNNER" "$START_FALLBACK_MODEL" || true
  log "Finished entrypoint: _start.md (status=$(get_status))"
  case "$(get_status)" in
    "### BUILDER_COMPLETE")
      log "Starting entrypoint: _check.md"
      run_entrypoint "$ENTRY_CHECK" "$CHECK_RUNNER" "$CHECK_MODEL" "$CHECK_EFFORT" "$CHECK_FALLBACK_RUNNER" "$CHECK_FALLBACK_MODEL" || true
      log "Finished entrypoint: _check.md (status=$(get_status))"
      ;;
    "### BLOCKED")
      handle_blocked
      exit_after_single_cycle_if_needed
      continue
      ;;
    *)
      handle_blocked
      exit_after_single_cycle_if_needed
      continue
      ;;
  esac

  case "$(get_status)" in
    "### QA_COMPLETE")
      run_update_cycle || true
      append_archive
      move_prompt_to_finished
      : > "$TASK"
      write_status "### IDLE"
      reset_troubleshoot_count
      exit_after_single_cycle_if_needed
      ;;
    "### QUICKFIX_NEEDED")
      while [ "$(get_status)" = "### QUICKFIX_NEEDED" ] && [ "$(get_quickfix_count)" -lt 2 ]; do
        inc_quickfix_count >/dev/null
        log "Starting entrypoint: _start.md (quickfix attempt $(get_quickfix_count))"
        run_entrypoint "$ENTRY_START" "$START_RUNNER" "$START_MODEL" "$START_EFFORT" "$START_FALLBACK_RUNNER" "$START_FALLBACK_MODEL" || true
        log "Finished entrypoint: _start.md (status=$(get_status))"
        log "Starting entrypoint: _check.md (quickfix attempt $(get_quickfix_count))"
        run_entrypoint "$ENTRY_CHECK" "$CHECK_RUNNER" "$CHECK_MODEL" "$CHECK_EFFORT" "$CHECK_FALLBACK_RUNNER" "$CHECK_FALLBACK_MODEL" || true
        log "Finished entrypoint: _check.md (status=$(get_status))"
      done
      if [ "$(get_status)" = "### QUICKFIX_NEEDED" ] && [ "$(get_quickfix_count)" -ge 2 ]; then
        append_backburner
        : > "$TASK"
        write_status "### IDLE"
        reset_troubleshoot_count
        exit_after_single_cycle_if_needed
        continue
      fi
      if [ "$(get_status)" = "### QA_COMPLETE" ]; then
        run_update_cycle || true
        append_archive
        move_prompt_to_finished
        : > "$TASK"
        write_status "### IDLE"
        reset_troubleshoot_count
        exit_after_single_cycle_if_needed
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
      handle_blocked
      exit_after_single_cycle_if_needed
      ;;
  esac

done
