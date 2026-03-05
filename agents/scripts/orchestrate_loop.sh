#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
cd "$REPO_ROOT"

TASK="agents/work/task.md"
BACKLOG="agents/work/tasksbacklog.md"
BACKBURNER="agents/work/tasksbackburner.md"
ARCHIVE="agents/work/tasksarchive.md"
STATUS="agents/orchestrate_status.md"
HISTORY="agents/historylog.md"
PROMPTS_DIR="agents/work/prompts"
FINISHED_DIR="agents/work/finished"
TMP_DIR="agents/.tmp"
AUTONOMY_COMPLETE_MARKER="agents/AUTONOMY_COMPLETE"

ENTRY_START="agents/entrypoints/_start.md"
ENTRY_CHECK="agents/entrypoints/_check.md"
ENTRY_TROUBLE="agents/entrypoints/_troubleshoot.md"

RUNNER="${TURNLOOP_RUNNER:-codex}"
RUNNER_MODEL="${TURNLOOP_MODEL:-gpt-5.2-codex}"
DAEMON_MODE="true"
IDLE_POLL_SECS="120"
PROMOTE_DELAY_SECS="180"

START_EFFORT="high"
CHECK_EFFORT="high"
TROUBLE_EFFORT="xhigh"

TROUBLE_COUNT_FILE="${TMP_DIR}/troubleshoot_count.txt"
QUICKFIX_COUNT_FILE="${TMP_DIR}/quickfix_count.txt"
CURRENT_TASK_ID_FILE="${TMP_DIR}/current_task_id.txt"

mkdir -p "$TMP_DIR" "$PROMPTS_DIR" "$FINISHED_DIR"

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
  if [ -n "$rel_path" ] && [ -f "$REPO_ROOT/$rel_path" ]; then
    mv "$REPO_ROOT/$rel_path" "$FINISHED_DIR/"
  fi
}

run_entrypoint() {
  local entry="$1"
  local effort="$2"
  if ! command -v "$RUNNER" >/dev/null 2>&1; then
    echo "Missing runner: $RUNNER" >&2
    write_status "### BLOCKED"
    return 1
  fi

  if [ "$RUNNER" = "codex" ]; then
    "$RUNNER" exec --model "$RUNNER_MODEL" --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"${effort}\"" "Open ${entry} and follow instructions." || { write_status "### BLOCKED"; return 1; }
  elif [ "$RUNNER" = "claude" ]; then
    "$RUNNER" -p "Open ${entry} and follow instructions." --model "$RUNNER_MODEL" --output-format text --dangerously-skip-permissions || { write_status "### BLOCKED"; return 1; }
  else
    "$RUNNER" "Open ${entry} and follow instructions." || { write_status "### BLOCKED"; return 1; }
  fi
}

handle_blocked() {
  local count
  run_entrypoint "$ENTRY_TROUBLE" "$TROUBLE_EFFORT" || true
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

  run_entrypoint "$ENTRY_START" "$START_EFFORT" || true
  case "$(get_status)" in
    "### BUILDER_COMPLETE")
      run_entrypoint "$ENTRY_CHECK" "$CHECK_EFFORT" || true
      ;;
    "### BLOCKED")
      handle_blocked
      continue
      ;;
    *)
      handle_blocked
      continue
      ;;
  esac

  case "$(get_status)" in
    "### QA_COMPLETE")
      append_archive
      move_prompt_to_finished
      : > "$TASK"
      write_status "### IDLE"
      reset_troubleshoot_count
      ;;
    "### QUICKFIX_NEEDED")
      while [ "$(get_status)" = "### QUICKFIX_NEEDED" ] && [ "$(get_quickfix_count)" -lt 2 ]; do
        inc_quickfix_count >/dev/null
        run_entrypoint "$ENTRY_START" "$START_EFFORT" || true
        run_entrypoint "$ENTRY_CHECK" "$CHECK_EFFORT" || true
      done
      if [ "$(get_status)" = "### QUICKFIX_NEEDED" ] && [ "$(get_quickfix_count)" -ge 2 ]; then
        append_backburner
        : > "$TASK"
        write_status "### IDLE"
        reset_troubleshoot_count
        continue
      fi
      if [ "$(get_status)" = "### QA_COMPLETE" ]; then
        append_archive
        move_prompt_to_finished
        : > "$TASK"
        write_status "### IDLE"
        reset_troubleshoot_count
      elif [ "$(get_status)" = "### BLOCKED" ]; then
        handle_blocked
      fi
      ;;
    "### BLOCKED")
      handle_blocked
      ;;
    *)
      handle_blocked
      ;;
  esac

done
