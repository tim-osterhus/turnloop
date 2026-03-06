<prompt id="008-low-fuel-warning-state" task="Low-Fuel Warning State">
  <objective>
    Add a low-fuel warning visual state in the HUD by styling the Fuel row and toggling that style when fuel is at or below the low-fuel threshold, clearing it once fuel rises above the threshold.
  </objective>
  <context>
    - Repo root: /mnt/f/_evolve/turnloop
    - Corebound game code lives in corebound/ with HUD in corebound/style.css and corebound/game.js
    - Keep changes minimal and within turnloop/
  </context>
  <requirements>
    - Add a CSS warning style for the Fuel row (example: .hud-row.is-low .hud-value)
    - Cache the Fuel row element and toggle warning class in updateHud when fuel <= FUEL_LOW_THRESHOLD
    - Clear the warning when fuel rises above FUEL_LOW_THRESHOLD
    - Do not change fuel drain/refuel tuning
  </requirements>
  <plan>
    1. (developer) Inspect corebound/style.css and add a warning style for the Fuel HUD row.
    2. (developer) Inspect corebound/game.js, cache the Fuel row element, and toggle warning class in updateHud.
    3. (refactor) Quick scan for low-risk cleanups; log if none.
    4. (remediator) If agents/work/quickfix.md has OPEN items, address only those.
  </plan>
  <commands>
    - python3 -m http.server
  </commands>
  <verification>
    - Fuel row visually changes when fuel <= 20
    - Warning clears when fuel > 20 (e.g., after refuel)
  </verification>
  <handoff>
    - Prepend history entry to agents/historylog.md with prompt path
    - Overwrite agents/orchestrate_status.md with ### BUILDER_COMPLETE when done
  </handoff>
</prompt>
