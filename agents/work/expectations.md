# Expectations

## Goal
Enforce required section headings (case-insensitive) and required `Scope (In / Out)` labels (`In:` and `Out:`) in spec validation.

## Expected behavior
- Validator parses Markdown headings and fails if any required section title is missing, regardless of heading case.
- Validator checks the `Scope (In / Out)` section for lines containing `In:` and `Out:` labels; missing either causes failure.
- A distinct violation message is recorded for each missing heading or missing label.
- A spec missing `Open questions` fails validation and the report mentions the missing heading.
- The staging spec `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` validates successfully.

## Expected file changes
- `agents/scripts/validate_spec.sh` updated to implement the new checks and messaging.

## Verification commands
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL be present." "# Verification plan" "# Assumptions" > agents/.tmp/spec-missing-heading.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-heading.md; echo "exit=$?"`
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`

## Non-functional requirements
- Maintain existing validation report format and output location.
- Avoid false positives from heading case differences.

## Notes / assumptions
- Required headings list is defined in `agents/scripts/validate_spec.sh` or related config and should include `Open questions`.
