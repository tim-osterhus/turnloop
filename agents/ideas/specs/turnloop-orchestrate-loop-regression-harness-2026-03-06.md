# Summary
Add isolated local regression coverage for the execution loop so Turnloop can prove backlog promotion, task completion, prompt archival, and quickfix auto-demotion behavior without mutating the real repo queue state or calling external runners.

# Problem statement
`agents/scripts/orchestrate_loop.sh` controls the highest-risk execution-loop state transitions in Turnloop: promoting the next task, retrying Builder and QA, demoting stuck tasks, archiving completed work, and moving prompt artifacts. The research loop already has single-cycle test knobs and a queue-contract harness, but the execution loop does not have comparable isolated test coverage. That gap makes control-flow regressions harder to detect and raises the risk of corrupting real queue files during manual verification.

# Scope (In / Out)
In: Add isolated-workspace and timing overrides to `agents/scripts/orchestrate_loop.sh`, add repo-local execution-loop regression harnesses, and document the local harness commands in `README.md`.
Out: Changes to Builder, QA, Troubleshooter, or Updater entrypoint instructions; changes to research-loop behavior; changes under `corebound/`; changes to runner fallback policy or model defaults.

# Constraints
- Keep the file-based queue model and overwrite-only status markers intact.
- Preserve the current default execution-loop behavior when no new override variables are set.
- Keep harness execution fully local to the repo and isolated temp state under the repo root.
- Do not add new runtime dependencies beyond shell utilities already used by Turnloop.

# Requirements
- `agents/scripts/orchestrate_loop.sh` SHALL support `TURNLOOP_WORK_ROOT` so queue and status mutations can target an isolated workspace while preserving the current repo-root behavior when the variable is unset.
- `agents/scripts/orchestrate_loop.sh` SHALL support `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_IDLE_POLL_SECS` with the current hard-coded values as defaults when the variables are unset.
- `agents/scripts/orchestrate_loop.sh` SHALL preserve the current default runner, model, and control-flow behavior when the new override variables are unset.
- The repo SHALL include a local happy-path execution-loop harness that seeds two backlog cards in isolated temp state and runs one non-daemon cycle through the real `agents/scripts/orchestrate_loop.sh` control flow.
- The happy-path harness SHALL verify that only the oldest backlog card is promoted and completed in that cycle.
- The happy-path harness SHALL verify that the completed card is appended to `agents/work/tasksarchive.md`, its referenced prompt artifact is moved to `agents/work/finished/`, and the newer backlog card remains queued in `agents/work/tasksbacklog.md`.
- The repo SHALL include a local quickfix-demotion harness that drives one isolated execution-loop cycle to `### QUICKFIX_NEEDED` twice and then verifies the task is auto-demoted to `agents/work/tasksbackburner.md`.
- The quickfix-demotion harness SHALL verify that the active task file is cleared after auto-demotion and that the loop returns `agents/orchestrate_status.md` to `### IDLE`.
- The execution-loop harnesses SHALL use only repo-local shell utilities and local runner stubs.
- The execution-loop harnesses SHALL NOT invoke external runners or network services.
- `README.md` SHALL document the local execution-loop regression commands and state that they run against isolated temp state.

# Verification plan
- `rg -n 'TURNLOOP_WORK_ROOT|TURNLOOP_DAEMON_MODE|TURNLOOP_PROMOTE_DELAY_SECS|TURNLOOP_IDLE_POLL_SECS' agents/scripts/orchestrate_loop.sh` — Expected: all four override names appear in the execution-loop script.
- `bash -n agents/scripts/orchestrate_loop.sh` — Expected: exit 0 with no syntax errors after the override changes.
- `bash agents/scripts/test_orchestrate_happy_path.sh` — Expected: exit 0 and output confirming that only the oldest backlog card was promoted, archived, and had its prompt moved to `agents/work/finished/` while the newer card remained queued.
- `bash agents/scripts/test_orchestrate_quickfix_demotion.sh` — Expected: exit 0 and output confirming that two quickfix loops auto-demoted the task to `agents/work/tasksbackburner.md`, cleared `agents/work/task.md`, and restored `agents/orchestrate_status.md` to `### IDLE`.
- `rg -n 'test_orchestrate_happy_path.sh|test_orchestrate_quickfix_demotion.sh|isolated temp state' README.md agents/scripts` — Expected: both harness scripts exist and the README documents isolated execution-loop regression usage.

# Assumptions
- Local runner stubs can stand in for Codex, Claude, or Gemini during harness runs as long as the real `agents/scripts/orchestrate_loop.sh` control flow is exercised.
- One-cycle isolated harnesses provide sufficient evidence for the execution-loop queue and demotion contracts without invoking live model runners.
- The first reliability slice only needs happy-path completion and quickfix auto-demotion coverage; update-stage retry coverage can follow in a later spec if needed.

# Open questions
- Should the first execution-loop regression suite also cover the troubleshoot auto-demotion path, or is quickfix auto-demotion the higher-value first contract?
- Should the execution-loop harnesses remain as standalone scripts, or later merge into a broader loop-regression suite alongside the research-loop harness?
