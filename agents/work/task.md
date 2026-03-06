## 2026-03-06 — Corebound Upgrade Ladder Data Scaffold
Goal: Replace the one-off surface upgrade state with structured upgrade-line data and session depth milestone tracking in `corebound/game.js`.
Prompt: `agents/work/prompts/021-corebound-upgrade-ladder-data-scaffold.md`
Scope:
- In: Add data-driven upgrade line definitions, per-line tier state, and deepest-depth session tracking helpers.
- Out: Final multi-row shop markup, visual styling, or gameplay tuning beyond the scaffold.
Assumptions: Track unlock progress as the deepest tile row reached this session; each upgrade line starts with two tiers for the first ladder pass.
Files to touch:
- corebound/game.js
Steps:
1. Replace the single `SURFACE_UPGRADE` definition with a structured upgrade collection that describes line ids, names, tier data, and unlock requirements.
2. Add session state for current purchased tier per upgrade line and the deepest depth reached during the session.
3. Add generic helpers for reading the next tier, checking unlock status, checking affordability, and rejecting invalid or maxed purchases.
4. Keep the current starting balance, inventory, fuel, and movement defaults unchanged until later cards wire tier effects into them.
Acceptance:
- `corebound/game.js` defines at least three upgrade lines with two tiers each in structured data.
- Session state records deepest depth reached and exposes it to unlock checks.
- `node --check corebound/game.js` exits `0`.
Verification commands:
- `rg -n "deepestDepth|tiers|canPurchaseUpgrade|purchaseUpgrade|unlock" corebound/game.js` — Expected: matches for session-depth tracking plus generic upgrade helpers and tier data.
- `node --check corebound/game.js` — Expected: exit `0` with no syntax output.
