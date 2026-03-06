<prompt id="007-fuel-constants-hud" task="Fuel constants and HUD binding">
  <objective>
    Introduce fuel tuning constants, initialize session fuel state, and wire the Fuel HUD row to display current fuel versus max each tick.
  </objective>
  <context>
    - Repo has a playable Corebound prototype in `corebound/`.
    - Task scope is limited to constants, state init, and HUD display only.
    - Avoid adding fuel drain, digging costs, refuel behavior, or warnings.
  </context>
  <requirements>
    - Define `FUEL_MAX`, `FUEL_MOVE_RATE`, `FUEL_DIG_COST`, `FUEL_LOW_THRESHOLD`, and `FUEL_EMPTY_SPEED_MULT` near other tuning constants in `corebound/game.js`.
    - Initialize `state.fuel` to `FUEL_MAX` when a session starts.
    - Cache the `hud-fuel` element and update the HUD each tick to render `fuel / FUEL_MAX`.
    - Keep changes minimal and within `corebound/game.js`.
  </requirements>
  <plan>
    1. Prompt-architect: produce this prompt and link it in the task file.
    2. Developer: implement constants, state init, and HUD binding with minimal diffs.
    3. Refactor: quick scan for low-risk cleanup; note if none.
    4. Remediator: only act if `agents/work/quickfix.md` has OPEN items.
  </plan>
  <commands>
    - `python3 -m http.server`
  </commands>
  <verification>
    - On load, the Fuel HUD row shows `100 / 100`.
    - No console errors appear during HUD updates.
  </verification>
  <handoff>
    - Prepend a history log entry with summary, files, commands, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when done.
  </handoff>
</prompt>
