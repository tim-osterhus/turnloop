<prompt id="021-corebound-upgrade-ladder-data-scaffold" task="Corebound Upgrade Ladder Data Scaffold">
  <objective>
    Replace the one-off surface upgrade handling in `corebound/game.js` with structured upgrade-line data, per-line purchased-tier session state, and deepest-depth session tracking helpers that future upgrade UI and effect wiring can reuse without changing the current starting gameplay values.
  </objective>
  <context>
    - Scope is limited to `corebound/game.js` plus the required prompt link in `agents/work/task.md`.
    - The current game stores one boolean upgrade flag and a single hard-coded `SURFACE_UPGRADE` definition.
    - The task requires at least three upgrade lines with two tiers each, with unlock progress based on the deepest tile row reached during the current session.
    - The current starter cash, capacity, fuel, and movement defaults must stay unchanged for this scaffold pass.
    - `agents/work/quickfix.md` is closed, so remediator work is only needed if OPEN items appear.
  </context>
  <requirements>
    - Define structured upgrade-line data with line ids, names, tier arrays, and unlock requirements.
    - Store purchased tier progress per upgrade line and deepest-depth session state.
    - Add generic helpers for next-tier lookup, unlock checks, affordability checks, and guarded purchase rejection.
    - Keep the existing surface shop wiring functional without introducing broader markup or tuning changes.
    - Keep the diff minimal and reviewable.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: replace the single upgrade definition/state in `corebound/game.js` with structured upgrade-line data and generic purchase helpers.
    - 3. Developer: track deepest depth reached during the session and expose it to unlock checks and HUD/shop state.
    - 4. Developer: run the required verification commands and confirm they pass.
    - 5. Refactor: perform a brief evidence-based no-op improvement scan and only keep changes if verification still passes.
    - 6. Builder: prepend `agents/historylog.md` and overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `rg -n "deepestDepth|tiers|canPurchaseUpgrade|purchaseUpgrade|unlock" corebound/game.js`
    - `node --check corebound/game.js`
  </commands>
  <verification>
    - `corebound/game.js` defines at least three upgrade lines with two tiers each in structured data.
    - Session state records deepest depth reached and uses it in unlock checks.
    - Generic upgrade helpers exist for next-tier lookup, affordability, unlocks, and guarded purchases.
    - `node --check corebound/game.js` exits `0`.
  </verification>
  <handoff>
    - Record the prompt path, files touched, commands run, refactor result, and quickfix/remediator status in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success, or `### BLOCKED` if blocked.
  </handoff>
</prompt>
