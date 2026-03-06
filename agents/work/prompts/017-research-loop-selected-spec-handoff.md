<prompt id="017-research-loop-selected-spec-handoff" task="Research Loop Selected-Spec Handoff">
  <objective>
    Update `agents/scripts/research_loop.sh` so each manage cycle selects the oldest staging spec exactly once, validates that exact path, and passes the same selected path into the Manager run deterministically.
  </objective>
  <context>
    - The active task scope is limited to `agents/scripts/research_loop.sh` plus the required prompt link in `agents/work/task.md`.
    - `agents/entrypoints/_manage.md` already states that a caller-provided selected path may be used if it still resolves to the oldest eligible staging spec.
    - `agents/work/quickfix.md` is closed, so remediator work is only needed if OPEN items appear.
    - The current manage block already assigns `staging_spec` once for validation, but the Manager invocation does not yet receive that exact path.
  </context>
  <requirements>
    - Keep a single `staging_spec="$(oldest_file "$STAGING_DIR")"` lookup per manage cycle.
    - Reuse `"$staging_spec"` for the validation command.
    - Inject the same selected path into the Manager invocation through repo-local process state.
    - Keep changes minimal and do not alter mechanic retry behavior, validator rules, or multi-spec processing.
    - Preserve the existing success and blocked flow in the manage cycle.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: update `agents/scripts/research_loop.sh` so the manage run reuses the single selected `staging_spec` for validation and Manager dispatch.
    - 3. Developer: make the Manager invocation receive the selected path explicitly while preserving current runner behavior.
    - 4. Developer: run the required verification commands and confirm they pass.
    - 5. Refactor: perform a no-op improvement scan and only change code if explicit evidence justifies it.
    - 6. Builder: prepend `agents/historylog.md` and overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `rg -n 'staging_spec=\"\\$\\(oldest_file \"\\$STAGING_DIR\"\\)\"|validate_spec.sh \"\\$staging_spec\"|TURNLOOP_STAGING_SPEC=\"\\$staging_spec\"|run_entrypoint \"\\$ENTRY_MANAGE\"' agents/scripts/research_loop.sh`
    - `bash -n agents/scripts/research_loop.sh`
  </commands>
  <verification>
    - The script performs exactly one oldest-file lookup per manage cycle and stores it in `staging_spec`.
    - The validation command uses `"$staging_spec"` directly.
    - The Manager invocation receives the same selected path during that cycle.
    - `bash -n agents/scripts/research_loop.sh` exits 0.
  </verification>
  <handoff>
    - Record the prompt path, files touched, commands run, refactor result, and quickfix/remediator status in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
