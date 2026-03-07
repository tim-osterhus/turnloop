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


## 2026-03-05 — 2026-03-06 — Apply Strata Metadata in World Generation

## 2026-03-06 — Apply Strata Metadata in World Generation
Goal: Tag underground tiles with stratum metadata while preserving surface and starter shaft traversal.
Scope:
- In: Assign a stratum id/name to underground tiles during world generation; keep surface row and starter shaft behavior intact.
- Out: Ore weighting updates, tile visual changes, or HUD updates.
Files to touch:
- corebound/game.js
Steps:
1. During world generation, resolve the stratum for each underground row and store `stratumId` (or equivalent) on solid tiles.
2. Keep the surface row generation unchanged and ensure starter shaft carving remains air tiles.
3. Ensure stratum metadata is present on underground tiles for later rendering/ore selection.
Acceptance:
- The surface row remains traversable and the starter shaft is open.
- Underground tiles expose stratum metadata when inspected in DevTools.
Verification commands:
- `python3 -m http.server` — Expected: page loads; you can move down the starter shaft and inspect an underground tile with stratum metadata in DevTools.

Prompt artifact: `agents/work/prompts/010-apply-strata-metadata-world-generation.md`


## 2026-03-05 — 2026-03-06 — Per-Stratum Ore Tables + New Ore

## 2026-03-06 — Per-Stratum Ore Tables + New Ore
Prompt: `agents/work/prompts/011-per-stratum-ore-tables-new-ore.md`

Goal: Replace global depth weighting with per-stratum ore tables and add a deeper-only ore type.
Scope:
- In: Add at least one new ore type (3+ total), define per-stratum ore weight tables, and generate ore using stratum weights.
- Out: HUD changes, tile visual styling, or new controls.
Files to touch:
- corebound/game.js
Steps:
1. Add a new ore definition (id, label, color, value) so the total ore types are at least three.
2. Define ore weight tables per stratum with a deeper-only ore weight set to `0` in the shallowest stratum and non-zero in deeper strata.
3. Update ore generation to use the current stratum’s weight table instead of any global depth ratio.
4. Tune weights/values so the deepest stratum’s expected ore value exceeds the shallowest stratum’s.
Acceptance:
- The deeper-only ore never appears in the shallowest stratum after several digs.
- The deeper-only ore appears in the deepest stratum and average sell value is higher than near the surface.
Verification commands:
- `python3 -m http.server` — Expected: manual mining confirms deeper-only ore appears only in deeper strata and average sell value is higher.


## 2026-03-05 — 2026-03-06 — Distinct Stratum Solid Tile Visuals

## 2026-03-06 — Distinct Stratum Solid Tile Visuals
Prompt: agents/work/prompts/012-distinct-stratum-solid-tile-visuals.md
Goal: Make solid non-ore tiles visually distinct per stratum.
Scope:
- In: Add a per-stratum visual palette and render solid tiles using the palette.
- Out: Ore color changes or HUD updates.
Files to touch:
- corebound/game.js
Steps:
1. Define a per-stratum palette (e.g., base colors) for solid non-ore tiles.
2. Update tile rendering to use the palette based on each tile’s stratum metadata while keeping ore tiles rendered by ore color.
3. Preserve the existing surface row visuals.
Acceptance:
- Solid tile visuals change when crossing strata boundaries.
- Ore tiles remain visually distinct from solid tiles.
Verification commands:
- `python3 -m http.server` — Expected: descending shows solid tile colors change at strata boundaries.


## 2026-03-05 — 2026-03-06 — HUD Stratum Label

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


## 2026-03-05 — 2026-03-06 — Hardening: Stratum Lookup Fallbacks

## 2026-03-06 — Hardening: Stratum Lookup Fallbacks
Goal: Prevent undefined stratum states and keep HUD stable at surface and boundaries.
Prompt: `agents/work/prompts/014-hardening-stratum-lookup-fallbacks.md`
Scope:
- In: Add safe fallback handling for surface/out-of-range rows and ensure all stratum lookups use it.
- Out: New visuals, ore types, or controls.
Files to touch:
- corebound/game.js
Steps:
1. Extend the stratum lookup helper to return a safe fallback for surface rows (e.g., "Surface") and clamp out-of-range rows.
2. Use the safe helper everywhere strata are referenced (HUD, ore generation, rendering).
3. Confirm no undefined stratum values propagate to UI or gameplay logic.
Acceptance:
- The HUD shows "Surface" at depth 0 and a named stratum below without blank or undefined values.
- No console errors occur while moving across strata boundaries or at world edges.
Verification commands:
- `python3 -m http.server` — Expected: page loads with no console errors at surface or when crossing strata boundaries.


## 2026-03-05 — 2026-03-06 — Research Loop Single-Cycle Test Knobs

## 2026-03-06 — Research Loop Single-Cycle Test Knobs
Prompt: agents/work/prompts/015-research-loop-single-cycle-test-knobs.md
Goal: Make `agents/scripts/research_loop.sh` runnable in one fast local cycle without changing its default daemon behavior.
Scope:
- In: Add environment-variable overrides for daemon mode and the promote/poll delays, preserving the current defaults when unset.
- Out: Any change to the default production cadence, runner selection, or queue semantics.
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Read `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_POLL_SECS` from the environment with the current hard-coded values as defaults.
2. Keep the existing control flow intact so the loop still sleeps and repeats when the overrides are not provided.
3. Confirm the script can be invoked in a no-wait single-cycle mode for local harness use.
Acceptance:
- The script preserves its current behavior when the new environment variables are unset.
- The script can be configured for a zero-delay, non-daemon run without syntax errors.
Verification commands:
- `rg -n 'TURNLOOP_DAEMON_MODE|TURNLOOP_PROMOTE_DELAY_SECS|TURNLOOP_POLL_SECS' agents/scripts/research_loop.sh` — Expected: all three override names are present.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0.


## 2026-03-05 — 2026-03-06 — Manager Oldest-Only Staging Contract

## 2026-03-06 — Manager Oldest-Only Staging Contract
Prompt: `agents/work/prompts/016-manager-oldest-only-staging-contract.md`
Goal: Update the Manager instructions so each run targets exactly one staging spec: the oldest eligible file.
Scope:
- In: Rewrite `agents/entrypoints/_manage.md` to select one oldest staging spec, decompose only that spec, and move only that processed file to `agents/ideas/specs/`.
- Out: Changes to loop scripts, validator rules, or execution-loop behavior.
Assumptions: If a selected path is provided by the caller, Manager may use it as long as it still resolves to the oldest file being processed for that run.
Files to touch:
- agents/entrypoints/_manage.md
Steps:
1. Replace the batch-processing language with oldest-only staging selection language in the critical rules, inputs, and workflow sections.
2. State explicitly that newer staging files remain queued after a successful run.
3. Keep the existing overwrite-only status-file rules and history-log requirements intact.
Acceptance:
- The instructions say to process exactly one file per run.
- The selected file is described as the oldest staging spec.
- Success criteria say only the processed oldest spec moves to `agents/ideas/specs/`.
Verification commands:
- `rg -n 'process exactly one file per run|oldest file in `agents/ideas/staging/`|leave newer unprocessed staging specs|move only the processed oldest staging spec' agents/entrypoints/_manage.md` — Expected: all four phrases match.


## 2026-03-05 — 2026-03-06 — Research Loop Selected-Spec Handoff

## 2026-03-06 — Research Loop Selected-Spec Handoff
Goal: Make the research loop select the oldest staging spec once and reuse that exact path for validation and Manager dispatch.
Scope:
- In: Capture a single `staging_spec` per manage cycle, validate that path, and pass the same path into the Manager run through repo-local process state such as an environment variable.
- Out: Mechanic retry-count changes, validator-rule changes, or multi-spec processing.
Assumptions: A process-local environment variable is an acceptable handoff mechanism between the loop script and the Manager runner.
Prompt: `agents/work/prompts/017-research-loop-selected-spec-handoff.md`
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Keep a single oldest-file lookup for the manage cycle and store it in `staging_spec`.
2. Reuse `staging_spec` for the validation command instead of recomputing a staging path later in the cycle.
3. Export or inject the same `staging_spec` into the Manager invocation so Manager can target the validated file deterministically.
Acceptance:
- The manage cycle performs one oldest-file selection per run.
- The same selected path is used for validation and Manager dispatch.
- Newer staging files are not selected during that cycle.
Verification commands:
- `rg -n 'staging_spec=\"\\$\\(oldest_file \"\\$STAGING_DIR\"\\)\"|validate_spec.sh \"\\$staging_spec\"|TURNLOOP_STAGING_SPEC=\"\\$staging_spec\"|run_entrypoint \"\\$ENTRY_MANAGE\"' agents/scripts/research_loop.sh` — Expected: the selected staging path is assigned once, validated, and passed into Manager.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0.


## 2026-03-05 — 2026-03-06 — Validation Failure Blocks Manage Cycle

## 2026-03-06 — Validation Failure Blocks Manage Cycle
Goal: Ensure a validation failure for the selected staging spec blocks the research status and skips Manager for that cycle.
Scope:
- In: Write `### BLOCKED` before manage-stage mechanic handling begins and keep the Manager entrypoint on the success-only path.
- Out: Any change to mechanic escalation counts, nonviable moves, or validation-report content.
Assumptions: The loop should continue using the existing next-poll retry behavior after a blocked cycle.
Prompt: `agents/work/prompts/018-validation-failure-blocks-manage-cycle.md`
Files to touch:
- agents/scripts/research_loop.sh
Steps:
1. Keep the validation step on the selected `staging_spec` and capture the failure branch explicitly.
2. Write `### BLOCKED` before invoking manage-stage mechanic handling.
3. Ensure the Manager entrypoint is not reached when validation fails for that cycle.
Acceptance:
- Validation failure writes `### BLOCKED` before manage-stage mechanic handling starts.
- Validation failure does not invoke Manager for any staging spec in that cycle.
- The success path still runs Manager normally.
Verification commands:
- `rg -n 'Staging validation failed for \\$staging_spec|write_status \"### BLOCKED\"|handle_mechanic \"manage\"|run_entrypoint \"\\$ENTRY_MANAGE\"' agents/scripts/research_loop.sh` — Expected: blocked-status and mechanic handling exist on the validation-failure path, and Manager remains on the success path.
- `bash -n agents/scripts/research_loop.sh` — Expected: exit 0.


## 2026-03-05 — 2026-03-06 — README One-Spec Queue Documentation

## 2026-03-06 — README One-Spec Queue Documentation
Goal: Align the public Turnloop documentation with oldest-only staging validation and Manager processing.
Scope:
- In: Update `README.md` so the research-loop overview and task descriptions describe one-spec-at-a-time staging handling.
- Out: Outline changes, execution-loop docs, or new operational guidance beyond the queue contract.
Prompt: `agents/work/prompts/019-readme-one-spec-queue-documentation.md`
Files to touch:
- README.md
Steps:
1. Update the research-loop overview to say the oldest staging spec is validated and managed one at a time.
2. Clarify that successful manage cycles leave newer staging specs in `agents/ideas/staging/`.
3. Preserve the rest of the repo workflow documentation as-is unless wording must change for consistency.
Acceptance:
- README states that staging processing is one-spec-at-a-time.
- README matches the oldest-only validation and manage behavior.
Verification commands:
- `rg -n 'oldest staging spec|one-spec-at-a-time|leave newer staging specs' README.md` — Expected: the README reflects the oldest-only queue contract.


## 2026-03-05 — 2026-03-06 — Research Queue Contract Harness

## 2026-03-06 — Research Queue Contract Harness
Prompt: agents/work/prompts/020-research-queue-contract-harness.md
Goal: Add a local regression harness that exercises a two-spec staging queue and proves one cycle targets only the oldest spec.
Scope:
- In: Create a repo-local shell harness that seeds two staging specs, runs one manage-ready research-loop cycle with stubbed local components, and asserts the newer spec remains queued.
- Out: External runners, network calls, or a broader end-to-end integration suite.
Assumptions: The harness may stub the runner and validation behavior locally as long as it exercises the real queue-selection path in `agents/scripts/research_loop.sh`.
Files to touch:
- agents/scripts/test_research_queue_contract.sh
- agents/scripts/research_loop.sh
Steps:
1. Build the harness around an isolated temp workspace under the repo so it does not mutate real queue state.
2. Seed two staging specs with deterministic ordering and capture which path the loop validates and dispatches to Manager.
3. Stub any runner or validator dependencies locally so the harness stays offline and does not call Codex, Claude, or network services.
4. Assert that one cycle targets only the oldest spec and leaves the newer spec in staging afterward.
Acceptance:
- The harness exits 0 when only the oldest staging spec is validated and dispatched in one cycle.
- The harness fails if the newer spec is selected or if both specs are processed in the same cycle.
- The harness uses only local shell utilities and repo-local stubs.
Verification commands:
- `bash agents/scripts/test_research_queue_contract.sh` — Expected: exit 0 and output confirming that only the oldest staging spec was targeted while the newer spec remained queued.


## 2026-03-06 — 2026-03-06 — Corebound Upgrade Ladder Data Scaffold

## 2026-03-06 — Corebound Upgrade Ladder Data Scaffold
Goal: Replace the one-off surface upgrade state with structured upgrade-line data and session depth milestone tracking in `corebound/game.js`.
Prompt: `agents/work/prompts/021-corebound-upgrade-ladder-data-scaffold.md`
Scope:
- In: Add data-driven upgrade line definitions, per-line tier state, and deepest-depth session tracking helpers.
- Out: Final multi-row shop markup, visual styling, or gameplay tuning beyond the scaffold.
Assumptions: Track unlock progress as the deepest tile row reached this session; each upgrade line starts with two tiers for the first ladder pass.
Files to touch:
- corebound/game.js
Steps:
1. Replace the single `SURFACE_UPGRADE` definition with a structured upgrade collection that describes line ids, names, tier data, and unlock requirements.
2. Add session state for current purchased tier per upgrade line and the deepest depth reached during the session.
3. Add generic helpers for reading the next tier, checking unlock status, checking affordability, and rejecting invalid or maxed purchases.
4. Keep the current starting balance, inventory, fuel, and movement defaults unchanged until later cards wire tier effects into them.
Acceptance:
- `corebound/game.js` defines at least three upgrade lines with two tiers each in structured data.
- Session state records deepest depth reached and exposes it to unlock checks.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "deepestDepth|tiers|canPurchaseUpgrade|purchaseUpgrade|unlock" corebound/game.js` — Expected: matches for session-depth tracking plus generic upgrade helpers and tier data.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.


## 2026-03-06 — 2026-03-06 — Multi-Line Surface Shop UI Shell

## 2026-03-06 — Multi-Line Surface Shop UI Shell
Goal: Replace the single-upgrade HUD row with a repeatable surface shop list that can show multiple upgrade lines and availability states.
Prompt: `agents/work/prompts/022-corebound-multi-line-surface-shop-ui-shell.md`
Scope:
- In: Update the HUD/shop markup, render a generated list of upgrade rows, and add baseline locked/available/maxed styling hooks.
- Out: Final stat-effect tuning for specific upgrade lines.
Files to touch:
- corebound/index.html
- corebound/style.css
- corebound/game.js
Steps:
1. Replace the single upgrade row in `corebound/index.html` with a shop container that can host multiple generated lines.
2. Add CSS hooks in `corebound/style.css` for line layout and state styling such as locked, affordable, unaffordable, and maxed.
3. Update `corebound/game.js` to render one shop row per configured upgrade line with name, current level, next effect, cost, and status text placeholders.
4. Keep the shop visible at the surface and ensure startup still succeeds before specific upgrade effects are completed.
Acceptance:
- The shop can render at least three upgrade lines without duplicating hard-coded markup per line.
- Each line has visible fields for level, next effect, cost, and availability state.
- `python3 -m http.server 8000` serves `/corebound/` without startup console errors.
Verification commands:
- `rg -n "hud-shop-list|shop-line|shop-status|shop-level" corebound/index.html corebound/style.css corebound/game.js` — Expected: matches for generated multi-line shop markup/styling/rendering.
- `python3 -m http.server 8000` — Expected: `Serving HTTP on ...`; opening `http://localhost:8000/corebound/` shows the expanded shop UI.


## 2026-03-06 — 2026-03-06 — Cargo Pods Capacity Tiers

## 2026-03-06 — Cargo Pods Capacity Tiers
Goal: Implement a cargo upgrade line whose purchased tiers immediately increase inventory capacity and keep the shop relevant after the first buy.
Prompt: `agents/work/prompts/023-corebound-cargo-pods-capacity-tiers.md`
Scope:
- In: Define cargo tier values/costs, apply capacity boosts immediately, and update the line’s current/next tier state after each purchase.
- Out: Fuel-capacity tuning or locked depth-gated upgrades.
Files to touch:
- corebound/game.js
Steps:
1. Define the Cargo Pods line’s tier effects and costs inside the shared upgrade data structure.
2. Apply the purchased tier’s inventory-capacity effect immediately when the line is bought.
3. Update the shop row so the current level, next effect, next cost, and maxed state advance correctly after each purchase.
4. Preserve existing ore collection and sell behavior with the higher capacity values.
Acceptance:
- Buying Cargo Pods at the surface raises inventory capacity immediately in the same session.
- A later Cargo Pods tier remains available after the first purchase until the line reaches max tier.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "cargo|capacity|inventory\\.capacity" corebound/game.js` — Expected: matches for tier data and immediate capacity application.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.


## 2026-03-06 — 2026-03-06 — Fuel Tank Endurance Tiers

## 2026-03-06 — Fuel Tank Endurance Tiers
Goal: Add a second upgrade line that increases trip endurance by raising the player’s fuel capacity while preserving surface auto-refuel behavior.
Prompt: agents/work/prompts/024-corebound-fuel-tank-endurance-tiers.md
Scope:
- In: Replace the fixed max-fuel assumption with a derived fuel cap, define tiered fuel upgrades, and keep HUD/refill logic aligned with the upgraded cap.
- Out: New warning systems or changes to ore generation.
Files to touch:
- corebound/game.js
Steps:
1. Introduce a derived max-fuel helper so fuel capacity can change by upgrade tier instead of remaining a fixed constant.
2. Define the Fuel Tank line’s tier effects and costs in the shared upgrade data structure.
3. Apply the purchased fuel-capacity effect immediately and ensure surface auto-refuel fills to the upgraded maximum.
4. Update HUD fuel text and low-fuel checks to use the derived cap consistently.
Acceptance:
- Buying Fuel Tank at the surface increases the current max fuel immediately.
- Returning to the surface refills fuel to the upgraded maximum in the same session.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "getMaxFuel|Fuel Tank|clampFuel|hudFuel" corebound/game.js` — Expected: matches for derived fuel-capacity handling and UI updates.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.


## 2026-03-06 — 2026-03-06 — Depth-Gated Thruster Upgrade Line

## 2026-03-06 — Depth-Gated Thruster Upgrade Line
Prompt: `agents/work/prompts/025-depth-gated-thruster-upgrade-line.md`
Goal: Add a locked third upgrade line that unlocks after reaching Mid Depths and immediately improves mining throughput by increasing movement speed.
Scope:
- In: Define the locked line, gate it on session deepest depth, surface the lock text in the shop, and apply movement-speed boosts on purchase.
- Out: Persistent unlocks across sessions or new strata definitions.
Assumptions: Use the existing `mid-depths` strata boundary as the unlock milestone instead of introducing a separate hard-coded depth number.
Files to touch:
- corebound/game.js
Steps:
1. Add a movement-speed upgrade line with at least two tiers and an unlock rule tied to the Mid Depths entry row.
2. Keep the line locked and non-purchasable until the player reaches the milestone, while showing the unlock condition in the shop.
3. Update deepest-depth tracking during play so returning to the surface in the same session unlocks the line immediately.
4. Apply the purchased movement-speed bonus immediately and advance the row to its next tier or maxed state.
Acceptance:
- Before reaching Mid Depths, the thruster line is locked and shows its unlock condition.
- After reaching Mid Depths and returning to the surface in the same session, the line becomes purchasable if affordable.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "mid-depths|deepestDepth|speed|unlock" corebound/game.js` — Expected: matches for milestone tracking, lock checks, and speed upgrades.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.


## 2026-03-06 — 2026-03-06 — Shop State Hardening + Loop Regression

## 2026-03-06 — Shop State Hardening + Loop Regression
Prompt: `agents/work/prompts/026-shop-state-hardening-loop-regression.md`
Goal: Harden invalid purchase paths and confirm the expanded shop does not break selling, digging, movement, fuel drain, or surface auto-refuel.
Scope:
- In: Final purchase guards, disabled-state/button-label polish, and manual regression checks across the existing mine-sell-refuel loop.
- Out: Save/load, combat, fail states, or large UI redesigns.
Files to touch:
- corebound/game.js
- corebound/style.css
Steps:
1. Ensure purchase handlers no-op when the player is below the surface, lacks cash, has not met an unlock condition, or has maxed the selected line.
2. Finalize button labels and row styling for locked, affordable, unaffordable, and maxed states so the UI matches the actual purchase rules.
3. Re-run the mining loop manually to verify digging, ore collection, selling, movement fuel drain, low-fuel warning, and surface auto-refuel still behave correctly with the new upgrade ladder.
4. Fix any shop-state edge cases uncovered during regression without widening scope beyond the upgrade ladder.
Acceptance:
- Invalid purchase attempts are no-ops and the corresponding UI stays disabled or locked.
- The mining/selling/fuel loop still works after the shop expansion with no normal-play console errors.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.
- `python3 -m http.server 8000` — Expected: `Serving HTTP on ...`; manual play at `http://localhost:8000/corebound/` confirms the upgraded shop does not break the existing loop.


## 2026-03-06 — 2026-03-06 — Orchestrate Loop Isolated Work Root

## 2026-03-06 — Orchestrate Loop Isolated Work Root
Goal: Let `agents/scripts/orchestrate_loop.sh` mutate queue, status, prompt, log, and temp files inside an isolated repo-local workspace when `TURNLOOP_WORK_ROOT` is set, while preserving current repo-root behavior when it is unset.
Prompt: agents/work/prompts/027-orchestrate-loop-isolated-work-root.md
Scope:
- In: Derive execution-loop work files and directories from `TURNLOOP_WORK_ROOT`, keep default paths unchanged when the variable is unset, and preserve the existing file-based queue contract.
- Out: Timing overrides, harness scripts, README updates, or any changes to Builder/QA/Troubleshooter/Updater entrypoints.
Assumptions: `TURNLOOP_WORK_ROOT` points at a directory under the repo root that mirrors the needed `agents/` workspace layout for queue files and prompt artifacts.
Files to touch:
- agents/scripts/orchestrate_loop.sh
Steps:
1. Refactor the execution-loop path setup so workspace files and directories derive from `TURNLOOP_WORK_ROOT` when it is set and from the current repo root when it is unset.
2. Keep entrypoint instructions and runner invocation anchored to the real repo checkout so the live control flow still runs the real Turnloop prompts.
3. Update helper functions that read or write task, backlog, archive, backburner, status, prompt, finished, log, and temp paths so they use the isolated workspace consistently.
4. Verify the script still parses and that the new override name is discoverable by grep.
Acceptance:
- `agents/scripts/orchestrate_loop.sh` contains a `TURNLOOP_WORK_ROOT` override and routes workspace mutations through it.
- With the override unset, the script still targets the current repo-root workspace paths.
- `bash -n agents/scripts/orchestrate_loop.sh` exits 0.
Verification commands:
- `rg -n 'TURNLOOP_WORK_ROOT|WORK_ROOT|TASK=|BACKLOG=|STATUS=|PROMPTS_DIR=|FINISHED_DIR=' agents/scripts/orchestrate_loop.sh` — Expected: the work-root override appears and the workspace paths derive from it.
- `bash -n agents/scripts/orchestrate_loop.sh` — Expected: exit 0.



## 2026-03-06 — 2026-03-06 — Orchestrate Loop Single-Cycle Timing Overrides

## 2026-03-06 — Orchestrate Loop Single-Cycle Timing Overrides
Goal: Make `agents/scripts/orchestrate_loop.sh` configurable for fast local one-cycle runs by reading daemon and sleep values from environment variables without changing the current defaults.
Prompt: agents/work/prompts/028-orchestrate-loop-single-cycle-timing-overrides.md
Scope:
- In: Add environment-backed overrides for daemon mode, promote delay, and idle poll delay using the current hard-coded values as defaults.
- Out: Work-root path routing, harness scripts, README edits, or changes to runner/model fallback behavior.
Assumptions: `TURNLOOP_DAEMON_MODE=false` should allow a local harness to run one execution-loop cycle without sleeping indefinitely, and zero-second overrides are valid for test runs.
Files to touch:
- agents/scripts/orchestrate_loop.sh
Steps:
1. Replace the hard-coded `DAEMON_MODE`, `PROMOTE_DELAY_SECS`, and `IDLE_POLL_SECS` assignments with environment-backed defaults using the required variable names.
2. Preserve the current execution-loop flow and default values when the new variables are unset.
3. Verify the override names are present and the script parses in both default and explicit single-cycle forms.
Acceptance:
- `agents/scripts/orchestrate_loop.sh` contains `TURNLOOP_DAEMON_MODE`, `TURNLOOP_PROMOTE_DELAY_SECS`, and `TURNLOOP_IDLE_POLL_SECS`.
- The default values remain the current production values when those variables are unset.
- `bash -n agents/scripts/orchestrate_loop.sh` exits 0.
Verification commands:
- `rg -n 'TURNLOOP_DAEMON_MODE|TURNLOOP_PROMOTE_DELAY_SECS|TURNLOOP_IDLE_POLL_SECS' agents/scripts/orchestrate_loop.sh` — Expected: all three override names appear.
- `bash -n agents/scripts/orchestrate_loop.sh` — Expected: exit 0.
- `TURNLOOP_DAEMON_MODE=false TURNLOOP_PROMOTE_DELAY_SECS=0 TURNLOOP_IDLE_POLL_SECS=0 bash -n agents/scripts/orchestrate_loop.sh` — Expected: exit 0.



## 2026-03-06 — 2026-03-06 — Orchestrate Happy-Path Regression Harness

## 2026-03-06 — Orchestrate Happy-Path Regression Harness
Goal: Add a repo-local harness that seeds two backlog cards in isolated temp state, runs one real non-daemon execution-loop cycle, and proves only the oldest card is promoted and completed.
Prompt: agents/work/prompts/029-orchestrate-happy-path-regression-harness.md
Scope:
- In: Add a local shell harness that seeds isolated queue files and prompt artifacts, uses local runner stubs, executes the real `agents/scripts/orchestrate_loop.sh` control flow once, and asserts happy-path queue/archive/prompt movement outcomes.
- Out: Quickfix auto-demotion coverage, README updates, or any external runner/network usage.
Assumptions: Local runner stubs can drive `_start.md`, `_check.md`, and `_update.md` by writing the expected status markers and prompt side effects inside the isolated workspace.
Files to touch:
- agents/scripts/test_orchestrate_happy_path.sh
- agents/scripts/orchestrate_loop.sh
Steps:
1. Create `agents/scripts/test_orchestrate_happy_path.sh` to build an isolated workspace under the repo root with two deterministically ordered backlog cards and matching prompt artifacts.
2. Add only the minimum local stub wiring needed so one `TURNLOOP_DAEMON_MODE=false` run exercises the real orchestration path without invoking external runners.
3. Assert that the oldest card is promoted, appended to `agents/work/tasksarchive.md`, has its prompt moved to `agents/work/finished/`, and leaves the newer backlog card queued.
4. Assert that the real repo-root queue files remain unchanged after the harness exits.
Acceptance:
- `bash agents/scripts/test_orchestrate_happy_path.sh` exits 0 using only local stubs and repo-local temp state.
- The harness fails if the newer backlog card is promoted or if both cards are consumed in one cycle.
- The harness output confirms archive, prompt-move, and remaining-backlog checks passed.
Verification commands:
- `bash -n agents/scripts/test_orchestrate_happy_path.sh` — Expected: exit 0.
- `bash agents/scripts/test_orchestrate_happy_path.sh` — Expected: exit 0 and output confirming oldest-only promotion, archive append, prompt move, and preserved newer backlog state.



## 2026-03-06 — 2026-03-06 — Orchestrate Quickfix Auto-Demotion Harness

## 2026-03-06 — Orchestrate Quickfix Auto-Demotion Harness
Goal: Add a repo-local harness that drives two isolated `### QUICKFIX_NEEDED` cycles and proves the execution loop auto-demotes the task to `agents/work/tasksbackburner.md`, clears `agents/work/task.md`, and returns `agents/orchestrate_status.md` to `### IDLE`.
Prompt: agents/work/prompts/030-orchestrate-quickfix-auto-demotion-harness.md
Scope:
- In: Add a local shell harness for the quickfix retry path using isolated queue state and local runner stubs, then assert backburner demotion, task clearing, and idle-status restoration after the second failed quickfix loop.
- Out: Happy-path archival checks, README updates, troubleshooter auto-demotion coverage, or external runner/network usage.
Assumptions: The quickfix path can be driven entirely by isolated `_check.md` stub behavior that returns `### QUICKFIX_NEEDED` twice while the real orchestration loop handles retry counting and demotion.
Files to touch:
- agents/scripts/test_orchestrate_quickfix_demotion.sh
- agents/scripts/orchestrate_loop.sh
Steps:
1. Create `agents/scripts/test_orchestrate_quickfix_demotion.sh` to seed isolated backlog, active-task, status, and prompt state under a repo-local temp workspace.
2. Reuse the real `agents/scripts/orchestrate_loop.sh` control flow with local stubs so one non-daemon run reaches `### QUICKFIX_NEEDED` twice and triggers auto-demotion.
3. Assert that the task is appended to `agents/work/tasksbackburner.md`, `agents/work/task.md` is cleared, `agents/orchestrate_status.md` returns to `### IDLE`, and the harness exits non-zero on any contract break.
4. Confirm the real repo-root workspace files are untouched after the harness completes.
Acceptance:
- `bash agents/scripts/test_orchestrate_quickfix_demotion.sh` exits 0 using only repo-local shell utilities and local stubs.
- The harness proves the second quickfix failure auto-demotes the task to `agents/work/tasksbackburner.md`.
- The harness proves the isolated active task file is cleared and the isolated orchestrate status returns to `### IDLE`.
Verification commands:
- `bash -n agents/scripts/test_orchestrate_quickfix_demotion.sh` — Expected: exit 0.
- `bash agents/scripts/test_orchestrate_quickfix_demotion.sh` — Expected: exit 0 and output confirming quickfix auto-demotion, cleared task file, and restored idle status.



