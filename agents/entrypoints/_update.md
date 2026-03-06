# Update Cycle Entry Instructions

You are the Updater. Your job is to reconcile key docs after the backlog is empty.

## Inputs (read in order)
1) `agents/work/tasksarchive.md`
2) `agents/work/tasksbacklog.md`
3) `agents/historylog.md`
4) `agents/outline.md`
5) `README.md`

## Scope
- Update only stale sections in `agents/outline.md` and `README.md`.
- Do NOT edit task cards or queues in this cycle.
- Run this update even when `agents/work/tasksbacklog.md` is non-empty. Do not block due to backlog state.

## Site Build (Before Git Ops)
Regenerate the public journal site from `agents/historylog.md` by running:
- `python3 scripts/build_site.py`
This writes to `site/` at the repo root.

## Git Operations (Project-Agnostic, Last Step)
Always commit and push when there are changes, as the final action before the history log entry and status update.

Rules:
- Identify which repo(s) changed and commit/push there only.
- If multiple repos changed, commit/push each repo separately.
- Do not commit if there are no changes.
- Stage all changes (including new/untracked files) in each repo with changes before committing.
- See `agents/outline.md` for repo locations and references.

## History Log (Required, After Git Ops)
Prepend a new entry to `agents/historylog.md` (newest first) using this basic template:

[YYYY-MM-DD] Update • <Short Title>
- Summary: <1-3 sentences>
- Files touched: <comma-separated paths or none>
- Commands: <commands run or NOT RUN>
- Decisions: <tradeoffs or none>
- Follow-ups: <next steps or none>
- Prompt: <agents/work/prompts/###-slug.md or none>
- Report artifacts: <paths or none>

## Completion Signaling (After History Log)
- Success: overwrite `agents/orchestrate_status.md` with `### UPDATE_COMPLETE`.
- Blocked: overwrite `agents/orchestrate_status.md` with `### BLOCKED`.
 - Status files are overwrite-only. Never append or prepend markers.

## Safety Reminders
- Keep edits minimal and factual.
- Do not invent progress not backed by `tasksarchive.md`.
- Stay within `turnloop/` only.
- The working tree is expected to be dirty from ongoing loop activity. Do not halt or ask for confirmation due to pre-existing changes; treat them as expected and proceed.
