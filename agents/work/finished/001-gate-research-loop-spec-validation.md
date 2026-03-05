<prompt id="001-gate-research-loop-spec-validation" task="Gate research loop on spec validation">
  <objective>
    Add a validation gate to the research loop so the oldest staging spec is validated before the Manager runs; on failure, block the loop, log the failure, and invoke the mechanic without calling Manager.
  </objective>
  <context>
    - Repo instructions live in agents/entrypoints/_start.md and agents/outline.md.
    - Scope is limited to agents/scripts/research_loop.sh.
    - Manager entrypoint is _manage.md and must remain after validation.
    - Do not change Manager entrypoint or execution loop.
  </context>
  <requirements>
    - Run agents/scripts/validate_spec.sh against the oldest staging spec before Manager invocation.
    - On validation failure, set research status to ### BLOCKED, log the failure, and call handle_mechanic "manage" while skipping Manager.
    - On validation success, continue with the existing Manager invocation flow.
    - Keep changes minimal and reviewable.
  </requirements>
  <plan>
    1. Developer: Inspect agents/scripts/research_loop.sh to locate Manager invocation and staging spec selection.
    2. Developer: Insert validation gate before Manager invocation with failure handling and success fallthrough.
    3. Refactor: Briefly scan for low-risk cleanup; make changes only if clearly beneficial.
    4. Remediator: If agents/work/quickfix.md has OPEN items, address only those.
  </plan>
  <commands>
    - rg -n "validate_spec.sh" agents/scripts/research_loop.sh
    - rg -n "_manage.md" agents/scripts/research_loop.sh
  </commands>
  <verification>
    - Validation call appears before Manager invocation in research_loop.sh.
    - Failure path sets ### BLOCKED and skips Manager.
  </verification>
  <handoff>
    - Prepend history entry to agents/historylog.md with summary, files, commands, decisions, follow-ups, prompt path.
    - Overwrite agents/orchestrate_status.md with ### BUILDER_COMPLETE or ### BLOCKED when done.
  </handoff>
</prompt>
