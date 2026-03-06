# Summary
Add named depth strata with distinct visuals, band-specific ore tables, and HUD zone feedback so descending feels meaningfully different and deeper runs offer clearer payoff.

# Problem statement
The current Corebound prototype has a stable mining loop with fuel pressure, but most underground tiles still look the same and ore progression is limited to a shallow copper/iron mix. As a result, the depth meter changes while the player’s moment-to-moment experience changes very little, which weakens the prompt’s goal of making deeper play feel discoverable and rewarding.

# Scope (In / Out)
In: Fixed depth bands below the surface, distinct solid-tile presentation per band, at least one new deeper ore, band-specific ore weighting, and HUD feedback for the current depth zone.
Out: New controls, enemies, damage systems, save/load, shop expansion, fuel tuning changes, audio, or procedural cave generation beyond the existing grid approach.

# Constraints
- Keep the game playable with the current keyboard controls and existing sell/shop interactions.
- Do not add new dependencies, build steps, or assets outside `corebound/`.
- Limit implementation changes to `corebound/index.html`, `corebound/style.css`, and `corebound/game.js`.

# Requirements
- The world generation SHALL define at least three named depth strata with explicit row ranges that cover every underground row below the surface.
- Each depth stratum SHALL render solid non-ore tiles with a distinct visual treatment so the current layer is recognizable while mining.
- The game SHALL expose at least three total ore types after the change.
- At least one ore type SHALL have a spawn weight of zero in the shallowest underground stratum and a non-zero spawn weight in a deeper stratum.
- Ore generation SHALL use per-stratum weighting rules instead of a single global depth-ratio function.
- The expected cash value of ore generated in the deepest stratum SHALL exceed the expected cash value of ore generated in the shallowest underground stratum.
- The HUD SHALL display the current depth stratum name during play.
- Crossing a stratum boundary SHALL update the HUD stratum label on the next HUD refresh without requiring a page reload or manual action.
- The surface row and starter shaft SHALL remain traversable after the strata changes are applied.
- Existing movement, digging, selling, surface refuel, and upgrade purchase flows SHALL continue to work with no new input bindings.
- The game SHALL continue to run from `corebound/index.html` on a static file server with no console errors during normal play.

# Verification plan
- `python3 -m http.server` from the repo root and open `http://localhost:8000/corebound/`.
- Descend from the surface into each depth band; expected: underground tile presentation changes at the configured boundaries and the HUD shows the matching stratum name.
- Dig and collect ore in the shallowest underground stratum for several pickups; expected: the new deeper-only ore does not appear there.
- Continue into the deepest stratum and collect ore for several pickups; expected: the deeper-only ore appears and average sell value is noticeably higher than near the surface.
- Return to depth `0`, sell inventory, and buy the existing upgrade if affordable; expected: sell, fuel refill, and shop behavior still match the current loop.
- Watch the browser console during play; expected: no runtime errors while moving, digging, crossing strata boundaries, selling, or refueling.

# Assumptions
- Fixed row thresholds are sufficient for this iteration and do not need procedural biome transitions.
- Adding one new deeper ore tier is enough to make the depth bands feel more rewarding without requiring a larger economy rebalance.

# Open questions
- Should the strata breakpoints align with likely fuel turnaround points, or should they be spaced purely for visual pacing?
- Should the HUD show only the current stratum name, or also surface upcoming strata names in the controls or shop UI later?
