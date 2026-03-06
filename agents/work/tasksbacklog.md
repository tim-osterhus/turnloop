# Tasks Backlog

## 2026-03-06 — Multi-Line Surface Shop UI Shell
Goal: Replace the single-upgrade HUD row with a repeatable surface shop list that can show multiple upgrade lines and availability states.
Scope:
- In: Update the HUD/shop markup, render a generated list of upgrade rows, and add baseline locked/available/maxed styling hooks.
- Out: Final stat-effect tuning for specific upgrade lines.
Files to touch:
- corebound/index.html
- corebound/style.css
- corebound/game.js
Steps:
1. Replace the single upgrade row in `corebound/index.html` with a shop container that can host multiple generated lines.
2. Add CSS hooks in `corebound/style.css` for line layout and state styling such as locked, affordable, unaffordable, and maxed.
3. Update `corebound/game.js` to render one shop row per configured upgrade line with name, current level, next effect, cost, and status text placeholders.
4. Keep the shop visible at the surface and ensure startup still succeeds before specific upgrade effects are completed.
Acceptance:
- The shop can render at least three upgrade lines without duplicating hard-coded markup per line.
- Each line has visible fields for level, next effect, cost, and availability state.
- `python3 -m http.server 8000` serves `/corebound/` without startup console errors.
Verification commands:
- `rg -n "hud-shop-list|shop-line|shop-status|shop-level" corebound/index.html corebound/style.css corebound/game.js` — Expected: matches for generated multi-line shop markup/styling/rendering.
- `python3 -m http.server 8000` — Expected: `Serving HTTP on ...`; opening `http://localhost:8000/corebound/` shows the expanded shop UI.

## 2026-03-06 — Cargo Pods Capacity Tiers
Goal: Implement a cargo upgrade line whose purchased tiers immediately increase inventory capacity and keep the shop relevant after the first buy.
Scope:
- In: Define cargo tier values/costs, apply capacity boosts immediately, and update the line’s current/next tier state after each purchase.
- Out: Fuel-capacity tuning or locked depth-gated upgrades.
Files to touch:
- corebound/game.js
Steps:
1. Define the Cargo Pods line’s tier effects and costs inside the shared upgrade data structure.
2. Apply the purchased tier’s inventory-capacity effect immediately when the line is bought.
3. Update the shop row so the current level, next effect, next cost, and maxed state advance correctly after each purchase.
4. Preserve existing ore collection and sell behavior with the higher capacity values.
Acceptance:
- Buying Cargo Pods at the surface raises inventory capacity immediately in the same session.
- A later Cargo Pods tier remains available after the first purchase until the line reaches max tier.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "cargo|capacity|inventory\\.capacity" corebound/game.js` — Expected: matches for tier data and immediate capacity application.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.

## 2026-03-06 — Fuel Tank Endurance Tiers
Goal: Add a second upgrade line that increases trip endurance by raising the player’s fuel capacity while preserving surface auto-refuel behavior.
Scope:
- In: Replace the fixed max-fuel assumption with a derived fuel cap, define tiered fuel upgrades, and keep HUD/refill logic aligned with the upgraded cap.
- Out: New warning systems or changes to ore generation.
Files to touch:
- corebound/game.js
Steps:
1. Introduce a derived max-fuel helper so fuel capacity can change by upgrade tier instead of remaining a fixed constant.
2. Define the Fuel Tank line’s tier effects and costs in the shared upgrade data structure.
3. Apply the purchased fuel-capacity effect immediately and ensure surface auto-refuel fills to the upgraded maximum.
4. Update HUD fuel text and low-fuel checks to use the derived cap consistently.
Acceptance:
- Buying Fuel Tank at the surface increases the current max fuel immediately.
- Returning to the surface refills fuel to the upgraded maximum in the same session.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "getMaxFuel|Fuel Tank|clampFuel|hudFuel" corebound/game.js` — Expected: matches for derived fuel-capacity handling and UI updates.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.

## 2026-03-06 — Depth-Gated Thruster Upgrade Line
Goal: Add a locked third upgrade line that unlocks after reaching Mid Depths and immediately improves mining throughput by increasing movement speed.
Scope:
- In: Define the locked line, gate it on session deepest depth, surface the lock text in the shop, and apply movement-speed boosts on purchase.
- Out: Persistent unlocks across sessions or new strata definitions.
Assumptions: Use the existing `mid-depths` strata boundary as the unlock milestone instead of introducing a separate hard-coded depth number.
Files to touch:
- corebound/game.js
Steps:
1. Add a movement-speed upgrade line with at least two tiers and an unlock rule tied to the Mid Depths entry row.
2. Keep the line locked and non-purchasable until the player reaches the milestone, while showing the unlock condition in the shop.
3. Update deepest-depth tracking during play so returning to the surface in the same session unlocks the line immediately.
4. Apply the purchased movement-speed bonus immediately and advance the row to its next tier or maxed state.
Acceptance:
- Before reaching Mid Depths, the thruster line is locked and shows its unlock condition.
- After reaching Mid Depths and returning to the surface in the same session, the line becomes purchasable if affordable.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "mid-depths|deepestDepth|speed|unlock" corebound/game.js` — Expected: matches for milestone tracking, lock checks, and speed upgrades.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.

## 2026-03-06 — Shop State Hardening + Loop Regression
Goal: Harden invalid purchase paths and confirm the expanded shop does not break selling, digging, movement, fuel drain, or surface auto-refuel.
Scope:
- In: Final purchase guards, disabled-state/button-label polish, and manual regression checks across the existing mine-sell-refuel loop.
- Out: Save/load, combat, fail states, or large UI redesigns.
Files to touch:
- corebound/game.js
- corebound/style.css
Steps:
1. Ensure purchase handlers no-op when the player is below the surface, lacks cash, has not met an unlock condition, or has maxed the selected line.
2. Finalize button labels and row styling for locked, affordable, unaffordable, and maxed states so the UI matches the actual purchase rules.
3. Re-run the mining loop manually to verify digging, ore collection, selling, movement fuel drain, low-fuel warning, and surface auto-refuel still behave correctly with the new upgrade ladder.
4. Fix any shop-state edge cases uncovered during regression without widening scope beyond the upgrade ladder.
Acceptance:
- Invalid purchase attempts are no-ops and the corresponding UI stays disabled or locked.
- The mining/selling/fuel loop still works after the shop expansion with no normal-play console errors.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.
- `python3 -m http.server 8000` — Expected: `Serving HTTP on ...`; manual play at `http://localhost:8000/corebound/` confirms the upgraded shop does not break the existing loop.
