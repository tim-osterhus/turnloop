## 2026-03-06 — Movement Fuel Drain + Empty Speed
Prompt: agents/work/prompts/008-movement-fuel-drain-empty-speed.md
Goal: Drain fuel during active movement and slow the player when empty.
Scope:
- In: Deduct `FUEL_MOVE_RATE * deltaSeconds` while actively moving and apply `FUEL_EMPTY_SPEED_MULT` when fuel is empty, clamping to `0..FUEL_MAX`.
- Out: Dig fuel costs, surface refuel, or low-fuel warning states.
Files to touch:
- corebound/game.js
Steps:
1. Add a helper to clamp fuel updates to `0..FUEL_MAX` and reuse it whenever fuel changes.
2. In `movePlayer`, detect when movement input results in movement and subtract `FUEL_MOVE_RATE * delta` only when moving.
3. Apply `FUEL_EMPTY_SPEED_MULT` to movement speed when `state.fuel` is `0` (or less) before calculating deltas.
Assumptions: "Actively moving" means input direction is non-zero and at least one axis step is applied (not fully blocked by collisions).
Acceptance:
- Holding movement keys for ~10 seconds reduces fuel while movement succeeds.
- Fuel does not decrease while idle.
- At fuel 0, movement speed is visibly slower.
Verification commands:
- `python3 -m http.server` — Expected: fuel drains while moving, holds while idle, and speed slows at 0.
