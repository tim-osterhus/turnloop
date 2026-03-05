<prompt id="001-depth-weighted-ore-surface-selling" task="Depth-Weighted Ore + Surface Selling">
  <objective>
    Implement depth-weighted ore generation and add surface-only selling so inventory converts to cash at depth 0 with HUD updates, keeping changes minimal and within the specified Corebound files.
  </objective>
  <context>
    - Active task: `agents/work/task.md` dated 2026-03-05.
    - Target files: `corebound/game.js`, `corebound/index.html`, `corebound/style.css`.
    - Scope: depth-weighted ore distribution, surface sell control, inventory-to-cash conversion, HUD cash updates.
    - Out of scope: upgrades, persistence/storage.
    - Constraints from repo: keep changes minimal, do not introduce secrets, stay within `turnloop/`.
  </context>
  <requirements>
    - Bias ore generation so higher-value ore is more frequent at greater depth than near the surface.
    - Add a Sell button in the HUD that is visible/enabled only at depth 0 and when inventory is non-empty.
    - Implement selling to convert inventory to cash and clear inventory after sale.
    - Update the HUD cash total after selling.
  </requirements>
  <plan>
    1. Developer: inspect current ore generation, inventory, and HUD rendering in `corebound/game.js` and related UI in `corebound/index.html`/`corebound/style.css`.
    2. Developer: implement depth-weighted ore selection, add Sell button UI with depth/inventory gating, and selling logic with HUD refresh.
    3. Refactor: do a brief low-risk scan for simplifications or small cleanup; skip changes if none.
    4. Remediator: only if `agents/work/quickfix.md` has OPEN items.
  </plan>
  <commands>
    - NONE
  </commands>
  <verification>
    - At depth 0, Sell button appears and selling increases cash while clearing inventory.
    - Below depth 0, Sell button is hidden or disabled.
    - Deeper mining yields higher-value ore more frequently than near surface.
    - Manual check: `python -m http.server` and verify in browser.
  </verification>
  <handoff>
    - Prepend a history entry in `agents/historylog.md` with summary, files, commands, decisions, follow-ups, prompt path.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if blocked.
  </handoff>
</prompt>
