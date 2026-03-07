<prompt id="001-save-state-tutorial" task="Corebound save state and tutorial prompts">
  <objective>
    Implement persistent local save/load support for the Corebound game state, add a main menu that exposes Start, Continue, and Reset Save actions, and add contextual tutorial prompts that permanently dismiss once the player completes the associated action. Keep the changes minimal and verify them with the required persistence test command.
  </objective>
  <context>
    - Project context comes from `agents/outline.md`: work is limited to `turnloop/corebound/`.
    - Active task scope is defined in `agents/work/task.md`.
    - Target files named in scope are `corebound/src/simulation/persistence.ts`, `corebound/src/render/Menu.tsx`, and `corebound/src/simulation/tutorial.ts`.
    - Acceptance requires persistence across reloads and first-run tutorial prompts that disappear after successful completion.
    - Final smoke-check is explicitly out of scope.
  </context>
  <requirements>
    - Implement serialization and restore behavior for vehicle stats, economy, and world seed using LocalStorage.
    - Add menu behavior for Start, Continue, and Reset Save.
    - Implement contextual tutorial prompts for R18 and make each prompt dismiss permanently after the relevant action succeeds.
    - Add tests covering tutorial completion triggers as required by R22.
    - Keep diffs minimal and do not expand beyond the listed scope unless required to complete the task safely.
  </requirements>
  <plan>
    - 1. Developer: inspect the existing Corebound persistence, menu, and tutorial flow plus relevant tests to determine minimal integration points.
    - 2. Developer: implement persistence changes for save/load/reset and wire menu actions to new game / continue / reset behaviors.
    - 3. Developer: implement contextual tutorial state and dismissal-on-success behavior, then add or update focused tests.
    - 4. Developer: run `cd corebound && npm test tests/persistence.test.ts` and any smallest additional relevant test command needed for tutorial coverage.
    - 5. Refactor: perform a brief evidence-based improvement scan and either make a low-risk fix or record a no-op.
    - 6. Historian: prepend the run summary to `agents/historylog.md`.
  </plan>
  <commands>
    - `cd corebound && npm test tests/persistence.test.ts`
    - Additional focused tutorial test command only if needed after adding coverage.
  </commands>
  <verification>
    - Persistence test command completes successfully.
    - Game state save/load logic covers vehicle stats, economy, and world seed.
    - Menu exposes Start, Continue, and Reset Save behavior tied to persistence state.
    - Tutorial prompts appear for first-run context and no longer appear after successful completion of their associated action.
  </verification>
  <handoff>
    - Prepend a Builder entry to `agents/historylog.md` with summary, files touched, commands, decisions, follow-ups, prompt path, and report artifacts.
    - Overwrite `agents/orchestrate_status.md` with `### BUILDER_COMPLETE` on success or `### BLOCKED` on blocker.
  </handoff>
</prompt>
