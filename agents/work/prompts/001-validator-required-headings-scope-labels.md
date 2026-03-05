<prompt id="001-validator-required-headings-scope-labels" task="Validator: Required Headings + Scope Labels">
  <objective>
    Update the spec validator to enforce required section headings (case-insensitive) and to require "In:" and "Out:" labels inside the "Scope (In / Out)" section, emitting distinct violations for each missing item.
  </objective>
  <context>
    - Repo root: /mnt/f/_evolve/turnloop.
    - Validator script: agents/scripts/validate_spec.sh.
    - Keep changes minimal and within turnloop/.
  </context>
  <requirements>
    - Parse Markdown headings and ensure all required section titles are present (case-insensitive).
    - Within the "Scope (In / Out)" section, assert lines with "In:" and "Out:" exist.
    - Record a distinct violation message for each missing heading or missing label.
    - Do not add requirements-content rules or report formatting polish.
  </requirements>
  <plan>
    - 1) Developer: inspect validate_spec.sh to understand current heading/section parsing and required headings list.
    - 2) Developer: implement case-insensitive heading checks and Scope (In / Out) label checks with distinct violations.
    - 3) Refactor: quick low-risk scan for readability or edge-case clarity; if no changes needed, note in historylog.
    - 4) Remediator: if agents/work/quickfix.md has OPEN items, address only those.
  </plan>
  <commands>
    - rg -n "required" agents/scripts/validate_spec.sh
    - bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md
    - printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL be present." "# Verification plan" "# Assumptions" > agents/.tmp/spec-missing-heading.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-heading.md; echo "exit=$?"
  </commands>
  <verification>
    - Missing "Open questions" heading causes non-zero exit and validation report mentions it.
    - Staging spec validates successfully (exit 0).
  </verification>
  <handoff>
    - Update agents/historylog.md with summary, files touched, commands, decisions, follow-ups, prompt path, and report artifacts.
    - Do not move prompt artifacts; set agents/orchestrate_status.md to ### BUILDER_COMPLETE or ### BLOCKED.
  </handoff>
</prompt>
