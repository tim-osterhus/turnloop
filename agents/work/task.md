## 2026-03-06 — Distinct Stratum Solid Tile Visuals
Prompt: agents/work/prompts/012-distinct-stratum-solid-tile-visuals.md
Goal: Make solid non-ore tiles visually distinct per stratum.
Scope:
- In: Add a per-stratum visual palette and render solid tiles using the palette.
- Out: Ore color changes or HUD updates.
Files to touch:
- corebound/game.js
Steps:
1. Define a per-stratum palette (e.g., base colors) for solid non-ore tiles.
2. Update tile rendering to use the palette based on each tile’s stratum metadata while keeping ore tiles rendered by ore color.
3. Preserve the existing surface row visuals.
Acceptance:
- Solid tile visuals change when crossing strata boundaries.
- Ore tiles remain visually distinct from solid tiles.
Verification commands:
- `python3 -m http.server` — Expected: descending shows solid tile colors change at strata boundaries.
