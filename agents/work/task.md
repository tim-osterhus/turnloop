## 2026-03-05 — Validator: Required Headings + Scope Labels
Goal: Enforce required section headings and Scope In/Out labels in spec files.
Prompt: agents/work/prompts/001-validator-required-headings-scope-labels.md
Scope:
In: Add case-insensitive checks for required headings and verify `Scope (In / Out)` contains both `In:` and `Out:` labels.
Out: Requirements section content rules and report formatting polish.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Parse the spec for Markdown headings and ensure all required section titles are present (case-insensitive match).
2. Within the `Scope (In / Out)` section, assert that lines with `In:` and `Out:` exist.
3. Record a distinct violation message for each missing heading or missing label.
Acceptance:
- A spec missing `Open questions` fails validation with a report that lists the missing heading.
- The current staging spec validates successfully.
Verification commands:
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL be present." "# Verification plan" "# Assumptions" > agents/.tmp/spec-missing-heading.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-heading.md; echo "exit=$?"` — Expected: non-zero exit and a report in `agents/ideas/validation_reports/spec-missing-heading.validation.md` mentioning `Open questions`.
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0.
