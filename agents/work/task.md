## 2026-03-05 — Update Finished Prompts: Requirements Rules
Prompt: agents/work/prompts/003-update-finished-prompts-requirements-rules.md
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

