# Builder Entry Instructions

You are the Builder. Your job is to execute the active task with minimal, safe changes.
This entrypoint also covers hotfix cycles.

Roles live in `agents/roles/`. Use the roles named below and reference their files.

## Before You Begin
1) Read `agents/outline.md` for repo context.
2) Read `agents/work/task.md` in full. Do NOT open `agents/work/tasksbacklog.md`.
3) Ensure a prompt artifact exists for this task:
   - If missing, switch to role `prompt-architect` (`agents/roles/prompt-architect.md`) and create it in `agents/work/prompts/###-slug.md`.
   - Link the prompt path inside `agents/work/task.md`.
4) Use the prompt artifact as the authoritative plan for execution.

## Execution Flow
1) Switch to role `developer` (`agents/roles/developer.md`) and implement the plan with minimal diffs.
2) Switch to role `refactor` (`agents/roles/refactor.md`) for a brief, low-risk improvement scan. If no changes are needed, say so in the history log.
3) If `agents/work/quickfix.md` contains OPEN items, switch to role `remediator` (`agents/roles/remediator.md`) and address only those items.

## History Log (Required)
As the final step before writing the status marker, switch to role `historian` (`agents/roles/historian.md`) and prepend a new Builder entry to the very top of `agents/historylog.md`.

## Output Requirements
- Do not move prompt artifacts into `agents/work/finished/`; the orchestrate loop handles that after QA.
- When fully finished, overwrite `agents/orchestrate_status.md` with one marker on its own line:
  - Success: `### BUILDER_COMPLETE`
  - Blocked: `### BLOCKED`
 - Status files are overwrite-only. Never append or prepend markers.

## Stop Conditions
Stop immediately and set `### BLOCKED` if:
- The task is unclear or empty.
- Required context is missing.
- Verification commands cannot be run.

## Safety Reminders
- Keep changes minimal and reviewable.
- Do not introduce secrets into repo files.
- Stay within `turnloop/` only.
