# Quickfix

- Status: CLOSED (2026-03-05) — staging spec present in `agents/ideas/staging/`.
- Issue: `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` is missing.
- Impact: `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` exits 3, so the staging validation acceptance fails.
- Required fix: Restore/copy `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` into `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- Verification: `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` (exit 0 on 2026-03-05).
