## Goal
Validate that `corebound/game.js` replaces the one-off surface upgrade state with a structured upgrade-ladder scaffold and session depth milestone tracking, without changing the current starting gameplay defaults.

## Expected behavior
- `corebound/game.js` defines structured upgrade-line data rather than a single upgrade constant.
- The structured data includes at least three upgrade lines.
- Each upgrade line includes at least two tiers for this first ladder pass.
- Session state records the deepest tile row reached during the current session.
- Unlock checks can read the deepest session depth.
- Generic helpers exist for reading the next tier, checking unlock status, checking affordability, and rejecting invalid or maxed upgrade purchases.
- The current starting balance, inventory, fuel, and movement defaults remain unchanged unless explicitly derived from purchased tiers during play.

## Expected file changes
- `corebound/game.js` contains new structured upgrade definitions with per-line ids, names, tier data, and unlock requirements.
- `corebound/game.js` contains per-line purchased-tier state and deepest-depth session tracking helpers.
- No other file changes are required for this task.

## Verification commands
- `rg -n "deepestDepth|tiers|canPurchaseUpgrade|purchaseUpgrade|unlock" corebound/game.js`
- `node --check corebound/game.js`
- `rg -n "startingCash|inventory|fuel|maxFuel|player\\.speed|moveSpeed" corebound/game.js`

## Non-functional requirements
- The implementation must stay within `corebound/game.js`.
- `corebound/game.js` must remain syntactically valid JavaScript.
- The scaffold should be data-driven and generic enough to support multiple upgrade lines and tiers without one-off purchase logic.

## Notes / assumptions
- Unlock progress is based on the deepest tile row reached in the current session.
- This task is a scaffold only; multi-row shop UI, visual styling, and gameplay tuning beyond the scaffold are out of scope.
