<prompt id="028-orchestrate-loop-single-cycle-timing-overrides" task="Orchestrate Loop Single-Cycle Timing Overrides">
  <objective>
    Make `agents/scripts/orchestrate_loop.sh` configurable for fast local one-cycle runs by reading daemon and sleep timing values from environment variables while preserving the current production defaults when those overrides are unset.
  </objective>
  <context>
    - Repo context comes from `agents/outline.md`; this task only touches `agents/scripts/orchestrate_loop.sh`.
    - The script currently hard-codes daemon mode, backlog promote delay, and idle poll delay near the top of the file.
    - The active task explicitly keeps scope away from work-root routing, harness scripts, README edits, and runner/model fallback behavior.
    - Zero-second overrides are valid for local test runs, and `TURNLOOP_DAEMON_MODE=false` must allow a single-cycle run without daemon sleeping.
  </context>
  <requirements>
    - Replace the hard-coded `DAEMON_MODE`, `PROMOTE_DELAY_SECS`, and `IDLE_POLL_SECS` assignments with environment-backed defaults.
    - Use the exact override names `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_IDLE_POLL_SECS`.
    - Preserve the current execution-loop flow and the existing default values when the overrides are unset.
    - Keep the diff minimal and avoid unrelated script behavior changes.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this missing prompt artifact at the task's existing prompt path.
    - 2. Developer: inspect the timing constants and their call sites in `agents/scripts/orchestrate_loop.sh`.
    - 3. Developer: implement the environment-backed defaults with the smallest possible shell change.
    - 4. Developer: run the required grep and syntax verification commands, including the explicit single-cycle override form.
    - 5. Refactor: perform a brief evidence-based scan and keep it no-op unless verification exposes a clear low-risk cleanup.
  </plan>
  <commands>
    - `rg -n 'TURNLOOP_DAEMON_MODE|TURNLOOP_PROMOTE_DELAY_SECS|TURNLOOP_IDLE_POLL_SECS' agents/scripts/orchestrate_loop.sh`
    - `bash -n agents/scripts/orchestrate_loop.sh`
    - `TURNLOOP_DAEMON_MODE=false TURNLOOP_PROMOTE_DELAY_SECS=0 TURNLOOP_IDLE_POLL_SECS=0 bash -n agents/scripts/orchestrate_loop.sh`
  </commands>
  <verification>
    - `agents/scripts/orchestrate_loop.sh` contains `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_IDLE_POLL_SECS`.
    - The default values remain the current production values when those variables are unset.
    - `bash -n agents/scripts/orchestrate_loop.sh` exits 0 both with defaults and with explicit single-cycle overrides.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Record the refactor pass as a no-op if verification produces no evidence-backed follow-up change.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
