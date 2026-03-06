## 2026-03-06 — Validation Failure Blocks Manage Cycle
Goal: Ensure a validation failure for the selected staging spec blocks the research status and skips Manager for that cycle.
Scope:
- In: Write `### BLOCKED` before manage-stage mechanic handling begins and keep the Manager entrypoint on the success-only path.
- Out: Any change to mechanic escalation counts, nonviable moves, or validation-report content.
Assumptions: The loop should continue using the existing next-poll retry behavior after a blocked cycle.
Prompt: `agents/work/prompts/018-validation-failure-blocks-manage-cycle.md`
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Keep the validation step on the selected `staging_spec` and capture the failure branch explicitly.
2. Write `### BLOCKED` before invoking manage-stage mechanic handling.
3. Ensure the Manager entrypoint is not reached when validation fails for that cycle.
Acceptance:
- Validation failure writes `### BLOCKED` before manage-stage mechanic handling starts.
- Validation failure does not invoke Manager for any staging spec in that cycle.
- The success path still runs Manager normally.
Verification commands:
- `rg -n 'Staging validation failed for \\$staging_spec|write_status \"### BLOCKED\"|handle_mechanic \"manage\"|run_entrypoint \"\\$ENTRY_MANAGE\"' agents/scripts/research_loop.sh` — Expected: blocked-status and mechanic handling exist on the validation-failure path, and Manager remains on the success path.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0.
