# Summary
Add a fuel system that drains during movement and digging, refills at the surface, and provides clear HUD feedback so the core loop gains urgency and a reason to return.

# Problem statement
The current loop has no pressure beyond inventory capacity, so going deeper does not add meaningful tension or a stronger return-to-surface incentive. A simple, readable resource constraint can make depth feel riskier without destabilizing gameplay.

# Scope (In / Out)
In: Fuel resource tracked in game state, drain on movement/digging, surface refuel behavior, HUD display + low-fuel warning, and a controls note describing refuel.
Out: New art assets, new ore types, new tiles, save/load, additional upgrades, or combat/damage systems.

# Constraints
- Keep the game fully playable with keyboard-only input and the existing controls.
- Do not add new dependencies or build steps.
- Touch only `corebound/index.html`, `corebound/style.css`, and `corebound/game.js`.

# Requirements
- The game SHALL track a `fuel` value with a configurable maximum and initialize it to full at session start.
- The implementation SHALL define default tuning values: `FUEL_MAX = 100`, `FUEL_MOVE_RATE = 6` per second, `FUEL_DIG_COST = 8` per dig, `FUEL_LOW_THRESHOLD = 20`, and `FUEL_EMPTY_SPEED_MULT = 0.6`.
- Movement input SHALL reduce fuel by `FUEL_MOVE_RATE * deltaSeconds` only while the player is actively moving.
- Digging SHALL reduce fuel by `FUEL_DIG_COST` when a dig action succeeds.
- Fuel SHALL remain within the inclusive range `0..FUEL_MAX`.
- When fuel reaches `0`, digging SHALL be disabled until fuel is restored.
- When fuel reaches `0`, player movement speed SHALL be multiplied by `FUEL_EMPTY_SPEED_MULT`.
- At depth `0`, fuel SHALL refill automatically to `FUEL_MAX` without player input.
- The HUD SHALL display current fuel and max fuel in a dedicated row.
- The HUD SHALL present a visible low-fuel warning state at or below `FUEL_LOW_THRESHOLD`.
- The controls panel SHALL include a line indicating that fuel refills at the surface.

# Verification plan
- `python3 -m http.server` and open `http://localhost:8000/corebound/`.
- Move and dig for ~10 seconds; expected: fuel value decreases while moving/digging and remains steady while idle.
- Drain fuel to 0; expected: digging no longer removes tiles and movement speed is visibly slower.
- Return to depth 0; expected: fuel refills to max and low-fuel warning clears.
- Confirm the HUD shows a fuel row and the controls list includes a refuel-at-surface note.

# Assumptions
- Fuel drain only needs to apply during active movement/digging and does not need to penalize idle time.
- Surface refuel can be instantaneous on reaching depth 0 without additional UI.

# Open questions
- Should fuel drain scale with depth to increase tension further, or stay constant for simplicity?
- Is the chosen tuning set (`FUEL_MOVE_RATE`, `FUEL_DIG_COST`) too punishing or too lenient after a short playtest?
