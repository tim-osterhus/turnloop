## 2026-03-05 — Update Finished Prompts: Scaffold + Headings
Goal: Update validator prompt artifacts for scaffold and headings tasks to use the specs-path reference.
Scope:
- In: Replace staging-path references in the finished prompt artifacts for validator scaffold and required headings.
- Out: Changes to prompt content unrelated to the spec path.
Files to touch:
- agents/work/finished/001-spec-validator-scaffold.md
- agents/work/finished/001-validator-required-headings-scope-labels.md
Steps:
1. Replace staging-path references in command lists with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
2. Update any “staging spec” wording to reference the specs path instead.
Acceptance:
- The two prompt artifacts contain no `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references.
- The command lists reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md` — Expected: matches in command lists.


## 2026-03-05 — Update Finished Prompts: Requirements Rules
Goal: Update validator prompt artifacts for requirements-rule tasks to use the specs-path reference.
Scope:
- In: Replace staging-path references in the finished prompt artifacts for requirements line rules.
- Out: Any other prompt artifact changes.
Files to touch:
- agents/work/finished/001-requirements-lines-present.md
- agents/work/finished/002-validator-requirements-line-rules.md
Steps:
1. Replace staging-path references in command lists with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
2. Update any “staging spec” wording to reference the specs path instead.
Acceptance:
- The two prompt artifacts contain no `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references.
- The command lists reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md` — Expected: matches in command lists.


## 2026-03-05 — Update Finished Prompt: Validator Reports
Goal: Update the validator reports prompt artifact to use the specs-path reference.
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
