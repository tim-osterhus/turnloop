## 2026-03-06 — README One-Spec Queue Documentation
Goal: Align the public Turnloop documentation with oldest-only staging validation and Manager processing.
Scope:
- In: Update `README.md` so the research-loop overview and task descriptions describe one-spec-at-a-time staging handling.
- Out: Outline changes, execution-loop docs, or new operational guidance beyond the queue contract.
Prompt: `agents/work/prompts/019-readme-one-spec-queue-documentation.md`
Files to touch:
- README.md
Steps:
1. Update the research-loop overview to say the oldest staging spec is validated and managed one at a time.
2. Clarify that successful manage cycles leave newer staging specs in `agents/ideas/staging/`.
3. Preserve the rest of the repo workflow documentation as-is unless wording must change for consistency.
Acceptance:
- README states that staging processing is one-spec-at-a-time.
- README matches the oldest-only validation and manage behavior.
Verification commands:
- `rg -n 'oldest staging spec|one-spec-at-a-time|leave newer staging specs' README.md` — Expected: the README reflects the oldest-only queue contract.
