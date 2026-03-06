## 2026-03-06 — Per-Stratum Ore Tables + New Ore
Prompt: `agents/work/prompts/011-per-stratum-ore-tables-new-ore.md`

Goal: Replace global depth weighting with per-stratum ore tables and add a deeper-only ore type.
Scope:
- In: Add at least one new ore type (3+ total), define per-stratum ore weight tables, and generate ore using stratum weights.
- Out: HUD changes, tile visual styling, or new controls.
Files to touch:
- corebound/game.js
Steps:
1. Add a new ore definition (id, label, color, value) so the total ore types are at least three.
2. Define ore weight tables per stratum with a deeper-only ore weight set to `0` in the shallowest stratum and non-zero in deeper strata.
3. Update ore generation to use the current stratum’s weight table instead of any global depth ratio.
4. Tune weights/values so the deepest stratum’s expected ore value exceeds the shallowest stratum’s.
Acceptance:
- The deeper-only ore never appears in the shallowest stratum after several digs.
- The deeper-only ore appears in the deepest stratum and average sell value is higher than near the surface.
Verification commands:
- `python3 -m http.server` — Expected: manual mining confirms deeper-only ore appears only in deeper strata and average sell value is higher.
