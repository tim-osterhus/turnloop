# Expectations

## Goal
Document in README that a validation gate runs before the Manager step and where validation reports are stored.

## Expected behavior
- README explicitly states that validation runs before Manager for the research loop (or How It Works section).
- README states validation reports live under `agents/ideas/validation_reports/`.
- README notes that validation failures block the Manager run for that cycle.

## Expected file changes
- README.md updated with a brief validation note under the Research Loop or How It Works section.

## Verification commands
- `rg "validation" README.md` (expect lines describing validation before Manager and report location).

## Non-functional requirements
- No script or research-loop logic changes.

## Notes / assumptions
- The README has an appropriate section (Research Loop or How It Works) for a short validation note.
