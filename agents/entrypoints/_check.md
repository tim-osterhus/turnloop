# QA Entry Instructions

You are QA. Your job is to validate the active task with evidence and catch gaps.
This entrypoint also covers doublecheck for quickfix cycles.

Roles live in `agents/roles/`. Use the roles named below and reference their files.

## Critical QA Workflow (Strict Ordering)

### Phase 1: Understand Requirements (before looking at implementation)
1) Read `agents/outline.md`.
2) Read `agents/work/task.md`.
3) If `agents/work/quickfix.md` contains OPEN items, read it now and treat this run as a doublecheck.
4) Do NOT read `agents/historylog.md`, `git diff`, or test output yet.

### Phase 2: Write Expectations FIRST
5) Switch to role `rubric-maker` (`agents/roles/rubric-maker.md`) and write or overwrite `agents/work/expectations.md`.
6) Expectations must list:
- Expected behavior.
- Expected file changes.
- Verification commands.
- Non-functional constraints.

### Phase 3: Inspect Implementation
7) Read `agents/historylog.md`.
8) Inspect repo state (`git status`, `git diff`) and relevant files.

### Phase 4: Validate Against Expectations
9) Switch to role `tester` (`agents/roles/tester.md`) and run the verification commands from `agents/work/expectations.md`.
10) Compare results to expectations. If quickfix was involved, switch to role `double-check` (`agents/roles/double-check.md`) for final validation.

### Phase 5: Document Results
11) If all expectations are met:
- Switch to role `historian` (`agents/roles/historian.md`) and prepend a QA entry to the very top of `agents/historylog.md`.
- Overwrite `agents/orchestrate_status.md` with `### QA_COMPLETE`.
12) If gaps exist:
- Update `agents/work/quickfix.md` with issues, impact, required fixes, and verification commands.
- Switch to role `historian` (`agents/roles/historian.md`) and prepend a QA entry to the very top of `agents/historylog.md`.
- Overwrite `agents/orchestrate_status.md` with `### QUICKFIX_NEEDED`.
13) If blocked:
- Switch to role `historian` (`agents/roles/historian.md`) and prepend a QA entry to the very top of `agents/historylog.md`.
- Overwrite `agents/orchestrate_status.md` with `### BLOCKED`.
 - Status files are overwrite-only. Never append or prepend markers.

## History Log (Required)
Use the `historian` role's exact prepend method and minute-precision timestamp format.

## Safety Reminders
- Never write secrets into repo files.
- Do not skip the expectations step.
- Stay within `turnloop/` only.
