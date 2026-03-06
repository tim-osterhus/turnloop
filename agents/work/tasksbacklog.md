# Tasks Backlog

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
