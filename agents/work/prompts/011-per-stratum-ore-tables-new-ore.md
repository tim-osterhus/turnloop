<prompt id="011-per-stratum-ore-tables-new-ore" task="Per-stratum ore tables and new ore">
  <objective>
    Replace the current depth-ratio ore generation with explicit ore weight tables per stratum and introduce a deeper-only ore so underground rewards scale by stratum, while keeping the rest of the mining loop unchanged.
  </objective>
  <context>
    - Repo context for this task is the Corebound prototype in `corebound/`.
    - Scope is limited to `corebound/game.js`.
    - `STRATA` and `getStratumForRow(row)` already exist and should drive ore selection.
    - Current ore generation uses a global depth ratio in `pickOreForDepth(row)` and guarantees at least one spawn per ore type via `seedOres(tiles)`.
    - Acceptance requires the deeper-only ore to be absent from the shallowest stratum and present in the deepest stratum, with deeper average ore value exceeding the shallowest stratum.
  </context>
  <requirements>
    - Add at least one new ore type so the total ore types are three or more.
    - Define ore weight tables per stratum, with the deeper-only ore weight set to `0` in the shallowest stratum and non-zero in deeper strata.
    - Update world ore generation to use the current row's stratum weight table instead of any global depth-ratio logic.
    - Tune ore values and/or weights so the deepest stratum's expected ore value is greater than the shallowest stratum's.
    - Keep scope tight: no HUD layout, rendering style, controls, or non-ore gameplay changes.
  </requirements>
  <plan>
    1. Prompt-architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect the existing ore definitions and generation helpers in `corebound/game.js`, then add a new ore and per-stratum weight tables keyed by stratum id.
    3. Developer: replace depth-ratio ore selection with weighted per-stratum selection while preserving the existing world-generation flow and ore seeding guarantees.
    4. Developer: run the prompt commands to verify the shallowest stratum excludes the deeper-only ore, the deepest stratum includes it, and deeper expected ore value is higher.
    5. Refactor: perform a brief evidence-backed improvement scan and make no changes unless verification or code inspection surfaces a low-risk issue.
    6. Remediator: skip unless `agents/work/quickfix.md` contains OPEN items.
  </plan>
  <commands>
    - `timeout 2s python3 -m http.server 8000`
    - `node - <<'NODE'`
  </commands>
  <verification>
    - The shallowest stratum's weight table assigns `0` to the deeper-only ore and generated shallow solid tiles never receive that ore in the verification harness.
    - The deepest stratum's weight table assigns a non-zero weight to the deeper-only ore and generated deep solid tiles include at least one instance in the verification harness.
    - The deepest stratum's expected weighted ore value exceeds the shallowest stratum's expected weighted ore value.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if execution cannot be completed.
  </handoff>
</prompt>
