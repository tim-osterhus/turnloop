# QA Expectations — 2026-03-05 Update Backburner Validator Card

## Goal
Align the backburner validator task card with the specs-path reference in acceptance/verification.

## Expected behavior
- The validator task card in `agents/work/tasksbackburner.md` references the specs-path (not staging) in acceptance/verification text.
- Wording in the validator card uses “specs spec” instead of “staging spec”.

## Expected file changes
- `agents/work/tasksbackburner.md` updated in the validator task card acceptance/verification section.

## Verification commands
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md` — Expected: 1 match.

## Non-functional requirements
- Only the validator task card in `agents/work/tasksbackburner.md` is modified; no other backburner entries or logic changes.

## Notes / assumptions
- The validator card exists and includes acceptance/verification text referencing a spec path.
