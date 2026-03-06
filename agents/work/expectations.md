# Expectations - 2026-03-06 Manager Oldest-Only Staging Contract

## Goal
Validate that `agents/entrypoints/_manage.md` now instructs the Manager to process exactly one staging spec per run, specifically the oldest eligible staging file, while preserving existing status-file and history-log rules.

## Expected behavior
- The Manager instructions state that each run processes exactly one file.
- The selected file is defined as the oldest eligible file in `agents/ideas/staging/`.
- If a caller provides a path, the instructions still constrain the run to the oldest file being processed for that run.
- The workflow and success criteria state that only the processed oldest staging spec moves to `agents/ideas/specs/`.
- The instructions explicitly say newer staging files remain queued or unprocessed after a successful run.
- Existing overwrite-only status-file rules and history-log requirements remain present.

## Expected file changes
- `agents/entrypoints/_manage.md` contains the oldest-only staging selection language in the critical rules, inputs, workflow, and success criteria sections.
- No implementation changes are expected outside `agents/entrypoints/_manage.md`.

## Verification commands
- `rg -n 'process exactly one file per run|oldest file in \`agents/ideas/staging/\`|leave newer unprocessed staging specs|move only the processed oldest staging spec' agents/entrypoints/_manage.md`
  - Expected: all four phrases match.
- `sed -n '1,260p' agents/entrypoints/_manage.md`
  - Expected: the surrounding instructions consistently enforce oldest-only processing and retain the existing overwrite-only status-file and history-log requirements.
- `git diff -- agents/entrypoints/_manage.md`
  - Expected: changes are limited to the Manager entrypoint and align with the task scope.

## Non-functional requirements
- The instructions are internally consistent with no batch-processing ambiguity.
- The task scope stays limited to Manager instructions and does not introduce loop-script, validator, or execution-loop changes.
- The file remains readable and specific enough for an agent to execute without interpretation gaps.

## Notes / assumptions
- "Oldest" is interpreted by the instruction text as the single eligible staging spec selected for that run.
- QA will confirm both exact phrase presence and surrounding semantic consistency, not just isolated string matches.
