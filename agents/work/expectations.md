# QA Expectations

## Goal
Charge fuel for successful digs and prevent digging when fuel is empty.

## Expected behavior
- If `state.fuel` is 0 or less, digging does not remove tiles and does not change fuel.
- Each successful dig (tile removed to air) reduces fuel by `FUEL_DIG_COST` (expected 8) and clamps fuel within `0..FUEL_MAX`.
- Failed digs (air tile, out of bounds, or inventory-full ore) do not consume fuel.

## Expected file changes
- corebound/game.js: `digAdjacentTile` updated with an early fuel check and fuel decrement on successful dig.

## Verification commands
- `python3 -m http.server`

## Non-functional requirements
- No changes to movement drain or surface refuel behavior.

## Notes / assumptions
- Manual verification in browser is required to observe fuel decrement and dig lockout at 0.
