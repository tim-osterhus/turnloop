<prompt id="008-movement-fuel-drain-empty-speed" task="Movement Fuel Drain + Empty Speed">
  <objective>
    Implement fuel draining during active movement and slow movement when fuel is empty, using a shared clamp helper and minimal changes in corebound/game.js.
  </objective>
  <context>
    - Repo: turnloop; gameplay code lives in corebound/game.js
    - Task scope: only movement fuel drain and empty-speed multiplier
    - Use a clamp helper for fuel updates: 0..FUEL_MAX
    - Avoid adding new features outside task scope
  </context>
  <requirements>
    - Deduct FUEL_MOVE_RATE * deltaSeconds only when movement input results in movement
    - Apply FUEL_EMPTY_SPEED_MULT when fuel is 0 (or less) before movement delta calculations
    - Clamp fuel after updates to 0..FUEL_MAX
    - Touch only corebound/game.js
  </requirements>
  <plan>
    1. Prompt-architect: produce this prompt artifact and link it in agents/work/task.md
    2. Developer: add clamp helper, integrate fuel drain in movePlayer, apply empty-speed multiplier before deltas
    3. Refactor: quick scan for low-risk cleanup; note no changes if none
    4. Remediator: only if agents/work/quickfix.md has OPEN items
  </plan>
  <commands>
    - python3 -m http.server
  </commands>
  <verification>
    - Fuel drains only while movement succeeds
    - Fuel holds steady while idle
    - Movement speed is visibly slower at fuel 0
  </verification>
  <handoff>
    - Prepend history entry in agents/historylog.md
    - Update agents/orchestrate_status.md to ### BUILDER_COMPLETE on success
  </handoff>
</prompt>
