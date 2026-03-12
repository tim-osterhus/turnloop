# Summary

Corebound already ships as an authored, playable game page under `auto-games/games/corebound/`, but its surrounding shell still reads like a standalone microsite instead of a Millrace arcade page. This spec defines a shell-focused retrofit that brings Corebound's public page into the shared Millrace family while preserving the current mining loop, persistence, and authored publishing flow.

Maturity assessment: Established. Corebound already has a functioning gameplay surface, onboarding flow, upgrade economy, and manifest-backed public release entry; the gap is visual/system cohesion at the page-shell layer.

# Problem Statement

The current Corebound page uses its own typography, color system, page chrome, and document head setup. It does not expose the same branded top bar, favicon, pill styling, or glassy dark industrial shell used by the Millrace arcade, so the flagship game feels detached from the public arcade identity. The repo already includes a local theme reference in `site/millrace-theme.md`, a shared arcade shell aesthetic in `auto-games/assets/site.css`, and a manifest contract requiring visible versioned releases, but the authored Corebound page does not currently align with those cues.

# Scope

## In

- Refresh the Corebound page shell in `auto-games/games/corebound/` so it matches the Millrace arcade's branded outer frame.
- Align shell-level typography, spacing, pill styling, panel treatment, backlink treatment, and page metadata with the Millrace theme note.
- Add the shared Millrace favicon and visible release metadata to the Corebound page.
- Keep the gameplay surface, HUD, upgrades, onboarding, and persistence working after the shell retrofit.
- Bump Corebound's manifest version for the new public-facing build.

## Out

- New gameplay systems, new resources, new upgrade types, new map generation, or balance redesign.
- Broad arcade-wide shell redesign work outside Corebound.
- Changes to unrelated game directories.
- Resetting or replacing the existing local save model.

# Constraints

- `rules.md` keeps the work scoped to one game plus allowed shared touchpoints; for this prompt that means Corebound, `site/millrace-theme.md`, and `auto-games/data/games.json`.
- Corebound is published through `source_dir: "games/corebound"`, so shell work should land in the authored source files rather than in generated placeholder-page code.
- The existing shared favicon asset already lives at `auto-games/MillraceIconTransparent.png`.
- The current public Corebound manifest entry is `status: "Alpha"` and `version: "0.0.3"`.
- The prompt explicitly prioritizes shell cohesion over gameplay expansion, so gameplay code changes should be limited to what is necessary to preserve behavior inside the new shell.
- No external research is required because the authoritative theme reference is local to the repo.

# Requirements

| ID | Requirement | Verification | Expected evidence |
| --- | --- | --- | --- |
| R1 | The Corebound authored page SHALL include Millrace-branded document-head assets: a title containing both `Corebound` and Millrace branding, the shared Millrace favicon file, and the Millrace shell font families for display, body, and monospace text. | Inspect `auto-games/games/corebound/index.html` and open the built page. | The head includes font imports and favicon links pointing at the shared icon, and the browser tab shows Millrace-branded metadata instead of a generic `Corebound` page. |
| R2 | The page shell SHALL render a recognizable Millrace top bar above the gameplay content, including the `MR` brand kicker, the `Millrace Arcade` brand copy, and a clear back-to-arcade link to `../`. | Open `http://localhost:8000/corebound/` after a build and inspect the first visible navigation block. | The first visible shell element matches the shared arcade navigation affordances and provides a working route back to the arcade root. |
| R3 | The shell SHALL expose release context near the top of the page using Millrace-style metadata pills or badges that show the current release status and the current public version. | Inspect the rendered hero/header area and the authored markup or DOM. | The page shows visible status/version metadata in pill-style treatment near the title, and those values match the manifest entry. |
| R4 | The outer Corebound shell SHALL use the Millrace dark, glassy, industrial visual language for page background, panel surfaces, borders, spacing, and shell-level controls, with warm red accents reserved for the shared shell layer. | Compare the rendered Corebound shell with `site/millrace-theme.md` and `auto-games/assets/site.css`. | The page frame uses charcoal backgrounds, layered glass panels, soft borders, rounded containers, and restrained red highlights instead of the current disconnected blue/orange page chrome. |
| R5 | The gameplay surface SHALL remain visually distinct inside the shared shell so the mining field, HUD telemetry, and in-world feedback still read as Corebound-specific rather than being flattened into generic arcade styling. | Manual UI inspection during play. | The surrounding shell reads as Millrace, while the grid, extractor, ore colors, and gameplay feedback still preserve Corebound's mining identity. |
| R6 | The shell retrofit SHALL preserve existing player-facing functionality: movement, mining, pickups, banking, restart flow, upgrades, onboarding, and live HUD updates. | Play through a manual smoke test covering a full run loop. | Keyboard movement, tile breaking, pickups, banking, upgrades, overlays, and HUD values all work after the visual refactor. |
| R7 | The shell retrofit SHALL NOT break compatibility with the current `corebound-save-v1` local save payload for banked currency, upgrade levels, and onboarding dismissal. | Seed `localStorage` with the current save shape, reload the page, and verify saved values appear correctly. | Existing saved banked credits, upgrades, and onboarding state continue to load without reset or console errors. |
| R8 | The refreshed page SHALL remain usable on both desktop and mobile widths, keeping the top navigation, key telemetry, restart control, and gameplay area reachable without overlapping or hidden shell elements. | Manually inspect the page at a narrow mobile width and a standard desktop width. | The shell stacks cleanly on mobile, the navigation/backlink stay visible, HUD content remains readable, and the gameplay area remains accessible. |
| R9 | The public release update SHALL bump Corebound's manifest version from `0.0.3` to `0.0.4` and keep the page's visible version indicator synchronized with that new value. | Inspect `auto-games/data/games.json`, rebuild the arcade, and compare the rendered version text. | The manifest entry reads `0.0.4`, and the page shows `v0.0.4` anywhere release metadata is surfaced. |

# Verification Plan

- `cd auto-games && python3 scripts/build_arcade.py`
  Expected result: the build completes without errors and republishes the authored Corebound page.
- `cd auto-games && python3 -m http.server 8000`
  Expected result: `http://localhost:8000/corebound/` loads the refreshed shell with no missing asset errors in the browser console.
- Manual browser smoke test of `http://localhost:8000/corebound/`
  Expected result: top bar, backlink, metadata pills, hero/panel styling, gameplay loop, onboarding, upgrades, and restart flow all work.
- Manual responsive inspection at desktop and mobile widths
  Expected result: shell panels reflow cleanly and critical controls remain visible.
- Local save compatibility check using `localStorage["corebound-save-v1"]`
  Expected result: existing save data is read successfully after the shell update.

# Assumptions

- A player-facing shell refresh counts as a public build change and therefore should take a patch bump from `0.0.3` to `0.0.4`.
- Reusing the same remote font providers already used by the arcade shell is acceptable for the authored Corebound page.
- The shared Millrace favicon asset will remain at `auto-games/MillraceIconTransparent.png`.
- No build-system change is required because Corebound is already published from its authored source directory.

# Open Questions

- Should the Corebound page directly reuse shared shell CSS tokens from `auto-games/assets/site.css`, or should it mirror the same visual contract locally to avoid coupling authored game pages to arcade-wide stylesheet changes?
- Should visible version/status metadata remain manually maintained inside the authored page alongside the manifest bump, or is a later shared mechanism needed to inject manifest metadata into authored game shells automatically?
