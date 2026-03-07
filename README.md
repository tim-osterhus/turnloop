# Turnloop

Turnloop is a minimal, public‑friendly agentic development framework built around a dual‑loop architecture.
It is designed to prove that a single agent can run continuous execution and research loops without stepping on itself.

## How It Works
Turnloop separates work into two always‑on loops:
- Execution loop: drains the task backlog, runs Builder and QA, and resolves quickfixes.
- Research loop: ingests prompts from `agents/ideas/inbox/`, validates and manages the oldest staging spec one-spec-at-a-time, and decomposes approved specs into backlog tasks.

The loops communicate only through files on disk, keeping state simple and auditable.

## How To Use Turnloop
1. Add research work by dropping a prompt file into `agents/ideas/inbox/`.
2. Add execution work by writing task cards into `agents/work/tasksbacklog.md`.
3. Start the loops (see Running The Loops below).
4. Monitor progress using:
   - `agents/orchestrate_status.md`
   - `agents/research_status.md`
   - `agents/historylog.md`
5. If a task is auto‑demoted, review it in `agents/work/tasksbackburner.md`.
6. To stop the loops, create `agents/AUTONOMY_COMPLETE`.

## Execution Loop (High Level)
1. Promote the top task card from `agents/work/tasksbacklog.md` into `agents/work/task.md`.
2. Run Builder (`agents/entrypoints/_start.md`) to implement the prompt artifact.
3. Run QA (`agents/entrypoints/_check.md`) to validate changes.
4. If QA returns `### QUICKFIX_NEEDED`, run Builder + QA up to two times.
5. If still failing, auto‑demote the card to `agents/work/tasksbackburner.md`.
6. On success, archive the task and move the prompt artifact to `agents/work/finished/`.

If the loop is blocked, it invokes the troubleshooter. Two consecutive troubleshoot failures also demote the card.

## Research Loop (High Level)
1. Read the oldest prompt in `agents/ideas/inbox/`.
2. Run Researcher to write a spec into `agents/ideas/staging/`.
3. Validate the oldest staging spec with `agents/scripts/validate_spec.sh`; failures write reports to `agents/ideas/validation_reports/` and block the Manager run for that one-spec-at-a-time cycle.
4. Run Manager to decompose the oldest staging spec one-spec-at-a-time into task cards in `agents/work/tasksbacklog.md`, then move only the processed oldest staging spec to `agents/ideas/specs/` and leave newer staging specs in `agents/ideas/staging/` when validation passes.

If research is blocked, the loop invokes the Mechanic. Two consecutive mechanic blocks move the offending file to `agents/ideas/nonviable/`.

## Core Concepts
- Status files are overwrite‑only markers:
  - Execution: `agents/orchestrate_status.md`
  - Research: `agents/research_status.md`
- Every run prepends a history log entry in `agents/historylog.md`.
- Prompt artifacts live in `agents/work/prompts/` and are moved to `agents/work/finished/` after QA.
- Task cards use `##` headings and live in `agents/work/tasksbacklog.md`.
- The research loop runs `agents/scripts/validate_spec.sh` before Manager on the oldest staging spec; failures write reports under `agents/ideas/validation_reports/` and block Manager for that one-spec-at-a-time cycle.

## Repository Layout
- `agents/entrypoints/`: entry prompts for each stage.
- `agents/roles/`: reusable role instructions.
- `agents/scripts/`: long‑running loop scripts and watchdog.
- `agents/work/`: active task, backlog, archive, expectations, quickfix, and prompt artifacts.
- `agents/ideas/`: research intake plus staged and processed specs (`inbox/`, `staging/`, `specs/`, `processed/`, `nonviable/`).
- `agents/historylog.md`: prepend‑only run log.
- `corebound/`: separate git repo for the Corebound prototype game.
- `site/`: generated public journal site built from `agents/historylog.md`.

## Running The Loops
These scripts are designed to be long‑running foreground processes:

```bash
bash agents/scripts/orchestrate_loop.sh
bash agents/scripts/research_loop.sh
```

A watchdog script can be used to restart loops if they stop:

```bash
bash agents/scripts/loops_watchdog.sh
```

## Execution Loop Regression Harnesses
Use the local harnesses below to regression-test the execution loop without mutating the real queue state:
- `bash agents/scripts/test_orchestrate_happy_path.sh`
- `bash agents/scripts/test_orchestrate_quickfix_demotion.sh`

Both harnesses run against isolated temp state under the repo root and leave the real queue files untouched when they pass.

## Task Cards
Each task card should be a small, testable unit of work and must start with a double‑hash heading:

```md
## YYYY-MM-DD — Short Title
```

Task cards belong in `agents/work/tasksbacklog.md` and should include explicit file paths, numbered steps, acceptance checks, and verification commands.

## Runners
Turnloop expects a CLI runner such as Codex, Claude, or Gemini. Runners are invoked by the loop scripts, and each entrypoint is executed with its configured model.

### Gemini Headless Usage
Turnloop can call Gemini CLI in headless mode with JSON output and auto-approved actions. The loops support stage-specific runner selection, so only chosen stages need to be Gemini-backed.

```bash
export TURNLOOP_START_RUNNER=gemini
export TURNLOOP_START_MODEL=gemini-3.1-pro-preview
export TURNLOOP_START_FALLBACK_RUNNER=codex
export TURNLOOP_START_FALLBACK_MODEL=gpt-5.4

export TURNLOOP_MANAGE_RUNNER=gemini
export TURNLOOP_MANAGE_MODEL=gemini-3-flash-preview
export TURNLOOP_MANAGE_FALLBACK_RUNNER=codex
export TURNLOOP_MANAGE_FALLBACK_MODEL=gpt-5.4
```

Gemini is invoked in the equivalent shape of:

```bash
gemini --model gemini-3.1-pro-preview --approval-mode yolo --output-format json "Open agents/entrypoints/_start.md and follow instructions."
```

If a Gemini run fails with a quota/capacity/rate-limit style error, Turnloop will automatically retry the same entrypoint with that stage's configured fallback runner and model, typically Codex.

For headless Gemini auth, use cached Gemini CLI login or environment-based auth such as `GEMINI_API_KEY`, or Vertex settings like `GOOGLE_GENAI_USE_VERTEXAI=true`, `GOOGLE_CLOUD_PROJECT`, and `GOOGLE_CLOUD_LOCATION`.

Public repo (for reference):
- Turnloop: `https://github.com/tim-osterhus/turnloop`

## Public Repo Notes
- Do not commit secrets or credentials.
- Keep prompt artifacts and logs free of sensitive data.

## License
See `LICENSE`.
