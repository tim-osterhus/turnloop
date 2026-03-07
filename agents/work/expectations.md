## Goal
Confirm that `README.md` documents the local execution-loop regression harness commands and explicitly states that they run against isolated temp state under the repo root without mutating the real queue state when they pass.

## Expected behavior
- `README.md` contains a concise subsection near existing loop-running or testing guidance for local execution-loop regression coverage.
- The subsection mentions `bash agents/scripts/test_orchestrate_happy_path.sh`.
- The subsection mentions `bash agents/scripts/test_orchestrate_quickfix_demotion.sh`.
- The subsection states that both harnesses run against isolated temp state under the repo root.
- The wording makes clear that successful runs do not mutate the real queue state.
- Existing loop documentation remains intact aside from the targeted documentation addition.

## Expected file changes
- `README.md` is the only file that should change for this task.

## Verification commands
- `rg -n 'test_orchestrate_happy_path.sh|test_orchestrate_quickfix_demotion.sh|isolated temp state' README.md`
- `git diff -- README.md`

## Non-functional requirements
- Documentation should be concise and scoped to usage guidance.
- Script names and behavior notes must be accurate to the task definition.
- No loop behavior or harness implementation changes are introduced.

## Notes / assumptions
- The harness scripts remain standalone shell entrypoints under `agents/scripts/`.
- The task does not require executing the harnesses unless needed to resolve ambiguity during QA.
