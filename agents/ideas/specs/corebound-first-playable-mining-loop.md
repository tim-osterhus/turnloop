# Corebound First Playable Mining Loop

## Summary
Corebound is currently a generated release page rather than a playable game. This spec defines the first flagship gameplay release: a desktop-first mining run with extraction tension, permanent upgrades, and the minimum publishing-flow change required to ship authored gameplay without breaking the manifest-generated arcade index.

## Problem statement
- `corebound` is advertised as the flagship mining game, but the published page only contains release copy and no playable mechanics.
- There is no moment-to-moment interaction, no risk-reward loop, no progression, and no retention hook for repeat sessions.
- `scripts/build_arcade.py` currently regenerates `corebound/index.html` from manifest text, which blocks safe iteration on real gameplay unless the build contract changes.

## Scope
### In
- A first playable Corebound release centered on one cohesive mining expedition loop.
- A minimal shared publishing-flow update that allows Corebound to ship authored HTML, CSS, JavaScript, and game assets.
- Release metadata updates required to publish the new player-visible build.

### Out
- Additional games or cross-game product work beyond the publishing support needed for Corebound.
- Online services, multiplayer, leaderboards, or account systems.
- Narrative campaign content, multiple biomes, or a large content catalog.
- Mobile-first controls.

## Constraints
- Area maturity is greenfield for gameplay and established for the manifest-generated arcade shell.
- Work must stay scoped to `corebound` plus shared manifest/build touchpoints required to publish it.
- `auto-games/data/games.json` remains the source of truth for discoverability and public version metadata.
- The current repo is a static-site project with Python-based generation and no existing frontend build toolchain.
- The published game must survive a normal arcade rebuild without requiring manual edits in generated output directories.

## Requirements
1. The arcade build flow SHALL generate the shared arcade index from `data/games.json` while publishing `corebound` from authored game source files instead of manifest-only placeholder markup.
2. The repo SHALL contain a dedicated Corebound source directory for gameplay code, styles, and assets that can be published repeatably on each arcade build.
3. The `corebound` manifest entry SHALL bump from `0.0.1` to `0.0.2` for the first playable release covered by this spec.
4. The published `corebound/` page SHALL load directly into a playable mining run with no setup step beyond opening the page.
5. A run SHALL let the player move a mining rig through a destructible underground playfield and break tiles in real time with desktop controls.
6. The mine SHALL contain at least three distinct collectible resource types with different visual treatment and different bank values.
7. Player movement and mining SHALL consume or risk a finite run-pressure resource that can end the run if the player overextends.
8. The player SHALL bank collected resources only by returning to a clearly marked surface or extraction point.
9. A failed run SHALL penalize unbanked resources while preserving already banked progression.
10. The in-run HUD SHALL show current depth, carried resources, banked currency, and the active run-pressure meter at all times.
11. The first session SHALL teach controls, extraction, and failure rules through an in-game onboarding layer.
12. Mining, pickups, damage, and banking SHALL produce immediate visual feedback through animation, particles, color change, or screen motion.
13. The between-run layer SHALL offer at least three permanent upgrades that improve different player capabilities on later runs.
14. Banked currency and purchased upgrades SHALL persist locally across page reloads.
15. The game SHALL provide a restart path from both success and failure states that returns the player to a valid next run within one interaction.
16. Corebound SHALL NOT require network access or remote services during moment-to-moment play.
17. Corebound SHALL NOT depend on manual post-build edits inside published output directories to remain playable.

## Verification plan
- Run `cd auto-games && python3 scripts/build_arcade.py`.
  Expected result: the arcade index rebuilds successfully and the published `corebound/` output includes the authored game files required by the playable release.
- Run `cd auto-games && python3 -m unittest tests.test_build_arcade`.
  Expected result: tests pass and cover the build contract for publishing an authored Corebound game surface.
- Inspect `auto-games/data/games.json`.
  Expected result: the `corebound` entry reads `0.0.2` and its summary/description match a playable mining release rather than a placeholder page.
- Open `auto-games/corebound/index.html` in a browser.
  Expected result: the page starts a playable mining run, the HUD is visible, mining destroys tiles, resource pickups change cargo totals, and banking converts cargo into persistent currency.
- Play until the run-pressure resource is depleted or the player otherwise fails.
  Expected result: the run ends cleanly, unbanked resources are penalized, and the player can restart immediately.
- Buy at least one permanent upgrade, reload the page, and start another run.
  Expected result: the purchased upgrade and remaining banked currency persist after reload and affect the next run.

## Assumptions
- Desktop keyboard play is the primary control target for `0.0.2`.
- A single coherent mine zone is sufficient for the first playable release.
- Local browser storage is acceptable persistence for the current arcade maturity level.
- This spec is based on the prompt and current repo state; external genre research was not required to resolve major unknowns.

## Open questions
- Which run-pressure model should anchor the loop: battery, heat, hull integrity, or a small combination of them?
- Should the first mine layout be handcrafted, seeded, or regenerated every run?
- Should banking happen only at the absolute surface or at a mid-run extraction pad?
- Should permanent upgrades live in a dedicated hangar screen or in a compact between-run panel on the main page?
