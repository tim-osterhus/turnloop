<prompt id="005-update-finished-validator-prompts-scaffold-headings" task="Update finished validator prompt artifacts for scaffold + headings">
  <objective>
    Update the finished validator prompt artifacts for scaffold and required headings so their command lists and wording reference the specs-path validation spec instead of the staging path.
  </objective>
  <context>
    - Repo root: turnloop; stay within this repo.
    - Task source: agents/work/task.md.
    - Files to update: agents/work/finished/001-spec-validator-scaffold.md, agents/work/finished/001-validator-required-headings-scope-labels.md.
    - Scope: replace staging-path references with specs-path references; avoid unrelated content changes.
  </context>
  <requirements>
    - Replace any references to agents/ideas/staging/turnloop-spec-validation-2026-03-05.md with agents/ideas/specs/turnloop-spec-validation-2026-03-05.md in command lists.
    - Update any “staging spec” wording to reference the specs path instead.
    - Leave all other prompt content unchanged.
  </requirements>
  <plan>
    1. (developer) Edit the two finished prompt artifacts to replace staging-path references and staging wording with specs-path references.
    2. (refactor) Perform a brief scan for low-risk improvements; if none, note that in history.
    3. (remediator) If agents/work/quickfix.md contains OPEN items, address only those items.
  </plan>
  <commands>
    - rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md
    - rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md
  </commands>
  <verification>
    - The two prompt artifacts contain no agents/ideas/staging/turnloop-spec-validation-2026-03-05.md references.
    - The command lists reference agents/ideas/specs/turnloop-spec-validation-2026-03-05.md.
  </verification>
  <handoff>
    - Update agents/historylog.md with the Builder entry template.
    - Set agents/orchestrate_status.md to ### BUILDER_COMPLETE on success or ### BLOCKED on stop conditions.
  </handoff>
</prompt>
