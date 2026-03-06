# Expectations

## Goal
Introduce fuel tuning constants, initialize fuel state, and bind Fuel HUD updates.

## Expected behavior
- On load, the Fuel HUD row shows `100 / 100`.
- Fuel HUD value reflects `state.fuel / FUEL_MAX` each tick.
- No console errors occur during HUD updates.

## Expected file changes
- `corebound/game.js`: add `FUEL_*` constants near other tuning constants, initialize `state.fuel` to `FUEL_MAX`, cache `hud-fuel`, and update `updateHud` to render fuel.

## Verification commands
- `python3 -m http.server` (then load the game in a browser and confirm Fuel row renders `100 / 100` on load and updates with state.)

## Non-functional requirements
- No new fuel drain, digging cost, refuel logic, or warning states.

## Notes / assumptions
- Fuel HUD element has id `hud-fuel` and is present in the DOM on load.
