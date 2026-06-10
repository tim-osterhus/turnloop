# Workspace Rules

This file is the authoritative home for workspace-specific mission and scoping rules.

Framework docs, entrypoints, and roles should stay generic where possible and refer back here for game-factory behavior.

## Default Mission

The default autonomous mission is building and maintaining browser games plus the small shared surfaces required to publish and organize them.

This is not a self-improving-framework mission by default.

Framework or harness changes are in scope only when at least one of these is true:
- the prompt or task explicitly asks for harness maintenance
- a loop/runtime failure must be fixed to restore autonomous operation
- a shared publishing or repo contract cannot be implemented safely without the harness change

If none of those are true, prefer game work over harness work.

## One-Game-At-A-Time Rule

Game work should stay scoped to one game at a time.

Normal game-scoped work may touch:
- one game directory or game slug
- task/journal/docs files that describe that same work
- allowed shared touchpoints listed below

Do not touch multiple game directories in one task unless the task is explicitly about shared infrastructure that truly spans those games.

## Slug And Directory Rules

- Every game uses one stable slug in lowercase kebab-case.
- Every game gets one isolated directory or path rooted at that slug.
- Public URLs should map cleanly to the slug when possible.
- Once a slug exists, do not rename it casually. Treat slug changes as migrations.
- Shared code should not be mixed into a game directory unless it is truly game-local.

## Allowed Shared Touchpoints

The only normal shared touchpoints for game work are:
- the game registry or manifest
- the generated arcade index source
- shared assets, styles, or UI primitives used by multiple games
- shared build, deploy, or test tooling
- docs that describe the touched game or shared system

Avoid discretionary edits outside the active game plus these shared touchpoints.

## Generated Index Contract

The main games index should be generated from a source of truth such as:
- a manifest or registry file
- or a directory contract that can be enumerated deterministically

Agents should prefer editing the source of truth and any generator scripts, not hand-editing generated output as the long-term system of record.

## How To Add A New Game

When creating a new game:
- choose a unique kebab-case slug
- create the isolated directory/path for that slug
- add the minimum required registration metadata to the source of truth
- keep the first version focused and playable rather than broad
- avoid copying unrelated code from another game unless the reuse is intentional and explicit

## How To Improve An Existing Game

When improving an existing game:
- preserve the game's slug and public path unless the task explicitly includes a migration
- keep edits local to that game's directory plus allowed shared touchpoints
- prefer improvements that produce a visible step up in playability, clarity, feel, or robustness
- do not bundle unrelated work from a second game into the same task

## Game Version Contract

- Every public game entry in `auto-games/data/games.json` must carry a semantic version string in `MAJOR.MINOR.PATCH` format.
- New public game entries start at `0.0.1`.
- Patch bumps are the default for one task's player-visible improvement to one game.
- Minor bumps are for an intentional public batch or milestone that groups multiple player-visible improvements into one release.
- Major bumps are manual only. Do not move a game to `1.0.0` or higher unless the task or prompt explicitly says to do so.
- When a task changes a published game's player-visible build or release copy, update that game's version in the manifest before finishing.
- For multi-card work, do not leave a final task pinned to a specific future version if earlier cards may ship player-visible changes first.
- In those cases, fold version/release metadata sync into the last player-visible card, or keep any separate metadata task version-agnostic and aligned to the current shipped patch.

## Shared Infrastructure Work

Shared infrastructure work is valid when it directly supports the game-factory mission, for example:
- game registry or manifest changes
- generated arcade index work
- shared asset pipeline or build pipeline work
- journal/site changes that support the public experiment

Treat this as infrastructure work, not as permission to make unrelated harness edits.

## Harness Maintenance Is Explicit

Harness work is not the recurring mission. Treat it as maintenance.

When harness maintenance is explicitly in scope:
- keep it generic rather than embedding more workspace-specific behavior into the framework core
- prefer fixes to contracts, reliability, observability, and safety over speculative redesign
- keep project-specific rules in this file instead of scattering them across entrypoints and roles

## Entrypoint And Role Contract

Entrypoints and roles that plan or execute work should read this file and obey it.

At minimum, they should use it to:
- keep the default mission centered on browser-game work
- preserve one-game-at-a-time scope
- respect shared-touchpoint boundaries
- treat harness changes as explicit maintenance rather than default product work
