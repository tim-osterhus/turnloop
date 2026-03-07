<prompt id="001-corebound-foundation" task="Corebound foundation scaffolding and movement simulation">
  <objective>
    Turn the existing default Vite scaffold in `corebound/` into a runnable React/TypeScript game foundation with a deterministic fixed-timestep simulation loop, vehicle movement, basic terrain collision, configurable drill timings, and physics tests that verify determinism and drill behavior.
  </objective>
  <context>
    - The active task is `2026-03-07 — Corebound Foundation: Scaffolding & Movement Simulation`.
    - Work must stay within `turnloop/`, with primary changes limited to `corebound/` plus required agent bookkeeping files.
    - `corebound/` already contains a Vite React TypeScript scaffold and installed dependencies.
    - Acceptance requires `npm run dev` to start and `npm test tests/physics.test.ts` to pass.
    - Prompt artifacts remain in `agents/work/prompts/`; do not move them to finished.
  </context>
  <requirements>
    - Preserve or complete the Vite/React/TS setup in `corebound/`.
    - Implement a fixed-timestep simulation loop in `corebound/src/simulation/physics.ts`.
    - Define vehicle state and movement in `corebound/src/simulation/vehicle.ts`.
    - Include basic solid-terrain collision behavior and drill timings for dirt and hard material.
    - Add unit tests for deterministic movement and drill timing behavior.
    - Keep diffs minimal and reviewable.
  </requirements>
  <plan>
    1. Developer: inspect the existing Corebound scaffold and identify the minimal set of files needed for the simulation foundation.
    2. Developer: implement simulation primitives, vehicle movement, collision, and drilling behavior.
    3. Developer: replace the placeholder app with a minimal controllable simulation view.
    4. Developer: add and run targeted tests and the required verification commands.
    5. Refactor: perform a brief evidence-backed improvement pass only if needed.
    6. Historian: prepend the Builder run entry with files touched, commands, decisions, and prompt path.
  </plan>
  <commands>
    - `cd corebound && npm test tests/physics.test.ts`
    - `cd corebound && npm run build`
  </commands>
  <verification>
    - `corebound/` runs as a Vite React TypeScript app.
    - Physics behavior is frame-rate independent under fixed-timestep stepping.
    - Terrain collision prevents movement into solid cells.
    - Drill timings match 0.35s for dirt and 0.75s for harder material.
    - The listed commands complete successfully.
  </verification>
  <handoff>
    - Record implementation summary, files touched, commands run, and any refactor no-op result in `agents/historylog.md`.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` on blocker.
  </handoff>
</prompt>
