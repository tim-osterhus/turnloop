## 2026-03-06 — Dig Fuel Cost + Empty Lockout
Prompt: agents/work/prompts/008-dig-fuel-cost-lockout.md
Goal: Charge fuel for successful digs and prevent digging when fuel is empty.
Scope:
- In: Block digging when fuel is empty and subtract `FUEL_DIG_COST` on successful tile removal, clamped to `0..FUEL_MAX`.
- Out: Movement drain or surface refuel behavior.
Files to touch:
- corebound/game.js
Steps:
1. Add an early return in `digAdjacentTile` when `state.fuel` is `0` (or less).
2. After a dig succeeds (tile becomes air), subtract `FUEL_DIG_COST` and clamp the result.
3. Ensure failed digs (air tile, bounds guard, or inventory-full ore) do not consume fuel.
Acceptance:
- Each successful dig reduces fuel by 8.
- At fuel 0, digging no longer removes tiles.
Verification commands:
- `python3 -m http.server` — Expected: fuel drops per successful dig and digging stops at 0.
