## 2026-03-05 — Validator Reports
Goal: Produce clear validation reports on failure and remove stale reports on success.
Prompt: agents/work/prompts/002-validator-reports.md
Scope:
In: Write validation reports that include the spec path and violation list; remove any report on success; ensure the report directory exists.
Out: README updates or research-loop gating.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Ensure the validator creates `agents/ideas/validation_reports/` when needed.
2. On validation failure, write `agents/ideas/validation_reports/<spec_basename>.validation.md` with the spec path and each violation on its own line.
3. On successful validation, delete any existing report file for that spec.
Acceptance:
- A failing spec produces a report that includes the spec path and at least one violation line.
- A passing spec leaves no validation report for that spec basename.
Verification commands:
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL and SHALL NOT both appear." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-double-shall.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-shall.md; rg "Spec path" agents/ideas/validation_reports/spec-double-shall.validation.md` — Expected: report exists and includes the spec path line.
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md; test ! -f agents/ideas/validation_reports/turnloop-spec-validation-2026-03-05.validation.md && echo "report removed"` — Expected: prints `report removed`.
