<prompt id="016-manager-oldest-only-staging-contract" task="Manager Oldest-Only Staging Contract">
  <objective>
    Update `agents/entrypoints/_manage.md` so each Manager run selects and processes exactly one staging spec: the oldest eligible file in `agents/ideas/staging/`, while preserving the existing overwrite-only status-file and history-log requirements.
  </objective>
  <context>
    - The active task scope is limited to `agents/entrypoints/_manage.md`.
    - `agents/work/quickfix.md` is closed, so remediator work is only needed if OPEN items appear.
    - The current `_manage.md` still describes batch processing of all staging specs in one run.
    - The task acceptance requires exact phrases to be present for the new single-file oldest-only contract.
  </context>
  <requirements>
    - State that Manager must process exactly one file per run.
    - Describe the selected file as the oldest file in `agents/ideas/staging/`.
    - State that newer unprocessed staging specs remain queued after a successful run.
    - State that completion moves only the processed oldest staging spec to `agents/ideas/specs/`.
    - Preserve the existing overwrite-only status-file rules and history-log requirements.
    - Do not change loop scripts, validator rules, or other execution-loop behavior.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: rewrite the critical rules, inputs, workflow, history context, and completion language in `agents/entrypoints/_manage.md` to enforce oldest-only single-spec processing.
    - 3. Developer: run the required verification command and confirm all expected phrases match.
    - 4. Refactor: perform a no-op improvement scan and only change code if explicit evidence justifies it.
    - 5. Builder: prepend `agents/historylog.md` and overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `rg -n 'process exactly one file per run|oldest file in \`agents/ideas/staging/\`|leave newer unprocessed staging specs|move only the processed oldest staging spec' agents/entrypoints/_manage.md`
  </commands>
  <verification>
    - The command output contains matches for all four required phrases.
    - `agents/entrypoints/_manage.md` no longer instructs Manager to process all staging files in one run.
    - The completion text makes it clear that only the processed oldest spec moves to `agents/ideas/specs/`.
  </verification>
  <handoff>
    - Record the prompt path, files touched, commands run, refactor result, and quickfix/remediator status in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
