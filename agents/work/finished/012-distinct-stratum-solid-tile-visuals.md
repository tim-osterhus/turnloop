<prompt id="012-distinct-stratum-solid-tile-visuals" task="Distinct stratum solid tile visuals">
  <objective>
    Give solid non-ore underground tiles a distinct visual color per stratum so descending across stratum boundaries is visible in the terrain, while preserving ore colors and the existing surface row appearance.
  </objective>
  <context>
    - Repo context for this task is the Corebound prototype in `corebound/`.
    - Scope is limited to `corebound/game.js`.
    - `STRATA` and `getStratumForRow(row)` already exist, and generated solid tiles already carry `stratumId` metadata through `getStratumTileMetadata(row)`.
    - `drawWorld(cameraX, cameraY)` currently renders ore tiles by `ORE_TYPES[oreId].color`, the surface row by `TILE_COLORS.surface`, and every other solid tile by a single `TILE_COLORS.solid`.
    - Acceptance requires visible solid-tile color changes at stratum boundaries without changing ore visuals or the surface row.
  </context>
  <requirements>
    - Define a per-stratum palette for solid non-ore tiles keyed by stratum id.
    - Update rendering so solid tiles use the palette derived from the tile's stratum metadata or row stratum.
    - Keep ore tile rendering driven by ore color and leave surface row rendering unchanged.
    - Keep scope tight: no ore balance, HUD, controls, world generation shape, or non-visual gameplay changes.
  </requirements>
  <plan>
    1. Prompt-architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect the existing stratum metadata and world rendering flow in `corebound/game.js`.
    3. Developer: add a per-stratum solid-tile palette and route non-ore solid rendering through a helper that resolves the correct stratum color.
    4. Developer: run the prompt commands to verify surface rendering remains unchanged and each underground stratum resolves to a distinct solid color.
    5. Refactor: perform a brief evidence-backed improvement scan and make no changes unless implementation or verification surfaces a low-risk issue.
    6. Remediator: skip because `agents/work/quickfix.md` has no OPEN items.
  </plan>
  <commands>
    - `timeout 2s python3 -m http.server 8000`
    - `node - <<'NODE'`
  </commands>
  <verification>
    - Surface tiles still render with `TILE_COLORS.surface`.
    - Ore tiles still render with `ORE_TYPES[oreId].color`.
    - Each configured underground stratum resolves to a non-ore solid tile color, and the colors are distinct across strata.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if execution cannot be completed.
  </handoff>
</prompt>
