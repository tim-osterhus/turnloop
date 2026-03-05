## 2026-03-05 — Update Archived Validator Task Cards
Prompt: agents/work/prompts/003-update-archived-validator-task-cards.md
Goal: Replace staging-path references with specs-path references in archived validator task cards.
Scope:
- In: Update validator-related cards in `agents/work/tasksarchive.md` to reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` and remove any staging-path mentions.
- Out: Editing `agents/historylog.md`, spec files, or validator scripts.
Assumptions: Scope is limited to task cards and prompt artifacts, so repo-wide `rg ... agents` checks may still find legacy staging references in non-task files like history logs.
Files to touch:
- agents/work/tasksarchive.md
Steps:
1. Locate all references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` within validator cards in `agents/work/tasksarchive.md`.
2. Replace staging-path references with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` and update any “staging spec” wording accordingly.
3. Ensure no validator card instructions in `agents/work/tasksarchive.md` include copy steps that recreate the staging spec.
Acceptance:
- `agents/work/tasksarchive.md` contains no references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- Validator cards in `agents/work/tasksarchive.md` reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` in verification commands.
- No copy-back instructions recreate the staging spec in these archived cards.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` — Expected: matches inside validator card verification commands.
- `rg -n "cp .*turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` — Expected: no matches.

