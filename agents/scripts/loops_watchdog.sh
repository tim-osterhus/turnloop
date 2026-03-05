#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="${ROOT_DIR}/agents/scripts"
LOG_DIR="${ROOT_DIR}/agents/logs"

ORCH_SCRIPT="${SCRIPT_DIR}/orchestrate_loop.sh"
RES_SCRIPT="${SCRIPT_DIR}/research_loop.sh"

CHECK_INTERVAL_SECS=120
RESTART_DELAY_SECS=300

mkdir -p "${LOG_DIR}"

is_running() {
  local script_path="$1"
  local name first rest
  name="$(basename "$script_path")"
  first="${name:0:1}"
  rest="${name:1}"
  pgrep -f "[${first}]${rest}" >/dev/null 2>&1
}

start_loop() {
  local script_path="$1"
  local log_name="$2"
  nohup bash "${script_path}" >> "${LOG_DIR}/${log_name}.log" 2>&1 &
}

while true; do
  if ! is_running "${ORCH_SCRIPT}"; then
    sleep "${RESTART_DELAY_SECS}"
    if ! is_running "${ORCH_SCRIPT}"; then
      start_loop "${ORCH_SCRIPT}" "orchestrate_loop"
    fi
  fi

  if ! is_running "${RES_SCRIPT}"; then
    sleep "${RESTART_DELAY_SECS}"
    if ! is_running "${RES_SCRIPT}"; then
      start_loop "${RES_SCRIPT}" "research_loop"
    fi
  fi

  sleep "${CHECK_INTERVAL_SECS}"
done
