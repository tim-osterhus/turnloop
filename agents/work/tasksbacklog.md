## 2026-03-06 — Dig Fuel Cost + Empty Lockout
Goal: Charge fuel for successful digs and prevent digging when fuel is empty.
Scope:
- In: Block digging when fuel is empty and subtract `FUEL_DIG_COST` on successful tile removal, clamped to `0..FUEL_MAX`.
- Out: Movement drain or surface refuel behavior.
Files to touch:
- corebound/game.js
Steps:
1. Add an early return in `digAdjacentTile` when `state.fuel` is `0` (or less).
2. After a dig succeeds (tile becomes air), subtract `FUEL_DIG_COST` and clamp the result.
3. Ensure failed digs (air tile, bounds guard, or inventory-full ore) do not consume fuel.
Acceptance:
- Each successful dig reduces fuel by 8.
- At fuel 0, digging no longer removes tiles.
Verification commands:
- `python3 -m http.server` — Expected: fuel drops per successful dig and digging stops at 0.

## 2026-03-06 — Surface Auto-Refuel
Goal: Automatically refill fuel to max at the surface.
Scope:
- In: When depth is 0, set fuel to `FUEL_MAX` and keep the HUD in sync.
- Out: Additional UI changes or new upgrades.
Files to touch:
- corebound/game.js
Steps:
1. In the main tick or HUD update path, detect `depth === 0` and set `state.fuel = FUEL_MAX` (clamped).
2. Ensure refuel happens without input and never exceeds `FUEL_MAX`.
Acceptance:
- After draining fuel, returning to depth 0 instantly refills to `100 / 100`.
- The Fuel HUD row reflects the refilled value.
Verification commands:
- `python3 -m http.server` — Expected: fuel refills to max on reaching depth 0.

## 2026-03-06 — Low-Fuel Warning State
Goal: Highlight low fuel in the HUD when at or below the threshold.
Scope:
- In: Add a warning style in CSS and toggle it when `fuel <= FUEL_LOW_THRESHOLD`.
- Out: Changes to fuel drain or refuel tuning.
Files to touch:
- corebound/style.css
- corebound/game.js
Steps:
1. Add a CSS warning style for the Fuel row (for example, `.hud-row.is-low .hud-value`).
2. Cache the Fuel row element and toggle the warning class in `updateHud` when fuel is at or below `FUEL_LOW_THRESHOLD`.
3. Ensure the warning clears when fuel rises above the threshold (such as after refuel).
Acceptance:
- The Fuel row visually changes when fuel falls to 20 or below.
- The warning clears when fuel refills above 20.
Verification commands:
- `python3 -m http.server` — Expected: low-fuel warning activates at <=20 and clears after refuel.
