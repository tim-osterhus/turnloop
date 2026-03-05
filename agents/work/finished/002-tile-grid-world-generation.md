<prompt id="002-tile-grid-world-generation" task="Tile Grid + World Generation">
  <objective>
    Add a tile-based world to the Corebound canvas game with a visible surface row and solid tiles beneath it, a starter shaft at the spawn column, collision blocking against solid tiles, and a depth HUD that updates based on the player’s tile Y position.
  </objective>
  <context>
    - Repo is Turnloop; Corebound game lives in `corebound/`.
    - Keep changes minimal, within the scope of the task.
    - Do not add digging, ore collection, inventory, selling, or upgrades.
    - Starter shaft is required to allow initial downward movement.
    - Stay within `turnloop/` only.
  </context>
  <requirements>
    - Add grid constants (tile size, world width/height) and a world-generation function.
    - Surface row at depth 0; solid tiles below.
    - Carve a starter shaft at spawn location.
    - Render tiles with distinct colors for air/surface and solid blocks.
    - Block movement into solid tiles and update depth HUD from player tile Y coordinate.
  </requirements>
  <plan>
    1. Developer: Implement world grid constants, generation, starter shaft, tile rendering, collision checks, and depth HUD updates in `corebound/` files.
    2. Refactor: Quick scan for low-risk cleanup; only change if needed.
    3. Remediator: If `agents/work/quickfix.md` has OPEN items, address only those.
  </plan>
  <commands>
    - python3 -m http.server
  </commands>
  <verification>
    - Surface row is visible with solid tiles beneath it.
    - Player cannot move into solid tiles and can move within the starter shaft.
    - Depth HUD increases as the player moves downward in the shaft.
  </verification>
  <handoff>
    - Prepend a history log entry in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with the required marker when done.
  </handoff>
</prompt>
