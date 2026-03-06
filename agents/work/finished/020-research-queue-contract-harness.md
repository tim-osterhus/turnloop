<prompt id="020-research-queue-contract-harness" task="Research Queue Contract Harness">
  <objective>
    Add a repo-local shell harness that seeds two staging specs, runs one offline manage-ready research-loop cycle against isolated temp state, and proves the cycle validates and dispatches only the oldest staged spec.
  </objective>
  <context>
    - The active task scope is limited to `agents/scripts/research_loop.sh`, `agents/scripts/test_research_queue_contract.sh`, and the required prompt link in `agents/work/task.md`.
    - `agents/scripts/research_loop.sh` already selects the oldest staging spec once per manage cycle and passes that path into Manager via `TURNLOOP_STAGING_SPEC`.
    - The harness must not mutate the real queue state under the repo root; it needs isolated temp directories under the repo.
    - The task permits local stubs for runner or validator behavior as long as the real queue-selection path in `agents/scripts/research_loop.sh` is exercised.
    - `agents/work/quickfix.md` is closed, so remediator work is only needed if OPEN items appear.
  </context>
  <requirements>
    - Keep the production manage-cycle behavior unchanged for normal runs.
    - Add only the minimum loop test hooks needed to point the real script at isolated workspace paths and a local validator stub.
    - The harness SHALL seed two staging specs with deterministic oldest/newest ordering.
    - The harness SHALL capture the spec path sent to validation and the spec path dispatched to Manager.
    - The harness SHALL fail if the newer spec is selected or if more than one staging spec is targeted in the single cycle.
    - The harness SHALL use only local shell utilities and repo-local stubs.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: add low-risk environment overrides in `agents/scripts/research_loop.sh` for isolated workspace execution and validator injection.
    - 3. Developer: implement `agents/scripts/test_research_queue_contract.sh` to seed two specs, stub dependencies locally, run one non-daemon cycle, and assert oldest-only targeting.
    - 4. Developer: run the required commands and confirm the harness passes.
    - 5. Refactor: perform a no-op improvement scan and only change code if explicit evidence justifies it.
    - 6. Builder: prepend `agents/historylog.md` and overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `rg -n 'TURNLOOP_WORK_ROOT|TURNLOOP_VALIDATE_SPEC_SCRIPT|validate_spec.sh|TURNLOOP_STAGING_SPEC' agents/scripts/research_loop.sh`
    - `bash -n agents/scripts/research_loop.sh`
    - `bash agents/scripts/test_research_queue_contract.sh`
  </commands>
  <verification>
    - The loop script can run against an isolated temp workspace without mutating the real queue directories.
    - One harness run validates exactly one staging spec and dispatches exactly one manage target.
    - The validated and dispatched spec path is the older of the two seeded staging specs.
    - The newer seeded spec remains in staging after the cycle.
    - `bash -n agents/scripts/research_loop.sh` exits 0 and `bash agents/scripts/test_research_queue_contract.sh` exits 0.
  </verification>
  <handoff>
    - Record the prompt path, files touched, commands run, refactor result, and quickfix/remediator status in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
