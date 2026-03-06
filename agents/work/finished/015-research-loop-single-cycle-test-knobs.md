<prompt id="015-research-loop-single-cycle-test-knobs" task="Research loop single-cycle test knobs">
  <objective>
    Make `agents/scripts/research_loop.sh` configurable for fast local single-cycle runs by reading daemon mode and delay values from environment variables while preserving the script's current default behavior when those variables are unset.
  </objective>
  <context>
    - Repo context is Turnloop's automation shell scripts under `agents/scripts/`.
    - Scope is limited to `agents/scripts/research_loop.sh`.
    - The script currently hard-codes `DAEMON_MODE=true`, `POLL_SECS=120`, and `PROMOTE_DELAY_SECS=180`.
    - The active task requires a no-wait, non-daemon local harness mode without changing default production cadence or queue behavior.
  </context>
  <requirements>
    - Read `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_POLL_SECS` from the environment, using the current hard-coded values as defaults.
    - Keep the existing loop and sleep behavior unchanged when the new variables are unset.
    - Keep the diff minimal and confined to `agents/scripts/research_loop.sh`, plus required builder artifacts.
    - Do not change runner selection, queue semantics, or default timings.
  </requirements>
  <plan>
    1. Prompt-architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect `agents/scripts/research_loop.sh` and identify the current hard-coded daemon and delay assignments.
    3. Developer: replace those assignments with environment-backed defaults using the required variable names and preserve existing control flow.
    4. Developer: run the task verification commands and one explicit single-cycle invocation proving the override form parses in zero-delay, non-daemon mode.
    5. Refactor: perform a brief evidence-backed scan and keep it as a no-op unless verification surfaces a small explicit issue.
    6. Remediator: skip because `agents/work/quickfix.md` has no OPEN items.
  </plan>
  <commands>
    - `rg -n 'TURNLOOP_DAEMON_MODE|TURNLOOP_PROMOTE_DELAY_SECS|TURNLOOP_POLL_SECS' agents/scripts/research_loop.sh`
    - `bash -n agents/scripts/research_loop.sh`
    - `TURNLOOP_DAEMON_MODE=false TURNLOOP_PROMOTE_DELAY_SECS=0 TURNLOOP_POLL_SECS=0 bash -n agents/scripts/research_loop.sh`
  </commands>
  <verification>
    - All three override names appear in `agents/scripts/research_loop.sh`.
    - `bash -n agents/scripts/research_loop.sh` exits successfully.
    - The script parses successfully when invoked with `TURNLOOP_DAEMON_MODE=false`, `TURNLOOP_PROMOTE_DELAY_SECS=0`, and `TURNLOOP_POLL_SECS=0`.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if execution cannot be completed.
  </handoff>
</prompt>
