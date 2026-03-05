# Summary
Create a minimal, playable Corebound vertical slice so the game is immediately usable and can be iterated on. The slice focuses on responsive movement, digging, ore collection, surface selling, and a single upgrade to make progress feel earned.

# Problem statement
The Corebound repo in this workspace has no playable game state. Without a basic loop, there is no stable foundation for “noticeable improvements,” nor any way to validate player feedback, controls, or progression.

# Scope (In)
- A single-page, browser-based game that runs without a build step.
- Tile-based world with surface and depth.
- Movement, digging, and ore collection.
- Inventory capacity and cash.
- Surface selling and one upgrade that affects gameplay.
- Minimal HUD and controls reference.

# Scope (Out)
- Save/load or persistence.
- Audio, particles, or advanced visual effects.
- Multiple biomes, enemies, hazards, or fuel systems.
- Mobile/touch-specific controls.
- Complex economy tuning.

# Constraints
- Must remain lightweight and self-contained under `corebound/` with no external build dependencies.
- Code should favor readability and extensibility over cleverness.
- The game should remain stable and playable throughout development.

# Requirements
- `corebound/index.html` SHALL run the game without a build step (double-click or static server).
- The game SHALL render the world and player using a HTML `<canvas>`.
- The player SHALL move with `WASD` and arrow keys, blocked by solid tiles.
- The player SHALL dig an adjacent solid tile using a single input (keyboard or mouse), removing the tile.
- World generation SHALL produce a surface row and increasing depth downward in a 2D grid.
- The game SHALL include at least two ore types with distinct cash values.
- Ore distribution SHALL increase the chance of higher-value ore at greater depth.
- The HUD SHALL display depth, cash, and inventory usage.
- The inventory SHALL have a fixed capacity that prevents collecting ore when full.
- Returning to the surface (depth 0) SHALL allow selling all inventory for cash via a visible control or automatic sale.
- The surface shop SHALL provide at least one upgrade purchasable with cash that changes a gameplay stat.
- Controls SHALL be documented on-screen or in a README visible from the game.
- All game logic and assets SHALL live under `corebound/`.

# Verification plan
- Open `corebound/index.html` in a browser or run `python -m http.server` from `corebound/` and load the page.
- Confirm the canvas renders a grid, the player avatar, and the HUD values.
- Move with `WASD` and arrow keys; verify collision with solid tiles.
- Dig adjacent tiles; verify tiles are removed and ores are collected until inventory is full.
- Dig at different depths; verify higher-value ore appears deeper than near the surface.
- Return to depth 0; sell inventory and confirm cash increases.
- Purchase the upgrade; verify the associated stat changes immediately.
- Verify controls documentation is visible without leaving the page.

# Assumptions
- No existing playable Corebound implementation is present in this workspace.
- A simple static HTML/JS/CSS structure is acceptable.
- No persistence is required for this iteration.

# Open questions
- Is there a preferred control scheme or key bindings beyond `WASD`/arrows?
- Which upgrade should be prioritized (dig speed vs. inventory capacity)?
- Are there target browsers or performance constraints to validate against?
- Should selling be automatic at surface or require an explicit action?
