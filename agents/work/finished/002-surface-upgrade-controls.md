<prompt id="002-surface-upgrade-controls" task="Surface Upgrade + Controls Reference">
  <objective>
    Add a surface-only shop UI with a single purchasable upgrade that increases inventory capacity, wire purchase logic that updates the gameplay stat and HUD immediately, and display an on-screen controls reference panel.
  </objective>
  <context>
    - Repo root: /mnt/f/_evolve/turnloop
    - Corebound game lives under corebound/
    - Keep changes minimal and within turnloop/
    - Verification uses a local HTTP server
  </context>
  <requirements>
    - Add upgrade data (name, cost, capacity increase) and render a shop section with a Buy button
    - Disable Buy when player is not at surface or lacks cash
    - On purchase, deduct cash, increase inventory capacity immediately, and update HUD
    - Controls reference panel lists movement, digging, and selling/shop actions, visible on-screen
    - Limit scope to corebound/game.js, corebound/index.html, corebound/style.css
  </requirements>
  <plan>
    1. Developer: Inspect current HUD/inventory/cash flow; add upgrade data and purchase logic gated by surface depth and cash.
    2. Developer: Add shop UI markup and controls reference panel in index.html, style minimally to fit HUD.
    3. Developer: Wire button enable/disable state and HUD updates in game.js.
    4. Refactor: Quick scan for low-risk cleanup; do not expand scope.
    5. Remediator: If agents/work/quickfix.md has OPEN items, address only those.
  </plan>
  <commands>
    - rg -n "inventory|capacity|cash|hud|depth" corebound/game.js
    - rg -n "hud|controls|shop" corebound/index.html
    - rg -n "hud|controls|shop" corebound/style.css
    - python3 -m http.server
  </commands>
  <verification>
    - At depth 0 with enough cash, clicking Buy increases inventory capacity immediately.
    - Buy is disabled when not at surface or when cash is insufficient.
    - Controls panel is visible without leaving the game page.
  </verification>
  <handoff>
    - Prepend a history log entry with summary, files, commands, decisions, follow-ups, and prompt path.
    - Write orchestrate status marker when finished.
  </handoff>
</prompt>
