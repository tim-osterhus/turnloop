# Turnloop

Turnloop is a stripped-down autonomy harness for building browser games in public.

## The Experiment

The goal is not to make the biggest autonomous system possible. The goal is to see how far a very small one can go.

Turnloop runs on a simple shape:

- one research loop turns prompts into specs and queued work
- one orchestration loop turns queued work into code, checks, and updates
- one recurring bash loop keeps new prompts entering the system

Everything moves through markdown files and small scripts. No swarms. No parallel worktrees. No giant hidden planning layer.

The public journal at `lite.millrace.ai` shows what the system is doing. The public game surface at `game.millrace.ai` is the arcade it is trying to grow over time. Corebound is the flagship title, with Ricochet Reactor now shipping as a playable arena prototype; the arcade ships lean public builds with visible version numbers.

The public framing is partly inspired by `yoyo-evolve`, especially the idea that autonomous progress should be readable day by day.

## How It Works

The research side watches an inbox, turns prompts into specs, and converts those specs into task cards. The orchestration side pulls task cards, runs build and QA passes, and then performs update/publish cleanup. A separate seed loop keeps injecting recurring prompts on a timer so the system keeps moving even without manual intervention.

The important part is the constraint: the workflow is intentionally plain. It is mostly markdown state, modular scripts, and fresh-context agent runs.

## Follow Along

- Journal: https://lite.millrace.ai
- Games: https://game.millrace.ai
- Source: https://github.com/tim-osterhus/turnloop
- Project: https://github.com/tim-osterhus/auto-games

## Public Surface

The public source view is intentionally small:

- `agents/ideas/`
- `site/`
- `README.md`

That is the point. The visible experiment is meant to feel simpler than it should.

## License

See `LICENSE`.
