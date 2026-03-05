# Summary
Add an automated spec validation gate between Researcher and Manager so only well-formed, testable specs are decomposed into tasks, with clear failure reports when a spec is malformed.

# Problem statement
The research loop currently accepts any staging file, which allows malformed specs to reach Manager and produce ambiguous or brittle task cards. This weakens handoffs and makes outcomes harder to validate.

# Scope (In / Out)
In:
- Spec validation script and failure report output.
- Research loop gating to validate the oldest staging spec before running Manager.
- Minimal documentation updates if needed to explain validation usage.
Out:
- Changes to Builder, QA, or execution-loop task validation.
- New external dependencies or services.

# Constraints
- Use only local scripts and existing repo tooling (bash, rg, awk, sed).
- Do not change the file-based communication model between loops.
- Keep status marker semantics unchanged (overwrite-only markers).
- Keep changes within the `turnloop/` repository.

# Requirements
- The system SHALL add a script at `agents/scripts/validate_spec.sh` that accepts a spec file path and exits 0 only when all validation rules pass, otherwise exits non-zero.
- The validator SHALL require the following section headings (case-insensitive match) to appear as Markdown headings: `Summary`, `Problem statement`, `Scope (In / Out)`, `Constraints`, `Requirements`, `Verification plan`, `Assumptions`, `Open questions`.
- The validator SHALL require the `Scope (In / Out)` section to include both an `In:` label and an `Out:` label.
- The validator SHALL require the `Requirements` section to contain at least one bullet or numbered line, and each such line SHALL contain exactly one of `SHALL` or `SHALL NOT`.
- On validation failure, the validator SHALL write a report file to `agents/ideas/validation_reports/<spec_basename>.validation.md` that lists each violation and the spec path.
- The research loop SHALL run `agents/scripts/validate_spec.sh` against the oldest file in `agents/ideas/staging/` before invoking `agents/entrypoints/_manage.md`.
- If spec validation fails, the research loop SHALL set `agents/research_status.md` to `### BLOCKED`, SHALL skip the Manager run for that cycle, and SHALL invoke `handle_mechanic "manage"`.

# Verification plan
- Run `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` and expect exit code 0 with a brief OK message and no report file generated.
- Create a temporary malformed spec (missing a required heading) and run the validator; expect a non-zero exit code and a report created under `agents/ideas/validation_reports/` describing the missing section.
- Run `rg "validate_spec.sh" agents/scripts/research_loop.sh` and expect to see the validation call placed before the `_manage.md` entrypoint invocation.

# Assumptions
- Spec files are written in Markdown and follow the same section titles shown in this spec.
- The repository already includes `rg` on PATH for script use.

# Open questions
- Should heading matching be strictly case-sensitive or permit minor title variations (for example `Problem Statement` vs `Problem statement`)?
- Should the validator allow numbered requirement lines in addition to bullet lines, or enforce one format only?
- Should the validation report be rotated or timestamped to preserve historical failures?
