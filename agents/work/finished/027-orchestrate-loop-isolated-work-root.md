<prompt id="027-orchestrate-loop-isolated-work-root" task="Orchestrate Loop Isolated Work Root">
  <objective>
    Update `agents/scripts/orchestrate_loop.sh` so its mutable execution-loop workspace files can be redirected into an isolated repo-local root via `TURNLOOP_WORK_ROOT`, while preserving the current repo-root behavior when the override is unset and keeping the live entrypoint flow anchored to the real checkout.
  </objective>
  <context>
    - Scope is limited to `agents/scripts/orchestrate_loop.sh` plus the required Builder artifacts for this task.
    - The active task already links this prompt from `agents/work/task.md`; the missing work is to create the prompt artifact itself.
    - `agents/scripts/research_loop.sh` already uses a `TURNLOOP_WORK_ROOT` pattern, but this task also requires orchestrate entrypoints and runner invocation to stay anchored to the real repo checkout.
    - `agents/work/quickfix.md` is resolved, so remediator work is only needed if OPEN items appear during this task.
  </context>
  <requirements>
    - Add a discoverable `TURNLOOP_WORK_ROOT` override to `agents/scripts/orchestrate_loop.sh`.
    - Route task, backlog, backburner, archive, status, prompt, finished, log, and temp paths through the derived work root.
    - Preserve the existing repo-root path behavior when `TURNLOOP_WORK_ROOT` is unset.
    - Keep entrypoint references and normal runner execution anchored to the real repo checkout.
    - Keep the diff minimal and do not change queue semantics, status markers, or default model policy.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and keep the existing `agents/work/task.md` prompt link intact.
    - 2. Developer: inspect `agents/scripts/orchestrate_loop.sh` and identify the current hard-coded workspace paths and repo-anchored entrypoint usage.
    - 3. Developer: add a derived work-root path layer for mutable execution-loop files while preserving repo-root execution for entrypoints.
    - 4. Developer: run the required grep and syntax checks and confirm the override is visible in the script.
    - 5. Refactor: perform a brief evidence-backed scan and keep it no-op unless verification exposes a small explicit cleanup.
    - 6. Remediator: skip unless `agents/work/quickfix.md` gains OPEN items.
  </plan>
  <commands>
    - `rg -n 'TURNLOOP_WORK_ROOT|WORK_ROOT|TASK=|BACKLOG=|STATUS=|PROMPTS_DIR=|FINISHED_DIR=' agents/scripts/orchestrate_loop.sh`
    - `bash -n agents/scripts/orchestrate_loop.sh`
  </commands>
  <verification>
    - `agents/scripts/orchestrate_loop.sh` contains a `TURNLOOP_WORK_ROOT` override and derives mutable workspace paths from `WORK_ROOT`.
    - With the override unset, the script still defaults to the current repo-root workspace paths.
    - Entrypoint paths remain anchored to the real repo checkout rather than the isolated work root.
    - `bash -n agents/scripts/orchestrate_loop.sh` exits 0.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Record the refactor pass as a no-op if no explicit evidence-backed cleanup is needed.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
