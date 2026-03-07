#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="turnloop"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required to run this launcher." >&2
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux attach -t "$SESSION_NAME"
  exit 0
fi

tmux new-session -d -s "$SESSION_NAME" -c "$ROOT_DIR"

# Pane 0: orchestrate loop
 tmux send-keys -t "$SESSION_NAME":0.0 " bash \"${ROOT_DIR}/agents/scripts/orchestrate_loop.sh\"" C-m

# Pane 1: research loop
 tmux split-window -t "$SESSION_NAME":0 -v -c "$ROOT_DIR"
 tmux send-keys -t "$SESSION_NAME":0.1 " bash \"${ROOT_DIR}/agents/scripts/research_loop.sh\"" C-m

# Pane 2: seed prompt loop
 tmux split-window -t "$SESSION_NAME":0 -h -c "$ROOT_DIR"
 tmux send-keys -t "$SESSION_NAME":0.2 " bash \"${ROOT_DIR}/agents/scripts/seed_prompt_loop.sh\"" C-m

tmux select-layout -t "$SESSION_NAME":0 tiled

tmux attach -t "$SESSION_NAME"
