<prompt id="023-corebound-cargo-pods-capacity-tiers" task="Cargo Pods Capacity Tiers">
  <objective>
    Update the Corebound cargo upgrade line so purchased Cargo Pods tiers immediately raise inventory capacity in-session and the shop continues advancing through later cargo tiers until the line is maxed.
  </objective>
  <context>
    - Repo context comes from `agents/outline.md`; the active gameplay file is `corebound/game.js`.
    - Scope is limited to `corebound/game.js` plus the required prompt link in `agents/work/task.md`.
    - The current upgrade shop already renders from shared `UPGRADE_LINES` data and uses purchased-tier counts to drive row state.
    - Keep changes minimal and preserve existing ore collection, selling, and non-cargo upgrade behavior.
  </context>
  <requirements>
    - Keep Cargo Pods tier data in the shared upgrade-line structure.
    - Ensure buying Cargo Pods immediately updates the effective inventory capacity in the same session.
    - Keep the shop row advancing through current level, next effect, next cost, and maxed state after each purchase.
    - Do not expand scope into fuel-balance retuning or new depth-gated upgrade work.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: update `corebound/game.js` so Cargo Pods purchases apply inventory-capacity changes immediately and the existing tiered shop state remains correct after each buy.
    - 3. Developer: run the required verification commands and capture outcomes.
    - 4. Refactor: perform a brief evidence-based no-op-or-small-pass review and keep it no-op unless verification reveals a clear low-risk improvement.
  </plan>
  <commands>
    - `rg -n "cargo|capacity|inventory\\.capacity" corebound/game.js`
    - `node --check corebound/game.js`
  </commands>
  <verification>
    - Cargo Pods tier values/costs remain defined in shared upgrade data.
    - Buying Cargo Pods updates inventory capacity immediately in the running session.
    - Cargo Pods can still advance to a later tier after the first purchase until maxed.
    - `node --check corebound/game.js` exits 0.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
