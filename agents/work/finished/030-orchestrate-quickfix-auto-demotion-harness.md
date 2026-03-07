<prompt id="030-orchestrate-quickfix-auto-demotion-harness" task="Orchestrate Quickfix Auto-Demotion Harness">
  <objective>
    Add a repo-local shell harness that exercises the real orchestration loop against an isolated workspace and local runner stubs, forcing two `### QUICKFIX_NEEDED` cycles so the task is auto-demoted to `agents/work/tasksbackburner.md`, the isolated active task is cleared, and the isolated orchestrate status returns to `### IDLE`.
  </objective>
  <context>
    - The active task already points to this prompt path and the file is currently missing.
    - `agents/scripts/orchestrate_loop.sh` already contains the quickfix retry and auto-demotion control flow that the harness must drive through real script execution.
    - The harness must stay repo-local, avoid network/external runners, and leave the repo-root workspace files unchanged.
  </context>
  <requirements>
    - Create `agents/scripts/test_orchestrate_quickfix_demotion.sh`.
    - Seed isolated backlog, active-task, status, and prompt state under a repo-local temp workspace.
    - Use a local runner stub so one non-daemon `agents/scripts/orchestrate_loop.sh` run reaches `### QUICKFIX_NEEDED` twice and then auto-demotes the active task.
    - Assert the isolated backburner receives the task, the isolated task file is cleared, the isolated status returns to `### IDLE`, and repo-root workspace files remain unchanged.
    - Keep changes minimal and within `turnloop/`.
  </requirements>
  <plan>
    1. Create this missing prompt artifact and keep the existing task link intact.
    2. Inspect the existing isolated orchestration harness pattern and implement the quickfix-focused variant with local runner stubs.
    3. Apply only minimal orchestration-loop edits if the new harness exposes a real contract gap.
    4. Run the required syntax and harness verification commands.
    5. Record the builder outcome in `agents/historylog.md` and set `agents/orchestrate_status.md` to `### BUILDER_COMPLETE`.
  </plan>
  <commands>
    - `bash -n agents/scripts/test_orchestrate_quickfix_demotion.sh`
    - `bash agents/scripts/test_orchestrate_quickfix_demotion.sh`
  </commands>
  <verification>
    - The harness exits 0 after proving two isolated quickfix failures trigger auto-demotion.
    - The isolated task is appended to `agents/work/tasksbackburner.md`.
    - The isolated `agents/work/task.md` is cleared and the isolated `agents/orchestrate_status.md` ends at `### IDLE`.
    - Repo-root workspace files remain unchanged after the harness completes.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with the summary, files touched, commands run, and the note that refactor was a no-op unless explicit evidence justifies a small cleanup.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE`.
  </handoff>
</prompt>
