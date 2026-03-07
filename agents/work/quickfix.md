# Quickfix

## 2026-03-06 — Orchestrate Loop Isolated Work Root
- Status: RESOLVED (2026-03-06)
- Issue 1: `move_prompt_to_finished()` still resolves prompt artifacts against `REPO_ROOT` even when the active task file lives under `WORK_ROOT`.
- Impact: An isolated-workspace run can leave the workspace prompt artifact behind or move the wrong repo-root prompt into `agents/work/finished/`, so prompt-file mutations are not consistently isolated.
- Resolution: `move_prompt_to_finished()` now resolves prompt artifacts against `WORK_ROOT`, and the script bootstrap tolerates the sourced verification harness so the isolated prompt move can be exercised directly.
- Verification: `tmp_root="$(pwd)/agents/.tmp/qa-isolated-root"; rm -rf "$tmp_root"; mkdir -p "$tmp_root"/agents/{work/prompts,work/finished,.tmp,logs}; printf '## Test\nPrompt: agents/work/prompts/999-test.md\n' > "$tmp_root"/agents/work/task.md; : > "$tmp_root"/agents/work/tasksbacklog.md; : > "$tmp_root"/agents/work/tasksbackburner.md; : > "$tmp_root"/agents/work/tasksarchive.md; printf 'prompt\n' > "$tmp_root"/agents/work/prompts/999-test.md; TURNLOOP_WORK_ROOT="$tmp_root" bash -lc 'source <(sed "/^while true; do/,\$d" agents/scripts/orchestrate_loop.sh); move_prompt_to_finished; test -f "$FINISHED_DIR/999-test.md" && test ! -f "$WORK_ROOT/agents/work/prompts/999-test.md"'` (PASS)
- Issue 2: `run_entrypoint()` still launches child agents with `instruction="Open ${entry} and follow instructions."`, while the entrypoint files still hardcode repo-root workspace files such as `agents/work/task.md`, `agents/historylog.md`, and `agents/orchestrate_status.md`.
- Impact: When `TURNLOOP_WORK_ROOT` is set, Builder/QA/Troubleshooter/Updater still target the repo-root workspace instead of the isolated one, so the file-based queue contract is not actually preserved.
- Resolution: `run_entrypoint()` now builds an override-aware instruction payload for isolated runs, and every runner receives `TURNLOOP_REPO_ROOT` plus `TURNLOOP_WORK_ROOT` in its environment so child agents can keep repo files anchored while mutating the isolated workspace.
- Verification: `nl -ba agents/scripts/orchestrate_loop.sh | sed -n '366,430p'` (PASS)
- Verification: `rg -n 'agents/work/task.md|agents/historylog.md|agents/orchestrate_status.md' agents/entrypoints/_start.md agents/entrypoints/_check.md agents/entrypoints/_troubleshoot.md agents/entrypoints/_update.md` (PASS)
- Verification: `bash -n agents/scripts/orchestrate_loop.sh` (PASS)

## 2026-03-06 — Shop State Hardening + Loop Regression
- Status: RESOLVED (2026-03-06)
- Issue: `corebound/style.css` defines state-specific `.shop-buy-button` styles, but a live browser check shows the affordable and maxed shop buttons still render with the same default white background and border as the unaffordable state. The purchase guards, labels, row states, and loop regression checks all pass; the remaining gap is the missing button-state polish in the running UI.
- Impact: The shop behavior is correct, but the affordable and maxed buttons are not visually distinct from the unaffordable button in the browser, so the task's state-specific button polish is incomplete.
- Resolution: Removed the shared `.hud-button` background and border transitions so the state-specific affordable and maxed `.shop-buy-button` styles apply immediately when shop rows change state, while preserving the existing locked and unaffordable styles.
- Verification: `node --check corebound/game.js` (PASS)
- Verification: `python3 -m http.server 8000` (PASS)
- Verification: `NODE_PATH=/tmp/pw-check/node_modules PLAYWRIGHT_BROWSERS_PATH=/mnt/f/_evolve/turnloop/.playwright-browsers node <<'EOF' ... live browser regression for invalid purchases, immediate affordable/maxed button styling, digging, ore collection, movement fuel drain, low-fuel warning, surface auto-refuel, and selling ... EOF` (PASS)
