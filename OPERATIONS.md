# Turnloop Operations

This document is the technical runbook for operating and debugging Turnloop.

## Runtime Overview

Turnloop is usually run as three long-lived foreground processes:

```bash
bash agents/scripts/orchestrate_loop.sh
bash agents/scripts/research_loop.sh
bash agents/scripts/seed_prompt_loop.sh
```

Optional local launcher: if `start_turnloop.sh` exists in your working copy, you can use it to spawn all three loops in tmux.

To stop loops cleanly, create `agents/AUTONOMY_COMPLETE`.

Each long-lived loop now self-supervises:
- unexpected script exits are converted into configurable retry/backoff rather than dead panes
- watched loop script/runtime config drift triggers an in-place worker relaunch
- runtime state is written to JSON under `agents/.tmp/runtime/`

## Control Surface

- `rules.md`: authoritative workspace-specific mission and scoping contract for entrypoints and roles.
- `agents/orchestrate_status.md`: execution loop state marker.
- `agents/research_status.md`: research loop state marker.
- `agents/orchestrate_historylog.md`: prepend-only execution-loop journal.
- `agents/research_historylog.md`: prepend-only research-loop journal.
- `agents/work/task.md`: active execution task card.
- `agents/work/taskspending.md`: research-owned pending queue.
- `agents/work/tasksbacklog.md`: execution backlog.
- `agents/work/tasksbackburner.md`: execution auto-demotion queue.
- `agents/work/tasksarchive.md`: completed execution cards.
- `agents/ideas/inbox/`: incoming research prompts.
- `agents/ideas/staging/`: staged specs awaiting manager.
- `agents/ideas/specs/`: processed specs.
- `agents/ideas/nonviable/`: items demoted after repeated mechanic failures.
- `agents/.tmp/`: runtime counters/toggles/state files.
- `agents/.tmp/runtime/`: per-loop runtime-state JSON heartbeats.
- `agents/logs/`: runner logs.

## Seed Prompt Sources

`seed_prompt.sh` reads live prompt content from:
- numbered files under `agents/prompts/seed/`

Contract:
- prompt files must begin with an integer, such as `1-corebound.md` or `2-new-game.md`
- the loop advances to the next integer if it exists
- if the next sequential number is missing, rotation wraps back to `1`
- edits to prompt files or the prompt directory take effect on the next seed run without restarting the loop

## Execution Loop (Orchestrate)

Script: `agents/scripts/orchestrate_loop.sh`

High-level behavior:
1. If `agents/work/task.md` is empty, check `agents/work/tasksbacklog.md` first.
2. If backlog is empty, check `agents/work/taskspending.md`, wait `PENDING_TRANSFER_DELAY_SECS`, then move pending cards into backlog.
3. Promote the first `##` card from `agents/work/tasksbacklog.md` after `BACKLOG_PROMOTE_DELAY_SECS`.
4. Run Builder (`agents/entrypoints/_start.md`).
5. Run QA (`agents/entrypoints/_check.md`).
6. If QA returns `### QUICKFIX_NEEDED`, run Builder+QA retry rounds up to `ORCH_QUICKFIX_MAX_ATTEMPTS`.
7. If still failing, demote active task to `agents/work/tasksbackburner.md` and clear `task.md`.
8. On `### QA_COMPLETE`, archive active task into `agents/work/tasksarchive.md`, move prompt artifact to `agents/work/finished/`, then run Update (`agents/entrypoints/_update.md`).
9. Update gets up to `ORCH_UPDATE_MAX_ATTEMPTS` attempts per cycle before returning to idle flow.

Blocked behavior:
- `### BLOCKED` triggers Troubleshooter (`agents/entrypoints/_troubleshoot.md`) when `ORCH_TROUBLESHOOT_ON_BLOCKED=true`.
- Unexpected builder or QA statuses trigger Troubleshooter when `ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS=true`.
- After `ORCH_TROUBLESHOOT_MAX_ATTEMPTS`, the task is auto-demoted to backburner and cleared.

## Research Loop

Script: `agents/scripts/research_loop.sh`

High-level behavior:
1. If inbox has work, wait `RESEARCH_RESEARCH_DELAY_SECS`, then run Researcher (`agents/entrypoints/_research.md`).
2. If staging has work, wait `RESEARCH_MANAGE_DELAY_SECS`, select oldest staged spec, and run Manager (`agents/entrypoints/_manage.md`) with `TURNLOOP_STAGING_SPEC` pinned to that file.
3. Manager writes newly created task cards into `agents/work/taskspending.md`, not directly into `agents/work/tasksbacklog.md`.
4. Any blocked or unexpected non-idle path can run Mechanic (`agents/entrypoints/_mechanic.md`), depending on the loop config toggles.
5. After `RESEARCH_MECHANIC_MAX_ATTEMPTS`, the offending oldest file is moved to `agents/ideas/nonviable/` and the loop resets to idle.

## Seed Loop

Scripts:
- `agents/scripts/seed_prompt_loop.sh`
- `agents/scripts/seed_prompt.sh`

Behavior:
1. `seed_prompt_loop.sh` reloads `agents/config/seed_config.env` before every tick and during between-tick waits.
2. `seed_prompt.sh` reloads the same config on every run, then selects the next numbered prompt from `agents/prompts/seed/`.
3. `seed_prompt.sh` checks remaining usage and skips if below `SEED_USAGE_MIN_REMAINING_PCT` (default 10).
4. If the usage check returns no usable value, behavior is controlled by `SEED_USAGE_FAILURE_BEHAVIOR`:
   `skip` leaves inbox untouched for that tick; `continue` seeds anyway.
5. Chosen prompt is written into `agents/ideas/inbox/` with a timestamped filename.

Usage source precedence:
1. `TURNLOOP_USAGE_REMAINING_PCT`
2. `SEED_USAGE_SOURCE=file` using `SEED_USAGE_FILE` or `TURNLOOP_SEED_USAGE_FILE`
3. `SEED_USAGE_SOURCE=cmd` using `SEED_USAGE_CMD` or `TURNLOOP_SEED_USAGE_CMD`
4. `SEED_USAGE_SOURCE=auto` trying file, then cmd, then Codex probe
5. `SEED_USAGE_SOURCE=codex` using the Codex app-server probe with timeout
6. `SEED_USAGE_SOURCE=none` to disable the check entirely

Live seed config file:
- `agents/config/seed_config.env`

Seed config path override:
- `TURNLOOP_SEED_CONFIG_FILE`

## Models And Runners

Loop scripts invoke runner CLIs (Codex/Claude/Gemini) per stage.

Live model config file:
- `agents/entrypoints/model_config.env`

Both orchestrate and research loops reload this config before each stage invocation, so model changes apply without restarts.

Config path override:
- `TURNLOOP_MODEL_CONFIG_FILE`

Loop-runtime config file:
- `agents/config/runtime_config.env`

Loop-runtime config path override:
- `TURNLOOP_RUNTIME_CONFIG_FILE`

Runtime config controls:
- retry/backoff after unexpected loop crashes
- sleep chunk size for faster hot-reload pickup during long waits
- whether drift-triggered relaunch is enabled
- whether runtime-state heartbeat files are written

Loop-behavior config file:
- `agents/config/loop_config.env`

Loop-behavior config path override:
- `TURNLOOP_LOOP_CONFIG_FILE`

Loop-behavior config controls:
- orchestrate and research entrypoint file paths
- queue and poll delays
- quickfix, update, troubleshoot, and mechanic attempt limits
- whether blocked or unexpected statuses trigger troubleshoot or mechanic repair paths

Gemini stages support fallback runner/model retries when quota/capacity/rate-limit style failures are detected.

## Runtime Freshness And Heartbeats

The long-lived loops watch their own script files plus runtime config for drift.

Observed behavior:
- if a watched file changes on disk, the current worker exits with a reserved restart code and the supervisor immediately relaunches it
- if a loop crashes unexpectedly, the supervisor waits `RUNTIME_RETRY_DELAY_SECS` and retries
- loop state remains inspectable in `agents/.tmp/runtime/orchestrate.json`, `research.json`, and `seed.json`

Each runtime JSON file includes:
- current phase
- last known status marker
- worker/supervisor mode
- restart count
- watched-file hash
- last error, when present

## Current Default Model Configuration

From `agents/entrypoints/model_config.env`:
- Shared runner default: `codex` with `gpt-5.2-codex`
- `_start`: `gpt-5.4` (fallback `gpt-5.3-codex-spark`)
- `_check`: `gpt-5.2` (fallback `gpt-5.4`)
- `_troubleshoot`: `gpt-5.4` (fallback `gpt-5.3-codex`)
- `_update`: `gpt-5.2-codex` (fallback `gpt-5.4`)
- `_research`: `gpt-5.4` (fallback `gpt-5.2`)
- `_manage`: `gpt-5.2-codex` (fallback `gpt-5.4`)
- `_mechanic`: `gpt-5.2-codex` (fallback `gpt-5.3-codex-spark`)

For deterministic repo discovery during Update runs, use:

```bash
python3 agents/scripts/repo_inventory.py --root . --pretty
```

## History Log Contract

History entries are prepend-only and should be authored using `agents/roles/historian.md`.

Required format:
- Header: `[YYYY-MM-DD HH:MM] Role • Title`
- Minute precision only (no seconds)
- New entry must be inserted at top of the correct loop-specific history log

## Testing

Run the framework tests:

```bash
python3 -m unittest discover tests
```

## Task Card Format

Execution cards in `agents/work/tasksbacklog.md` should start with:

```md
## YYYY-MM-DD - Short Title
```

Cards should include concrete file paths, numbered steps, acceptance checks, and verification commands.

## Safety Notes

- Do not commit secrets or credentials.
- Keep prompt artifacts and logs free of sensitive data.
