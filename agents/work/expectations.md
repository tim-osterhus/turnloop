# QA Expectations — Distinct Stratum Solid Tile Visuals

## Goal
Make solid (non-ore) underground tiles visually distinct per stratum by introducing a per-stratum visual palette used during rendering.

## Expected behavior
- Solid **non-ore** tiles render using a palette that varies by stratum (driven by each tile’s stratum metadata or `getStratumForRow(row)` / `STRATA`).
- When descending across a stratum boundary, the visual appearance (e.g., fill/stroke color) of solid non-ore tiles changes clearly between strata.
- Ore tiles continue to render using their existing ore-specific visuals/colors (no ore color changes).
- Surface row visuals are preserved (surface should not start using the underground stratum palette).

## Expected file changes
- `corebound/game.js`: define a per-stratum solid-tile palette and update tile rendering to use it for solid non-ore tiles only.
- No other Corebound implementation files change.
- Turnloop workflow files may change (task/prompt/status/history/expectations).

## Verification commands
- `git -C corebound diff --name-only`
  - Expected: only `game.js` is changed.
- `git diff --name-only`
  - Expected: only `agents/` workflow files are changed (no unrelated Turnloop code changes).
- `cd corebound && python3 -m http.server 8000`
  - Expected: game loads with no console errors.
  - Expected: dig/move down across at least one stratum boundary; solid non-ore tile visuals change at the boundary.
  - Expected: ore tiles remain visually distinct from solid tiles and match prior ore visuals.
  - Expected: surface row looks the same as before (no unexpected palette-tinting).

## Non-functional requirements
- No HUD updates, ore balance tweaks, controls changes, or unrelated gameplay changes.
- Rendering remains lightweight (simple palette lookup per tile; no expensive per-frame work).

## Notes / assumptions
- The project already has a source of truth for stratum boundaries (`STRATA` + helper) or per-tile stratum metadata.
