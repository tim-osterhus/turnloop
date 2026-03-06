## Goal

Validate that the active task adds a repo-local regression harness proving one manage-ready research-loop cycle selects only the oldest of two staged specs.

## Expected behavior

- `bash agents/scripts/test_research_queue_contract.sh` seeds two staged specs with deterministic oldest/newest ordering inside an isolated temp workspace under the repo.
- The harness exercises the real queue-selection path in `agents/scripts/research_loop.sh` for exactly one cycle, rather than reimplementing queue selection separately.
- The harness uses local stubs for validator/runner dependencies and records which staged spec was validated and dispatched.
- The harness exits 0 only when the oldest staged spec is the only spec validated and dispatched in that cycle.
- The harness fails if the newer spec is selected or if both staged specs are processed in the same cycle.
- After the cycle, the newer staged spec remains queued in staging.

## Expected file changes

- `agents/scripts/test_research_queue_contract.sh`: new or updated offline regression harness with isolated temp state, local stubs, deterministic queue seeding, and assertions for oldest-only processing.
- `agents/scripts/research_loop.sh`: only minimal changes needed to allow the harness to exercise the real queue-selection path and stay offline, if any.
- No unrelated repo files should change for this task.

## Verification commands

- `bash agents/scripts/test_research_queue_contract.sh`
- `git diff -- agents/scripts/test_research_queue_contract.sh agents/scripts/research_loop.sh`

## Non-functional requirements

- No network calls.
- No Codex, Claude, or other external runner invocations during the harness.
- Only local shell utilities and repo-local stubs are used.
- The harness does not mutate the real staging queue or other live repo state.
- Behavior is deterministic and repeatable across runs.

## Notes / assumptions

- The task only needs to prove one-cycle oldest-only behavior, not multi-cycle queue draining.
- Evidence may be captured through recorded validator/manager inputs, remaining staged files, exit status, and harness output.
