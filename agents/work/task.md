## 2026-03-05 — Update Finished Prompt: Validator Reports
Goal: Update the validator reports prompt artifact to use the specs-path reference.
Prompt: `agents/work/prompts/006-update-finished-validator-reports.md`
Scope:
- In: Replace staging-path references in the validator reports finished prompt artifact.
- Out: Changes to report logic requirements or other prompt artifacts.
Files to touch:
- agents/work/finished/002-validator-reports.md
Steps:
1. Replace the staging-path reference in the command list with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
2. Update any “staging spec” wording to reference the specs path instead.
Acceptance:
- `agents/work/finished/002-validator-reports.md` contains no `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references.
- The command list references `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md` — Expected: 1 match.
