## Goal
Confirm that `README.md` documents the one-spec-at-a-time staging queue contract, including oldest-only validation and management plus the retention of newer staged specs after a successful manage cycle.

## Expected behavior
- The research-loop overview says staging specs are processed one at a time.
- The README identifies the oldest staging spec as the one validated and managed in a cycle.
- The README states that newer staging specs remain in `agents/ideas/staging/` after a successful manage cycle.
- Documentation outside this queue-contract clarification remains materially unchanged unless a small wording adjustment is required for consistency.

## Expected file changes
- `README.md` contains the documentation update for the oldest-only, one-spec-at-a-time staging behavior.
- `agents/work/expectations.md` is overwritten during this QA run.

## Verification commands
- `rg -n 'oldest staging spec|one-spec-at-a-time|leave newer staging specs' README.md`
- `git diff -- README.md`

## Non-functional requirements
- The README wording is clear, public-facing, and internally consistent with the described queue contract.
- The change stays scoped to README queue-contract wording and does not introduce unrelated operational guidance.
- The QA run stays within `turnloop/` and records results with evidence.

## Notes / assumptions
- The task scope excludes outline or execution-loop documentation edits unless the README needs a minimal consistency change.
- `agents/work/quickfix.md` is closed, so this pass validates the primary task rather than an open quickfix.
