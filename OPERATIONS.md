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

## Control Surface

- `agents/orchestrate_status.md`: execution loop state marker.
- `agents/research_status.md`: research loop state marker.
- `agents/historylog.md`: prepend-only canonical run log.
- `agents/work/task.md`: active execution task card.
- `agents/work/tasksbacklog.md`: execution backlog.
- `agents/work/tasksbackburner.md`: execution auto-demotion queue.
- `agents/work/tasksarchive.md`: completed execution cards.
- `agents/ideas/inbox/`: incoming research prompts.
- `agents/ideas/staging/`: staged specs awaiting manager.
- `agents/ideas/specs/`: processed specs.
- `agents/ideas/nonviable/`: items demoted after repeated mechanic failures.
- `agents/.tmp/`: runtime counters/toggles/state files.
- `agents/logs/`: runner logs.

## Seed Prompt Sources

`seed_prompt.sh` reads live prompt content from:
- `agents/prompts/self_prompt.md`
- `agents/prompts/game_prompt.md`

These are loaded from disk on every seed run, so edits apply without restarting loops.

## Execution Loop (Orchestrate)

Script: `agents/scripts/orchestrate_loop.sh`

High-level behavior:
1. If `agents/work/task.md` is empty, promote first `##` card from `agents/work/tasksbacklog.md` after `PROMOTE_DELAY_SECS`.
2. Run Builder (`agents/entrypoints/_start.md`).
3. Run QA (`agents/entrypoints/_check.md`).
4. If QA returns `### QUICKFIX_NEEDED`, run Builder+QA retry rounds (max 2 quickfix attempts).
5. If still failing, demote active task to `agents/work/tasksbackburner.md` and clear `task.md`.
6. On `### QA_COMPLETE`, archive active task into `agents/work/tasksarchive.md`, move prompt artifact to `agents/work/finished/`, then run Update (`agents/entrypoints/_update.md`).
7. Update gets two attempts per cycle before returning to idle flow.

Blocked behavior:
- `### BLOCKED` triggers Troubleshooter (`agents/entrypoints/_troubleshoot.md`).
- Two consecutive troubleshoot failures demote active task to backburner and clear active task.

## Research Loop

Script: `agents/scripts/research_loop.sh`

High-level behavior:
1. If inbox has work, wait `PROMOTE_DELAY_SECS`, then run Researcher (`agents/entrypoints/_research.md`).
2. If staging has work, wait `PROMOTE_DELAY_SECS`, select oldest staged spec, and run Manager (`agents/entrypoints/_manage.md`) with `TURNLOOP_STAGING_SPEC` pinned to that file.
3. Any non-idle/blocking path runs Mechanic (`agents/entrypoints/_mechanic.md`).
4. Two consecutive mechanic blocks move the offending oldest file to `agents/ideas/nonviable/` and reset to idle.

## Seed Loop

Scripts:
- `agents/scripts/seed_prompt_loop.sh`
- `agents/scripts/seed_prompt.sh`

Behavior:
1. `seed_prompt_loop.sh` invokes `seed_prompt.sh` every 6 hours by default (`SEED_PROMPT_SLEEP_SECS=21600`).
2. `seed_prompt.sh` checks remaining usage and skips if below `MIN_REMAINING_PCT` (default 10).
3. Prompt choice alternates via `agents/.tmp/seed_prompt_toggle.txt`.
4. Chosen prompt is written into `agents/ideas/inbox/` with timestamped filename.

Usage source precedence:
1. `TURNLOOP_USAGE_REMAINING_PCT`
2. `TURNLOOP_USAGE_FILE`
3. `agents/.tmp/usage_remaining_pct.txt`
4. `TURNLOOP_USAGE_CMD`
5. Codex probing when `TURNLOOP_USAGE_SOURCE=codex`

## Models And Runners

Loop scripts invoke runner CLIs (Codex/Claude/Gemini) per stage.

Live model config file:
- `agents/entrypoints/model_config.env`

Both orchestrate and research loops reload this config before each stage invocation, so model changes apply without restarts.

Config path override:
- `TURNLOOP_MODEL_CONFIG_FILE`

Gemini stages support fallback runner/model retries when quota/capacity/rate-limit style failures are detected.

## Current Default Model Configuration

From `agents/entrypoints/model_config.env`:
- Shared runner default: `codex` with `gpt-5.2-codex`
- `_start`: `gemini-3.1-pro-preview` (fallback `gpt-5.4`)
- `_check`: `gpt-5.4` (fallback `gpt-5.4`)
- `_troubleshoot`: `gpt-5.3-codex-spark` (fallback `gpt-5.3-codex`)
- `_update`: `gpt-5.3-codex-spark` (fallback `gpt-5.2-codex`)
- `_research`: `gpt-5.4` (fallback `gpt-5.4`)
- `_manage`: `gemini-3-flash-preview` (fallback `gpt-5.4`)
- `_mechanic`: `gpt-5.3-codex-spark` (fallback `gpt-5.3-codex`)

## History Log Contract

History entries are prepend-only and should be authored using `agents/roles/historian.md`.

Required format:
- Header: `[YYYY-MM-DD HH:MM] Role • Title`
- Minute precision only (no seconds)
- New entry must be inserted at top of `agents/historylog.md`

## Testing And Site Generation

Run site tests:

```bash
python3 -m unittest tests.test_build_site
```

Rebuild site:

```bash
python3 scripts/build_site.py
```

Test artifacts should live under `tests/test-build-site-results/`.

## Task Card Format

Execution cards in `agents/work/tasksbacklog.md` should start with:

```md
## YYYY-MM-DD — Short Title
```

Cards should include concrete file paths, numbered steps, acceptance checks, and verification commands.

## Safety Notes

- Do not commit secrets or credentials.
- Keep prompt artifacts and logs free of sensitive data.
