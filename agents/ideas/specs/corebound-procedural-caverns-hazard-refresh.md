# Corebound — Procedural Caverns And Hazard Pressure Refresh

## Summary
Refresh Corebound's mining loop from a fixed puzzle board into a replayable expedition by generating distinct caverns each run, layering in environmental hazards that reshape route choices, preserving the existing bank-and-upgrade meta loop, and shipping the pass as version `0.0.5`.

## Problem statement
Corebound is no longer greenfield: it already ships a playable mining run, local persistence, upgrades, onboarding, and a branded shell. The weakest part of the current flagship loop is replayability. `createGrid()` builds the mine from fixed arithmetic rather than per-run randomness, so the ore layout repeats every run. Pressure loss currently comes almost entirely from movement and mining costs, which makes the mine feel like a static resource worksheet instead of a risky descent. Local inspection also surfaced a reliability issue in which the onboarding overlay can lose pointer priority to the shell, which is unacceptable for a flagship game that depends on overlays for first-run teaching and restart flow.

## Scope
In:
- Replace the fixed mine layout with replayable cave generation for Corebound.
- Introduce environmental hazard tiles that create immediate route-planning tension.
- Improve run-state clarity for hazards, onboarding, and restart overlays.
- Preserve and validate the current banking, upgrade, and local persistence loop on top of the new cave system.
- Bump the public Corebound release metadata for the new player-visible patch.

Out:
- New combat systems, enemies, or weapons.
- New biomes, narrative campaign content, or multi-screen world maps.
- Shared harness or build-pipeline changes beyond the Corebound manifest/version touchpoint.
- Mobile-first controls or touch UX redesign.

## Constraints
- Area maturity is early-stage: the core mining, banking, upgrade, persistence, and shell layers already exist, but the mine-generation and hazard systems remain shallow.
- Changes must stay within `auto-games/games/corebound/` plus `auto-games/data/games.json`.
- Keyboard movement, mining, banking, failure, restart, local persistence, and the Millrace shell must remain intact.
- The implementation must continue to run as authored static files with no new build toolchain or network dependency.
- The spec must remain one-game-at-a-time per `rules.md`.

## Requirements
- Corebound SHALL generate a fresh mine layout for each new run instead of reusing one fixed ore map.
- Each generated mine SHALL provide at least one traversable route from the surface extractor to the deepest depth band.
- Each generated mine SHALL contain at least two pre-carved caverns or widened air pockets below the surface band.
- The shallowest playable depth band SHALL contain reachable standard resource deposits before any hazard interaction is required.
- Resource distribution SHALL escalate by depth so deeper bands contain a higher concentration of high-value deposits than the upper bands.
- The mine SHALL include at least two environmental hazard tile types.
- Each hazard tile type SHALL use a visual treatment that is distinct from normal rock, air, extractor, and resource tiles.
- Hazard interactions SHALL telegraph their threat state before they apply pressure loss, movement denial, or route collapse.
- Triggering a hazard SHALL either consume pressure, alter traversable tiles, or both.
- Hazards SHALL NOT create unwinnable states that permanently prevent a return path to the surface extractor.
- Restarting a run SHALL regenerate the mine layout and clear transient pickups and hazard state.
- Restarting a run SHALL preserve banked currency, purchased upgrades, and onboarding-dismissal state.
- Banking cargo at the extractor SHALL remain functional on generated maps.
- Permanent upgrades SHALL remain purchasable and effective after the cave-generation refresh.
- The HUD or status messaging SHALL identify hazard warnings and hazard outcomes during play.
- The first-run onboarding copy SHALL teach the new cave and hazard rules.
- The onboarding overlay SHALL remain pointer-interactive above the game shell.
- The failed-run overlay SHALL remain pointer-interactive above the game shell.
- Mining, hazard triggers, and cave collapses SHALL produce distinct visual feedback.
- The `corebound` manifest entry SHALL bump the version from `0.0.4` to `0.0.5`.
- The Corebound page SHALL display `v0.0.5` in the version pill.
- The Corebound manifest summary or description SHALL mention the procedural-cavern or hazard-refresh release.

## Verification plan
- `cd auto-games && python3 scripts/build_arcade.py`
  - Expected: the arcade build completes without errors and publishes the updated authored Corebound files.
- `cd auto-games && rg -n '"slug": "corebound"|"version": "0.0.5"|v0.0.5|procedural|hazard' data/games.json games/corebound/index.html`
  - Expected: the manifest entry shows `0.0.5`, the page shows `v0.0.5`, and release copy references the new cave/hazard refresh.
- `cd auto-games && python3 -m http.server 8000`
  - Expected: loading `http://127.0.0.1:8000/corebound/` shows the onboarding overlay above the shell and its button is clickable with a pointer.
  - Expected: starting three fresh runs through the restart flow produces at least two visually distinct cave layouts.
  - Expected: the opening descent exposes reachable resource tiles before hazard interaction is mandatory.
  - Expected: deeper excavation reveals denser or richer high-value deposits than the upper mine.
  - Expected: at least two distinct hazard tile types appear during play and each one is visually readable before it resolves.
  - Expected: triggering a hazard changes pressure, traversable terrain, or both, while banking at the extractor still works.
  - Expected: after restarting, the run state resets but banked currency and purchased upgrades persist.
  - Expected: the failure overlay appears above the shell and its restart button is clickable with a pointer.

## Assumptions
- The current Corebound renderer can absorb generated caverns and hazard tiles without replacing the full DOM-grid presentation.
- Existing upgrades remain a valid first-pass meta layer, even if their tuning changes to fit the new cave system.
- A patch release is the correct version increment for this player-visible improvement.
- External internet research is unnecessary because the prompt and repo state are sufficient to define this spec.

## Open questions
- Which two hazard archetypes should ship first: unstable cave-ins, pressure vents, acid pools, or another mining-native pair?
- Should the generator surface a visible run seed for debugging and sharing, or stay invisible to players?
- Should any existing upgrade gain hazard-specific mitigation, or should upgrades remain pressure-and-efficiency focused in `0.0.5`?
