# Ricochet Reactor First Playable Baseline

## Summary
The arcade currently has one public game, `corebound`, and the prompt asks for a new browser game that already feels intentional rather than like a loose prototype. This spec defines a greenfield second title, `ricochet-reactor`, as a desktop-first single-screen arena defense game with immediate controls, ricocheting shots, escalating pressure, and a persistent local best-score loop.

## Problem statement
- The public arcade is still a one-game experience, which makes the catalog feel early even though the build and publishing flow already support authored game pages.
- The repo has the infrastructure needed to publish a second game cleanly, but there is no scoped spec for a new title that uses a fresh slug and grows the arcade in a player-visible way.
- The prompt explicitly calls for a small but genuinely playable game with strong feel and future growth potential, so the baseline needs a clear hook, readable stakes, and replay value from the first release.

## Scope
### In
- A new public game published under a fresh slug: `ricochet-reactor`.
- An authored HTML/CSS/JS game page inside `auto-games/games/ricochet-reactor/`.
- A Millrace-coherent public shell around the new game page.
- One cohesive score-attack loop built around arena defense, ricochet shooting, enemy waves, and restart flow.
- Manifest registration and release metadata required to publish the new game on the generated arcade index.

### Out
- Touch controls or mobile-first combat input.
- Multiple arenas, bosses, weapon trees, or meta-progression beyond a local best score.
- Online leaderboards, accounts, cloud saves, or any remote service dependency.
- Changes to other game directories besides the new game and the required shared registry/index touchpoints.

## Constraints
- Maturity assessment: greenfield for `ricochet-reactor`; established for the authored-game publishing flow and manifest-generated arcade index.
- `rules.md` keeps the work scoped to one game plus allowed shared touchpoints, so the implementation should stay local to `auto-games/games/ricochet-reactor/`, `auto-games/data/games.json`, and the generated output produced from that manifest entry.
- Every new public game entry must use a unique kebab-case slug and start at version `0.0.1`.
- Any public-facing game subpage should follow `site/millrace-theme.md` for shell-level branding while allowing the arena interior to carry its own identity.
- The repo is a static HTML/CSS/JS project with Python build scripts and no frontend bundler.
- External search is not required for this spec because the prompt and local repo artifacts provide enough direction.

## Requirements
1. The arcade manifest SHALL add a new public entry for `ricochet-reactor` with title, status, version `0.0.1`, summary, description, CTA label, and `source_dir: "games/ricochet-reactor"`.
2. The repo SHALL contain an authored source directory at `auto-games/games/ricochet-reactor/` with the files needed to publish the game through the existing arcade build flow.
3. A normal arcade build SHALL publish `ricochet-reactor/` as a second playable title and surface it on the generated arcade index.
4. The `ricochet-reactor` page SHALL use a Millrace-coherent outer shell with a branded top bar, a `../` backlink, a game title block, and visible status/version metadata.
5. Opening the published `ricochet-reactor/` page SHALL place the player into a playable run without a setup menu or external configuration step.
6. A run SHALL take place inside a single-screen arena focused on defending a central reactor from incoming enemies.
7. The player SHALL move with keyboard controls and aim and fire with the mouse.
8. The player SHALL have a short-cooldown dash that supports fast repositioning during combat.
9. The primary weapon SHALL ricochet off arena walls for a limited number of bounces before disappearing.
10. The baseline enemy roster SHALL include at least three distinct behaviors that pressure the player in different ways.
11. A run SHALL progress through timed waves that increase enemy pressure over time.
12. A run SHALL end cleanly when reactor integrity reaches zero or the player loses all health.
13. Destroyed enemies SHALL award score and drop at least one collectible energy pickup that the player can recover during combat.
14. The live HUD SHALL show current score, local best score, reactor integrity, player health, and the current wave or threat state at all times.
15. The local best score SHALL persist across page reloads in the same browser.
16. The page SHALL present the core objective and control instructions in visible on-page copy or a first-run overlay.
17. Shooting, enemy hits, enemy deaths, dash use, and player damage SHALL each trigger distinct on-screen feedback that makes the combat readable and responsive.
18. The game SHALL provide a restart path that returns the player to a fresh run within one interaction after failure.
19. The page shell SHALL remain legible and navigable at narrow mobile widths even if combat remains desktop-first.
20. Ricochet Reactor SHALL NOT require network access or remote services during gameplay.
21. The baseline release SHALL NOT require edits to any existing game directory other than the new `ricochet-reactor` directory.

## Verification plan
- Inspect `auto-games/data/games.json`.
  Expected result: the manifest contains a `ricochet-reactor` entry with `version: "0.0.1"` and `source_dir: "games/ricochet-reactor"`.
- Run `cd auto-games && python3 scripts/build_arcade.py`.
  Expected result: the build completes successfully, publishes `ricochet-reactor/`, and keeps the generated arcade index intact.
- Run `cd auto-games && python3 -m http.server 8000`.
  Expected result: `http://localhost:8000/ricochet-reactor/` and `http://localhost:8000/` both load without missing-page failures.
- Open `http://localhost:8000/`.
  Expected result: the arcade index shows Ricochet Reactor as a second public game card linked to `ricochet-reactor/`.
- Open `http://localhost:8000/ricochet-reactor/` and play one run.
  Expected result: the page shows a Millrace shell, the game starts immediately, keyboard movement and mouse aiming work, dash works, ricochet shots bounce, enemies arrive in escalating waves, and the run ends cleanly on failure.
- During manual play, observe combat feedback and HUD updates.
  Expected result: score, wave state, integrity, health, and best score update correctly, and hits, kills, damage, and dash use all produce distinct visual feedback.
- Set a new best score, reload the page, and reopen the game.
  Expected result: the best score persists after reload and appears correctly in the HUD.
- Inspect the page at a narrow mobile width.
  Expected result: the shell header, backlink, metadata pills, and explanatory copy remain readable without overlapping the page chrome.

## Assumptions
- Desktop keyboard-and-mouse play is acceptable for the first public release of a new action game in this repo.
- A single arena with escalating waves is enough to establish a strong first-release identity without requiring multiple content sets.
- Local browser storage is an acceptable persistence layer for a best-score loop at this stage of the arcade.
- The Millrace shell can be reused around a faster, more arcade-like combat game without forcing the arena itself to mimic Corebound's visual language.

## Open questions
- Should the first release use an endless survival score chase or a fixed-length wave set with a clear completion state?
- How aggressive should the dash be in the first build: pure repositioning, a brief invulnerability tool, or a damage-capable collision move?
- What enemy trio best supports the ricochet hook: direct chasers, ranged turrets, shielded units, splitters, or another mix?
- Should the energy pickup feed score only, reactor repair, dash charge recovery, or a small temporary overdrive state?
