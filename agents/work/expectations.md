## Goal
Confirm that a staging-spec validation failure blocks the manage cycle before manage-stage mechanic handling begins, while the success path still reaches Manager normally.

## Expected behavior
- `agents/scripts/research_loop.sh` validates the selected `"$staging_spec"` and has an explicit failure branch for that validation step.
- On validation failure, the script writes `### BLOCKED` before any manage-stage mechanic handling starts.
- On validation failure, the script does not invoke the Manager entrypoint for that cycle.
- On validation success, the existing manage flow still reaches Manager normally.

## Expected file changes
- `agents/scripts/research_loop.sh` only, with changes limited to the staging-validation failure branch and manage-stage control flow.

## Verification commands
- `rg -n 'Staging validation failed for \\$staging_spec|write_status "### BLOCKED"|handle_mechanic "manage"|run_entrypoint "\\$ENTRY_MANAGE"' agents/scripts/research_loop.sh`
- `bash -n agents/scripts/research_loop.sh`

## Non-functional requirements
- Changes stay within `turnloop/`.
- Shell syntax remains valid.
- The implementation keeps existing next-poll retry behavior for blocked cycles.
- The change does not alter mechanic escalation counts, nonviable moves, or validation-report content.

## Notes / assumptions
- `agents/work/quickfix.md` is closed, so this QA run is not a doublecheck cycle.
