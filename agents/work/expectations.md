# QA Expectations

- Goal: Update archived validator task cards to reference the specs-path spec file and remove any staging-path mentions.

- Expected behavior:
- Validator-related cards in `agents/work/tasksarchive.md` reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` where they point to the validation spec.
- Validator-related cards do not mention `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` or instruct recreating a staging spec.

- Expected file changes:
- `agents/work/tasksarchive.md`

- Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` (expect no matches)
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` (expect matches in validator card verification commands)
- `rg -n "cp .*turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` (expect no matches)

- Non-functional requirements:
- Scope limited to task cards; do not edit history, spec files, or validator scripts.
- Use objective, verifiable wording in validator cards.

- Notes / assumptions:
- Validator-related cards are the only cards that should reference the spec path in this archive.
