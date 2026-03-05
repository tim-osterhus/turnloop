# Expectations

## Goal
Update the validator reports finished prompt artifact to reference the specs path instead of the staging path.

## Expected behavior
- `agents/work/finished/002-validator-reports.md` replaces the staging-path reference with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` in the command list.
- Any wording that mentions a “staging spec” in `agents/work/finished/002-validator-reports.md` is updated to reference the specs path instead.
- No references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` remain in `agents/work/finished/002-validator-reports.md`.

## Expected file changes
- `agents/work/finished/002-validator-reports.md` updated.
- No other files modified.

## Verification commands
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md` (expect no matches)
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md` (expect 1 match)

## Non-functional requirements
- Keep prompt semantics the same aside from path/wording updates.
- Avoid changes to report logic requirements or other prompt artifacts.

## Notes / assumptions
- The only required edits are path and wording updates within `agents/work/finished/002-validator-reports.md`.
