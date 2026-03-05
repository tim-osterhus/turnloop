## 2026-03-05 — Docs: Spec Validation Note
Prompt: agents/work/prompts/001-docs-spec-validation-note.md
Goal: Document the spec validation gate and report location.
Scope:
In: Add a README note that validation runs before Manager and reports live under `agents/ideas/validation_reports/`.
Out: Script or research-loop changes.
Files to touch:
- README.md
Steps:
1. Add a brief README note under Research Loop or How It Works that validation runs before Manager and reports live in `agents/ideas/validation_reports/`.
2. Mention that validation failures block the Manager run for that cycle.
Acceptance:
- README mentions validation before Manager and the report directory.
Verification commands:
- `rg "validation" README.md` — Expected: a line describing validation before Manager and report location.
