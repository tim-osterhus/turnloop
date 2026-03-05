<prompt id="001-validator-requirement-keyword-count" task="Validator: Requirement Keyword Count">
  <objective>
    Update the spec validator so every Requirements bullet/numbered line contains exactly one requirement keyword; lines with zero or multiple keywords must be reported as violations.
  </objective>
  <context>
    - Repo root: /mnt/f/_evolve/turnloop.
    - Validator script: agents/scripts/validate_spec.sh.
    - Requirements keywords: SHALL, SHOULD, MUST, MAY (case-insensitive), matched as whole words.
    - Phrase "SHALL NOT" counts as one keyword occurrence.
  </context>
  <requirements>
    - Count requirement keywords per Requirements bullet/numbered line.
    - Record a violation when the count is not exactly one.
    - Keep changes minimal and within the validator script.
  </requirements>
  <plan>
    1. Read the validator script to locate Requirements parsing logic.
    2. Implement keyword counting with whole-word matching and SHALL NOT handling.
    3. Ensure violations are recorded for zero or multiple keywords.
    4. Run the required verification commands.
  </plan>
  <commands>
    - cat > agents/.tmp/spec-double-keyword.md <<'SPEC'
# Summary
# Problem statement
# Scope (In / Out)
In: test
Out: test
# Constraints
# Requirements
- The system SHALL and SHOULD fail.
# Verification plan
# Assumptions
# Open questions
SPEC
    - bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-keyword.md; echo "exit=$?"
    - cat > agents/.tmp/spec-no-keyword.md <<'SPEC'
# Summary
# Problem statement
# Scope (In / Out)
In: test
Out: test
# Constraints
# Requirements
- The system will fail without a keyword.
# Verification plan
# Assumptions
# Open questions
SPEC
    - bash agents/scripts/validate_spec.sh agents/.tmp/spec-no-keyword.md; echo "exit=$?"
  </commands>
  <verification>
    - Double-keyword spec exits non-zero and report mentions the double-keyword line.
    - No-keyword spec exits non-zero and report mentions the missing-keyword line.
  </verification>
  <handoff>
    - Update agents/historylog.md with summary, files touched, commands, decisions, and prompt path.
    - Overwrite agents/orchestrate_status.md with the completion marker when done.
  </handoff>
</prompt>
