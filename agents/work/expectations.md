# QA Expectations — Per-Stratum Ore Tables + New Ore

## Goal
Replace global depth-ratio ore generation with explicit per-stratum ore weight tables and add a deeper-only ore type, while keeping the rest of the mining loop unchanged.

## Expected behavior
- `corebound/game.js` defines at least **three** ore types.
- One ore type is "deeper-only" (its per-stratum weight is `0` in the shallowest stratum and **non-zero** in deeper strata).
- Ore generation selects ores using the current row’s stratum table (driven by `getStratumForRow(row)` / `STRATA`), not any global depth-ratio logic.
- Any ore seeding/guarantee logic does **not** place the deeper-only ore into the shallowest stratum.
- After world generation / several digs:
  - Shallowest stratum contains **0** instances of the deeper-only ore.
  - Deepest stratum contains **>= 1** instance of the deeper-only ore.
- The deepest stratum’s expected weighted ore value exceeds the shallowest stratum’s expected weighted ore value (based on per-stratum weights and ore `value`).

## Expected file changes
- `corebound/game.js`: add new ore definition, add per-stratum ore weight tables, update ore selection/generation to use stratum weights.
- No other implementation files change.

## Verification commands
- `git diff --name-only`
  - Expected: only `corebound/game.js` is changed.
- `cd corebound && python3 -m http.server 8000`
  - Expected: game loads with no console errors.
  - Expected: mine near the surface and in the deepest stratum; the deeper-only ore appears only in deeper strata.
  - Expected: average sell value from deep mining exceeds near-surface mining (over a small sample).
- (Optional, if a repo-provided JS/Node harness exists): run it to count ore-by-stratum and compute expected values.

## Non-functional requirements
- No HUD layout, tile rendering/styling, controls, or unrelated gameplay changes.
- Ore selection remains fast (no per-tile expensive work beyond a small weighted pick).

## Notes / assumptions
- `STRATA` and `getStratumForRow(row)` already exist and are the source of truth for stratum boundaries.
