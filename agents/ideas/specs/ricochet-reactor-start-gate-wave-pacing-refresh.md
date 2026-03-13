# Ricochet Reactor — Start Gate And Wave Pacing Refresh

## Summary
Refit Ricochet Reactor's run start and early-wave flow so the game waits for player intent, teaches the first run cleanly, ramps pressure in a readable order, and ships that polish pass as version `0.0.7`.

## Problem statement
Ricochet Reactor already has a playable combat loop, wave escalation, score tracking, pickups, and between-wave upgrades, but the run starts too early and ramps too hard. On a fresh load, combat advances behind the intro overlay, and a player who pauses to read can enter an already-active wave with lost health or reactor integrity. The current `queueWave()` balance also throws a mixed six-threat breach into Wave 1, which hides the strengths of the controls and feedback behind immediate chaos instead of a deliberate onboarding curve.

## Scope
In:
- Add a true pre-run state for first boot and post-failure restart.
- Gate combat behind an explicit player start action and a visible launch countdown.
- Rebalance the first few waves so threat types arrive in a readable order.
- Add spawn anticipation feedback for queued enemies.
- Clarify HUD state messaging around ready, countdown, combat, upgrade, and failure phases.
- Bump the public release metadata for the new patch.

Out:
- New enemy archetypes, weapons, arenas, or boss fights.
- New persistence systems beyond the current best-score behavior.
- Additional upgrade content or permanent meta-progression.
- Shared harness or build-system changes beyond the manifest/version touchpoint.

## Constraints
- Changes must stay within `auto-games/games/ricochet-reactor/` plus `auto-games/data/games.json`.
- The existing Millrace shell, keyboard movement, mouse aiming, dash, score, pickup, and upgrade systems must remain intact.
- The refresh must keep one-game-at-a-time scope per `rules.md`.
- The implementation must stay dependency-free and continue to run as authored static files.

## Requirements
- The game SHALL enter a pre-run state on fresh page load.
- The game SHALL enter the same pre-run state after every run restart.
- The game SHALL NOT advance wave timers while the pre-run state is active.
- The game SHALL NOT spawn enemies or enemy projectiles while the pre-run state is active.
- The game SHALL NOT reduce player health or reactor integrity while the pre-run state is active.
- The first wave SHALL NOT begin until the player performs an explicit start action.
- Starting a run SHALL display a visible launch countdown inside the arena.
- The launch countdown SHALL keep combat simulation paused until the countdown completes.
- The first-run briefing SHALL describe the objective, movement, firing, dash, and restart inputs in visible on-page copy.
- Restarting after a failure SHALL clear all live enemies, projectiles, pickups, and current-run upgrade tiers before returning to the pre-run state.
- Wave 1 SHALL spawn only `chaser` enemies.
- Wave 1 SHALL queue no more than three enemies total.
- Wave 2 SHALL introduce `splitter` enemies and SHALL NOT queue any `turret` enemies.
- Wave 3 SHALL be the earliest wave allowed to queue `turret` enemies.
- Each queued enemy spawn SHALL present a directional telegraph before the enemy becomes active in the arena.
- The HUD/status layer SHALL expose distinct copy for pre-run, launch countdown, active combat, upgrade selection, upgrade resume, and failed-run states.
- The HUD/status layer SHALL identify the upcoming threat mix during the launch countdown or queued-spawn window.
- The existing upgrade draft flow SHALL remain intact after wave clears.
- Choosing an upgrade SHALL surface a visible resume cue before the next wave becomes active.
- The manifest entry for `ricochet-reactor` SHALL bump the version to `0.0.7`.
- The Ricochet Reactor page SHALL display `v0.0.7` in the version pill.
- The manifest summary or description for `ricochet-reactor` SHALL mention the run-start and pacing refresh.

## Verification plan
- `cd auto-games && python3 scripts/build_arcade.py`
  - Expected: build completes without errors and publishes the updated `ricochet-reactor/` files.
- `cd auto-games && rg -n '"slug": "ricochet-reactor"|"version": "0.0.7"|v0.0.7' data/games.json games/ricochet-reactor/index.html`
  - Expected: the manifest entry and on-page version pill both show `0.0.7`.
- `cd auto-games && python3 -m http.server 8000`
  - Expected: after clearing `millrace.ricochet-reactor.intro-dismissed` in localStorage and loading `http://127.0.0.1:8000/ricochet-reactor/`, the game shows a ready/briefing state.
  - Expected: waiting 8 seconds without starting the run leaves health at `100%`, integrity at `100%`, and no active hostile wave on screen.
  - Expected: starting the run shows a visible countdown, and enemies do not enter the arena until that countdown completes.
  - Expected: Wave 1 contains only chasers and no more than three total queued enemies.
  - Expected: Wave 2 introduces splitters but no turrets, and Wave 3 is the first wave where turrets can appear.
  - Expected: queued spawns show directional telegraphs before enemies enter.
  - Expected: after a fail state, `R` or the restart control returns the game to the pre-run state with combat entities cleared and upgrade tiers reset, while best score still persists.

## Assumptions
- The current state machine in `main.js` can absorb a pre-run and launch-countdown phase without a renderer rewrite.
- The upgrade overlay remains the correct between-wave structure and only needs clearer resume signaling, not a redesign.
- Rebalancing the first three waves is sufficient to make the early run legible without redefining the endless scaling model.

## Open questions
- After the first completed run, should restarts reuse the full briefing overlay or switch to a smaller ready prompt?
- Should the directional telegraph be an edge indicator, a spawn reticle, or both?
- Should the launch countdown allow free player repositioning before combat starts, or should the player stay locked until the countdown finishes?
