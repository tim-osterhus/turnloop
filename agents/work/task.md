## 2026-03-06 — HUD Stratum Label
Prompt: agents/work/prompts/013-hud-stratum-label.md
Goal: Display the current stratum name in the HUD and update it when crossing boundaries.
Scope:
- In: Add a HUD row for stratum label and update HUD logic to show the current stratum name.
- Out: Additional HUD elements or new gameplay systems.
Files to touch:
- corebound/index.html
- corebound/game.js
- corebound/style.css
Steps:
1. Add a HUD row labeled "Stratum" with a value span `id="hud-stratum"` (and optional row id for styling) in `corebound/index.html`.
2. Cache the new HUD element in `corebound/game.js` and update `updateHud` to set the stratum name based on player depth.
3. If needed, adjust `corebound/style.css` to match existing HUD row styles.
Acceptance:
- The HUD shows a stratum name during play.
- Crossing a stratum boundary updates the label on the next HUD refresh without reload.
Verification commands:
- `rg -n "hud-stratum" corebound/index.html` — Expected: the stratum HUD row and value span are present.
- `python3 -m http.server` — Expected: label updates when moving across a boundary.
