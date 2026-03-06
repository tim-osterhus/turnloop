## 2026-03-06 — Surface Auto-Refuel
Goal: Automatically refill fuel to max at the surface.
Scope:
- In: When depth is 0, set fuel to `FUEL_MAX` and keep the HUD in sync.
- Out: Additional UI changes or new upgrades.
Files to touch:
- corebound/game.js
Steps:
1. In the main tick or HUD update path, detect `depth === 0` and set `state.fuel = FUEL_MAX` (clamped).
2. Ensure refuel happens without input and never exceeds `FUEL_MAX`.
Acceptance:
- After draining fuel, returning to depth 0 instantly refills to `100 / 100`.
- The Fuel HUD row reflects the refilled value.
Verification commands:
- `python3 -m http.server` — Expected: fuel refills to max on reaching depth 0.

Prompt: agents/work/prompts/008-surface-auto-refuel.md
