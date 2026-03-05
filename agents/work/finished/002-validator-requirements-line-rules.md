<prompt id="002-validator-requirements-line-rules" task="Validator: Requirements Line Rules">
  <objective>
    Update the spec validator to enforce Requirements section line rules: require at least one bullet/numbered requirement line and ensure each requirement line contains exactly one occurrence of SHALL or SHALL NOT, with violations otherwise.
  </objective>
  <context>
    - Repo root is turnloop; keep changes minimal and within this repo.
    - Target file for code changes: agents/scripts/validate_spec.sh.
    - Requirements section content must be extracted up to the next heading.
    - Validation reports are written by the existing validator; preserve current report patterns.
  </context>
  <requirements>
    - Parse the Requirements section content and detect bullet (- or *) and numbered (1.) lines.
    - Add a violation if no bullet/numbered requirement lines are found.
    - For each requirement line, require exactly one occurrence of SHALL or SHALL NOT; flag none or multiple.
    - Keep the specs-path validation passing.
  </requirements>
  <plan>
    - 1. Developer: Inspect current Requirements parsing in agents/scripts/validate_spec.sh and implement the new line rules with minimal diffs.
    - 2. Developer: Run the three verification commands from agents/work/task.md.
    - 3. Refactor: Perform a brief, low-risk scan for cleanup; if none, record no-op in history.
    - 4. Remediator: If agents/work/quickfix.md has OPEN items, address only those.
  </plan>
  <commands>
    - printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "This line has no bullet and SHALL be ignored." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-bad-requirements.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-bad-requirements.md; echo "exit=$?"
    - printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL and SHALL NOT both appear." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-double-shall.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-shall.md; echo "exit=$?"
    - bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md
  </commands>
  <verification>
    - The bad requirements spec reports missing bullet/numbered requirements and exits non-zero.
    - The double SHALL spec reports invalid SHALL usage and exits non-zero.
    - The specs-path spec validation exits 0.
  </verification>
  <handoff>
    - Prepend the Builder entry in agents/historylog.md with summary, files, commands, decisions, prompt path, and artifacts.
    - Overwrite agents/orchestrate_status.md with ### BUILDER_COMPLETE or ### BLOCKED when finished.
  </handoff>
</prompt>
