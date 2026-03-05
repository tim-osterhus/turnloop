# Summary
Stop `_manage.md` from re-triggering due to validator tasks repopulating `agents/ideas/staging/` by switching validator references to the archived spec path in `agents/ideas/specs/`.

# Problem statement
Validator tasks currently reference the spec file in `agents/ideas/staging/` and copy it back from `agents/ideas/specs/` when missing, which recreates staging files and causes `_manage.md` to run repeatedly. The loop should end by removing validator reliance on the staging path.

# Scope (In / Out)
In: Update validator-related task cards and prompt artifacts to reference the spec file in `agents/ideas/specs/` instead of `agents/ideas/staging/`.
Out: Changes to `_manage.md` logic, research loop gating, or spec validation behavior.

# Constraints
- Keep changes limited to task cards or prompt artifacts that reference the validator spec path.
- Use the existing spec file name `turnloop-spec-validation-2026-03-05.md` unless a newer validator spec is created.
- Do not add new automation or scripts as part of this fix.

# Requirements
- Validator-related task cards SHALL reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` instead of the staging path.
- Validator-related prompt artifacts SHALL reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` instead of the staging path.
- Validator task instructions SHALL NOT include copy steps that recreate `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` from `agents/ideas/specs/`.

# Verification plan
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work agents/ideas` — Expected: validator task cards or prompt artifacts reference the specs path.

# Assumptions
- Option A (point validator tasks at `agents/ideas/specs/`) is the chosen fix.
- All validator tasks that reference the spec are stored in `agents/work/` or `agents/ideas/`.

# Open questions
- Are there any validator tasks or prompt artifacts outside `agents/work/` and `agents/ideas/` that also reference the staging spec path?
