# Goal
Enforce Requirements section keyword rules: at least one requirement line and exactly one of `SHALL` or `SHALL NOT` per requirement line.

# Expected behavior
- Validator identifies bullet or numbered requirement lines only within the Requirements section.
- If Requirements section has no bullet/numbered lines, validation fails with a distinct report message about missing requirement lines.
- Each requirement line must contain exactly one keyword: `SHALL` or `SHALL NOT` (case-sensitive), treating `SHALL NOT` as a single keyword.
- Requirement lines containing zero keywords or multiple keyword matches fail with a distinct violation.

# Expected file changes
- `agents/scripts/validate_spec.sh`

# Verification commands
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
bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-req-lines.md; echo "exit=$?"`
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
bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-keyword.md; rg -n "keyword|SHALL" agents/ideas/validation_reports/spec-double-keyword.validation.md`
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`

# Non-functional requirements
- Only validate requirement lines inside the Requirements section.
- Do not add heading presence checks, scope label checks, or report formatting changes.

# Notes / assumptions
- Requirement keywords are uppercase `SHALL` and `SHALL NOT` only.
