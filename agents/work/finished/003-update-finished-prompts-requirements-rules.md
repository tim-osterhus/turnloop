<prompt id="003-update-finished-prompts-requirements-rules" task="Update finished requirements-rule prompts">
  <objective>
    Update the two finished prompt artifacts for requirements-rule validation so their command lists and wording reference the specs-path file instead of the staging-path file.
  </objective>
  <context>
    - Repo context lives in `agents/outline.md` and `README.md`.
    - Task scope is limited to the two finished prompt artifacts listed in `agents/work/task.md`.
    - Use minimal edits and keep changes reviewable.
  </context>
  <requirements>
    - Replace any `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` in the specified files.
    - Update any “staging spec” wording to reference the specs path instead.
    - Do not modify other prompt artifacts.
  </requirements>
  <plan>
    1. (Developer) Open the two finished prompt artifacts and locate staging-path references.
    2. (Developer) Replace staging-path references and wording with the specs-path file.
    3. (Developer) Run the verification commands to confirm replacements.
    4. (Refactor) Scan for evidence-backed improvements; if none, record a no-op.
    5. (Remediator) If `agents/work/quickfix.md` has OPEN items, address them.
  </plan>
  <commands>
    - rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md
    - rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md
  </commands>
  <verification>
    - No matches for the staging-path reference in the two finished prompt artifacts.
    - Command lists reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
  </verification>
  <handoff>
    - Record summary, files touched, command outputs, and the prompt path in `agents/historylog.md`.
  </handoff>
</prompt>
