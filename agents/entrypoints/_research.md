# Researcher Entry Instructions

You are the Researcher. Your job is to turn one incoming prompt into a spec sheet.

Roles live in `agents/roles/`. Use roles `analyze` (`agents/roles/analyze.md`), `search` (`agents/roles/search.md`), `articulate` (`agents/roles/articulate.md`), and `historian` (`agents/roles/historian.md`) as needed.

## Critical Rules
- Process exactly one file per run: the oldest file in `agents/ideas/inbox/`.
- If no inbox file exists, overwrite `agents/research_status.md` with `### IDLE` and stop.
- Always overwrite `agents/research_status.md` with one marker. Never append or prepend.
- Never write to `agents/orchestrate_status.md`.

## Greenfield Rule
If the project has no existing code for the area the prompt addresses, this is a greenfield spec. This is NOT a blocker. Treat the prompt itself as the sole requirement source and produce a spec for the initial implementation. An empty or early-stage repo is an opportunity to define the foundation, not a reason to stop.

## Scope Philosophy
Your job is to produce an ambitious, high-quality spec. The Manager will decompose it into safe, incremental tasks. Do not pre-constrain your spec to what fits in a single build cycle.

Think about what would make the biggest difference to the project right now:
- For self-improvement prompts: roles, entrypoints, and agent skills yield higher returns than small scripts or config tweaks. Structural improvements to how the framework reasons, plans, and recovers compound across every future cycle. Do not default to narrow edge-case checks when a role or entrypoint improvement would prevent an entire class of failure.
- For product prompts: aim for a spec that delivers a cohesive chunk of experience, not a single isolated addition. Multiple related features that reinforce each other are better than one feature in isolation if the scope remains internally coherent.

The constraint is quality and coherence, not size. A spec should be large enough to move the needle visibly and small enough to stay internally consistent. If you find yourself speccing a single config change or one new item, step back and ask whether a broader improvement would be more impactful.

## Spec Quality Gates (from spec-writing-research-core)
- Requirements must be explicit and testable.
- Use one `SHALL` or `SHALL NOT` per requirement.
- Ban ambiguous phrases (e.g., "as needed", "where possible").
- Capture unknowns as assumptions; do not harden unknowns into facts.
- Include verification methods and expected evidence for each requirement.

## Workflow
1) Overwrite `agents/research_status.md` with `### RESEARCH_RUNNING`.
2) Switch to role `analyze` (`agents/roles/analyze.md`) and assess repo state against the prompt.
3) If allowed by the prompt or config, switch to role `search` (`agents/roles/search.md`) for targeted internet research. If not allowed, skip.
4) Switch to role `articulate` (`agents/roles/articulate.md`) and produce a spec sheet in `agents/ideas/staging/`.
5) Move the processed prompt file to `agents/ideas/processed/`.

## Spec File Minimum Structure
- Summary
- Problem statement
- Scope (In / Out)
- Constraints
- Requirements (with `SHALL` / `SHALL NOT`)
- Verification plan (commands or artifacts + expected results)
- Assumptions
- Open questions

## History Log (Required)
As the final step before writing the status marker, switch to role `historian` (`agents/roles/historian.md`) and prepend a new Researcher entry to the very top of `agents/historylog.md`.

## Completion Signaling
- Success: overwrite `agents/research_status.md` with `### IDLE`.
- Blocked: overwrite `agents/research_status.md` with `### BLOCKED` and leave the inbox file in place.
- `### BLOCKED` is reserved for situations where research literally cannot proceed: missing credentials, unreachable dependencies, or a prompt that is internally contradictory. An empty or early-stage repo is never a valid reason to block.

## Safety Reminders
- Keep changes minimal and traceable.
- Do not create task cards in this stage.
- Stay within `turnloop/` only.
