# Tasks Archive

## 2026-03-05 — 2026-03-05 — Corebound Canvas Scaffold

## 2026-03-05 — Corebound Canvas Scaffold
Goal: Establish a static, no-build Corebound page with a canvas, HUD shell, and basic player movement in open space.
Scope:
- In: Create `corebound/index.html`, `corebound/style.css`, and `corebound/game.js` with a canvas, HUD placeholders, keyboard input, and a render/update loop.
- Out: Tile world, digging, ore, inventory, selling, or upgrades.
Assumptions: Movement uses `WASD` and arrow keys; a simple square avatar is acceptable for now.
Prompt: agents/work/prompts/001-corebound-canvas-scaffold.md
Files to touch:
- corebound/index.html
- corebound/style.css
- corebound/game.js
Steps:
1. Create `corebound/index.html` with a canvas element, HUD container, and a controls reference placeholder; link `style.css` and `game.js`.
2. Add minimal styling for full-viewport canvas and a readable HUD overlay.
3. Implement a render loop in `game.js` that sizes the canvas, draws a background grid, renders a player square, and updates HUD placeholders.
4. Add keyboard input handling for `WASD` and arrow keys to move the player in open space.
Acceptance:
- Opening the page shows the canvas, a visible player square, and HUD fields for depth, cash, and inventory.
- The player moves with `WASD` and arrow keys without console errors.
- A controls reference placeholder is visible on-screen.
Verification commands:
- `python3 -m http.server` — Expected: `Serving HTTP on ...` and the page loads at `http://localhost:8000/` with the player moving on the canvas.


## 2026-03-05 — 2026-03-05 — Tile Grid + World Generation

## 2026-03-05 — Tile Grid + World Generation
Prompt: agents/work/prompts/002-tile-grid-world-generation.md
Goal: Add a tile-based world with a surface row and solid tiles below, plus collision blocking.
Scope:
- In: 2D grid world generation, surface row at depth 0, solid tiles below, tile rendering, collision checks, and depth HUD updates.
- Out: Digging, ore collection, inventory, selling, or upgrades.
Assumptions: A starter shaft is carved at the spawn column to allow descending before digging is introduced.
Files to touch:
- corebound/game.js
- corebound/index.html
- corebound/style.css
Steps:
1. Add grid constants (tile size, world width/height) and a world-generation function that creates a surface row and solid tiles below.
2. Carve a small starter shaft at the spawn location to allow initial vertical movement.
3. Render tiles with distinct colors for air/surface and solid blocks.
4. Update movement to block entering solid tiles and update the depth HUD from the player’s tile Y coordinate.
Acceptance:
- The surface row is visible with solid tiles beneath it.
- The player cannot move into solid tiles and can move within the starter shaft.
- The depth HUD increases as the player moves downward in the shaft.
Verification commands:
- `python3 -m http.server` — Expected: `Serving HTTP on ...` and the page shows a tile grid with collision working.


## 2026-03-05 — 2026-03-05 — Digging + Inventory + Ore Types

## 2026-03-05 — Digging + Inventory + Ore Types
Prompt: agents/work/prompts/001-digging-inventory-ore.md
Goal: Implement digging to remove adjacent tiles and collect ores into a capped inventory.
Scope:
- In: Dig input, tile removal, at least two ore types with cash values, inventory capacity tracking, and HUD updates.
- Out: Depth-weighted ore distribution, selling, or upgrades.
Assumptions: Digging uses the Space bar and targets the adjacent tile in the last movement direction; if inventory is full, ore tiles cannot be collected.
Files to touch:
- corebound/game.js
- corebound/index.html
Steps:
1. Define at least two ore types (id, color, value) and allow tiles to store ore metadata.
2. Add inventory state with a fixed capacity and a per-ore count summary for the HUD.
3. Implement a dig action on Space that removes an adjacent solid tile; if it contains ore and inventory has space, add to inventory.
4. Update the HUD to show inventory usage and cash placeholders during digging.
Acceptance:
- Pressing Space removes an adjacent solid tile in the last movement direction.
- At least two ore types appear in the world and are collected into inventory.
- Inventory stops collecting ore when full.
Verification commands:
- `python3 -m http.server` — Expected: `Serving HTTP on ...` and digging collects ore until capacity is reached.


## 2026-03-05 — 2026-03-05 — Depth-Weighted Ore + Surface Selling

## 2026-03-05 — Depth-Weighted Ore + Surface Selling
Prompt: agents/work/prompts/001-depth-weighted-ore-surface-selling.md
Goal: Bias ore generation by depth and enable selling inventory at the surface for cash.
Scope:
- In: Depth-weighted ore distribution, a sell control available at depth 0, inventory-to-cash conversion, and HUD cash updates.
- Out: Upgrades or persistent storage.
Assumptions: Selling uses a visible button that appears only at depth 0 and when inventory is non-empty.
Files to touch:
- corebound/game.js
- corebound/index.html
- corebound/style.css
Steps:
1. Update world generation so higher-value ore appears more frequently at greater depth (tiered or weighted random).
2. Add a Sell button in the HUD that is visible/enabled only at depth 0 with non-empty inventory.
3. Implement selling logic to convert inventory to cash and clear the inventory on sale.
4. Update HUD to display cash totals after selling.
Acceptance:
- Higher-value ore appears more often at deeper depths than near the surface.
- At depth 0, the Sell button appears and converts inventory to cash.
- The Sell button is hidden or disabled below the surface.
Verification commands:
- `python3 -m http.server` — Expected: `Serving HTTP on ...` and selling at the surface increases cash.


## 2026-03-05 — 2026-03-05 — Surface Upgrade + Controls Reference

## 2026-03-05 — Surface Upgrade + Controls Reference
Goal: Add a single purchasable upgrade at the surface and document controls on-screen.
Prompt: agents/work/prompts/002-surface-upgrade-controls.md
Scope:
- In: A surface shop UI with one upgrade, purchase logic that changes a gameplay stat, and on-screen controls reference.
- Out: Additional upgrades or save/load.
Assumptions: The upgrade increases inventory capacity by a fixed amount (for example +5) and costs a fixed cash price.
Files to touch:
- corebound/game.js
- corebound/index.html
- corebound/style.css
Steps:
1. Add upgrade data (name, cost, effect) and render a shop section with a Buy button.
2. Gate purchase on cash and surface depth; apply the stat change immediately and update HUD capacity.
3. Add a controls reference panel listing movement, digging, and selling/shop actions.
Acceptance:
- At the surface with enough cash, purchasing the upgrade increases inventory capacity immediately.
- The Buy button is disabled when the player is not at the surface or lacks cash.
- Controls are visible on-screen without leaving the game page.
Verification commands:
- `python -m http.server` — Expected: `Serving HTTP on ...` and the upgrade changes capacity when purchased.


## 2026-03-05 — 2026-03-05 — Hardening: Bounds + UI Guards

## 2026-03-05 — Hardening: Bounds + UI Guards
Goal: Stabilize edge cases for movement, digging, selling, and upgrades.
Prompt: agents/work/prompts/001-hardening-bounds-ui-guards.md
Scope:
- In: Bounds checks for movement/digging, robust UI button states, and non-negative HUD values.
- Out: New features or visual polish.
Assumptions: Changes stay within existing files and do not add dependencies.
Files to touch:
- corebound/game.js
- corebound/index.html
Steps:
1. Clamp movement and dig target coordinates to world bounds; abort invalid digs safely.
2. Ensure sell and upgrade handlers no-op when invalid and keep buttons disabled in those states.
3. Guard HUD values against negative numbers or NaN display states.
Acceptance:
- Digging at the world edges does not throw errors.
- Sell and upgrade actions are no-ops when invalid and the UI reflects disabled states.
- HUD values remain consistent and non-negative.
Verification commands:
- `python -m http.server` — Expected: `Serving HTTP on ...` with no console errors when testing edge cases.


## 2026-03-05 — 2026-03-05 — Spec Validator Scaffold

## 2026-03-05 — Spec Validator Scaffold
Prompt: agents/work/prompts/001-spec-validator-scaffold.md
Goal: Add a validator script scaffold and reports directory to anchor spec validation.
Scope:
In: Create `agents/scripts/validate_spec.sh` with argument parsing, report path setup, and a violation accumulator; add `agents/ideas/validation_reports/.gitkeep`.
Out: Actual validation rules for headings or requirements.
Files to touch:
- agents/scripts/validate_spec.sh
- agents/ideas/validation_reports/.gitkeep
Steps:
1. Create the `agents/ideas/validation_reports/` directory with a `.gitkeep` file.
2. Add `agents/scripts/validate_spec.sh` with strict mode, usage messaging, file existence checks, basename-derived report path, and a violations array.
3. Have the script exit non-zero when violations exist and print a short OK message when none exist.
Acceptance:
- Running the script with no arguments exits non-zero and prints a usage message.
- Running the script against the staging spec exits 0 and prints a brief OK message.
Verification commands:
- `bash agents/scripts/validate_spec.sh` — Expected: usage message and non-zero exit.
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0 and OK output.


## 2026-03-05 — 2026-03-05 — Validator: Required Headings + Scope Labels

## 2026-03-05 — Validator: Required Headings + Scope Labels
Goal: Enforce required section headings and Scope In/Out labels in spec files.
Prompt: agents/work/prompts/001-validator-required-headings-scope-labels.md
Scope:
In: Add case-insensitive checks for required headings and verify `Scope (In / Out)` contains both `In:` and `Out:` labels.
Out: Requirements section content rules and report formatting polish.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Parse the spec for Markdown headings and ensure all required section titles are present (case-insensitive match).
2. Within the `Scope (In / Out)` section, assert that lines with `In:` and `Out:` exist.
3. Record a distinct violation message for each missing heading or missing label.
Acceptance:
- A spec missing `Open questions` fails validation with a report that lists the missing heading.
- The current staging spec validates successfully.
Verification commands:
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL be present." "# Verification plan" "# Assumptions" > agents/.tmp/spec-missing-heading.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-heading.md; echo "exit=$?"` — Expected: non-zero exit and a report in `agents/ideas/validation_reports/spec-missing-heading.validation.md` mentioning `Open questions`.
- `bash agents/scripts/validate_spec.sh agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0.


