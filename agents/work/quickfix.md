# Quickfix

- Status: RESOLVED (2026-03-06)
- Issue: `corebound/game.js` now stores tier `effects` data, but `purchaseUpgrade()` only subtracts cash and increments the purchased-tier counter. No purchased tier modifies inventory capacity, fuel capacity, or movement speed.
- Resolution: Applied the purchased tier data through derived-stat helpers so inventory capacity, fuel capacity, and movement speed now scale from purchased tiers without mutating the starting defaults.
- Result: The existing single-row surface shop flow still purchases one featured line at a time, and successful purchases now affect gameplay again while preserving the structured upgrade scaffold.
- Verification: `rg -n "purchaseUpgrade|effects|inventoryCapacity|fuelCapacity|moveSpeed|inventory\\.capacity|player\\.speed" corebound/game.js`
- Verification: `node --check corebound/game.js`
