# Expectations

## Goal
Validate that `README.md` documents the local execution-loop regression harness commands and clearly states that they run against isolated temp state under the repo root.

## Expected behavior
- `README.md` includes a concise subsection near existing loop-running or testing guidance for local execution-loop regression coverage.
- The README explicitly names `bash agents/scripts/test_orchestrate_happy_path.sh`.
- The README explicitly names `bash agents/scripts/test_orchestrate_quickfix_demotion.sh`.
- The README explicitly states that these harnesses operate on isolated temp state under the repo root.
- The surrounding loop documentation remains intact; the change is additive and scoped to usage guidance.

## Expected file changes
- `README.md` is updated.
- No loop scripts or non-README files are required to change for this task.

## Verification commands
- `rg -n 'test_orchestrate_happy_path.sh|test_orchestrate_quickfix_demotion.sh|isolated temp state' README.md`
- `rg -n 'execution-loop|regression|happy path|quickfix' README.md`

## Non-functional requirements
- Documentation is concise and user-facing.
- Wording is accurate about isolation behavior and does not claim the harnesses mutate real queue state when they pass.
- Scope stays limited to documentation for the existing harness scripts.

## Notes / assumptions
- The harness scripts remain standalone shell entrypoints under `agents/scripts/`.
- Acceptance can be satisfied entirely through `README.md` content if the required commands and isolation note are present and clearly phrased.
