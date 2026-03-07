<prompt id="022-corebound-multi-line-surface-shop-ui-shell" task="Corebound Multi-Line Surface Shop UI Shell">
  <objective>
    Replace the single featured surface upgrade row with a generated multi-line shop shell that renders every configured upgrade line with consistent fields for level, next effect, cost, status, and purchase availability, while keeping the current gameplay loop and startup behavior intact.
  </objective>
  <context>
    - Scope is limited to `corebound/index.html`, `corebound/style.css`, `corebound/game.js`, and the required prompt link in `agents/work/task.md`.
    - `corebound/game.js` already defines structured `UPGRADE_LINES`, purchase helpers, and derived stat calculations from purchased tiers.
    - The current HUD markup still hard-codes one featured upgrade row with a single button and detail string.
    - The task only requires a UI shell for multiple lines and availability states; final balance tuning for specific upgrade effects stays out of scope.
    - `agents/work/quickfix.md` is resolved, so remediator work is only needed if new OPEN items appear.
  </context>
  <requirements>
    - Replace the single hard-coded shop row in `corebound/index.html` with a container that supports generated upgrade rows.
    - Add baseline styling hooks in `corebound/style.css` for row layout plus locked, affordable, unaffordable, and maxed states.
    - Render one row per configured upgrade line in `corebound/game.js` with visible name, level, next effect, cost, and status fields.
    - Keep the surface shop visible at the surface and avoid startup/runtime errors when the page loads.
    - Keep changes minimal and reviewable.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: update `corebound/index.html` to provide a generated shop list container instead of a single upgrade row.
    - 3. Developer: update `corebound/style.css` with compact multi-line shop layout and availability state hooks.
    - 4. Developer: update `corebound/game.js` to build and refresh one shop row per upgrade line, including purchase button behavior and status text.
    - 5. Developer: run the required verification commands and confirm the page starts without script errors.
    - 6. Refactor: perform a brief, evidence-based improvement scan and keep it no-op unless a small verified fix is justified.
    - 7. Builder: prepend `agents/historylog.md` and overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `rg -n "hud-shop-list|shop-line|shop-status|shop-level" corebound/index.html corebound/style.css corebound/game.js`
    - `python3 -m http.server 8000`
  </commands>
  <verification>
    - The shop renders at least three generated upgrade lines without duplicated hard-coded HTML rows.
    - Each line shows visible level, next effect, cost, and availability state text.
    - Locked, affordable, unaffordable, and maxed styling hooks exist in CSS and are applied by the renderer.
    - `python3 -m http.server 8000` starts successfully and `/corebound/` loads without startup console errors.
  </verification>
  <handoff>
    - Record the prompt path, files touched, commands run, refactor result, and quickfix/remediator status in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
