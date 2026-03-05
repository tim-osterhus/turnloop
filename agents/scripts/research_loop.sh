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
AUTONOMY_COMPLETE_MARKER="agents/AUTONOMY_COMPLETE"

ENTRY_RESEARCH="agents/entrypoints/_research.md"
ENTRY_MANAGE="agents/entrypoints/_manage.md"
ENTRY_MECHANIC="agents/entrypoints/_mechanic.md"

RUNNER="${TURNLOOP_RUNNER:-codex}"
RUNNER_MODEL="${TURNLOOP_MODEL:-gpt-5.2-codex}"
DAEMON_MODE="true"
POLL_SECS="120"
PROMOTE_DELAY_SECS="180"

RESEARCH_EFFORT="high"
MANAGE_EFFORT="xhigh"
MECHANIC_EFFORT="xhigh"

mkdir -p "$TMP_DIR" "$INBOX_DIR" "$PROCESSED_DIR" "$STAGING_DIR" "$SPECS_DIR"
mkdir -p "$NONVIABLE_DIR"

MECHANIC_COUNT_FILE="${TMP_DIR}/mechanic_count.txt"

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
  run_entrypoint "$ENTRY_MECHANIC" "$MECHANIC_EFFORT" || true
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
    sleep "$PROMOTE_DELAY_SECS"
    run_entrypoint "$ENTRY_RESEARCH" "$RESEARCH_EFFORT" || true
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
    sleep "$PROMOTE_DELAY_SECS"
    run_entrypoint "$ENTRY_MANAGE" "$MANAGE_EFFORT" || true
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

  if [ "$DAEMON_MODE" = "true" ]; then
    sleep "$POLL_SECS"
    continue
  fi
  exit 0

done
