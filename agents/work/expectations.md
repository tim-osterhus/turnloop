# Expectations

## Goal
Enforce exactly one requirement keyword per Requirements line in the spec validator.

## Expected behavior
- The validator counts requirement keywords on each bullet/numbered line under the Requirements section.
- A line with zero keywords is reported as a violation and causes a non-zero exit.
- A line with more than one keyword is reported as a violation and causes a non-zero exit.
- A line with exactly one keyword is not reported as a violation.
- Keywords are `SHALL`, `SHOULD`, `MUST`, `MAY` (case-insensitive) matched as whole words; `SHALL NOT` counts as a single keyword.

## Expected file changes
- `agents/scripts/validate_spec.sh` updated to include keyword list, whole-word matching, and per-line counting logic.

## Verification commands
- `cat > agents/.tmp/spec-double-keyword.md <<'SPEC'
# Summary
# Problem statement
# Scope (In / Out)
In: test
Out: test
# Constraints
# Requirements
- The system SHALL and SHOULD fail.
# Verification plan
# Assumptions
# Open questions
SPEC
bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-keyword.md; echo "exit=$?"`
- `cat > agents/.tmp/spec-no-keyword.md <<'SPEC'
# Summary
# Problem statement
# Scope (In / Out)
In: test
Out: test
# Constraints
# Requirements
- The system will fail without a keyword.
# Verification plan
# Assumptions
# Open questions
SPEC
bash agents/scripts/validate_spec.sh agents/.tmp/spec-no-keyword.md; echo "exit=$?"`

## Non-functional requirements
- Avoid counting partial matches (must be whole words only).
- Do not expand the keyword list beyond the agreed set.

## Notes / assumptions
- Applies only to bullet/numbered lines within the Requirements section.
