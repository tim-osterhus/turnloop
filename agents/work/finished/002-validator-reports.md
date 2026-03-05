<prompt id="002-validator-reports" task="Validator Reports">
  <objective>
    Update the spec validator to generate clear per-spec validation reports on failure, remove stale reports on success, and ensure the report directory exists, strictly within the current task scope.
  </objective>
  <context>
    - Repo is Turnloop; validator lives in agents/scripts/validate_spec.sh.
    - Task scope is limited to validation report creation/removal; no README or gating changes.
    - Reports should live under agents/ideas/validation_reports/.
    - Builder must keep diffs minimal and update history log when done.
  </context>
  <requirements>
    - Ensure agents/ideas/validation_reports/ is created when needed.
    - On validation failure, write agents/ideas/validation_reports/<spec_basename>.validation.md.
    - Report content must include the spec path and list each violation on its own line.
    - On validation success, delete any existing report for that spec basename.
  </requirements>
  <plan>
    - 1. (developer) Update agents/scripts/validate_spec.sh to create report directory, emit report on failure, and remove report on success.
    - 2. (refactor) Scan for small, low-risk improvements; make none if unnecessary.
  </plan>
  <commands>
    - printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL and SHALL NOT both appear." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-double-shall.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-shall.md; rg "Spec path" agents/ideas/validation_reports/spec-double-shall.validation.md
    - bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md; test ! -f agents/ideas/validation_reports/turnloop-spec-validation-2026-03-05.validation.md && echo "report removed"
  </commands>
  <verification>
    - A failing spec produces a report containing the spec path and at least one violation line.
    - A passing spec leaves no validation report for that spec basename.
  </verification>
  <handoff>
    - Prepend entry to agents/historylog.md using the Builder template.
    - Record prompt path agents/work/prompts/002-validator-reports.md in agents/work/task.md and the history log.
  </handoff>
</prompt>
