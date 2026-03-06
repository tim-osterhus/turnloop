<prompt id="008-dig-fuel-cost-lockout" task="Dig fuel cost + empty lockout">
  <objective>
    Implement fuel consumption for successful digs and block digging when fuel is empty, limited to the scope in the current task.
  </objective>
  <context>
    - Repo: Turnloop, game code in `corebound/`.
    - Task scope: only digging fuel cost and empty lockout; do not change movement drain or surface refuel.
    - Target file: `corebound/game.js`.
    - Fuel constants exist (see prior fuel HUD work).
  </context>
  <requirements>
    - Add an early return in `digAdjacentTile` when `state.fuel` is <= 0.
    - On successful dig (tile becomes air), subtract `FUEL_DIG_COST` and clamp to `0..FUEL_MAX`.
    - Failed digs (air tile, bounds guard, or inventory-full ore) must not consume fuel.
  </requirements>
  <plan>
    1. Developer: update `digAdjacentTile` to block when fuel is empty and apply fuel cost only on successful dig.
    2. Refactor: quick scan for low-risk cleanup, no behavior changes unless needed.
    3. Remediator: address any OPEN items in `agents/work/quickfix.md` if present.
  </plan>
  <commands>
    - `python3 -m http.server`
  </commands>
  <verification>
    - Each successful dig reduces fuel by 8.
    - At fuel 0, digging no longer removes tiles.
  </verification>
  <handoff>
    - Update `agents/historylog.md` with summary, files touched, commands, decisions, follow-ups, prompt path.
    - Set `agents/orchestrate_status.md` to `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
