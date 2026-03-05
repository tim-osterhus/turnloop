## 2026-03-05 — Spec Validator Scaffold
Prompt: agents/work/prompts/001-spec-validator-scaffold.md
Goal: Add a validator script scaffold and reports directory to anchor spec validation.
Scope:
In: Create `agents/scripts/validate_spec.sh` with argument parsing, report path setup, and a violation accumulator; add `agents/ideas/validation_reports/.gitkeep`.
Out: Actual validation rules for headings or requirements.
Files to touch:
- agents/scripts/validate_spec.sh
- agents/ideas/validation_reports/.gitkeep
Steps:
1. Create the `agents/ideas/validation_reports/` directory with a `.gitkeep` file.
2. Add `agents/scripts/validate_spec.sh` with strict mode, usage messaging, file existence checks, basename-derived report path, and a violations array.
3. Have the script exit non-zero when violations exist and print a short OK message when none exist.
Acceptance:
- Running the script with no arguments exits non-zero and prints a usage message.
- Running the script against the staging spec exits 0 and prints a brief OK message.
Verification commands:
- `bash agents/scripts/validate_spec.sh` — Expected: usage message and non-zero exit.
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0 and OK output.
