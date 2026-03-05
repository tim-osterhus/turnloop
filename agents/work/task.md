## 2026-03-05 — Update Backburner Validator Card
Prompt: agents/work/prompts/004-update-backburner-validator-card.md
Goal: Align the backburner validator task card with the specs-path reference.
Scope:
- In: Update the validator card in `agents/work/tasksbackburner.md` to use the specs-path in acceptance/verification.
- Out: Changes to any other backburner entries or validator logic.
Files to touch:
- agents/work/tasksbackburner.md
Steps:
1. Find the validator task card in `agents/work/tasksbackburner.md` that references the staging spec path.
2. Replace the staging spec reference in acceptance/verification with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` and adjust wording from “staging spec” to “specs spec”.
Acceptance:
- `agents/work/tasksbackburner.md` contains no references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- The validator card verification command uses `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md` — Expected: 1 match.

