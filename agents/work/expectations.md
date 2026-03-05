# QA Expectations

## Goal
Gate the research loop so it validates the oldest staging spec before running Manager, blocking and invoking the mechanic on validation failure.

## Expected behavior
- `agents/scripts/research_loop.sh` runs `agents/scripts/validate_spec.sh` against the oldest staging spec before any Manager entrypoint invocation.
- If validation fails, the research status is set to `### BLOCKED`, the failure is logged, `handle_mechanic "manage"` is called, and Manager is not invoked.
- If validation succeeds, the existing Manager invocation flow continues unchanged after the validation block.

## Expected file changes
- `agents/scripts/research_loop.sh` updated to add the validation gating logic.

## Verification commands
- `rg -n "validate_spec.sh" agents/scripts/research_loop.sh`
- `rg -n "_manage.md" agents/scripts/research_loop.sh`

## Non-functional requirements
- No changes to Manager entrypoint or execution loop beyond gating in `agents/scripts/research_loop.sh`.
- Changes are limited to the scope described in `agents/work/task.md`.

## Notes / assumptions
- The "oldest staging spec" is determinable within the research loop script using existing conventions.
