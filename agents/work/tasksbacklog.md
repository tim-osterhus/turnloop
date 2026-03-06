# Tasks Backlog

## 2026-03-06 — Research Loop Selected-Spec Handoff
Goal: Make the research loop select the oldest staging spec once and reuse that exact path for validation and Manager dispatch.
Scope:
- In: Capture a single `staging_spec` per manage cycle, validate that path, and pass the same path into the Manager run through repo-local process state such as an environment variable.
- Out: Mechanic retry-count changes, validator-rule changes, or multi-spec processing.
Assumptions: A process-local environment variable is an acceptable handoff mechanism between the loop script and the Manager runner.
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Keep a single oldest-file lookup for the manage cycle and store it in `staging_spec`.
2. Reuse `staging_spec` for the validation command instead of recomputing a staging path later in the cycle.
3. Export or inject the same `staging_spec` into the Manager invocation so Manager can target the validated file deterministically.
Acceptance:
- The manage cycle performs one oldest-file selection per run.
- The same selected path is used for validation and Manager dispatch.
- Newer staging files are not selected during that cycle.
Verification commands:
- `rg -n 'staging_spec=\"\\$\\(oldest_file \"\\$STAGING_DIR\"\\)\"|validate_spec.sh \"\\$staging_spec\"|TURNLOOP_STAGING_SPEC=\"\\$staging_spec\"|run_entrypoint \"\\$ENTRY_MANAGE\"' agents/scripts/research_loop.sh` — Expected: the selected staging path is assigned once, validated, and passed into Manager.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0.

## 2026-03-06 — Validation Failure Blocks Manage Cycle
Goal: Ensure a validation failure for the selected staging spec blocks the research status and skips Manager for that cycle.
Scope:
- In: Write `### BLOCKED` before manage-stage mechanic handling begins and keep the Manager entrypoint on the success-only path.
- Out: Any change to mechanic escalation counts, nonviable moves, or validation-report content.
Assumptions: The loop should continue using the existing next-poll retry behavior after a blocked cycle.
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Keep the validation step on the selected `staging_spec` and capture the failure branch explicitly.
2. Write `### BLOCKED` before invoking manage-stage mechanic handling.
3. Ensure the Manager entrypoint is not reached when validation fails for that cycle.
Acceptance:
- Validation failure writes `### BLOCKED` before manage-stage mechanic handling starts.
- Validation failure does not invoke Manager for any staging spec in that cycle.
- The success path still runs Manager normally.
Verification commands:
- `rg -n 'Staging validation failed for \\$staging_spec|write_status \"### BLOCKED\"|handle_mechanic \"manage\"|run_entrypoint \"\\$ENTRY_MANAGE\"' agents/scripts/research_loop.sh` — Expected: blocked-status and mechanic handling exist on the validation-failure path, and Manager remains on the success path.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0.

## 2026-03-06 — README One-Spec Queue Documentation
Goal: Align the public Turnloop documentation with oldest-only staging validation and Manager processing.
Scope:
- In: Update `README.md` so the research-loop overview and task descriptions describe one-spec-at-a-time staging handling.
- Out: Outline changes, execution-loop docs, or new operational guidance beyond the queue contract.
Files to touch:
- README.md
Steps:
1. Update the research-loop overview to say the oldest staging spec is validated and managed one at a time.
2. Clarify that successful manage cycles leave newer staging specs in `agents/ideas/staging/`.
3. Preserve the rest of the repo workflow documentation as-is unless wording must change for consistency.
Acceptance:
- README states that staging processing is one-spec-at-a-time.
- README matches the oldest-only validation and manage behavior.
Verification commands:
- `rg -n 'oldest staging spec|one-spec-at-a-time|leave newer staging specs' README.md` — Expected: the README reflects the oldest-only queue contract.

## 2026-03-06 — Research Queue Contract Harness
Goal: Add a local regression harness that exercises a two-spec staging queue and proves one cycle targets only the oldest spec.
Scope:
- In: Create a repo-local shell harness that seeds two staging specs, runs one manage-ready research-loop cycle with stubbed local components, and asserts the newer spec remains queued.
- Out: External runners, network calls, or a broader end-to-end integration suite.
Assumptions: The harness may stub the runner and validation behavior locally as long as it exercises the real queue-selection path in `agents/scripts/research_loop.sh`.
Files to touch:
- agents/scripts/test_research_queue_contract.sh
- agents/scripts/research_loop.sh
Steps:
1. Build the harness around an isolated temp workspace under the repo so it does not mutate real queue state.
2. Seed two staging specs with deterministic ordering and capture which path the loop validates and dispatches to Manager.
3. Stub any runner or validator dependencies locally so the harness stays offline and does not call Codex, Claude, or network services.
4. Assert that one cycle targets only the oldest spec and leaves the newer spec in staging afterward.
Acceptance:
- The harness exits 0 when only the oldest staging spec is validated and dispatched in one cycle.
- The harness fails if the newer spec is selected or if both specs are processed in the same cycle.
- The harness uses only local shell utilities and repo-local stubs.
Verification commands:
- `bash agents/scripts/test_research_queue_contract.sh` — Expected: exit 0 and output confirming that only the oldest staging spec was targeted while the newer spec remained queued.
