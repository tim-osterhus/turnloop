# QA Expectations — Low-Fuel Warning State

## Goal
Highlight low fuel in the HUD when at or below the threshold.

## Expected behavior
- Fuel HUD row gains a visible warning style when `fuel <= FUEL_LOW_THRESHOLD` (threshold is 20 per task acceptance).
- Warning style clears when `fuel > FUEL_LOW_THRESHOLD` (e.g., after refuel).
- Other HUD rows remain unchanged.

## Expected file changes
- `corebound/style.css`: add a warning style targeting the Fuel row when a class like `.is-low` (or equivalent) is present.
- `corebound/game.js`: cache the Fuel row element and toggle the warning class in `updateHud` based on the fuel threshold.

## Verification commands
- `python3 -m http.server`
  - Expected: in the running game, Fuel row styling switches on at 20 or below and clears after refuel above 20.

## Non-functional requirements
- No changes to fuel drain/refuel tuning or gameplay balance.
- Warning logic is simple and deterministic; no animation or heavy DOM work required.

## Notes / assumptions
- `FUEL_LOW_THRESHOLD` is defined and equals 20 in `corebound/game.js`.
- Manual verification is acceptable for this UI-only change.
