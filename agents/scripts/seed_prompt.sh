#!/usr/bin/env bash
set -euo pipefail

# Seed prompt injector (one-shot).
# Intended to be run on a schedule (e.g., every 6 hours) by an external cron.
# Uses a weekly-usage percentage from an explicit override/file when available.
# Codex TUI probing is only a fallback because the status surface can change.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
INBOX_DIR="${REPO_ROOT}/agents/ideas/inbox"
STATE_DIR="${REPO_ROOT}/agents/.tmp"
TOGGLE_FILE="${STATE_DIR}/seed_prompt_toggle.txt"
USAGE_FILE_DEFAULT="${STATE_DIR}/usage_remaining_pct.txt"
USAGE_SOURCE="${TURNLOOP_USAGE_SOURCE:-codex}"

MIN_REMAINING_PCT=10

PROMPT_A=$(cat <<'PROMPT_A'
# Turnloop Goal

Make Turnloop a stronger, more reliable agentic development framework that works well across many kinds of projects, not just a single use case. The long‑term goal is broad, durable improvement: fewer failures, fewer wasted cycles, clearer handoffs, and more consistent progress from intent to implementation to validation. Focus on strengthening the framework itself so it performs better for any project placed within it.

Make at least one meaningful improvement that makes Turnloop noticeably better than its current state. You are free to choose the technical direction and the concrete implementation. The intent is to improve general effectiveness and robustness without overfitting to any single project or benchmark.

The framework should remain stable and usable throughout. If a change doesn’t work or introduces regressions, revert to the last stable behavior and leave the system cleaner than you found it. If you encounter dependency or tooling issues, resolve them in a way that keeps the framework general‑purpose; if that isn’t possible, step back and choose a simpler solution that avoids those dependencies.

Guiding intent:
- Improve reliability: fewer blocked runs, fewer ambiguous outcomes.
- Improve clarity: clearer contracts, easier to follow lifecycle.
- Improve autonomy: more progress per cycle with less manual intervention.
- Improve generality: works well across different projects and constraints.
- Improve discipline: small, verifiable changes over speculative rewrites.

The goal is steady compounding improvement rather than big rewrites. Prefer changes that make future work easier and reduce confusion. Avoid tuning the framework toward a narrow scenario; instead, strengthen the fundamentals so it becomes more dependable, more legible, and more adaptable in general.

You are free to decide the specific changes, as long as the result is a real, durable improvement. If you can’t make a safe improvement, revert and choose a smaller, safer step next time. The priority is making Turnloop consistently better, in ways that would matter to someone using it on a different codebase.

Look for the friction that most often slows or derails progress: unclear handoffs, missing signals, brittle loops, or ambiguity that causes rework. Prefer improvements that tighten the loop and make outcomes higher quality and more predictable without reducing flexibility. The framework should make it easy to recover from failure, easy to tell what happened, and easy to resume with minimal context loss.

Aim for changes that scale as the system grows. The framework should stay coherent as more roles, stages, features, or projects are added. Favor clarity, reversibility, and small improvements that build confidence over time.

Keep the system honest. Prefer mechanisms that surface reality rather than hide it: when something fails, it should be obvious; when something succeeds, it should be verifiable. The framework should encourage careful, minimal changes that can be understood and reviewed quickly, while still enabling meaningful progress.
PROMPT_A
)

PROMPT_B=$(cat <<'PROMPT_B'
# Corebound Goal

Build a lightweight browser‑based mining game inspired by MotherLoad. The long‑term aim is a smooth, satisfying game that stays fast and stable even as more content is added. The experience should feel simple to pick up but meaningful to master: descend, gather, return, upgrade, repeat. Each loop should give the player a clear sense of progress and a reason to go deeper.

Make a concrete improvement today that makes the game noticeably better than its current state. “Better” can mean more fun, clearer feedback, smoother controls, richer progression, improved performance, or a sharper sense of risk and reward. Choose the highest‑impact change you can land without destabilizing the experience. If you find yourself chasing a large or uncertain improvement, scale down to the smallest slice that still moves the game forward in a visible way.

The game should remain playable and coherent throughout. If a change breaks the experience or can’t be stabilized quickly, revert to the last stable behavior and leave the project cleaner than you found it. If you run into dependency or tooling issues, resolve them in a way that preserves a lightweight, self‑contained game; if that isn’t possible, choose a simpler approach that avoids that dependency entirely.

If the repository is empty or lacks a playable baseline, create a minimal, fully runnable baseline first. That baseline should include the core loop scaffolding (start, descend, mine, return), a simple UI, and basic state updates so the game is playable at a basic level. Once a baseline exists, proceed with a concrete improvement. Do not block just because the repo is empty.

Think in terms of player experience and longevity:
- The controls should feel predictable and responsive.
- The feedback loop should be immediate and understandable.
- The economy should reward smart choices without feeling grindy.
- Progress should feel earned, not random.
- Deeper play should introduce new tension or payoff.

You are free to choose the technical approach and the specific design decisions. The goal is clarity of intent and steady improvement, not a perfect or exhaustive system. Make one meaningful step forward that compounds with future work, and preserve a stable, playable foundation.

Additional intent to guide choices:
- Favor readability and coherence over complexity.
- Avoid brittle systems that are hard to extend.
- Prefer improvements that reduce friction for new players.
- Keep the moment‑to‑moment flow engaging; the player should always have a next action that feels worthwhile.
- If you introduce new mechanics, make sure they integrate naturally with the existing loop.

The bar is not “finish the game.” The bar is “ship a stable, noticeable improvement that makes the game more fun or more robust.” If you can’t do that without breaking the experience, revert and choose a smaller, safer step.

Consider the feel of depth and discovery. The player should sense that going deeper changes the game, not just the number on a depth meter. Encourage a progression that introduces new choices, tradeoffs, or dangers as depth increases. Variety matters, but only if it strengthens the core loop and keeps the game readable and coherent.

Keep the experience resilient to growth. As the game gains content, it should remain smooth, stable, and understandable. If a new idea adds complexity without a clear payoff in fun or clarity, favor a smaller, cleaner improvement instead.
PROMPT_B
)

mkdir -p "$INBOX_DIR" "$STATE_DIR"

log() {
  local ts
  ts="$(date '+%F %T')"
  printf '[%s] %s\n' "$ts" "$1"
}

normalize_pct() {
  local raw="$1"
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

  # Fixed waits to allow the TUI to fully initialize.
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
  tmux_weekly_remaining_pct
}

get_remaining_pct() {
  local raw=""

  if [ -n "${TURNLOOP_USAGE_REMAINING_PCT:-}" ]; then
    raw="$TURNLOOP_USAGE_REMAINING_PCT"
  elif [ -n "${TURNLOOP_USAGE_FILE:-}" ] && [ -f "$TURNLOOP_USAGE_FILE" ]; then
    raw="$(head -n 1 "$TURNLOOP_USAGE_FILE" 2>/dev/null || true)"
  elif [ -f "$USAGE_FILE_DEFAULT" ]; then
    raw="$(head -n 1 "$USAGE_FILE_DEFAULT" 2>/dev/null || true)"
  elif [ -n "${TURNLOOP_USAGE_CMD:-}" ]; then
    raw="$(bash -lc "$TURNLOOP_USAGE_CMD" 2>/dev/null | head -n 1 || true)"
  elif [ "$USAGE_SOURCE" = "codex" ]; then
    raw="$(codex_weekly_remaining_pct || true)"
  fi

  normalize_pct "$raw" || return 1
}

remaining_pct="$(get_remaining_pct || true)"
if [ -z "$remaining_pct" ]; then
  log "WARN: usage remaining unknown; set TURNLOOP_USAGE_REMAINING_PCT or ${USAGE_FILE_DEFAULT} (or TURNLOOP_USAGE_SOURCE=codex to attempt /status). Skipping seed prompt."
  exit 0
fi

if [ "$remaining_pct" -lt "$MIN_REMAINING_PCT" ]; then
  log "Usage remaining ${remaining_pct}% < ${MIN_REMAINING_PCT}% — skipping seed prompt"
  exit 0
fi

last="A"
if [ -f "$TOGGLE_FILE" ]; then
  last="$(tr -d '\r' < "$TOGGLE_FILE" || echo B)"
fi

next="A"
if [ "$last" = "A" ]; then
  next="B"
fi

stamp="$(date '+%m-%d-%y-%H')"
if [ "$next" = "A" ]; then
  file_path="${INBOX_DIR}/turnloop-prompt-${stamp}.md"
  printf '%s\n' "$PROMPT_A" > "$file_path"
else
  file_path="${INBOX_DIR}/corebound-prompt-${stamp}.md"
  printf '%s\n' "$PROMPT_B" > "$file_path"
fi

printf '%s\n' "$next" > "$TOGGLE_FILE"
log "Seeded prompt: $(basename "$file_path") (usage remaining ${remaining_pct}%)"
