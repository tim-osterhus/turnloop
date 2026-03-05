<prompt id="001-hardening-bounds-ui-guards" task="Hardening: Bounds + UI Guards">
  <objective>
    Stabilize edge cases for movement, digging, selling, and upgrades in the Corebound prototype by adding bounds checks, robust UI button states, and non-negative HUD values, without introducing new features or dependencies.
  </objective>
  <context>
    - Repo: Turnloop, Corebound game lives under `corebound/`.
    - Scope is limited to `corebound/game.js` and `corebound/index.html`.
    - Changes must be minimal and safe; no new dependencies.
  </context>
  <requirements>
    - Clamp movement and dig target coordinates to world bounds; abort invalid digs safely.
    - Ensure sell and upgrade handlers no-op when invalid and keep buttons disabled in those states.
    - Guard HUD values against negative numbers or NaN display states.
    - Do not add new features or visual polish.
  </requirements>
  <plan>
    1. (developer) Inspect current movement, digging, selling, upgrade, and HUD update flows in `corebound/game.js` and UI in `corebound/index.html`.
    2. (developer) Implement bounds checks and safe aborts for invalid targets; tighten UI disabled states and handler guards; clamp HUD values.
    3. (refactor) Perform a brief low-risk scan for cleanup; only change if clearly beneficial.
    4. (remediator) If `agents/work/quickfix.md` has OPEN items, address only those items.
  </plan>
  <commands>
    - `python -m http.server`
  </commands>
  <verification>
    - Digging at world edges does not throw errors.
    - Sell and upgrade actions are no-ops when invalid and buttons stay disabled.
    - HUD values remain consistent and non-negative (no NaN).
  </verification>
  <handoff>
    - Prepend a history entry in `agents/historylog.md` with summary, files touched, commands, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
