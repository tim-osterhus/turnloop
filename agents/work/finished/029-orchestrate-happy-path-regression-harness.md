<prompt id="029-orchestrate-happy-path-regression-harness" task="Orchestrate Happy-Path Regression Harness">
  <objective>
    Add a repo-local regression harness that seeds two isolated backlog cards and prompt artifacts, runs the real execution loop once in non-daemon mode with local runner stubs, and proves the loop promotes and completes only the oldest card while leaving the newer card queued.
  </objective>
  <context>
    - Repo context comes from `agents/outline.md`; this task is limited to `agents/scripts/orchestrate_loop.sh` and `agents/scripts/test_orchestrate_happy_path.sh`.
    - The harness must use `TURNLOOP_WORK_ROOT` so all queue, archive, prompt, and status mutations stay inside a temporary workspace under the repo root.
    - Runner behavior may be stubbed locally, but the harness must execute the real `agents/scripts/orchestrate_loop.sh` control flow and must not call external network-backed runners.
    - Keep the change minimal; do not expand into README changes, quickfix auto-demotion coverage, or unrelated loop behavior.
  </context>
  <requirements>
    - `agents/scripts/test_orchestrate_happy_path.sh` must seed two deterministically ordered backlog cards plus matching prompt artifacts inside an isolated workspace.
    - One `TURNLOOP_DAEMON_MODE=false` execution-loop run must complete exactly one happy-path cycle: oldest card promoted, archived, prompt moved to `agents/work/finished/`, active task cleared, and newer backlog card left queued.
    - The harness must fail if the newer card is promoted or if both cards are consumed in the same non-daemon run.
    - The real repo-root queue files must remain unchanged after the harness exits.
    - Use only the minimum runner wiring needed to let the real loop path reach `### BUILDER_COMPLETE`, `### QA_COMPLETE`, and `### UPDATE_COMPLETE` locally.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and ensure `agents/work/task.md` points to it.
    - 2. Developer: inspect `agents/scripts/orchestrate_loop.sh` to confirm the current non-daemon behavior and identify the smallest single-cycle exit change needed for the harness.
    - 3. Developer: implement the minimal `orchestrate_loop.sh` change, then add `agents/scripts/test_orchestrate_happy_path.sh` with isolated workspace setup, local runner stubs, and happy-path assertions.
    - 4. Developer: run the required shell verification commands and confirm the harness output reports archive, prompt-move, and remaining-backlog success.
    - 5. Refactor: perform a brief evidence-based scan and keep it no-op unless verification exposes a clear low-risk cleanup.
  </plan>
  <commands>
    - `bash -n agents/scripts/orchestrate_loop.sh`
    - `bash -n agents/scripts/test_orchestrate_happy_path.sh`
    - `bash agents/scripts/test_orchestrate_happy_path.sh`
  </commands>
  <verification>
    - `bash agents/scripts/test_orchestrate_happy_path.sh` exits 0 using only repo-local temp state and local runner stubs.
    - The harness output confirms oldest-only promotion plus archive append, prompt move, and preserved newer backlog checks.
    - The harness fails if both backlog cards are consumed in one non-daemon run or if the newer card is promoted first.
    - `bash -n agents/scripts/orchestrate_loop.sh` and `bash -n agents/scripts/test_orchestrate_happy_path.sh` both exit 0.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - If refactor finds no evidence-backed improvement, record that no-op outcome in the history log summary or decisions.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
