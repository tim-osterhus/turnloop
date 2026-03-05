# QA Expectations — Spec Validator Scaffold

Goal
- Add a validator script scaffold and reports directory to anchor spec validation.

Expected behavior
- Running `bash agents/scripts/validate_spec.sh` with no arguments prints a usage message and exits non-zero.
- Running `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` exits 0 and prints a brief OK message.
- Script derives a report path based on the target spec basename and initializes a violations accumulator.
- Script exits non-zero when violations exist.

Expected file changes
- `agents/scripts/validate_spec.sh` is created with strict mode, argument parsing/usage, file existence checks, report path setup, and violations array handling.
- `agents/ideas/validation_reports/.gitkeep` is created to anchor the reports directory.

Verification commands
- `bash agents/scripts/validate_spec.sh`
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`

Non-functional requirements
- Stay within `turnloop/` only.
- No secrets added.

Notes / assumptions
- The staging spec file exists at `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
