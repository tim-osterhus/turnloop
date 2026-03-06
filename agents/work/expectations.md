# QA Expectations — HUD Stratum Label

## Goal
Display the current stratum name in the HUD and update it when crossing stratum boundaries.

## Expected behavior
- The HUD includes a row labeled `Stratum` with a value element that shows the current stratum name (non-empty during normal play).
- On initial load, the label reflects the player’s starting stratum.
- When the player crosses a stratum boundary (deeper or shallower), the HUD stratum label updates on the next HUD refresh without requiring a reload.
- The displayed name is derived from the game’s existing stratum definitions/lookup so it matches gameplay logic.
- If player depth does not map to a defined stratum (unexpected), the HUD shows a safe fallback (e.g., `Unknown`) rather than throwing.

## Expected file changes
- `corebound/index.html`: Add a HUD row labeled `Stratum` with a value span `id="hud-stratum"` (optional row id/class consistent with existing HUD rows).
- `corebound/game.js`: Cache the `hud-stratum` element and set its `textContent` in the HUD update path based on current player depth/stratum.
- `corebound/style.css` (optional): Minor styling so the new row matches existing HUD formatting and spacing.

## Verification commands
- `rg -n "id=\"hud-stratum\"" corebound/index.html` (expect: HUD value span present)
- `rg -n "hud-stratum|hudStratum|Stratum" corebound/game.js` (expect: element cached + updated in HUD path)
- `rg -n "hud-stratum|stratum" corebound/style.css` (expect: either no changes needed, or style consistent with HUD rows)
- Manual run:
  - `python3 -m http.server`
  - Open `http://localhost:8000/corebound/` and move/dig across a known stratum boundary; confirm the `Stratum` value updates shortly after crossing.

## Non-functional requirements
- No new console errors or uncaught exceptions during play.
- HUD update remains lightweight (reuse existing stratum lookup; no expensive per-frame work beyond current HUD updates).
- UI remains readable and consistent with existing HUD rows (no overlap or broken layout at typical viewport sizes).

## Notes / assumptions
- The game already has named strata and a depth→stratum lookup used for ore/tiles; this change should reuse it.
- HUD refresh already occurs periodically or is triggered by gameplay events; the stratum label should piggyback on that mechanism.
