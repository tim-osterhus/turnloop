# Expectations

## Goal
Produce clear validation reports on failure, remove stale reports on success, and ensure the report directory exists.

## Expected behavior
- The validator creates `agents/ideas/validation_reports/` when needed.
- On validation failure, the validator writes `agents/ideas/validation_reports/<spec_basename>.validation.md`.
- The report includes the full spec path and lists each violation on its own line.
- On successful validation, any existing report file for that spec basename is deleted.

## Expected file changes
- `agents/scripts/validate_spec.sh` updated to create/remove validation report files and ensure the report directory exists.

## Verification commands
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL and SHALL NOT both appear." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-double-shall.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-shall.md; rg "Spec path" agents/ideas/validation_reports/spec-double-shall.validation.md`
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md; test ! -f agents/ideas/validation_reports/turnloop-spec-validation-2026-03-05.validation.md && echo "report removed"`

## Non-functional requirements
- Report format is plain text markdown.
- Validation reports are created/removed deterministically based on validation results.

## Notes / assumptions
- Spec basename uses the input file name without extension.
