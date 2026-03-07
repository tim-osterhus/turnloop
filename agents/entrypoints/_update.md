# Update Cycle Entry Instructions

You are the Updater. Your job is to clean up after a completed task batch, reconcile docs, rebuild the journal site, and commit/push.

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

## Task Cleanup (Before Anything Else)
This step prevents resume-contract bugs.

1) If `agents/work/task.md` still contains a completed task, clear it to a neutral placeholder.
2) If `agents/work/quickfix.md` has no OPEN items, clear it the same way.
3) If `agents/work/expectations.md` is stale and only reflects the just-completed task, clear it.
4) Move finished prompt artifacts from `agents/work/prompts/` to `agents/work/finished/` when they correspond to archived tasks.

Do not skip this step. If the loop restarts after a commit that still has stale task state, the orchestrator may re-enter the wrong phase.

## Doc Reconciliation
- Update `agents/outline.md` to reflect current repo state based on `agents/work/tasksarchive.md` and recent history.
- Update `README.md` only if factual changes warrant it.
- Keep edits minimal and factual. Do not invent progress not backed by the archive.

## Site Build (Before Git Ops)
Regenerate the public journal site from `agents/historylog.md` by running:
- `python3 scripts/build_site.py`
This writes to `site/` at the repo root.

## Git Operations (Last Step Before History Log)
Commit and push when there are changes, as the final action before the history log entry and status update.

### Staging Rules
- Never use broad staging blindly. Prefer explicit `git add <path>` calls.
- Respect `.gitignore`. If a clearly generated cache or binary artifact is unignored, fix `.gitignore` before staging it.
- Review `git status` before committing.
- If a staged file is unexpectedly large or clearly generated noise, unstage it and exclude it.

### Push Rules
- Attempt `git push` after committing.
- If push fails due to auth or transport, retry once, then record the failure and continue.
- If push fails due to diverged history, do not force-push from this stage. Record the failure and set `### BLOCKED`.
- If push fails due to large files or ignored-artifact mistakes, fix the staging mistake if it can be corrected safely within the repo, then retry once.

### Multi-Repo
- Identify which repo(s) changed and commit/push each separately.
- Do not commit if there are no changes in a given repo.

## History Log (Required, After Git Ops)
As the final step before writing the status marker, switch to role `historian` (`agents/roles/historian.md`) and prepend a new Update entry to the very top of `agents/historylog.md`.

## Completion Signaling (After History Log)
- Success: overwrite `agents/orchestrate_status.md` with `### UPDATE_COMPLETE`.
- Blocked: overwrite `agents/orchestrate_status.md` with `### BLOCKED`.
 - Status files are overwrite-only. Never append or prepend markers.

## Safety Reminders
- Keep edits minimal and factual.
- Do not invent progress not backed by `tasksarchive.md`.
- Stay within `turnloop/` only.
- The working tree is expected to be dirty from ongoing loop activity. Do not halt or ask for confirmation due to pre-existing changes; treat them as expected and proceed.
