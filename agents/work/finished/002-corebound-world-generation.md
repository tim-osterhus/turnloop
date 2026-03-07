<prompt id="002-corebound-world-generation" task="Corebound world generation and ore distribution">
  <objective>
    Implement deterministic seeded world generation for Corebound, including ore tier definitions, a visible surface opening with a clear descent path, a guaranteed early sellable ore node reachable from spawn, and tile removal through drilling. Keep the change set minimal and centered on simulation/content code plus focused tests.
  </objective>
  <context>
    - Corebound currently has fixed-timestep simulation and vehicle drilling in `src/simulation/vehicle.ts`.
    - The task card names `world.ts`, `ores.ts`, and `world.test.ts`; these files do not exist yet and must be created in the current repo layout.
    - `corebound/src/content/index.ts` is currently empty and can export new content modules.
    - Verification required by the task card is `cd corebound && npm test tests/world.test.ts`.
    - Builder flow also requires a brief refactor scan, quickfix OPEN-item check, a prepended history entry, and an overwrite of `agents/orchestrate_status.md`.
  </context>
  <requirements>
    - Add a seeded RNG implementation with deterministic output and optional query-parameter seed override support.
    - Define four ore tiers with depth bands and at least one sellable early-game ore.
    - Generate a tile grid with a surface visibility/opening line and a clear path below spawn.
    - Guarantee at least one sellable ore node is reachable within the early-game opening/travel window.
    - Support drilling by removing world tiles from generated state.
    - Add tests covering seed determinism and the guaranteed ore placement behavior.
    - Do not expand into economy, HUD, or unrelated gameplay systems.
  </requirements>
  <plan>
    1. Prompt Architect: create this prompt artifact and link it from `agents/work/task.md`.
    2. Developer: inspect current simulation interfaces and add `src/content/ores.ts`, `src/simulation/world.ts`, and `tests/world.test.ts`, plus any minimal export wiring required.
    3. Developer: run `cd corebound && npm test tests/world.test.ts` and capture the result.
    4. Refactor: perform a brief evidence-based scan; if nothing is justified, record a no-op outcome.
    5. Remediator: check `agents/work/quickfix.md` for OPEN items and only act if present.
    6. Historian: prepend a Builder entry to `agents/historylog.md`, then overwrite `agents/orchestrate_status.md` with the final marker.
  </plan>
  <commands>
    - `cd corebound && npm test tests/world.test.ts`
  </commands>
  <verification>
    - Matching seeds produce identical generated layouts and metadata.
    - The world generator creates a visible opening and clear initial path from spawn.
    - The guaranteed opening ore is present, sellable, and reachable in generated worlds across multiple seeds.
    - Drilling/removal updates generated world state as expected in test coverage.
  </verification>
  <handoff>
    - Record files touched, commands run, refactor outcome, quickfix outcome, and the prompt path in `agents/historylog.md`.
    - Leave the prompt artifact in `agents/work/prompts/`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` on blockers.
  </handoff>
</prompt>
