<prompt id="001-digging-inventory-ore" task="Digging + Inventory + Ore Types">
  <objective>
    Implement digging that removes an adjacent solid tile in the last movement direction, spawns at least two ore types, and collects ore into a capped inventory with HUD updates in the Corebound prototype.
  </objective>
  <context>
    - Repo root is turnloop; work only within this repo.
    - Corebound game code lives in `corebound/` and is currently minimal.
    - Dig uses Space and targets the adjacent tile in the last movement direction.
    - If inventory is full, ore tiles cannot be collected.
    - No selling, upgrades, or depth-weighted ore distribution in this task.
  </context>
  <requirements>
    - Define at least two ore types (id, color, value) and store ore metadata on tiles.
    - Add inventory state with fixed capacity and per-ore counts for the HUD.
    - Implement Space-bar dig to remove adjacent solid tiles; collect ore if capacity allows.
    - Update HUD to show inventory usage and a cash placeholder during digging.
  </requirements>
  <plan>
    1. Developer: Add ore type definitions and extend tiles to hold ore metadata.
    2. Developer: Implement inventory state, capacity logic, and Space-bar dig action.
    3. Developer: Update HUD for inventory usage, ore counts, and cash placeholder.
    4. Refactor: Low-risk scan for cleanup; apply minimal improvements if needed.
    5. Remediator: Address any OPEN items in `agents/work/quickfix.md` only.
  </plan>
  <commands>
    - `python -m http.server`
  </commands>
  <verification>
    - Space removes an adjacent solid tile in the last movement direction.
    - At least two ore types appear and can be collected.
    - Inventory stops collecting ore when capacity is reached.
  </verification>
  <handoff>
    - Prepend history entry in `agents/historylog.md` with summary, files, commands, decisions, follow-ups, and prompt path.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` or `### BLOCKED`.
  </handoff>
</prompt>
