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
