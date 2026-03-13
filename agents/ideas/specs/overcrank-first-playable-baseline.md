# Overcrank First Playable Baseline

## Summary
The arcade currently publishes `corebound` and `ricochet-reactor`, with no active pending or backlog work aimed at adding a third title. This spec defines a greenfield third public game, `overcrank`, as a Flash-like vertical escape climber where the player wall-kicks up an overheating industrial shaft, navigates collapsing traversal hazards, manages a rising heat line, and chases a persistent local best score.

## Problem statement
- The public arcade still reads as early-stage because it only offers two playable titles.
- The current inbox prompt explicitly asks for a fresh browser game baseline with clear controls, strong feel, and room to grow rather than a refinement pass on an existing game.
- The repo already supports authored game pages through `auto-games/data/games.json` and `source_dir`, but no current queued work is using that flow to expand the catalog.
- `agents/work/taskspending.md`, `agents/work/tasksbacklog.md`, and `agents/work/tasksbackburner.md` are empty, so there is no active queued work that overlaps a greenfield third title.

## Scope
### In
- A new public game published under the fresh slug `overcrank`.
- An authored HTML/CSS/JS game page inside `auto-games/games/overcrank/`.
- A Millrace-coherent public shell around the new game page.
- One cohesive vertical-climb score-attack loop built around movement, wall kicks, rising heat pressure, shaft hazards, coolant pickups, failure, and restart flow.
- Manifest registration and release metadata required to publish the game on the generated arcade index.

### Out
- Changes to `corebound` or `ricochet-reactor`.
- Mobile-first controls or touch-specific traversal tuning.
- Online leaderboards, accounts, cloud saves, or any remote service dependency.
- Boss fights, multiple biomes, or a full campaign structure in the first release.
- Harness or framework work unrelated to publishing the new game cleanly.

## Constraints
- Maturity assessment: greenfield for `overcrank`; established for the authored-game publishing flow, manifest-generated arcade index, and Millrace shell conventions.
- `rules.md` keeps normal game work scoped to one game plus allowed shared touchpoints, so implementation should stay local to `auto-games/games/overcrank/`, `auto-games/data/games.json`, and generated output derived from that manifest entry.
- Every new public game entry must use a unique kebab-case slug and start at version `0.0.1`.
- Any public-facing game subpage should follow `site/millrace-theme.md` for shell-level branding while allowing the game interior to carry its own identity.
- The repo is a static HTML/CSS/JS arcade with Python build scripts and no frontend bundler.
- External search was skipped because the prompt and local repo state were sufficient to define the baseline.

## Requirements
1. The arcade manifest SHALL add a new public entry for `overcrank` with title, status, version `0.0.1`, summary, description, CTA label, and `source_dir: "games/overcrank"`.
2. The repo SHALL contain an authored source directory at `auto-games/games/overcrank/` with the files needed to publish the game through the existing arcade build flow.
3. A normal arcade build SHALL publish `overcrank/` as a third public game and surface it on the generated arcade index.
4. The `overcrank` page SHALL use a Millrace-coherent outer shell with a branded top bar, a `../` backlink, a title block, and visible status/version metadata.
5. Opening the published `overcrank/` page SHALL show a visible start-state briefing and begin a fresh run within one interaction.
6. A run SHALL take place in a side-view industrial shaft that scrolls upward as the player climbs.
7. The player SHALL move horizontally with keyboard input and jump with a single dedicated keyboard input.
8. The movement model SHALL support wall kicks from either shaft wall to recover upward momentum.
9. A rising heat line SHALL climb from below and act as the main chase threat during each run.
10. The shaft SHALL extend beyond the opening viewport through a reusable segment or pattern system so successful runs continue past the first screen.
11. The baseline obstacle set SHALL include stable catwalks, crumbling platforms, moving lifts, and timed steam-vent hazards.
12. Collectible coolant cells SHALL appear in the shaft and temporarily push back or slow the rising heat line when collected.
13. Climbing progress SHALL award live score through height gain and chained upward movement rather than idle survival alone.
14. The live HUD SHALL show current height, current score, local best score, active combo or chain state, and the heat-threat status at all times.
15. The local best score SHALL persist across page reloads in the same browser.
16. Visible on-page instructions SHALL teach movement, wall kicks, coolant pickups, and failure conditions before or at run start.
17. Jump launches, hard landings, platform collapse, steam warnings, combo escalation, and failure SHALL each produce distinct on-screen feedback that makes the climb readable and responsive.
18. Contact with the rising heat line SHALL end the current run immediately.
19. The game SHALL provide a restart path that returns the player to a fresh run within one interaction after failure.
20. The page shell SHALL remain legible and navigable at narrow mobile widths even if precise play remains desktop-first.
21. Overcrank SHALL NOT require network access or remote services during gameplay.
22. The baseline release SHALL NOT require edits to any existing game directory other than the new `overcrank` directory.

## Verification plan
- Inspect `auto-games/data/games.json`.
  Expected result: the manifest contains an `overcrank` entry with `version: "0.0.1"` and `source_dir: "games/overcrank"`.
- Run `find auto-games/games/overcrank -maxdepth 1 -type f | sort`.
  Expected result: the authored source directory exists and includes the files needed to publish the page, including `index.html`, `styles.css`, and `main.js`.
- Run `cd auto-games && python3 scripts/build_arcade.py`.
  Expected result: the build completes successfully, publishes `overcrank/`, and keeps the generated arcade index intact.
- Run `cd auto-games && python3 -m http.server 8000`.
  Expected result: `http://localhost:8000/` and `http://localhost:8000/overcrank/` both load without missing-page failures.
- Open `http://localhost:8000/`.
  Expected result: the arcade index shows Overcrank as a third public game card linked to `overcrank/`.
- Open `http://localhost:8000/overcrank/`, start a run, and play upward for at least one failure cycle.
  Expected result: the page shows a Millrace shell, the start-state briefing is visible, keyboard movement and wall kicks work, the shaft scrolls upward, the heat line climbs, coolant pickups affect the chase threat, the HUD updates continuously, and failure plus restart work cleanly.
- Set a new best score, reload the page, and reopen the game.
  Expected result: the best score persists after reload and appears correctly in the HUD.
- Inspect the page at a narrow mobile width.
  Expected result: the shell header, backlink, metadata pills, and instructional copy remain readable without overlapping the page chrome.

## Assumptions
- Desktop keyboard play is acceptable for the first public release of a new action-climber in this repo.
- A segment-based endless or long-form climb is a stronger first-release hook for this concept than a short fixed level.
- Local browser storage is an acceptable persistence layer for a best-score loop at the current arcade maturity level.
- The Millrace shell can frame a hotter, more kinetic game interior without forcing the playfield to match Corebound or Ricochet Reactor visually.

## Open questions
- Should wall kicks fully refresh upward momentum, or should they preserve some decay to keep route choice meaningful?
- Should coolant pickups primarily slow the heat line, push it downward, or also increase score multiplier?
- Should the first release be endless by default, or should it include a short target height with a visible completion state?
- How punishing should platform collapse and steam vents be relative to the main heat-line failure condition?
