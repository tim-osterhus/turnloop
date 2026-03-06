# QA Expectations — 2026-03-06 Surface Auto-Refuel

## Goal
Automatically refill fuel to max at the surface (depth 0) and keep the HUD in sync.

## Expected behavior
- When the player reaches depth 0, fuel is immediately set to `FUEL_MAX` without user input.
- Fuel never exceeds `FUEL_MAX` (clamped).
- The Fuel HUD row updates to show `100 / 100` (or `FUEL_MAX / FUEL_MAX`) upon reaching depth 0 after fuel was drained.

## Expected file changes
- `corebound/game.js` updated to set fuel to `FUEL_MAX` when `depth === 0` in the main tick/HUD update flow.
- No other files are required by scope.

## Verification commands
- `python3 -m http.server`

## Non-functional requirements
- No new UI elements or upgrades added.
- Refuel logic runs automatically without input and does not create side effects beyond fuel state/HUD sync.

## Notes / assumptions
- `FUEL_MAX` is defined and equals 100 as in current HUD display.
- Manual browser interaction will be used to validate the behavior after starting the server.
