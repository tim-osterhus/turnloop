<prompt id="010-apply-strata-metadata-world-generation" task="Apply strata metadata in world generation">
  <objective>
    Tag underground solid tiles with their resolved stratum metadata during world generation so later rendering and ore-selection work can consume that information, while leaving the surface row and starter shaft traversal behavior unchanged.
  </objective>
  <context>
    - Repo context for this task is the Corebound prototype in `corebound/`.
    - Scope is limited to `corebound/game.js`.
    - `STRATA` and `getStratumForRow(row)` already exist and should be reused instead of redefining depth ranges.
    - Surface traversal and the carved starter shaft are existing behaviors that must remain intact.
  </context>
  <requirements>
    - Assign stratum metadata only to underground solid tiles during world generation.
    - Preserve row `0` surface generation behavior.
    - Preserve starter shaft air tiles after carving.
    - Keep the change minimal and suitable for later tile inspection in DevTools.
    - Do not change ore weighting, rendering, HUD output, or unrelated gameplay logic.
  </requirements>
  <plan>
    1. Prompt-architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect `corebound/game.js` generation helpers and attach `stratumId` and `stratumName` metadata when creating underground solid tiles.
    3. Developer: verify the surface row remains traversable, starter shaft cells remain air, and underground solid tiles expose stratum metadata.
    4. Refactor: perform a brief evidence-backed improvement scan and make no changes unless a low-risk issue is directly supported by the code or verification output.
    5. Remediator: skip unless `agents/work/quickfix.md` contains OPEN items.
  </plan>
  <commands>
    - `timeout 2s python3 -m http.server 8000`
    - `node - <<'NODE'`
  </commands>
  <verification>
    - Surface row tiles outside the starter shaft remain surface/traversable as before.
    - Starter shaft tiles remain air after generation.
    - At least one underground solid tile exposes both `stratumId` and `stratumName`.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if execution cannot be completed.
  </handoff>
</prompt>
