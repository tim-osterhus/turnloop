## 2026-03-05 — Validator: Requirement Keyword Count
Prompt: agents/work/prompts/001-validator-requirement-keyword-count.md
Goal: Enforce exactly one requirement keyword per Requirements line.
Scope:
In: Count requirement keywords on each bullet/numbered line within Requirements; record a violation when count is zero or greater than one.
Out: Defining new requirement keyword sets beyond the agreed list.
Assumptions: Requirement keywords are `SHALL`, `SHOULD`, `MUST`, `MAY` (case-insensitive) matched as whole words; `SHALL NOT` counts as one keyword.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Define the requirement keyword list and whole-word matching rules.
2. For each Requirements bullet/numbered line, count keyword occurrences.
3. Record a violation per line where the count is not exactly one.
Acceptance:
- A line with two requirement keywords fails validation and produces a violation.
- A line with zero requirement keywords fails validation and produces a violation.
Verification commands:
- `cat > agents/.tmp/spec-double-keyword.md <<'SPEC'\n# Summary\n# Problem statement\n# Scope (In / Out)\nIn: test\nOut: test\n# Constraints\n# Requirements\n- The system SHALL and SHOULD fail.\n# Verification plan\n# Assumptions\n# Open questions\nSPEC\nbash agents/scripts/validate_spec.sh agents/.tmp/spec-double-keyword.md; echo "exit=$?"` — Expected: non-zero exit and report mentions the double-keyword line.
- `cat > agents/.tmp/spec-no-keyword.md <<'SPEC'\n# Summary\n# Problem statement\n# Scope (In / Out)\nIn: test\nOut: test\n# Constraints\n# Requirements\n- The system will fail without a keyword.\n# Verification plan\n# Assumptions\n# Open questions\nSPEC\nbash agents/scripts/validate_spec.sh agents/.tmp/spec-no-keyword.md; echo "exit=$?"` — Expected: non-zero exit and report mentions the missing-keyword line.
