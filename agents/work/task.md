## 2026-03-06 — Fuel Constants + HUD Binding
Goal: Introduce fuel tuning constants, state, and HUD updates.
Prompt: `agents/work/prompts/007-fuel-constants-hud.md`
Scope:
- In: Add `FUEL_*` constants, initialize `state.fuel`, and populate the Fuel HUD value each tick.
- Out: Fuel drain, digging costs, refuel behavior, or warning states.
Files to touch:
- corebound/game.js
Steps:
1. Define `FUEL_MAX`, `FUEL_MOVE_RATE`, `FUEL_DIG_COST`, `FUEL_LOW_THRESHOLD`, and `FUEL_EMPTY_SPEED_MULT` near other tuning constants.
2. Initialize `state.fuel` to `FUEL_MAX` when the session starts.
3. Cache the `hud-fuel` element and update `updateHud` to render `fuel / FUEL_MAX` each tick.
Acceptance:
- On load, the Fuel HUD row shows `100 / 100`.
- No console errors appear during HUD updates.
Verification commands:
- `python3 -m http.server` — Expected: Fuel row renders `100 / 100` on load and stays in sync with state.
