#!/usr/bin/env bash
set -euo pipefail

# Alternating every-six-hours runner for seed_prompt.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SEED_SCRIPT="${SCRIPT_DIR}/seed_prompt.sh"
SLEEP_SECS="${SEED_PROMPT_SLEEP_SECS:-21600}"

while true; do
  bash "$SEED_SCRIPT" || true
  sleep "$SLEEP_SECS"
done
