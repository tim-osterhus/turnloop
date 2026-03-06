# Summary
Align the research loop, staging validation, and Manager handoff around exactly one oldest staging spec per cycle so the same artifact is validated, decomposed, and archived with deterministic queue behavior.

# Problem statement
The current research loop validates only the oldest file in `agents/ideas/staging/`, but `agents/entrypoints/_manage.md` instructs Manager to process all staging files in one run. If more than one staging spec exists, later files can bypass pre-manage validation or be moved in the same cycle, which weakens traceability and makes recovery behavior ambiguous.

# Scope (In / Out)
In: Align the Manager contract with oldest-only staging processing, update research-loop handoff behavior/documentation, and add a local regression harness for the queue contract.
Out: Changes to spec validation rules, Builder or QA behavior, execution-loop task promotion, or product-specific work under `corebound/`.

# Constraints
- Keep the file-based queue model and overwrite-only status markers intact.
- Use only repo-local tooling and shell utilities already expected by Turnloop.
- Preserve the existing staging/specs/processed directory layout.
- Keep mechanic handling scoped to the selected staging spec for the current cycle.

# Requirements
- `agents/entrypoints/_manage.md` SHALL instruct Manager to process exactly one file per run: the oldest file in `agents/ideas/staging/`.
- `agents/scripts/research_loop.sh` SHALL select the oldest staging spec once per manage cycle and reuse that same path for validation and Manager dispatch.
- When the selected staging spec fails validation, the research loop SHALL set `agents/research_status.md` to `### BLOCKED` before manage-stage mechanic handling begins.
- When the selected staging spec fails validation, the research loop SHALL NOT invoke Manager for any staging spec in that cycle.
- On a successful manage cycle, the system SHALL leave newer unprocessed staging specs in `agents/ideas/staging/`.
- On a successful manage cycle, Manager SHALL move only the processed oldest staging spec to `agents/ideas/specs/`.
- `README.md` SHALL describe staging processing as one-spec-at-a-time so operator expectations match runtime behavior.
- The repo SHALL include a local regression harness that exercises a two-spec staging queue and verifies that only the oldest spec is targeted in one cycle.
- The regression harness SHALL NOT invoke external runners or network services.

# Verification plan
- `rg -n "process exactly one file per run|oldest file in `agents/ideas/staging/`|one-spec-at-a-time" agents/entrypoints/_manage.md README.md` — Expected: Manager instructions and README both state oldest-only staging processing.
- `rg -n 'staging_spec=.*oldest_file "\\$STAGING_DIR"|validate_spec.sh "\\$staging_spec"|run_entrypoint "\\$ENTRY_MANAGE"' agents/scripts/research_loop.sh` — Expected: one selected staging path is reused for validation and Manager dispatch.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0 with no syntax errors after the queue-contract update.
- `bash agents/scripts/test_research_queue_contract.sh` — Expected: exit 0 and output showing that only the oldest staging spec is targeted while the newer spec remains queued.

# Assumptions
- More than one staging spec can exist because of retries, manual seeding, or backlog accumulation, even if the common case is a single file.
- Processing one staging spec per cycle is acceptable for throughput because it improves determinism and simplifies recovery.
- A dedicated shell harness is sufficient evidence for the queue contract without invoking the full Codex or Claude runner.

# Open questions
- After a successful oldest-only manage cycle, should the daemon immediately check for another staging file in the same wake-up or wait for the next poll interval?
- Should the queue-contract harness live as a standalone script permanently, or later fold into a broader loop regression suite?
