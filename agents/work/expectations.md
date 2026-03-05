# QA Expectations

## Goal
Update the finished prompt artifacts for requirements-rule tasks to reference the specs path instead of the staging path.

## Expected behavior
- `agents/work/finished/001-requirements-lines-present.md` contains no references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- `agents/work/finished/002-validator-requirements-line-rules.md` contains no references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- Command lists in both files reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
- Any wording about a “staging spec” is updated to refer to the specs path.

## Expected file changes
- `agents/work/finished/001-requirements-lines-present.md`
- `agents/work/finished/002-validator-requirements-line-rules.md`

## Verification commands
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md`
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md`

## Non-functional requirements
- Only the two specified finished prompt artifacts are updated.
- No other prompt artifacts or unrelated files change.

## Notes / assumptions
- Expectations assume the specs file exists at `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
