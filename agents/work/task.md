## 2026-03-06 — Research Loop Single-Cycle Test Knobs
Prompt: agents/work/prompts/015-research-loop-single-cycle-test-knobs.md
Goal: Make `agents/scripts/research_loop.sh` runnable in one fast local cycle without changing its default daemon behavior.
Scope:
- In: Add environment-variable overrides for daemon mode and the promote/poll delays, preserving the current defaults when unset.
- Out: Any change to the default production cadence, runner selection, or queue semantics.
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Read `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_POLL_SECS` from the environment with the current hard-coded values as defaults.
2. Keep the existing control flow intact so the loop still sleeps and repeats when the overrides are not provided.
3. Confirm the script can be invoked in a no-wait single-cycle mode for local harness use.
Acceptance:
- The script preserves its current behavior when the new environment variables are unset.
- The script can be configured for a zero-delay, non-daemon run without syntax errors.
Verification commands:
- `rg -n 'TURNLOOP_DAEMON_MODE|TURNLOOP_PROMOTE_DELAY_SECS|TURNLOOP_POLL_SECS' agents/scripts/research_loop.sh` — Expected: all three override names are present.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0.
