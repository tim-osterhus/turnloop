# Expectations — 2026-03-06 Hardening: Stratum Lookup Fallbacks

## Goal
Prevent undefined stratum states and keep the Stratum HUD stable at the surface and at boundaries/out-of-range rows.

## Expected behavior
- At depth 0 / surface rows, the stratum label resolves to a safe fallback (e.g., `Surface`) and never renders blank/`undefined`.
- For out-of-range row inputs (negative rows, rows beyond world bounds), stratum lookup clamps safely and returns a valid stratum object/name.
- All strata references (HUD, ore generation, rendering) use the safe lookup helper; no direct indexing that can yield `undefined`.
- Moving across stratum boundaries and at world edges produces no console errors related to stratum lookup.

## Expected file changes
- `corebound/game.js`: extend/adjust stratum lookup helper and refactor call sites to use it everywhere strata are referenced.
- No other files are expected to change.

## Verification commands
- `python3 -m http.server` (from repo root)
  - Open the game in a browser.
  - Expected: Stratum HUD shows `Surface` at depth 0 and a named stratum below; no blank/undefined values.
  - Expected: no console errors while moving across strata boundaries or at world edges.

## Non-functional requirements
- No new console warnings/errors introduced by the change.
- Behavior is backward-compatible aside from making previously-undefined stratum states deterministic and safe.

## Notes / assumptions
- “Surface” label is acceptable per task acceptance criteria (exact casing may vary but must be human-readable and non-empty).
- If ore generation depends on stratum metadata, the fallback must provide safe defaults so gameplay does not crash at boundaries.
