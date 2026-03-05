<prompt id="001-docs-spec-validation-note" task="Docs: Spec Validation Note">
  <objective>
    Add a brief README note explaining that spec validation runs before the Manager phase, that validation failures block the Manager run for that cycle, and that reports live under agents/ideas/validation_reports/.
  </objective>
  <context>
    - Repo is Turnloop; scope is limited to README documentation updates only.
    - Keep changes minimal and within turnloop/.
    - Task requires a README mention of validation before Manager and report directory.
  </context>
  <requirements>
    - Add a note under Research Loop or How It Works stating validation runs before Manager.
    - Mention reports live in agents/ideas/validation_reports/.
    - State that validation failures block the Manager run for that cycle.
  </requirements>
  <plan>
    1. (developer) Update README.md with the validation note in the appropriate section.
    2. (refactor) Briefly scan README.md for clarity and consistency; no changes if unnecessary.
    3. (remediator) Only act if agents/work/quickfix.md contains OPEN items.
  </plan>
  <commands>
    - rg "validation" README.md
  </commands>
  <verification>
    - README.md includes a line describing validation before Manager and the report directory.
  </verification>
  <handoff>
    - Prepend agents/historylog.md entry with summary, files touched, commands, decisions, follow-ups, prompt path.
    - Overwrite agents/orchestrate_status.md with ### BUILDER_COMPLETE when done.
  </handoff>
</prompt>
