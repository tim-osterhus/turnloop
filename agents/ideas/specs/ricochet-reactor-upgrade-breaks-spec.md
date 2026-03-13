# Ricochet Reactor — Between-Wave Upgrade Draft

## Summary
Introduce a between-wave upgrade selection layer for Ricochet Reactor that pauses combat between waves, offers three upgrade choices, and makes each run feel distinct while preserving the existing Millrace shell and core controls.

## Problem statement
Ricochet Reactor already has a satisfying survival loop, but every run feels mechanically identical from wave to wave. Without mid-run choices or growth, player agency and replayability plateau quickly, reducing the sense of progression and reward after surviving a wave.

## Scope
In:
- Add an upgrade selection overlay that appears after a wave is cleared and before the next wave spawns.
- Define a compact upgrade pool (5–7 entries) that modifies existing combat stats (movement, dash, firing, ricochet, or reactor recovery).
- Add a small HUD readout listing active upgrades and their current tiers.
- Update manifest version and on-page version pill for a patch release.

Out:
- Persistent meta-progression across sessions.
- New enemy archetypes, bosses, or weapon types.
- Audio, voiceover, or major visual overhaul of the arena.
- Mobile/touch controls overhaul.

## Constraints
- Changes must stay within `auto-games/games/ricochet-reactor/` plus allowed shared touchpoints (`auto-games/data/games.json`).
- Preserve the Millrace shell layout and theme per `site/millrace-theme.md`.
- Use the existing rendering loop and HUD structure; no external libraries.
- Maintain the one-game-at-a-time scope.

## Requirements
- The game SHALL display an upgrade selection overlay after each wave is cleared and before the next wave spawns.
- The overlay SHALL pause player movement, firing, dash input, enemy spawns, and projectiles until an upgrade is chosen.
- The overlay SHALL present exactly three upgrade cards sourced from a predefined upgrade pool.
- Each upgrade card SHALL include a title and one-sentence effect description.
- The selection logic SHALL avoid duplicate upgrade cards in the same choice set when the pool has three or more remaining options.
- Selecting a card SHALL immediately apply its effect and record the upgrade tier for the current run.
- The upgrade system SHALL support stacking tiers for repeated selections of the same upgrade.
- Active upgrades and their tiers SHALL be visible in the HUD during play.
- The upgrade overlay SHALL show the upcoming wave number before combat resumes.
- The wave loop SHALL resume automatically within 1–2 seconds after a selection is made.
- Restarting a run SHALL clear all upgrades and tiers.
- The intro overlay SHALL continue to function and SHALL not conflict with the upgrade overlay.
- The manifest entry for `ricochet-reactor` SHALL bump the version to `0.0.6`.
- The Ricochet Reactor page SHALL display `v0.0.6` in the version pill.
- The manifest summary or description for `ricochet-reactor` SHALL mention the between-wave upgrade system.

## Verification plan
- `cd auto-games && python3 scripts/build_arcade.py`
  - Expected: build completes without errors.
- `cd auto-games && python3 -m http.server 8000`
  - Expected: `/ricochet-reactor/` loads with Millrace shell intact and shows `v0.0.6` in the header.
  - Expected: after clearing a wave, an upgrade overlay appears with three choices and pauses combat.
  - Expected: selecting an upgrade applies the effect immediately, shows the upgrade in the HUD, and resumes the next wave after a short delay.
  - Expected: restarting the run removes all upgrades and reverts stats to defaults.

## Assumptions
- Wave completion is already detectable in the current run loop and can trigger a post-wave state.
- The existing HUD can accept an additional compact panel for upgrade listings without layout breaks.
- Balance values for upgrades can be defined using existing constants and simple multipliers.

## Open questions
- Which exact upgrade effects and tier scaling feel best for a first release (movement, dash, fire rate, ricochet count, pickup repair, max integrity)?
- Should the upgrade pool be fixed per run or reshuffled each wave?
- Do we want a short interstitial animation or sound cue when the upgrade overlay appears?
