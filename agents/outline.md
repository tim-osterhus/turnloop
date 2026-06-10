# Project Outline

## Games Repo:
- Goal: the generic browser-game repo that backs `game.millrace.ai`.
- Status update: the arcade is generated from `auto-games/data/games.json`, and each published title carries public metadata including version.
- Public repo link: `https://github.com/tim-osterhus/auto-games`
- Local repo location: `auto-games/`
  - Sits inside the base `turnloop/` repo as its own git repo and should be treated as a separate project.
- Discoverable games source of truth: `auto-games/data/games.json`
- Local Millrace theme reference for public-facing game shells: `site/millrace-theme.md`
- Current published slots: `corebound` remains the flagship mining game, with `ricochet-reactor` live as a playable arena prototype and `overcrank` shipping a score-attack climb loop with a rising-heat threat; all publish from the manifest with visible versions.

## Turnloop:
- Goal: a private autonomy harness for building and maintaining browser games in public.
- Public repo link: `https://github.com/tim-osterhus/turnloop`
- For a full description of how Turnloop works, see `README.md`.
