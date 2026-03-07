<prompt id="001-corebound-economy-base-interactions" task="Corebound economy base interactions and upgrade tuning">
  <objective>
    Implement the first-pass economy layer for Corebound by adding base interactions for selling cargo, refueling, and repairing, defining the initial upgrade set and escalating costs, centralizing economy tuning constants, and adding tests that verify the first-session affordability targets.
  </objective>
  <context>
    - Repo context from `agents/outline.md`: work is limited to `turnloop/`, targeting the nested `corebound/` project.
    - `corebound` currently has world generation, vehicle motion, and ore definitions, but no dedicated economy or upgrade modules yet.
    - Ore sell values already exist in `corebound/src/content/ores.ts`; new tuning should avoid duplicating or scattering gameplay constants.
    - Verification in `agents/work/task.md` requires `cd corebound && npm test tests/economy.test.ts`.
  </context>
  <requirements>
    - Add base interaction logic for selling cargo, refueling, and repairing.
    - Define upgrade categories: Engine, Fuel, Cargo, Drill.
    - Implement escalating upgrade costs and stat improvements that are observable in code/tests.
    - Centralize gameplay tuning constants in `corebound/src/content/tuning.ts`.
    - Add economy-focused tests covering the 8-minute and 15-minute affordability targets.
    - Keep diffs minimal and avoid unrelated UI work or hazard systems.
  </requirements>
  <plan>
    - 1. Developer: inspect existing world, vehicle, and ore modules to define a minimal economy state shape compatible with current code.
    - 2. Developer: add `tuning.ts` plus new `economy.ts` and `upgrades.ts` modules, exporting the types and helpers needed for cargo sale, service actions, upgrade definitions, and progression math.
    - 3. Developer: add `economy.test.ts` to verify service interactions, upgrade behavior, and the affordability targets using deterministic values.
    - 4. Developer: run the required economy test command and fix any failures.
    - 5. Refactor: perform a brief evidence-based improvement pass only if tests or code structure reveal a low-risk issue.
    - 6. Historian: prepend the Builder run entry to `agents/historylog.md`.
  </plan>
  <commands>
    - `cd corebound && npm test tests/economy.test.ts`
  </commands>
  <verification>
    - Economy tests pass with the required command.
    - New constants live in `corebound/src/content/tuning.ts`.
    - Upgrade costs and service actions are deterministic and covered by tests.
    - Affordability tests explicitly demonstrate at least one upgrade within 8 minutes and two upgrades within 15 minutes under the chosen deterministic assumptions.
  </verification>
  <handoff>
    - Record the prompt path, touched files, commands run, and refactor/remediation outcomes in `agents/historylog.md`.
    - If `agents/work/quickfix.md` has no OPEN items, record that as a no-op in the history entry.
  </handoff>
</prompt>
