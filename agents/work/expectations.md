# Expectations

## Goal
Update validator prompt artifacts for scaffold and required headings tasks to reference the specs-path instead of the staging-path.

## Expected behavior
- The two finished prompt artifacts no longer reference `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- Any command lists inside those artifacts reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
- Any wording that says “staging spec” is updated to reference the specs path instead.

## Expected file changes
- `agents/work/finished/001-spec-validator-scaffold.md`
- `agents/work/finished/001-validator-required-headings-scope-labels.md`

## Verification commands
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md` (expect no matches)
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md` (expect matches in command lists)

## Non-functional requirements
- Changes are limited to the spec-path references; no unrelated prompt edits.

## Notes / assumptions
- “Command lists” refer to any command examples or bullets that mention running a spec validation script.
