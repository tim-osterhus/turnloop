<prompt id="006-update-finished-validator-reports" task="Update Finished Prompt: Validator Reports">
  <objective>
    Update the finished validator reports prompt artifact to reference the specs-path validation spec instead of the staging-path reference, including wording updates.
  </objective>
  <context>
    - Repo uses prompt artifacts in `agents/work/prompts/` to drive Builder execution.
    - Scope is limited to `agents/work/finished/002-validator-reports.md` and its references.
    - Do not change report logic requirements or other prompt artifacts.
  </context>
  <requirements>
    - Replace the staging-path reference with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` in the command list.
    - Update any “staging spec” wording to reference the specs path instead.
    - Keep changes minimal and reviewable.
  </requirements>
  <plan>
    - 1. Developer: edit `agents/work/finished/002-validator-reports.md` to swap the staging reference and wording.
    - 2. Developer: run the verification `rg` commands and confirm expected matches.
    - 3. Refactor: perform a low-risk scan for evidence-backed improvements; apply only if warranted.
    - 4. Remediator: only if `agents/work/quickfix.md` lists OPEN items.
  </plan>
  <commands>
    - rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md
    - rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md
  </commands>
  <verification>
    - `agents/work/finished/002-validator-reports.md` contains no `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references.
    - The command list references `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` exactly once.
  </verification>
  <handoff>
    - Record summary, files touched, command results, decisions, follow-ups, and prompt path in `agents/historylog.md`.
  </handoff>
</prompt>
