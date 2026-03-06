# QA Expectations

## Goal
Drain fuel during active movement and slow the player when fuel is empty.

## Expected behavior
- Fuel decreases by `FUEL_MOVE_RATE * deltaSeconds` only while movement input results in movement (not blocked by collisions).
- Fuel does not decrease while idle or when movement input is fully blocked.
- Fuel is clamped to `0..FUEL_MAX` whenever it changes.
- When fuel is `0` (or less), movement speed is multiplied by `FUEL_EMPTY_SPEED_MULT` before applying movement deltas.

## Expected file changes
- `corebound/game.js` updated to add a fuel clamp helper and to apply movement fuel drain + empty-speed multiplier.

## Verification commands
- `python3 -m http.server` (manual): confirm fuel drains while moving, holds while idle, and speed slows at 0 fuel.

## Non-functional requirements
- No changes to dig fuel costs, surface refuel behavior, or low-fuel warning states.

## Notes / assumptions
- “Actively moving” means non-zero input and at least one axis step applied (not fully blocked).
