<prompt id="001-spec-validator-scaffold" task="Spec Validator Scaffold">
  <objective>
    Add a minimal validator script scaffold and a reports directory to anchor spec validation, without implementing any real validation rules yet.
  </objective>
  <context>
    - Repo root is /mnt/f/_evolve/turnloop.
    - Changes must stay within turnloop/.
    - Keep diffs minimal and reviewable.
    - Validation logic is intentionally out of scope.
  </context>
  <requirements>
    - Create agents/ideas/validation_reports/.gitkeep.
    - Add agents/scripts/validate_spec.sh with strict mode, usage messaging, file existence checks, basename-derived report path, and a violations array.
    - Script exits non-zero when violations exist; prints a short OK message and exits 0 when none.
  </requirements>
  <plan>
    - Builder: add the reports directory with .gitkeep and implement validate_spec.sh scaffold per requirements.
    - Refactor: scan for low-risk improvements; note if none.
    - Remediator: only act if agents/work/quickfix.md has OPEN items.
  </plan>
  <commands>
    - bash agents/scripts/validate_spec.sh
    - bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md
  </commands>
  <verification>
    - No-arg run prints usage and exits non-zero.
    - Running against the specs-path spec exits 0 and prints a brief OK message.
  </verification>
  <handoff>
    - Prepend historylog entry with summary, files, commands, decisions, follow-ups, prompt path.
    - Update agents/orchestrate_status.md with ### BUILDER_COMPLETE on success.
  </handoff>
</prompt>
