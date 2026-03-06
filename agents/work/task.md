## 2026-03-06 — Apply Strata Metadata in World Generation
Goal: Tag underground tiles with stratum metadata while preserving surface and starter shaft traversal.
Scope:
- In: Assign a stratum id/name to underground tiles during world generation; keep surface row and starter shaft behavior intact.
- Out: Ore weighting updates, tile visual changes, or HUD updates.
Files to touch:
- corebound/game.js
Steps:
1. During world generation, resolve the stratum for each underground row and store `stratumId` (or equivalent) on solid tiles.
2. Keep the surface row generation unchanged and ensure starter shaft carving remains air tiles.
3. Ensure stratum metadata is present on underground tiles for later rendering/ore selection.
Acceptance:
- The surface row remains traversable and the starter shaft is open.
- Underground tiles expose stratum metadata when inspected in DevTools.
Verification commands:
- `python3 -m http.server` — Expected: page loads; you can move down the starter shaft and inspect an underground tile with stratum metadata in DevTools.

Prompt artifact: `agents/work/prompts/010-apply-strata-metadata-world-generation.md`
