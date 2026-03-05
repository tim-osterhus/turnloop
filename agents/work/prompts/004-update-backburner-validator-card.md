<prompt id="004-update-backburner-validator-card" task="Update Backburner Validator Card">
  <objective>
    Align the backburner validator task card acceptance/verification to reference the specs-path validation spec.
  </objective>
  <context>
    - Repo: Turnloop (see agents/outline.md)
    - Scope: update only the validator card in agents/work/tasksbackburner.md
    - Constraint: do not change other backburner entries or any validator logic
    - Required spec path: agents/ideas/specs/turnloop-spec-validation-2026-03-05.md
    - Wording change: replace “staging spec” with “specs spec”
  </context>
  <requirements>
    - Replace staging spec references in acceptance/verification with the specs-path reference.
    - Ensure agents/work/tasksbackburner.md contains no references to agents/ideas/staging/turnloop-spec-validation-2026-03-05.md.
    - Keep changes minimal and limited to the targeted validator task card.
  </requirements>
  <plan>
    - 1) (developer) Edit the validator task card in agents/work/tasksbackburner.md to update the spec path and wording.
    - 2) (refactor) Perform a brief, low-risk scan for improvements; make no changes if unnecessary.
    - 3) (remediator) If agents/work/quickfix.md has OPEN items, address only those.
  </plan>
  <commands>
    - rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md
    - rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md
  </commands>
  <verification>
    - agents/work/tasksbackburner.md has zero matches for the staging spec path.
    - agents/work/tasksbackburner.md has one match for the specs path in the validator card.
    - The validator card wording uses “specs spec”.
  </verification>
  <handoff>
    - Update agents/historylog.md with the Builder entry template.
    - Overwrite agents/orchestrate_status.md with ### BUILDER_COMPLETE when done.
  </handoff>
</prompt>
