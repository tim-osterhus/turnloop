## 2026-03-06 — HUD Stratum Label
Goal: Display the current stratum name in the HUD and update it when crossing boundaries.
Scope:
- In: Add a HUD row for stratum label and update HUD logic to show the current stratum name.
- Out: Additional HUD elements or new gameplay systems.
Files to touch:
- corebound/index.html
- corebound/game.js
- corebound/style.css
Steps:
1. Add a HUD row labeled "Stratum" with a value span `id="hud-stratum"` (and optional row id for styling) in `corebound/index.html`.
2. Cache the new HUD element in `corebound/game.js` and update `updateHud` to set the stratum name based on player depth.
3. If needed, adjust `corebound/style.css` to match existing HUD row styles.
Acceptance:
- The HUD shows a stratum name during play.
- Crossing a stratum boundary updates the label on the next HUD refresh without reload.
Verification commands:
- `rg -n "hud-stratum" corebound/index.html` — Expected: the stratum HUD row and value span are present.
- `python3 -m http.server` — Expected: label updates when moving across a boundary.

## 2026-03-06 — Hardening: Stratum Lookup Fallbacks
Goal: Prevent undefined stratum states and keep HUD stable at surface and boundaries.
Scope:
- In: Add safe fallback handling for surface/out-of-range rows and ensure all stratum lookups use it.
- Out: New visuals, ore types, or controls.
Files to touch:
- corebound/game.js
Steps:
1. Extend the stratum lookup helper to return a safe fallback for surface rows (e.g., "Surface") and clamp out-of-range rows.
2. Use the safe helper everywhere strata are referenced (HUD, ore generation, rendering).
3. Confirm no undefined stratum values propagate to UI or gameplay logic.
Acceptance:
- The HUD shows "Surface" at depth 0 and a named stratum below without blank or undefined values.
- No console errors occur while moving across strata boundaries or at world edges.
Verification commands:
- `python3 -m http.server` — Expected: page loads with no console errors at surface or when crossing strata boundaries.
