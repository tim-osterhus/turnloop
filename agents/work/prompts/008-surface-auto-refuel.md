<prompt id="008-surface-auto-refuel" task="Surface Auto-Refuel">
  <objective>
    Automatically refill fuel to max when the player is at depth 0, keeping the Fuel HUD synchronized without requiring any input.
  </objective>
  <context>
    - Corebound game code lives in `corebound/`.
    - Task scope is limited to auto-refuel at surface; no new UI or upgrades.
    - Target file: `corebound/game.js`.
  </context>
  <requirements>
    - When `depth === 0`, set `state.fuel` to `FUEL_MAX` (clamped).
    - Refuel happens automatically without input and never exceeds `FUEL_MAX`.
    - Fuel HUD row must reflect the refilled value.
    - Keep changes minimal and reviewable.
  </requirements>
  <plan>
    1. Developer: Locate the main tick or HUD update path in `corebound/game.js` and insert a surface refuel check (depth 0) that clamps fuel to `FUEL_MAX`.
    2. Developer: Confirm Fuel HUD reads `state.fuel` so the refuel is reflected without extra UI changes.
    3. Refactor: Quick scan for low-risk cleanups related to the change; skip if unnecessary.
    4. Remediator: If `agents/work/quickfix.md` has OPEN items, address only those.
  </plan>
  <commands>
    - `python3 -m http.server`
  </commands>
  <verification>
    - After draining fuel, returning to depth 0 refills instantly to `100 / 100`.
    - Fuel HUD shows the refilled value on reaching depth 0.
  </verification>
  <handoff>
    - Prepend a history log entry to `agents/historylog.md` with summary, files, commands, decisions, follow-ups, and this prompt path.
  </handoff>
</prompt>
