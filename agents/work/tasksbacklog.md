## 2026-03-05 — Validator: Requirements Line Rules
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
- The staging spec validates successfully.
Verification commands:
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "This line has no bullet and SHALL be ignored." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-bad-requirements.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-bad-requirements.md; echo "exit=$?"` — Expected: non-zero exit and a report noting missing bullet/numbered requirements.
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL and SHALL NOT both appear." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-double-shall.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-shall.md; echo "exit=$?"` — Expected: non-zero exit and a report noting invalid SHALL usage.
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0.

## 2026-03-05 — Validator Reports
Goal: Produce clear validation reports on failure and remove stale reports on success.
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

## 2026-03-05 — Docs: Spec Validation Note
Goal: Document the spec validation gate and report location.
Scope:
In: Add a README note that validation runs before Manager and reports live under `agents/ideas/validation_reports/`.
Out: Script or research-loop changes.
Files to touch:
- README.md
Steps:
1. Add a brief README note under Research Loop or How It Works that validation runs before Manager and reports live in `agents/ideas/validation_reports/`.
2. Mention that validation failures block the Manager run for that cycle.
Acceptance:
- README mentions validation before Manager and the report directory.
Verification commands:
- `rg "validation" README.md` — Expected: a line describing validation before Manager and report location.

## 2026-03-05 — Hardening: Gate Research Loop on Spec Validation
Goal: Block Manager runs when staging specs fail validation and invoke the mechanic.
Scope:
In: Update `agents/scripts/research_loop.sh` to validate the oldest staging spec before running Manager, set status to `### BLOCKED` on failure, skip Manager, and call `handle_mechanic "manage"`.
Out: Changes to Manager entrypoint or execution loop.
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Add a validation step that runs `agents/scripts/validate_spec.sh` against the oldest staging spec before the Manager entrypoint.
2. On validation failure, set research status to `### BLOCKED`, log the failure, and call `handle_mechanic "manage"` without invoking Manager.
3. On validation success, proceed with the current Manager invocation flow.
Acceptance:
- The research loop script clearly shows validation happening before the `_manage.md` entrypoint.
- Validation failure path sets `### BLOCKED` and skips Manager.
Verification commands:
- `rg -n "validate_spec.sh" agents/scripts/research_loop.sh` — Expected: validation call present before Manager invocation.
- `rg -n "_manage.md" agents/scripts/research_loop.sh` — Expected: Manager invocation remains after validation block.
