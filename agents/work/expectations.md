# Expectations — 2026-03-06 Research Loop Single-Cycle Test Knobs

## Goal
Make `agents/scripts/research_loop.sh` configurable for a fast local single-cycle run via environment variables without changing its default daemon behavior when overrides are unset.

## Expected behavior
- The script reads `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_POLL_SECS` from the environment.
- When those variables are unset, the script preserves the current hard-coded daemon mode and delay values.
- When `TURNLOOP_DAEMON_MODE` requests a non-daemon run and both delay variables are set to `0`, the script supports a no-wait single-cycle execution path for local testing.
- Existing loop/repeat behavior remains intact in the default configuration.

## Expected file changes
- `agents/scripts/research_loop.sh` adds the three environment-variable overrides and wires them into the existing control flow.
- No other file changes are expected for the implementation.

## Verification commands
- `rg -n 'TURNLOOP_DAEMON_MODE|TURNLOOP_PROMOTE_DELAY_SECS|TURNLOOP_POLL_SECS' agents/scripts/research_loop.sh`
  - Expected: all three override names are present in the script.
- `bash -n agents/scripts/research_loop.sh`
  - Expected: exit 0.
- `TURNLOOP_DAEMON_MODE=0 TURNLOOP_PROMOTE_DELAY_SECS=0 TURNLOOP_POLL_SECS=0 bash agents/scripts/research_loop.sh`
  - Expected: if the script's required local dependencies are available, it completes a single non-daemon cycle without waiting on the default sleep cadence.

## Non-functional requirements
- Default production cadence is unchanged when environment overrides are unset.
- Runner selection and queue semantics remain unchanged.
- The script remains shell-syntax-valid and readable.

## Notes / assumptions
- `TURNLOOP_DAEMON_MODE=0` is assumed to be the non-daemon value unless the implementation documents an equivalent accepted falsey form.
- The runtime smoke test may depend on local repo state or helper scripts; if so, QA should record whether that blocks full runtime confirmation.
