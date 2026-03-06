<prompt id="019-readme-one-spec-queue-documentation" task="README One-Spec Queue Documentation">
  <objective>
    Update `README.md` so the public research-loop documentation matches the current oldest-only staging contract: the oldest staging spec is validated and managed one-spec-at-a-time, and successful runs leave newer staging specs queued in `agents/ideas/staging/`.
  </objective>
  <context>
    - The active task scope is limited to `README.md` plus the required prompt link in `agents/work/task.md`.
    - `README.md` already describes oldest staging validation and one-at-a-time Manager processing, but the wording needs to align exactly with the queue contract.
    - The task explicitly excludes outline changes, execution-loop documentation changes, and broader operational guidance.
    - `agents/work/quickfix.md` is closed, so remediator work is only needed if OPEN items appear.
  </context>
  <requirements>
    - Update the research-loop overview so it states the oldest staging spec is validated and managed one-spec-at-a-time.
    - Clarify that successful manage cycles leave newer staging specs in `agents/ideas/staging/`.
    - Preserve the rest of the README workflow documentation unless wording must change for consistency.
    - Keep the diff minimal and reviewable.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: update only the README lines needed to reflect the oldest-only research-loop queue contract.
    - 3. Developer: run the required verification command and confirm it passes.
    - 4. Refactor: perform a no-op improvement scan and only change files if explicit evidence justifies it.
    - 5. Builder: prepend `agents/historylog.md` and overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `rg -n 'oldest staging spec|one-spec-at-a-time|leave newer staging specs' README.md`
  </commands>
  <verification>
    - `README.md` states that staging processing is one-spec-at-a-time.
    - `README.md` matches the oldest-only validation and manage behavior.
    - Successful manage-cycle wording explicitly leaves newer staging specs queued in `agents/ideas/staging/`.
  </verification>
  <handoff>
    - Record the prompt path, files touched, commands run, refactor result, and quickfix/remediator status in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
