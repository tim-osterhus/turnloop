<prompt id="001-corebound-canvas-scaffold" task="Corebound Canvas Scaffold">
  <objective>
    Establish a static, no-build Corebound page that renders a canvas with a HUD shell and basic player movement in open space using a simple render/update loop.
  </objective>
  <context>
    - Repo: Turnloop; Corebound lives in `corebound/`.
    - Keep changes minimal and reviewable; stay within `turnloop/`.
    - Scope excludes tile world, digging, ore, inventory mechanics, selling, or upgrades.
  </context>
  <requirements>
    - Create `corebound/index.html`, `corebound/style.css`, and `corebound/game.js`.
    - Canvas fills the viewport with a visible player square.
    - HUD overlay shows placeholders for depth, cash, and inventory.
    - Controls reference placeholder visible on-screen.
    - Keyboard input: `WASD` and arrow keys move the player in open space.
    - Implement a render/update loop that sizes the canvas and draws a background grid.
  </requirements>
  <plan>
    1. Developer: implement HTML/CSS/JS per requirements with minimal diffs.
    2. Refactor: run a brief, low-risk improvement scan and apply only if needed.
    3. Remediator: if `agents/work/quickfix.md` contains OPEN items, address only those items.
  </plan>
  <commands>
    - `python -m http.server`
  </commands>
  <verification>
    - Opening `http://localhost:8000/` shows the canvas, HUD placeholders, and controls reference.
    - Player moves with `WASD` and arrow keys with no console errors.
  </verification>
  <handoff>
    - Prepend historylog entry with files touched, commands run, and prompt path.
    - Overwrite `agents/orchestrate_status.md` with the completion marker when done.
  </handoff>
</prompt>
