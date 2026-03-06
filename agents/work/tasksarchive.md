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
- Running the script against the spec validation spec exits 0 and prints a brief OK message.
Verification commands:
- `bash agents/scripts/validate_spec.sh` — Expected: usage message and non-zero exit.
- `bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0 and OK output.


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
- The current spec validation spec validates successfully.
Verification commands:
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL be present." "# Verification plan" "# Assumptions" > agents/.tmp/spec-missing-heading.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-heading.md; echo "exit=$?"` — Expected: non-zero exit and a report in `agents/ideas/validation_reports/spec-missing-heading.validation.md` mentioning `Open questions`.
- `bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0.


## 2026-03-05 — 2026-03-05 — Validator: Requirements Keywords

## 2026-03-05 — Validator: Requirements Keywords
Goal: Enforce Requirements section rules for at least one requirement line and exactly one keyword per line.
Prompt: agents/work/prompts/002-validator-requirements-line-rules.md
Scope:
In: Identify bullet/numbered requirement lines within the Requirements section and validate each line contains exactly one of `SHALL` or `SHALL NOT`.
Out: Heading presence checks, scope label checks, or report formatting changes.
Assumptions: Requirement keywords are uppercase `SHALL` and `SHALL NOT` (case-sensitive).
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Parse the Requirements section boundaries and collect bullet/numbered requirement lines inside it.
2. If no requirement lines are present, add a distinct violation message for the missing requirement lines.
3. For each requirement line, assert it contains exactly one requirement keyword (`SHALL` or `SHALL NOT`), treating `SHALL NOT` as a single keyword and flagging zero or multiple matches as violations.
Acceptance:
- A spec whose Requirements section contains no bullet/numbered lines fails validation with a report mentioning the missing requirement lines.
- A Requirements line that contains both `SHALL` and `SHALL NOT` (or multiple keyword matches) fails validation with a distinct violation.
- A Requirements line with exactly one keyword passes this rule when other validations are satisfied.
Verification commands:
- `cat > agents/.tmp/spec-missing-req-lines.md <<'EOF'
# Summary
ok
# Problem statement
ok
# Scope (In / Out)
In: ok
Out: ok
# Constraints
ok
# Requirements
No bullets here.
# Verification plan
ok
# Assumptions
ok
# Open questions
ok
EOF
bash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-req-lines.md; echo "exit=$?"` — Expected: non-zero exit and a report that mentions missing requirement lines.
- `cat > agents/.tmp/spec-double-keyword.md <<'EOF'
# Summary
ok
# Problem statement
ok
# Scope (In / Out)
In: ok
Out: ok
# Constraints
ok
# Requirements
- This SHALL and SHALL NOT both appear.
# Verification plan
ok
# Assumptions
ok
# Open questions
ok
EOF
bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-keyword.md; rg -n "keyword|SHALL" agents/ideas/validation_reports/spec-double-keyword.validation.md` — Expected: non-zero exit and a report noting the invalid keyword count.
- `bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0 with an OK message.


## 2026-03-05 — 2026-03-05 — Validator: Requirements Lines Present

## 2026-03-05 — Validator: Requirements Lines Present
Goal: Ensure the Requirements section includes at least one bullet or numbered requirement line.
Scope:
In: Detect bullet (`-`, `*`, `+`) or numbered (`1.`) lines within the Requirements section; fail when none exist.
Out: Requirement keyword counting or report formatting changes.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Extract the `Requirements` section body based on Markdown headings.
2. Match bullet (`-`, `*`, `+`) or numbered (`1.`) lines inside that section.
3. Record a violation when no requirement lines are found.
Acceptance:
- A spec with an empty Requirements section fails validation with a missing-requirement-lines violation.
- The spec validation spec validates successfully.
Verification commands:
- `cat > agents/.tmp/spec-missing-req-lines.md <<'SPEC'\n# Summary\n# Problem statement\n# Scope (In / Out)\nIn: test\nOut: test\n# Constraints\n# Requirements\n# Verification plan\n# Assumptions\n# Open questions\nSPEC\nbash agents/scripts/validate_spec.sh agents/.tmp/spec-missing-req-lines.md; echo "exit=$?"` — Expected: non-zero exit and report includes the missing-requirement-lines violation.
- `bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` — Expected: exit 0.

Prompt: agents/work/prompts/001-requirements-lines-present.md


## 2026-03-05 — 2026-03-05 — Validator: Requirement Keyword Count

## 2026-03-05 — Validator: Requirement Keyword Count
Prompt: agents/work/prompts/001-validator-requirement-keyword-count.md
Goal: Enforce exactly one requirement keyword per Requirements line.
Scope:
In: Count requirement keywords on each bullet/numbered line within Requirements; record a violation when count is zero or greater than one.
Out: Defining new requirement keyword sets beyond the agreed list.
Assumptions: Requirement keywords are `SHALL`, `SHOULD`, `MUST`, `MAY` (case-insensitive) matched as whole words; `SHALL NOT` counts as one keyword.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Define the requirement keyword list and whole-word matching rules.
2. For each Requirements bullet/numbered line, count keyword occurrences.
3. Record a violation per line where the count is not exactly one.
Acceptance:
- A line with two requirement keywords fails validation and produces a violation.
- A line with zero requirement keywords fails validation and produces a violation.
Verification commands:
- `cat > agents/.tmp/spec-double-keyword.md <<'SPEC'\n# Summary\n# Problem statement\n# Scope (In / Out)\nIn: test\nOut: test\n# Constraints\n# Requirements\n- The system SHALL and SHOULD fail.\n# Verification plan\n# Assumptions\n# Open questions\nSPEC\nbash agents/scripts/validate_spec.sh agents/.tmp/spec-double-keyword.md; echo "exit=$?"` — Expected: non-zero exit and report mentions the double-keyword line.
- `cat > agents/.tmp/spec-no-keyword.md <<'SPEC'\n# Summary\n# Problem statement\n# Scope (In / Out)\nIn: test\nOut: test\n# Constraints\n# Requirements\n- The system will fail without a keyword.\n# Verification plan\n# Assumptions\n# Open questions\nSPEC\nbash agents/scripts/validate_spec.sh agents/.tmp/spec-no-keyword.md; echo "exit=$?"` — Expected: non-zero exit and report mentions the missing-keyword line.


## 2026-03-05 — 2026-03-05 — Validator Reports

## 2026-03-05 — Validator Reports
Goal: Produce clear validation reports on failure and remove stale reports on success.
Prompt: agents/work/prompts/002-validator-reports.md
Scope:
In: Write validation reports that include the spec path and violation list; remove any report on success; ensure the report directory exists.
Out: README updates or research-loop gating.
Files to touch:
- agents/scripts/validate_spec.sh
Steps:
1. Ensure the validator creates `agents/ideas/validation_reports/` when needed.
2. On validation failure, write `agents/ideas/validation_reports/<spec_basename>.validation.md` with the spec path and each violation on its own line.
3. On successful validation, delete any existing report file for that spec.
Acceptance:
- A failing spec produces a report that includes the spec path and at least one violation line.
- A passing spec leaves no validation report for that spec basename.
Verification commands:
- `printf '%s\n' "# Summary" "# Problem statement" "# Scope (In / Out)" "In: test" "Out: test" "# Constraints" "# Requirements" "- This SHALL and SHALL NOT both appear." "# Verification plan" "# Assumptions" "# Open questions" > agents/.tmp/spec-double-shall.md; bash agents/scripts/validate_spec.sh agents/.tmp/spec-double-shall.md; rg "Spec path" agents/ideas/validation_reports/spec-double-shall.validation.md` — Expected: report exists and includes the spec path line.
- `bash agents/scripts/validate_spec.sh agents/ideas/specs/turnloop-spec-validation-2026-03-05.md; test ! -f agents/ideas/validation_reports/turnloop-spec-validation-2026-03-05.validation.md && echo "report removed"` — Expected: prints `report removed`.


## 2026-03-05 — 2026-03-05 — Docs: Spec Validation Note

## 2026-03-05 — Docs: Spec Validation Note
Prompt: agents/work/prompts/001-docs-spec-validation-note.md
Goal: Document the spec validation gate and report location.
Scope:
In: Add a README note that validation runs before Manager and reports live under `agents/ideas/validation_reports/`.
Out: Script or research-loop changes.
Files to touch:
- README.md
Steps:
1. Add a brief README note under Research Loop or How It Works that validation runs before Manager and reports live in `agents/ideas/validation_reports/`.
2. Mention that validation failures block the Manager run for that cycle.
Acceptance:
- README mentions validation before Manager and the report directory.
Verification commands:
- `rg "validation" README.md` — Expected: a line describing validation before Manager and report location.


## 2026-03-05 — 2026-03-05 — Hardening: Gate Research Loop on Spec Validation

## 2026-03-05 — Hardening: Gate Research Loop on Spec Validation
Goal: Block Manager runs when the spec validation spec fails validation and invoke the mechanic.
Prompt: agents/work/prompts/001-gate-research-loop-spec-validation.md
Scope:
In: Update `agents/scripts/research_loop.sh` to validate the oldest spec validation spec before running Manager, set status to `### BLOCKED` on failure, skip Manager, and call `handle_mechanic "manage"`.
Out: Changes to Manager entrypoint or execution loop.
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Add a validation step that runs `agents/scripts/validate_spec.sh` against the oldest spec validation spec before the Manager entrypoint.
2. On validation failure, set research status to `### BLOCKED`, log the failure, and call `handle_mechanic "manage"` without invoking Manager.
3. On validation success, proceed with the current Manager invocation flow.
Acceptance:
- The research loop script clearly shows validation happening before the `_manage.md` entrypoint.
- Validation failure path sets `### BLOCKED` and skips Manager.
Verification commands:
- `rg -n "validate_spec.sh" agents/scripts/research_loop.sh` — Expected: validation call present before Manager invocation.
- `rg -n "_manage.md" agents/scripts/research_loop.sh` — Expected: Manager invocation remains after validation block.
## 2026-03-05 — 2026-03-05 — Update Archived Validator Task Cards

## 2026-03-05 — Update Archived Validator Task Cards
Prompt: agents/work/prompts/003-update-archived-validator-task-cards.md
Goal: Replace staging-path references with specs-path references in archived validator task cards.
Scope:
- In: Update validator-related cards in `agents/work/tasksarchive.md` to reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` and remove any staging-path mentions.
- Out: Editing `agents/historylog.md`, spec files, or validator scripts.
Assumptions: Scope is limited to task cards and prompt artifacts, so repo-wide `rg ... agents` checks may still find legacy staging references in non-task files like history logs.
Files to touch:
- agents/work/tasksarchive.md
Steps:
1. Locate all references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` within validator cards in `agents/work/tasksarchive.md`.
2. Replace staging-path references with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` and update any “staging spec” wording accordingly.
3. Ensure no validator card instructions in `agents/work/tasksarchive.md` include copy steps that recreate the staging spec.
Acceptance:
- `agents/work/tasksarchive.md` contains no references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- Validator cards in `agents/work/tasksarchive.md` reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` in verification commands.
- No copy-back instructions recreate the staging spec in these archived cards.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` — Expected: matches inside validator card verification commands.
- `rg -n "cp .*turnloop-spec-validation-2026-03-05.md" agents/work/tasksarchive.md` — Expected: no matches.



## 2026-03-05 — 2026-03-05 — Update Backburner Validator Card

## 2026-03-05 — Update Backburner Validator Card
Prompt: agents/work/prompts/004-update-backburner-validator-card.md
Goal: Align the backburner validator task card with the specs-path reference.
Scope:
- In: Update the validator card in `agents/work/tasksbackburner.md` to use the specs-path in acceptance/verification.
- Out: Changes to any other backburner entries or validator logic.
Files to touch:
- agents/work/tasksbackburner.md
Steps:
1. Find the validator task card in `agents/work/tasksbackburner.md` that references the staging spec path.
2. Replace the staging spec reference in acceptance/verification with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md` and adjust wording from “staging spec” to “specs spec”.
Acceptance:
- `agents/work/tasksbackburner.md` contains no references to `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md`.
- The validator card verification command uses `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/tasksbackburner.md` — Expected: 1 match.



## 2026-03-05 — 2026-03-05 — Update Finished Prompts: Scaffold + Headings

## 2026-03-05 — Update Finished Prompts: Scaffold + Headings
Goal: Update validator prompt artifacts for scaffold and headings tasks to use the specs-path reference.
Prompt: agents/work/prompts/005-update-finished-validator-prompts-scaffold-headings.md
Scope:
- In: Replace staging-path references in the finished prompt artifacts for validator scaffold and required headings.
- Out: Changes to prompt content unrelated to the spec path.
Files to touch:
- agents/work/finished/001-spec-validator-scaffold.md
- agents/work/finished/001-validator-required-headings-scope-labels.md
Steps:
1. Replace staging-path references in command lists with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
2. Update any “staging spec” wording to reference the specs path instead.
Acceptance:
- The two prompt artifacts contain no `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references.
- The command lists reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-spec-validator-scaffold.md agents/work/finished/001-validator-required-headings-scope-labels.md` — Expected: matches in command lists.



## 2026-03-05 — 2026-03-05 — Update Finished Prompts: Requirements Rules

## 2026-03-05 — Update Finished Prompts: Requirements Rules
Prompt: agents/work/prompts/003-update-finished-prompts-requirements-rules.md
Goal: Update validator prompt artifacts for requirements-rule tasks to use the specs-path reference.
Scope:
- In: Replace staging-path references in the finished prompt artifacts for requirements line rules.
- Out: Any other prompt artifact changes.
Files to touch:
- agents/work/finished/001-requirements-lines-present.md
- agents/work/finished/002-validator-requirements-line-rules.md
Steps:
1. Replace staging-path references in command lists with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
2. Update any “staging spec” wording to reference the specs path instead.
Acceptance:
- The two prompt artifacts contain no `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references.
- The command lists reference `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/001-requirements-lines-present.md agents/work/finished/002-validator-requirements-line-rules.md` — Expected: matches in command lists.



## 2026-03-05 — 2026-03-05 — Update Finished Prompt: Validator Reports

## 2026-03-05 — Update Finished Prompt: Validator Reports
Goal: Update the validator reports prompt artifact to use the specs-path reference.
Prompt: `agents/work/prompts/006-update-finished-validator-reports.md`
Scope:
- In: Replace staging-path references in the validator reports finished prompt artifact.
- Out: Changes to report logic requirements or other prompt artifacts.
Files to touch:
- agents/work/finished/002-validator-reports.md
Steps:
1. Replace the staging-path reference in the command list with `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
2. Update any “staging spec” wording to reference the specs path instead.
Acceptance:
- `agents/work/finished/002-validator-reports.md` contains no `agents/ideas/staging/turnloop-spec-validation-2026-03-05.md` references.
- The command list references `agents/ideas/specs/turnloop-spec-validation-2026-03-05.md`.
Verification commands:
- `rg -n "ideas/staging/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md` — Expected: no matches.
- `rg -n "ideas/specs/turnloop-spec-validation-2026-03-05.md" agents/work/finished/002-validator-reports.md` — Expected: 1 match.


## 2026-03-05 — 2026-03-06 — Fuel HUD Row + Controls Note

## 2026-03-06 — Fuel HUD Row + Controls Note
Goal: Add a visible fuel row in the HUD and a controls note about surface refuel.
Prompt: agents/work/prompts/007-fuel-hud-row-controls-note.md
Scope:
- In: Add a Fuel HUD row with a value span and add a controls list item noting fuel refills at the surface.
- Out: Any fuel logic or styling changes beyond existing HUD layout.
Files to touch:
- corebound/index.html
Steps:
1. Insert a HUD row labeled Fuel with a value span using `id="hud-fuel"` and a row hook `id="hud-fuel-row"`.
2. Add a controls item indicating fuel refills at the surface.
Acceptance:
- The HUD shows a Fuel row alongside Depth, Cash, and Inventory.
- The controls panel lists a line indicating fuel refills at the surface.
Verification commands:
- `python3 -m http.server` — Expected: page loads at `http://localhost:8000/corebound/` with the Fuel HUD row and refuel note visible.


## 2026-03-05 — 2026-03-06 — Fuel Constants + HUD Binding

## 2026-03-06 — Fuel Constants + HUD Binding
Goal: Introduce fuel tuning constants, state, and HUD updates.
Prompt: `agents/work/prompts/007-fuel-constants-hud.md`
Scope:
- In: Add `FUEL_*` constants, initialize `state.fuel`, and populate the Fuel HUD value each tick.
- Out: Fuel drain, digging costs, refuel behavior, or warning states.
Files to touch:
- corebound/game.js
Steps:
1. Define `FUEL_MAX`, `FUEL_MOVE_RATE`, `FUEL_DIG_COST`, `FUEL_LOW_THRESHOLD`, and `FUEL_EMPTY_SPEED_MULT` near other tuning constants.
2. Initialize `state.fuel` to `FUEL_MAX` when the session starts.
3. Cache the `hud-fuel` element and update `updateHud` to render `fuel / FUEL_MAX` each tick.
Acceptance:
- On load, the Fuel HUD row shows `100 / 100`.
- No console errors appear during HUD updates.
Verification commands:
- `python3 -m http.server` — Expected: Fuel row renders `100 / 100` on load and stays in sync with state.


## 2026-03-05 — 2026-03-06 — Movement Fuel Drain + Empty Speed

## 2026-03-06 — Movement Fuel Drain + Empty Speed
Prompt: agents/work/prompts/008-movement-fuel-drain-empty-speed.md
Goal: Drain fuel during active movement and slow the player when empty.
Scope:
- In: Deduct `FUEL_MOVE_RATE * deltaSeconds` while actively moving and apply `FUEL_EMPTY_SPEED_MULT` when fuel is empty, clamping to `0..FUEL_MAX`.
- Out: Dig fuel costs, surface refuel, or low-fuel warning states.
Files to touch:
- corebound/game.js
Steps:
1. Add a helper to clamp fuel updates to `0..FUEL_MAX` and reuse it whenever fuel changes.
2. In `movePlayer`, detect when movement input results in movement and subtract `FUEL_MOVE_RATE * delta` only when moving.
3. Apply `FUEL_EMPTY_SPEED_MULT` to movement speed when `state.fuel` is `0` (or less) before calculating deltas.
Assumptions: "Actively moving" means input direction is non-zero and at least one axis step is applied (not fully blocked by collisions).
Acceptance:
- Holding movement keys for ~10 seconds reduces fuel while movement succeeds.
- Fuel does not decrease while idle.
- At fuel 0, movement speed is visibly slower.
Verification commands:
- `python3 -m http.server` — Expected: fuel drains while moving, holds while idle, and speed slows at 0.


## 2026-03-05 — 2026-03-06 — Dig Fuel Cost + Empty Lockout

## 2026-03-06 — Dig Fuel Cost + Empty Lockout
Prompt: agents/work/prompts/008-dig-fuel-cost-lockout.md
Goal: Charge fuel for successful digs and prevent digging when fuel is empty.
Scope:
- In: Block digging when fuel is empty and subtract `FUEL_DIG_COST` on successful tile removal, clamped to `0..FUEL_MAX`.
- Out: Movement drain or surface refuel behavior.
Files to touch:
- corebound/game.js
Steps:
1. Add an early return in `digAdjacentTile` when `state.fuel` is `0` (or less).
2. After a dig succeeds (tile becomes air), subtract `FUEL_DIG_COST` and clamp the result.
3. Ensure failed digs (air tile, bounds guard, or inventory-full ore) do not consume fuel.
Acceptance:
- Each successful dig reduces fuel by 8.
- At fuel 0, digging no longer removes tiles.
Verification commands:
- `python3 -m http.server` — Expected: fuel drops per successful dig and digging stops at 0.


## 2026-03-05 — 2026-03-06 — Surface Auto-Refuel

## 2026-03-06 — Surface Auto-Refuel
Goal: Automatically refill fuel to max at the surface.
Scope:
- In: When depth is 0, set fuel to `FUEL_MAX` and keep the HUD in sync.
- Out: Additional UI changes or new upgrades.
Files to touch:
- corebound/game.js
Steps:
1. In the main tick or HUD update path, detect `depth === 0` and set `state.fuel = FUEL_MAX` (clamped).
2. Ensure refuel happens without input and never exceeds `FUEL_MAX`.
Acceptance:
- After draining fuel, returning to depth 0 instantly refills to `100 / 100`.
- The Fuel HUD row reflects the refilled value.
Verification commands:
- `python3 -m http.server` — Expected: fuel refills to max on reaching depth 0.

Prompt: agents/work/prompts/008-surface-auto-refuel.md


## 2026-03-05 — 2026-03-06 — Low-Fuel Warning State

## 2026-03-06 — Low-Fuel Warning State
Goal: Highlight low fuel in the HUD when at or below the threshold.
Scope:
- In: Add a warning style in CSS and toggle it when `fuel <= FUEL_LOW_THRESHOLD`.
- Out: Changes to fuel drain or refuel tuning.
Files to touch:
- corebound/style.css
- corebound/game.js
Steps:
1. Add a CSS warning style for the Fuel row (for example, `.hud-row.is-low .hud-value`).
2. Cache the Fuel row element and toggle the warning class in `updateHud` when fuel is at or below `FUEL_LOW_THRESHOLD`.
3. Ensure the warning clears when fuel rises above the threshold (such as after refuel).
Acceptance:
- The Fuel row visually changes when fuel falls to 20 or below.
- The warning clears when fuel refills above 20.
Verification commands:
- `python3 -m http.server` — Expected: low-fuel warning activates at <=20 and clears after refuel.
Prompt: agents/work/prompts/008-low-fuel-warning-state.md


## 2026-03-05 — 2026-03-06 — Define Depth Strata Config

## 2026-03-06 — Define Depth Strata Config
Prompt: `agents/work/prompts/009-define-depth-strata-config.md`
Goal: Introduce named depth strata definitions and a helper to resolve strata by row/depth.
Scope:
- In: Add at least three named strata with explicit row ranges covering all underground rows; add a stratum lookup helper.
- Out: World generation changes, ore weighting, tile visuals, or HUD updates.
Assumptions: Strata breakpoints are evenly spaced across underground rows for this iteration.
Files to touch:
- corebound/game.js
Steps:
1. Add a `STRATA` array with at least three named entries and explicit `minRow`/`maxRow` ranges that cover rows `1..WORLD_ROWS-1`.
2. Add a `getStratumForRow(row)` helper that returns the matching stratum object for underground rows.
3. Ensure the helper is accessible for later ore/visual/HUD work without changing world generation yet.
Acceptance:
- `getStratumForRow(1)` and `getStratumForRow(WORLD_ROWS - 1)` return defined strata with names.
- The game loads without console errors.
Verification commands:
- `python3 -m http.server` — Expected: server starts; page loads without console errors and the helper returns strata objects in DevTools.


