## Goal
Confirm that the research loop selects one oldest staging spec per manage cycle, validates that exact path, and passes the same path into the Manager invocation deterministically.

## Expected behavior
- `agents/scripts/research_loop.sh` assigns a single `staging_spec` from `oldest_file "$STAGING_DIR"` during the manage cycle.
- The script reuses `"$staging_spec"` for staging-spec validation instead of recomputing another oldest-file result later in the same cycle.
- The Manager entrypoint is invoked with the same selected path made available through repo-local process state, such as `TURNLOOP_STAGING_SPEC="$staging_spec"`.
- The manage cycle does not switch to a newer staging spec after validation during that same cycle.

## Expected file changes
- `agents/scripts/research_loop.sh` only, with changes limited to selecting, validating, and handing off the chosen staging spec path.

## Verification commands
- `rg -n 'staging_spec="\\$\\(oldest_file "\\$STAGING_DIR"\\)"|validate_spec.sh "\\$staging_spec"|TURNLOOP_STAGING_SPEC="\\$staging_spec"|run_entrypoint "\\$ENTRY_MANAGE"' agents/scripts/research_loop.sh`
- `bash -n agents/scripts/research_loop.sh`

## Non-functional requirements
- Changes stay within `turnloop/`.
- Shell syntax remains valid.
- The implementation remains deterministic for a single manage cycle and does not broaden scope into retry logic, validator behavior, or multi-spec processing.

## Notes / assumptions
- A process-local environment variable is an acceptable handoff mechanism between the research loop and the Manager runner.
