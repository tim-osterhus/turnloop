<prompt id="001-requirements-lines-present" task="Validator: Requirements Lines Present">
  <objective>
    Ensure the spec validator flags a missing-requirement-lines violation when the Requirements section contains no bullet or numbered requirement lines, while keeping other validator behavior unchanged.
  </objective>
  <context>
    - Repo root: /mnt/f/_evolve/turnloop
    - Scope is limited to agents/scripts/validate_spec.sh
    - Detect bullet lines starting with -, *, + or numbered lines like "1." inside the Requirements section body
    - Do not change requirement keyword counting or report formatting
  </context>
  <requirements>
    - Extract the Requirements section body based on Markdown headings
    - Match bullet or numbered lines within that section
    - Record a violation when no requirement lines are found
    - Keep changes minimal and reviewable
  </requirements>
  <plan>
    - 1. Builder: Update agents/scripts/validate_spec.sh to detect empty Requirements sections by scanning for bullet/numbered lines
    - 2. Refactor: Quick scan for low-risk cleanup; skip changes if unnecessary
    - 3. Remediator: Address any OPEN items in agents/work/quickfix.md if present
  </plan>
  <commands>
    - rg --files agents/scripts
    - sed -n '1,200p' agents/scripts/validate_spec.sh
    - bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-req-lines.md
    - bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md
  </commands>
  <verification>
    - Spec with empty Requirements section fails validation and reports missing-requirement-lines
    - Specs-path spec validates with exit 0
  </verification>
  <handoff>
    - Prepend history log entry in agents/historylog.md with summary, files, commands, decisions, follow-ups, prompt path
    - Overwrite agents/orchestrate_status.md with ### BUILDER_COMPLETE when done
  </handoff>
</prompt>
