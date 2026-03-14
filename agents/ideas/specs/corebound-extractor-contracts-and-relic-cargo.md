# Corebound — Extractor Contracts And Relic Cargo

## Summary
Add a contract-driven objective layer to Corebound so each descent has explicit priorities, a deeper-bank target, and a higher-stakes extraction moment. The improvement centers on three visible extractor contracts, one run-defining relic cargo objective, and payout rules that make banking feel more strategic without replacing the existing mining, hazard, or upgrade loops.

## Problem statement
`agents/outline.md` identifies Corebound as the flagship mining game, and local repo inspection shows it already ships procedural caverns, hazard telegraphs, banking, persistence, and permanent upgrades. The current loop is playable but flat once the player understands ore values: the HUD shows hazards, cargo, and upgrades, yet there is no visible expedition objective beyond "mine something and come back." That leaves runs readable but under-motivated, with too little difference between a shallow safe haul and a risky deep push. `agents/work/taskspending.md`, `agents/work/tasksbacklog.md`, and `agents/work/tasksbackburner.md` are empty, so there is no active queued work overlapping a Corebound objective-layer expansion.

## Scope
In:
- Add a visible extractor contract layer to the Corebound HUD and run flow.
- Add one high-value relic cargo objective to each run.
- Extend run generation so contract targets and relic placement are reachable on generated maps.
- Add payout, carry, failure-loss, and feedback rules for contracts and relic cargo.
- Update onboarding and release metadata for the new objective layer.

Out:
- New combat systems, enemies, or weapons.
- A biome overhaul, world map, or narrative campaign structure.
- New permanent upgrade categories or a full economy rebalance outside contract payouts.
- Shared harness or build-pipeline work outside the Corebound release metadata touchpoint.
- Touch-specific input redesign.

## Constraints
- Maturity assessment: established Corebound core loop, missing expedition-objective layer.
- Changes should stay scoped to `auto-games/games/corebound/` plus the allowed shared release touchpoint `auto-games/data/games.json`.
- Existing keyboard movement, mining, hazard telegraphs, banking, restart, local persistence, and Millrace shell cohesion must remain intact.
- The implementation must continue to run as authored static HTML, CSS, and JavaScript with no new network dependency.
- The release metadata must follow `rules.md`; because this is a player-visible improvement, the shipped Corebound version must receive a PATCH bump before release.
- External internet research is unnecessary for this spec because the prompt and local repo state already define the product gap.

## Requirements
- Corebound SHALL add a visible extractor contract panel to the authored game page.
- The contract panel SHALL remain visible during live play without removing the existing hazard feed, cargo panel, or permanent-upgrade panel.
- Each fresh run SHALL generate exactly three active extractor contracts.
- The active contract set SHALL include at least one standard resource-quota contract.
- The active contract set SHALL include at least one contract tied to the lower half of the mine.
- The active contract set SHALL include one relic-recovery contract.
- Each run SHALL place one relic target on a reachable tile below the mine midpoint.
- Contract targets and relic placement SHALL remain reachable from the surface extractor on the generated map.
- The relic target SHALL use visual treatment distinct from standard resource tiles, pickups, and hazard telegraphs.
- Resource-quota progress SHALL update immediately when qualifying cargo is collected.
- Standard contract rewards SHALL be granted only when qualifying cargo is banked at the extractor.
- Banking a recovered relic SHALL award a bonus larger than the value of one iridium core.
- Failing a run SHALL discard unbanked relic cargo and any unbanked contract payout from the active run.
- The HUD or status layer SHALL show live progress for all active contracts.
- The HUD or status layer SHALL show a carried-relic state after the relic is recovered and before it is banked or lost.
- Contract completion SHALL trigger distinct on-screen feedback.
- Relic recovery SHALL trigger distinct on-screen feedback.
- Restarting a run SHALL generate a new contract set and a new relic placement.
- Restarting a run SHALL preserve banked currency, purchased upgrades, and onboarding-dismissal state.
- Existing movement, mining, hazard telegraphs, banking, and permanent upgrades SHALL remain functional after the contract layer is added.
- The first-run onboarding copy SHALL explain contract payouts, relic banking risk, and failure-loss rules.
- The public release metadata for `corebound` SHALL describe the contract-and-relic objective refresh.
- The public release metadata for `corebound` SHALL apply a PATCH version bump relative to the manifest value at the start of implementation.
- The Corebound page SHALL display the same version string as the manifest after the release metadata sync.

## Verification plan
- `cd auto-games && python3 scripts/build_arcade.py`
  - Expected: the arcade build completes without errors and republishes the updated Corebound page.
- `cd auto-games && rg -n '"slug": "corebound"|contract|relic|version-pill' data/games.json games/corebound/index.html games/corebound/main.js`
  - Expected: Corebound source and metadata include contract/relic terminology, and the authored page still exposes a visible version pill.
- `cd auto-games && python3 -m http.server 8000`
  - Expected: loading `http://127.0.0.1:8000/corebound/` shows a contract panel with three active objectives while the hazard, cargo, and upgrade panels still render.
  - Expected: starting two fresh runs through the restart flow produces at least two distinct contract sets or relic placements.
  - Expected: collecting qualifying ore updates visible contract progress before banking.
  - Expected: recovering the relic shows a carried-relic state and distinct feedback.
  - Expected: banking at the extractor converts completed contracts into bonus credits and awards the relic payout.
  - Expected: failing before banking removes the unbanked relic and contract payout from the active run while preserving banked currency and purchased upgrades.
  - Expected: existing hazard warnings, mining input, extractor banking, and upgrade purchasing still work after the contract layer is added.
- Inspect `auto-games/data/games.json` and `auto-games/games/corebound/index.html` after implementation.
  - Expected: the manifest summary/version and the page's visible version text both reflect the released contract-and-relic update.

## Assumptions
- The current DOM-grid renderer and HUD layout can absorb one additional contract panel without forcing a shell redesign.
- Contract and relic state can remain run-local, with only banked currency and purchased upgrades persisting across reloads.
- Using the existing resource set plus one new relic objective is sufficient to make runs feel more directed without adding a new biome layer.
- The exact PATCH version number should be resolved against the then-current manifest value when implementation ships.

## Open questions
- Should the three contract slots reroll only on full restart, or also after each successful bank within the same session?
- Should relic placement always favor the deepest band, or should some runs surface a hazard-heavy mid-depth relic route instead?
- Should future upgrades interact with contracts or relic play, or should this pass keep the current upgrade list unchanged?
