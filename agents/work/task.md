## 2026-03-06 — Manager Oldest-Only Staging Contract
Prompt: `agents/work/prompts/016-manager-oldest-only-staging-contract.md`
Goal: Update the Manager instructions so each run targets exactly one staging spec: the oldest eligible file.
Scope:
- In: Rewrite `agents/entrypoints/_manage.md` to select one oldest staging spec, decompose only that spec, and move only that processed file to `agents/ideas/specs/`.
- Out: Changes to loop scripts, validator rules, or execution-loop behavior.
Assumptions: If a selected path is provided by the caller, Manager may use it as long as it still resolves to the oldest file being processed for that run.
Files to touch:
- agents/entrypoints/_manage.md
Steps:
1. Replace the batch-processing language with oldest-only staging selection language in the critical rules, inputs, and workflow sections.
2. State explicitly that newer staging files remain queued after a successful run.
3. Keep the existing overwrite-only status-file rules and history-log requirements intact.
Acceptance:
- The instructions say to process exactly one file per run.
- The selected file is described as the oldest staging spec.
- Success criteria say only the processed oldest spec moves to `agents/ideas/specs/`.
Verification commands:
- `rg -n 'process exactly one file per run|oldest file in `agents/ideas/staging/`|leave newer unprocessed staging specs|move only the processed oldest staging spec' agents/entrypoints/_manage.md` — Expected: all four phrases match.
