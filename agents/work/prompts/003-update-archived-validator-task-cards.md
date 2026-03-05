<prompt id="003-update-archived-validator-task-cards" task="Update Archived Validator Task Cards">
  <objective>
    Update archived validator task cards to reference the specs-path validation spec instead of the staging-path copy, and remove any staging copy-back instructions while keeping changes minimal and localized.
  </objective>
  <context>
    - Scope is limited to validator-related cards inside agents/work/tasksarchive.md.
    - Do not edit spec files, historylog, or validator scripts.
    - Repo context is summarized in agents/outline.md.
  </context>
  <requirements>
    - Replace references to agents/ideas/staging/turnloop-spec-validation-2026-03-05.md with agents/ideas/specs/turnloop-spec-validation-2026-03-05.md in validator cards.
    - Remove any wording or instructions that recreate the staging spec (e.g., copy-back steps).
    - Keep changes minimal and confined to agents/work/tasksarchive.md.
  </requirements>
  <plan>
    1. Builder: Locate staging-path references in agents/work/tasksarchive.md and identify the validator cards containing them.
    2. Builder: Update those cards to use the specs-path reference and remove staging copy-back instructions.
    3. Builder: Run the specified rg verification commands and confirm expectations.
  </plan>
  <commands>
    - rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md
    - rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md
    - rg -n "cp .*turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md
  </commands>
  <verification>
    - No staging-path references remain in agents/work/tasksarchive.md.
    - Validator cards reference the specs-path in their verification commands.
    - No copy instructions recreate the staging spec in archived validator cards.
  </verification>
  <handoff>
    - Log changes in agents/historylog.md with prompt path agents/work/prompts/003-update-archived-validator-task-cards.md.
    - Overwrite agents/orchestrate_status.md with ### BUILDER_COMPLETE when done.
  </handoff>
</prompt>
