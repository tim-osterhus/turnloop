# Turnloop

Turnloop is a live autonomy harness for continuous software development. It runs with minimal human intervention and publishes a public, readable audit trail of what the agents do.

## The Experiment

This repo is being run as a live autonomy experiment. The goal is threefold:
1. Testing whether single-agent orchestration improves long-running autonomy compared to agent swarms
2. Observing the behavior and decisions of an agentic framework when repeatedly faced with an open-ended goal
3. Seeing if a dramatically stripped-down version of my private Millrace pipeline can still deliver end-to-end multi-week autonomous development

Every six hours, one of two different seed prompts is programmatically injected into the research loop, which initiates a new run. One of these seed prompts invites self-improvement to the framework, while the other invites iteration on a game called Corebound. While the intent is made clear in these prompts, the feature decisions and technical implementation are entirely decided by the agents, requiring that the framework turn an ambiguous goal into a clear end product.

While this loop remains fully autonomous, it's also capable of handling manual input/requests without any disruption to the standard, automated flow.

The public journal site under `site/` is generated from `agents/historylog.md`, so the repo itself is both the control surface and the audit trail.

Credit where credit is due. The project direction is partly inspired by `yoyo-evolve`:
- public, readable agent progress
- visible day-by-day iteration
- tight feedback between code changes and journal output
- self-improving agentic harness

Turnloop keeps a different structure and underlying goal from that project, but the public-journal framing is an explicit inspiration.

## How It Works (High Level)

Turnloop runs three persistent loops:
- Execution loop: pulls task cards, builds, QA checks, handles quickfix/blocker flow, and updates status.
- Research loop: turns incoming prompts into staged specs and backlog-ready work.
- Seed loop: injects alternating self-improvement and game-improvement prompts on a timer.

Everything coordinates through files on disk. That keeps the system transparent and auditable.

## Follow The Run

- Live journal: https://lite.millrace.ai
- Live game: https://game.millrace.ai
- Game repo: https://www.github.com/tim-osterhus/corebound
- Operational runbook: [OPERATIONS.md](./OPERATIONS.md)

## Repo Layout

- `agents/entrypoints/`: stage entry instructions.
- `agents/roles/`: reusable role prompts.
- `agents/scripts/`: execution/research/seed loop runners.
- `agents/prompts/`: live seed prompt text files.
- `agents/work/`: execution queue state and artifacts.
- `agents/ideas/`: research inbox, staging, specs, and nonviable queue.
- `agents/historylog.md`: canonical prepend-only run journal.
- `corebound/`: separate game repo.

## Public Repo Notes

- Do not commit secrets or credentials.
- Keep prompt artifacts and logs free of sensitive data.

## License

See `LICENSE`.
