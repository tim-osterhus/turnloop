# Tasks Backburner

## 2026-03-05 — 2026-03-05 — Validator: Requirements Line Rules (Auto-demoted)

## 2026-03-05 — Validator: Requirements Line Rules
Prompt: agents/work/prompts/002-validator-requirements-line-rules.md
Goal: Enforce Requirements section bullet/numbered line rules with SHALL/SHALL NOT semantics.
Scope:
In: Require at least one bullet or numbered line in `Requirements`, and ensure each such line contains exactly one of `SHALL` or `SHALL NOT`.
Out: Research-loop gating or documentation updates.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Extract the `Requirements` section content up to the next heading.
2. Identify bullet (`-` or `*`) and numbered (`1.`) lines and count them.
3. For each requirement line, verify it contains exactly one occurrence of `SHALL` or `SHALL NOT`; add violations for none or multiple matches.
4. Add a violation when no bullet/numbered requirement lines are found.
Acceptance:
- A spec with a `Requirements` section but no bullet/numbered items fails validation.
- A spec with a requirement line containing both `SHALL` and `SHALL NOT` fails validation.
- The specs spec validates successfully.
Verification commands:
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "This line has no bullet and SHALL be ignored." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-bad-requirements.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-bad-requirements.md; echo "exit=$?"` — Expected: non-zero exit and a report noting missing bullet/numbered requirements.
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL and SHALL NOT both appear." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-double-shall.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-shall.md; echo "exit=$?"` — Expected: non-zero exit and a report noting invalid SHALL usage.
- `bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0.

