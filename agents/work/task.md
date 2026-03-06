## 2026-03-06 — Research Loop Selected-Spec Handoff
Goal: Make the research loop select the oldest staging spec once and reuse that exact path for validation and Manager dispatch.
Scope:
- In: Capture a single `staging_spec` per manage cycle, validate that path, and pass the same path into the Manager run through repo-local process state such as an environment variable.
- Out: Mechanic retry-count changes, validator-rule changes, or multi-spec processing.
Assumptions: A process-local environment variable is an acceptable handoff mechanism between the loop script and the Manager runner.
Prompt: `agents/work/prompts/017-research-loop-selected-spec-handoff.md`
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
