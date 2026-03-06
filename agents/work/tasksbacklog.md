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
