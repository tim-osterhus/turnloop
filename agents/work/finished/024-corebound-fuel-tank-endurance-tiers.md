<prompt id="024-corebound-fuel-tank-endurance-tiers" task="Fuel Tank Endurance Tiers">
  <objective>
    Update the Corebound fuel upgrade line so purchased Fuel Tank tiers immediately raise the in-session fuel cap, the surface auto-refuel logic fills to that upgraded maximum, and HUD/low-fuel checks consistently read from the derived cap instead of a fixed max-fuel assumption.
  </objective>
  <context>
    - Repo context comes from `agents/outline.md`; the gameplay logic for this task lives in `corebound/game.js`.
    - Scope stays limited to `corebound/game.js` plus the required prompt link in `agents/work/task.md`.
    - The shop already uses shared `UPGRADE_LINES` data and derived upgrade-effect helpers to apply purchased tier effects.
    - Keep changes minimal and preserve existing mining, cargo, selling, and movement behavior outside fuel-cap handling.
  </context>
  <requirements>
    - Replace the fixed max-fuel assumption with a derived max-fuel helper.
    - Keep the Fuel Tank tiers defined in the shared upgrade-line data structure with explicit costs and fuel-capacity effects.
    - Ensure buying Fuel Tank at the surface applies the new cap immediately in the same session.
    - Ensure surface auto-refuel and HUD low-fuel state both use the derived max fuel consistently.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: update `corebound/game.js` so Fuel Tank tier data and all fuel-cap reads flow through a derived max-fuel helper.
    - 3. Developer: verify that purchases and surface refills clamp/fill against the upgraded cap and run the required commands.
    - 4. Refactor: perform a brief evidence-based improvement scan and leave it no-op unless verification reveals a clear low-risk cleanup.
  </plan>
  <commands>
    - `rg -n "getMaxFuel|Fuel Tank|clampFuel|hudFuel" corebound/game.js`
    - `node --check corebound/game.js`
  </commands>
  <verification>
    - Fuel Tank tier values and costs remain defined in shared upgrade data.
    - Buying Fuel Tank at the surface increases the current max fuel immediately.
    - Returning to the surface refills fuel to the upgraded maximum in the same session.
    - HUD fuel text and low-fuel checks both use the derived max fuel.
    - `node --check corebound/game.js` exits 0.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
