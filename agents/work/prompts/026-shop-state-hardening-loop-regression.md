<prompt id="026-shop-state-hardening-loop-regression" task="Shop State Hardening + Loop Regression">
  <objective>
    Harden the Corebound surface shop so invalid upgrade purchases are true no-ops, align the rendered row styling and button labels with the actual purchase rules, and confirm the expanded shop still preserves the normal mine, sell, fuel-drain, low-fuel, and surface-auto-refuel gameplay loop.
  </objective>
  <context>
    - Repo context comes from `agents/outline.md`; the active gameplay files for this task are `corebound/game.js` and `corebound/style.css`.
    - The current shop already renders multiple upgrade lines from shared `UPGRADE_LINES` data and uses helper state to decide affordability, locking, and maxed states.
    - Keep the change minimal and scoped to purchase-guard hardening, row/button state polish, and regression fixes discovered while testing the existing loop.
    - Do not expand scope into persistence, combat, fail states, or UI redesign.
  </context>
  <requirements>
    - `purchaseUpgrade()` must no-op when the player is below the surface, lacks cash, has not met an unlock condition, or the selected line is maxed.
    - The shop UI must present locked, affordable, unaffordable, and maxed rows distinctly, with button labels and disabled states that match the actual purchase rules.
    - Existing digging, ore collection, selling, movement fuel drain, low-fuel warning, and surface auto-refuel behavior must continue to work after the shop-state changes.
    - Keep diffs minimal and avoid changing unrelated gameplay behavior.
  </requirements>
  <plan>
    - 1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    - 2. Developer: inspect the existing shop-state helpers and purchase flow in `corebound/game.js`, plus the related row styling in `corebound/style.css`.
    - 3. Developer: implement the smallest guard/styling changes needed so purchase behavior and rendered state stay in sync.
    - 4. Developer: run the required syntax/server commands and verify the mine-sell-refuel loop in a live browser session.
    - 5. Refactor: perform a brief evidence-based follow-up scan and keep it no-op unless verification exposes a clear low-risk cleanup.
  </plan>
  <commands>
    - `rg -n "purchaseUpgrade|canPurchaseUpgrade|getShopLineState|renderShop|shop-line|shop-status|shop-button|surface|fuel|warning|sell" corebound/game.js corebound/style.css`
    - `node --check corebound/game.js`
    - `python3 -m http.server 8000`
  </commands>
  <verification>
    - Invalid purchase attempts stay disabled in the UI and produce no purchase effect when below the surface, short on cash, locked, or maxed.
    - The shop row/button styling clearly reflects locked, affordable, unaffordable, and maxed states.
    - A live browser regression pass at `http://localhost:8000/corebound/` confirms digging, ore collection, selling, movement fuel drain, low-fuel warning, and surface auto-refuel still work without normal-play console errors.
    - `node --check corebound/game.js` exits 0.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands run, decisions, follow-ups, prompt path, and report artifacts.
    - If refactor finds no evidence-backed improvement, record that no-op outcome in the history log summary/decisions.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` when finished.
  </handoff>
</prompt>
