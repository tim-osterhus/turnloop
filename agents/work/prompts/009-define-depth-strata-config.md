<prompt id="009-define-depth-strata-config" task="Define depth strata config">
  <objective>
    Introduce named depth strata definitions and a helper that resolves the stratum for a given underground row so later ore, visual, and HUD work can share the same depth-band source of truth.
  </objective>
  <context>
    - Repo context for this task is the Corebound prototype in `corebound/`.
    - Scope is limited to `corebound/game.js`.
    - Do not change world generation, ore weighting, tile visuals, or HUD output in this task.
    - The task assumption says strata breakpoints should be evenly spaced across underground rows for this iteration.
  </context>
  <requirements>
    - Add a `STRATA` array with at least three named entries.
    - Use explicit `minRow` and `maxRow` ranges that cover underground rows `1..WORLD_ROWS-1` without gaps.
    - Add `getStratumForRow(row)` that returns the matching stratum object for underground rows.
    - Keep the helper accessible for later work without wiring it into generation or rendering yet.
    - Keep the diff minimal and confined to `corebound/game.js`.
  </requirements>
  <plan>
    1. Prompt-architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect `corebound/game.js`, add evenly spaced named strata and the row lookup helper with minimal diffs.
    3. Developer: run the required verification command and a lightweight JS harness to confirm row 1 and `WORLD_ROWS - 1` resolve to named strata.
    4. Refactor: perform a brief evidence-backed cleanup scan; if no improvement is warranted, record a no-op outcome.
    5. Remediator: act only if `agents/work/quickfix.md` contains OPEN items.
  </plan>
  <commands>
    - `python3 -m http.server`
    - `node - <<'NODE'`
  </commands>
  <verification>
    - `getStratumForRow(1)` returns a defined stratum object with a `name`.
    - `getStratumForRow(WORLD_ROWS - 1)` returns a defined stratum object with a `name`.
    - The game code loads without introducing console or runtime errors from the new strata definitions.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if execution cannot be completed.
  </handoff>
</prompt>
