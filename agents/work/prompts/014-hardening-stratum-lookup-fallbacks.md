<prompt id="014-hardening-stratum-lookup-fallbacks" task="Hardening: stratum lookup fallbacks">
  <objective>
    Harden Corebound stratum resolution so surface and out-of-range rows always map to a safe fallback instead of leaking null or undefined values into the HUD, ore generation, or rendering paths.
  </objective>
  <context>
    - Repo context for this task is the Corebound prototype in `corebound/`.
    - Scope is limited to `corebound/game.js`.
    - `STRATA` defines the underground depth bands and `getStratumForRow(row)` currently returns `null` outside underground rows.
    - Existing helpers for HUD labels, ore tables, tile metadata, and solid tile colors all depend on stratum lookups.
    - The active task requires a stable `Surface` label at depth `0` and safe behavior at world boundaries without adding new gameplay or visuals.
  </context>
  <requirements>
    - Extend stratum lookup behavior so surface rows resolve to a safe fallback object and out-of-range rows clamp to the nearest valid row before lookup.
    - Route every stratum-dependent path through the safe lookup helper, including HUD text, ore generation helpers, and rendering helpers.
    - Keep the diff minimal and confined to `corebound/game.js`.
    - Do not add new visuals, ore types, controls, or unrelated refactors.
  </requirements>
  <plan>
    1. Prompt-architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect the existing stratum helpers and every call site in `corebound/game.js`.
    3. Developer: add a safe stratum fallback helper that clamps rows, resolves `Surface` for row `0`, and supplies a non-null stratum object for all consumers.
    4. Developer: update HUD, metadata, ore-table, and rendering code to use the safe helper consistently.
    5. Developer: run the required server command and a Node harness that checks surface, underground, and out-of-range lookups for stable names/ids.
    6. Refactor: perform a brief evidence-backed scan and keep it as a no-op unless verification surfaces a small, explicit issue.
    7. Remediator: skip because `agents/work/quickfix.md` has no OPEN items.
  </plan>
  <commands>
    - `python3 -m http.server`
    - `node - <<'NODE'`
  </commands>
  <verification>
    - The HUD path resolves `Surface` at depth `0` without fallback strings like `Unknown`, blank values, or undefined text.
    - Stratum-dependent helpers return stable values for rows below `0`, at `0`, within each underground band, and past the last world row.
    - No stratum lookup call site depends on a nullable return from the old helper.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if execution cannot be completed.
  </handoff>
</prompt>
