<prompt id="013-hud-stratum-label" task="HUD stratum label">
  <objective>
    Show the player's current named stratum in the Corebound HUD and update the label as the player crosses stratum boundaries, while leaving gameplay systems and the rest of the HUD behavior unchanged.
  </objective>
  <context>
    - Repo context for this task is the Corebound prototype in `corebound/`.
    - Scope is limited to `corebound/index.html`, `corebound/game.js`, and `corebound/style.css` only if styling changes are actually needed.
    - `STRATA` and `getStratumForRow(row)` already exist in `corebound/game.js` and provide the named underground depth bands.
    - `updateHud()` already refreshes depth, cash, inventory, fuel, sell visibility, and shop state each frame.
    - The surface row (`depth === 0`) does not belong to an underground stratum, so the HUD needs a stable non-null label there as well.
  </context>
  <requirements>
    - Add a HUD row labeled `Stratum` with a value element `id="hud-stratum"` in `corebound/index.html`.
    - Cache the new HUD element in `corebound/game.js`.
    - Update `updateHud()` so the HUD shows `Surface` at depth `0` and the correct `STRATA` name for underground rows.
    - Keep the diff minimal: no new gameplay rules, no stratum config changes, and no unrelated HUD redesign.
  </requirements>
  <plan>
    1. Prompt-architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect the current HUD markup and `updateHud()` flow in `corebound/`.
    3. Developer: add the stratum HUD row, bind the new element, and set its text from the current player depth using existing stratum helpers.
    4. Developer: run the prompt commands to verify the markup exists and the HUD logic reports `Surface`, `Shallows`, `Mid Depths`, and `Deep Core` at the expected depths.
    5. Refactor: perform a brief evidence-backed scan and make no changes unless implementation or verification surfaces a low-risk issue.
    6. Remediator: skip because `agents/work/quickfix.md` has no OPEN items.
  </plan>
  <commands>
    - `rg -n "hud-stratum" corebound/index.html`
    - `timeout 2s python3 -m http.server 8000`
    - `node - <<'NODE'`
  </commands>
  <verification>
    - `corebound/index.html` contains a `Stratum` HUD row with `id="hud-stratum"`.
    - `updateHud()` writes `Surface` at depth `0`.
    - `updateHud()` writes the correct named stratum when the player depth moves into each configured underground band.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` if execution cannot be completed.
  </handoff>
</prompt>
