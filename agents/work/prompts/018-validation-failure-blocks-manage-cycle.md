<prompt id="018-validation-failure-blocks-manage-cycle" task="Validation Failure Blocks Manage Cycle">
  <objective>
    Update `agents/scripts/research_loop.sh` so a validation failure for the selected staging spec explicitly writes `### BLOCKED`, enters manage-stage mechanic handling, and keeps the Manager entrypoint reachable only from the validation success path.
  </objective>
  <context>
    - The active task scope is limited to `agents/scripts/research_loop.sh` plus the required prompt link in `agents/work/task.md`.
    - The manage cycle already selects a single `staging_spec` from `agents/ideas/staging/` and validates it before running Manager.
    - The task explicitly excludes mechanic escalation count changes, nonviable moves, and validation-report content changes.
    - `agents/work/quickfix.md` is closed, so remediator work is only needed if OPEN items appear.
  </context>
  <requirements>
    - Keep validation bound to the selected `"$staging_spec"` for the current manage cycle.
    - Write `### BLOCKED` before `handle_mechanic "manage"` on validation failure.
    - Keep `run_entrypoint "$ENTRY_MANAGE"` on the success-only path for that cycle.
    - Preserve existing next-poll retry behavior and avoid changes outside the loop script.
    - Keep the diff minimal and reviewable.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: make the validation failure branch in `agents/scripts/research_loop.sh` explicit while keeping Manager behind a success-only gate.
    - 3. Developer: run the required verification commands and confirm they pass.
    - 4. Refactor: perform a no-op improvement scan and only change code if explicit evidence justifies it.
    - 5. Builder: prepend `agents/historylog.md` and overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `rg -n 'Staging validation failed for \$staging_spec|write_status "### BLOCKED"|handle_mechanic "manage"|run_entrypoint "\$ENTRY_MANAGE"' agents/scripts/research_loop.sh`
    - `bash -n agents/scripts/research_loop.sh`
  </commands>
  <verification>
    - Validation failure writes `### BLOCKED` before manage-stage mechanic handling starts.
    - Validation failure does not invoke Manager for any staging spec in that cycle.
    - The success path still runs Manager normally.
    - `bash -n agents/scripts/research_loop.sh` exits 0.
  </verification>
  <handoff>
    - Record the prompt path, files touched, commands run, refactor result, and quickfix/remediator status in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
