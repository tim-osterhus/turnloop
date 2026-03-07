<prompt id="031-readme-execution-loop-regression-usage" task="README Execution-Loop Regression Usage">
  <objective>
    Ensure `README.md` concisely documents the local execution-loop regression harness commands and states that they run against isolated temp state under the repo root without mutating the real queue state when they pass.
  </objective>
  <context>
    - Repo context comes from `agents/outline.md`; this task is documentation-only and should stay scoped to `README.md`.
    - The relevant harness entrypoints are standalone shell scripts under `agents/scripts/`.
    - Keep the existing loop documentation intact and make only the smallest README change needed, or no README edit if the file already satisfies the task verbatim.
    - Do not change loop behavior, harness implementation, or unrelated documentation sections.
  </context>
  <requirements>
    - `README.md` must mention `bash agents/scripts/test_orchestrate_happy_path.sh`.
    - `README.md` must mention `bash agents/scripts/test_orchestrate_quickfix_demotion.sh`.
    - `README.md` must state that the harnesses run against isolated temp state under the repo root and do not mutate the real queue state when they pass.
    - Keep the documentation concise and preserve the surrounding loop guidance.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and keep the link in `agents/work/task.md` valid.
    - 2. Developer: inspect the existing README loop/testing guidance and add or tighten a short execution-loop regression subsection only if required to satisfy the task.
    - 3. Developer: run the required grep-based verification against `README.md` and capture the result.
    - 4. Refactor: perform a brief evidence-based scan and keep it no-op unless the verification exposes a clear, low-risk documentation cleanup.
  </plan>
  <commands>
    - `rg -n 'test_orchestrate_happy_path.sh|test_orchestrate_quickfix_demotion.sh|isolated temp state' README.md`
  </commands>
  <verification>
    - `README.md` mentions both execution-loop regression harness scripts by name.
    - `README.md` states that the harnesses run against isolated temp state.
    - `rg -n 'test_orchestrate_happy_path.sh|test_orchestrate_quickfix_demotion.sh|isolated temp state' README.md` exits 0.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Record whether the Developer implementation was a README edit or a verification-backed no-op because the documentation already matched the task.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
