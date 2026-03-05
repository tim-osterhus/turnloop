## 2026-03-05 — Validator: Requirements Keywords
Goal: Enforce Requirements section rules for at least one requirement line and exactly one keyword per line.
Prompt: agents/work/prompts/002-validator-requirements-line-rules.md
Scope:
In: Identify bullet/numbered requirement lines within the Requirements section and validate each line contains exactly one of `SHALL` or `SHALL NOT`.
Out: Heading presence checks, scope label checks, or report formatting changes.
Assumptions: Requirement keywords are uppercase `SHALL` and `SHALL NOT` (case-sensitive).
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Parse the Requirements section boundaries and collect bullet/numbered requirement lines inside it.
2. If no requirement lines are present, add a distinct violation message for the missing requirement lines.
3. For each requirement line, assert it contains exactly one requirement keyword (`SHALL` or `SHALL NOT`), treating `SHALL NOT` as a single keyword and flagging zero or multiple matches as violations.
Acceptance:
- A spec whose Requirements section contains no bullet/numbered lines fails validation with a report mentioning the missing requirement lines.
- A Requirements line that contains both `SHALL` and `SHALL NOT` (or multiple keyword matches) fails validation with a distinct violation.
- A Requirements line with exactly one keyword passes this rule when other validations are satisfied.
Verification commands:
- `cat > agents/.tmp/spec-missing-req-lines.md <<'EOF'
# Summary
ok
# Problem statement
ok
# Scope (In / Out)
In: ok
Out: ok
# Constraints
ok
# Requirements
No bullets here.
# Verification plan
ok
# Assumptions
ok
# Open questions
ok
EOF
bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-req-lines.md; echo "exit=$?"` — Expected: non-zero exit and a report that mentions missing requirement lines.
- `cat > agents/.tmp/spec-double-keyword.md <<'EOF'
# Summary
ok
# Problem statement
ok
# Scope (In / Out)
In: ok
Out: ok
# Constraints
ok
# Requirements
- This SHALL and SHALL NOT both appear.
# Verification plan
ok
# Assumptions
ok
# Open questions
ok
EOF
bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-keyword.md; rg -n "keyword|SHALL" agents/ideas/validation_reports/spec-double-keyword.validation.md` — Expected: non-zero exit and a report noting the invalid keyword count.
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0 with an OK message.
