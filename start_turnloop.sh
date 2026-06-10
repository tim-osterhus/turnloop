#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="turnloop"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required to run this launcher." >&2
  exit 1
fi

ensure_layout() {
  if ! tmux list-panes -t "${SESSION_NAME}:0" >/dev/null 2>&1; then
    tmux new-window -t "$SESSION_NAME" -n loops -c "$ROOT_DIR"
  fi

  local pane_count
  pane_count="$(tmux list-panes -t "${SESSION_NAME}:0" -F '#{pane_index}' | wc -l | tr -d '[:space:]')"
  if [ "$pane_count" -lt 2 ]; then
    tmux split-window -t "${SESSION_NAME}:0" -v -c "$ROOT_DIR"
  fi
  pane_count="$(tmux list-panes -t "${SESSION_NAME}:0" -F '#{pane_index}' | wc -l | tr -d '[:space:]')"
  if [ "$pane_count" -lt 3 ]; then
    tmux split-window -t "${SESSION_NAME}:0" -h -c "$ROOT_DIR"
  fi
  tmux select-layout -t "${SESSION_NAME}:0" tiled
}

ensure_loop_in_pane() {
  local pane_index="$1"
  local script_name="$2"
  local pane_target="${SESSION_NAME}:0.${pane_index}"
  local pane_pid
  pane_pid="$(tmux display-message -p -t "$pane_target" '#{pane_pid}' 2>/dev/null || true)"
  if [ -n "$pane_pid" ] && pgrep -P "$pane_pid" -f "agents/scripts/${script_name}" >/dev/null 2>&1; then
    return 0
  fi
  tmux respawn-pane -k -t "$pane_target" "cd \"$ROOT_DIR\" && bash \"$ROOT_DIR/agents/scripts/${script_name}\""
}

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux new-session -d -s "$SESSION_NAME" -n loops -c "$ROOT_DIR"
fi

ensure_layout
ensure_loop_in_pane 0 "orchestrate_loop.sh"
ensure_loop_in_pane 1 "research_loop.sh"
ensure_loop_in_pane 2 "seed_prompt_loop.sh"
tmux attach -t "$SESSION_NAME"
