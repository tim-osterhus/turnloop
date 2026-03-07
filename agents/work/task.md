## 2026-03-06 — README Execution-Loop Regression Usage
Goal: Document the local execution-loop regression commands in `README.md` and state clearly that they run against isolated temp state under the repo root.
Prompt: agents/work/prompts/031-readme-execution-loop-regression-usage.md
Scope:
- In: Add concise README instructions for the happy-path and quickfix harness commands, note their isolated temp-state behavior, and keep the rest of the loop documentation intact.
- Out: Changes to loop behavior, harness implementation details beyond usage, or broader documentation rewrites.
Assumptions: The harness scripts remain standalone shell entrypoints under `agents/scripts/`.
Files to touch:
- README.md
Steps:
1. Add a short README subsection for local execution-loop regression coverage near the loop-running or testing guidance.
2. Document `bash agents/scripts/test_orchestrate_happy_path.sh` and `bash agents/scripts/test_orchestrate_quickfix_demotion.sh`.
3. State explicitly that both commands operate on isolated temp state under the repo root and do not mutate the real queue state when they pass.
4. Verify the README references both harness script names and the isolated temp-state note.
Acceptance:
- `README.md` mentions both execution-loop regression harness scripts by name.
- The README states that the harnesses run against isolated temp state.
- A grep command against `README.md` finds both script names and the isolation note.
Verification commands:
- `rg -n 'test_orchestrate_happy_path.sh|test_orchestrate_quickfix_demotion.sh|isolated temp state' README.md` — Expected: README contains both harness commands and the isolation note.
