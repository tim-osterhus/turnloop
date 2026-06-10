# Turnloop

Turnloop is a small Bash workflow automation framework.

It was built before Millrace as a deliberately plain experiment in sequential
agent orchestration: a few long-running shell loops, markdown queues, role
prompts, and stage entrypoints. The point was not to create a general autonomy
platform. The point was to see how much useful automation could be created with
ordinary files and simple process discipline.

## What This Is

Turnloop shows a basic pattern for automating a bespoke workflow:

- keep work state in markdown files,
- use shell scripts as the scheduler and supervisor,
- run one agent stage at a time with a fresh prompt,
- let each stage communicate by writing status markers and queue files,
- keep prompts, roles, configs, and runtime behavior inspectable in the repo.

The framework is intentionally direct. There is no service mesh, hidden planner,
database, queue server, vector store, or parallel swarm. A Turnloop run is a
sequence of shell-driven agent calls moving cards through a file tree.

## Core Pieces

- `agents/scripts/orchestrate_loop.sh` runs the execution loop.
- `agents/scripts/research_loop.sh` turns incoming ideas into specs and task
  cards.
- `agents/scripts/seed_prompt_loop.sh` periodically injects seed prompts.
- `agents/scripts/loop_runtime.sh` provides shared retry, heartbeat, hot-reload,
  drift detection, and provider-connectivity handling.
- `agents/entrypoints/` contains the stage prompts used by the loops.
- `agents/roles/` contains reusable role instructions.
- `agents/config/` contains live-reloaded loop, runtime, seed, and model config.
- `agents/work/` is the execution queue surface.
- `agents/ideas/` is the research/intake queue surface.

The included history logs are examples of the framework's operational style.
Raw runner logs and volatile runtime state are intentionally ignored.

## Loop Shape

Turnloop normally runs as three foreground processes:

```bash
bash agents/scripts/orchestrate_loop.sh
bash agents/scripts/research_loop.sh
bash agents/scripts/seed_prompt_loop.sh
```

Or, with tmux:

```bash
bash start_turnloop.sh
```

The execution loop promotes task cards, runs builder/check/update-style stages,
and archives completed work. The research loop processes incoming ideas into
specs and then into task cards. The seed loop periodically copies numbered seed
prompts into the idea inbox.

Each loop writes human-readable status files and can also emit runtime heartbeat
JSON under `agents/.tmp/runtime/` when enabled. That runtime directory is ignored
because it is local process state, not source.

## Why It Exists

Turnloop is a useful example of how simple workflow automation can be when the
workflow is specific and the handoff format is explicit.

The design is primitive on purpose:

- markdown is the task database,
- file moves are queue transitions,
- status markers are the control protocol,
- shell scripts are the scheduler,
- fresh-context agent runs are the workers.

That simplicity made it easy to inspect, interrupt, debug, and modify while the
system was running. Millrace later grew out of lessons learned from this style
of orchestration.

## Repository Scope

This branch is the framework showcase. It intentionally does not include the
browser games, generated journal website, built site assets, QA screenshots, raw
runner logs, or runtime-owned state from the original experiment.

Historical product work may still exist in git history or local checkouts, but
the current tree is focused on the automation framework itself.

## Configuration And Secrets

The config files in this repo are plain shell-style examples used by the loops.
They should not contain credentials. Runner authentication, API keys, tokens, and
other private values should live in the user's environment or external credential
manager, not in this repository.

## Tests

The test suite focuses on the loop contracts and helper scripts:

```bash
python3 -m unittest discover tests
```

## License

See `LICENSE`.
