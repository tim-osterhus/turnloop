# QA Expectations — Apply Strata Metadata in World Generation

## Goal
Tag underground tiles with stratum metadata during world generation, while preserving surface traversal and starter shaft openness.

## Expected behavior
- World generation assigns stratum metadata to **underground solid tiles** (not surface row, not air), visible in DevTools when inspecting tile objects.
- Surface row remains traversable (no new solids/regressions on the surface row).
- Starter shaft remains open from the surface into the underground (shaft tiles are air/traversable, not solid).
- Stratum tagging uses the existing depth→stratum resolver (no duplicate boundary logic).

## Expected file changes
- `corebound/game.js`: assign stratum metadata on underground solid tiles during generation.
- No other implementation files change.

## Verification commands
- `cd corebound && python3 -m http.server`
  - Expected: page loads with no console errors.
  - Expected: you can move down the starter shaft from the surface.
  - Expected: inspecting an underground solid tile shows a populated stratum identifier (e.g., `stratumId` or `stratumName`).
  - Expected: inspecting a surface tile and a starter-shaft air tile shows they are not treated as solid underground tiles (no stratum metadata required there).
- `git diff --name-only`
  - Expected: only `corebound/game.js` is changed in the implementation.

## Non-functional requirements
- No changes to ore weighting, tile visuals, HUD, controls, or gameplay tuning beyond adding metadata.
- No noticeable slowdown in world generation (stratum lookup should be O(1) per tile/row).
- Metadata field is stable and easy to inspect for later rendering/ore selection work.

## Notes / assumptions
- Exact property name may differ (`stratumId` preferred); requirement is that an underground solid tile exposes a stable, inspectable stratum identifier/value.
