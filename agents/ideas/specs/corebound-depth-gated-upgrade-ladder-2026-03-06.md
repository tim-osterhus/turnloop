# Summary
Add a depth-gated upgrade ladder to the surface shop so cash stays meaningful after the first purchase and deeper runs unlock new, immediately useful progression choices.

# Problem statement
The current Corebound prototype has a stable mine-sell-refuel loop, but the economy largely stops mattering after the player buys the single capacity upgrade. Depth bands now change ore value and visuals, yet the game still lacks a longer progression arc that turns those deeper runs into new shop choices. That weakens the prompt’s intended rhythm of descend, return, upgrade, repeat.

# Scope (In / Out)
In:
- Session-based depth milestone tracking for unlock logic.
- A data-driven surface shop with multiple upgrade lines or tiers.
- Immediate gameplay effects for purchased upgrades.
- Clear shop feedback for locked, affordable, and owned states.
Out:
- Save/load or cross-session persistence.
- Enemies, hull damage, combat, or fail-state systems.
- New external assets, dependencies, or build steps.
- Large world-generation rewrites outside what is needed to support unlock milestones.

# Constraints
- Keep the implementation lightweight and self-contained under `corebound/`.
- Preserve the current keyboard controls, digging flow, selling flow, and surface auto-refuel behavior.
- Favor data-driven upgrade definitions over one-off button handlers so the shop can grow without a rewrite.
- Keep the game playable from `corebound/index.html` on a static file server.

# Requirements
- The game SHALL track the deepest depth reached during the current session and keep that value available for shop unlock checks.
- The surface shop SHALL offer at least three upgrade lines with distinct gameplay effects after the change.
- At least one upgrade line SHALL improve trip endurance by increasing fuel capacity or reducing fuel consumption.
- At least one upgrade line SHALL improve mining throughput by increasing inventory capacity, movement speed, or digging effectiveness.
- At least one upgrade line SHALL remain locked until the player reaches an explicit underground depth milestone beyond the starter shaft.
- The implementation SHALL define upgrade data in a structured configuration inside `corebound/game.js` instead of hard-coding each upgrade through separate bespoke state variables and handlers.
- Each upgrade line SHALL expose at least two purchasable levels or tiers so the shop remains relevant after one purchase.
- The shop UI SHALL display each upgrade line’s name, current level, next effect, cost, and current availability state.
- A locked upgrade line SHALL display its unlock condition in the shop before the required depth milestone is reached.
- Buying an available upgrade SHALL apply its stat change immediately without requiring a page reload or a new run.
- Invalid upgrade purchases SHALL remain no-ops when the player lacks cash, is away from the surface, or has already reached the current line’s maximum tier.
- The existing sell, dig, movement, and fuel refill flows SHALL continue to work after the shop expansion.
- Reaching an upgrade unlock milestone and returning to the surface SHALL make the newly unlocked upgrade line available during the same session.
- The game SHALL continue to run from `corebound/index.html` on a static file server with no console errors during normal play.

# Verification plan
- Run `bash agents/scripts/validate_spec.sh agents/ideas/staging/corebound-depth-gated-upgrade-ladder-2026-03-06.md` and expect exit code `0`.
- Run `python3 -m http.server` from the repo root and open `http://localhost:8000/corebound/`; expected: the game loads with a multi-line shop and no startup errors.
- Mine and sell enough ore to buy an early upgrade at the surface; expected: the purchased stat changes immediately and the shop updates the line’s level, cost, and availability state.
- Attempt to buy each upgrade while below the surface and while lacking cash; expected: purchases do nothing and the UI remains disabled or unavailable.
- Before reaching the configured depth milestone, inspect the locked upgrade line in the shop; expected: the lock condition is visible and the line cannot be purchased.
- Reach the unlock milestone, return to the surface, and inspect the same line; expected: the line is now unlocked in the same session and can be purchased if affordable.
- Purchase multiple tiers from at least one upgrade line; expected: the line remains relevant beyond the first purchase and the next tier state updates after each buy.
- During play, verify digging, selling, fuel drain, low-fuel warning, and surface auto-refuel still behave as before; expected: the expanded shop does not break the existing loop.

# Assumptions
- Session-only depth milestone tracking is acceptable for this iteration and does not require persistence.
- The current HUD/shop layout can be extended to show multiple upgrade lines without a larger UI redesign.
- Simple numeric tuning for costs and tier effects is sufficient as long as the progression remains readable and testable.

# Open questions
- Which third upgrade line best fits the current game: movement speed, dig efficiency, or a fuel-efficiency discount on digging and movement?
- Should unlock milestones align with named strata boundaries such as `Mid Depths`, or use fixed numeric depth thresholds that can change independently of strata labels?
- Should every upgrade line use the same number of tiers, or should some lines intentionally cap earlier for balance?
