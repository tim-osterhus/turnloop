import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_RULES = REPO_ROOT / "rules.md"

ENTRYPOINTS_THAT_MUST_REFERENCE_RULES = [
    REPO_ROOT / "agents" / "entrypoints" / "_research.md",
    REPO_ROOT / "agents" / "entrypoints" / "_manage.md",
    REPO_ROOT / "agents" / "entrypoints" / "_start.md",
    REPO_ROOT / "agents" / "entrypoints" / "_check.md",
    REPO_ROOT / "agents" / "entrypoints" / "_update.md",
    REPO_ROOT / "agents" / "entrypoints" / "_troubleshoot.md",
    REPO_ROOT / "agents" / "entrypoints" / "_mechanic.md",
]

ROLES_THAT_MUST_REFERENCE_RULES = [
    REPO_ROOT / "agents" / "roles" / "analyze.md",
    REPO_ROOT / "agents" / "roles" / "prompt-architect.md",
    REPO_ROOT / "agents" / "roles" / "developer.md",
    REPO_ROOT / "agents" / "roles" / "rubric-maker.md",
    REPO_ROOT / "agents" / "roles" / "refactor.md",
    REPO_ROOT / "agents" / "roles" / "remediator.md",
]


class EntrypointContractTests(unittest.TestCase):
    def test_workspace_rules_file_covers_required_sections(self) -> None:
        text = WORKSPACE_RULES.read_text(encoding="utf-8")

        required_headings = [
            "## Default Mission",
            "## One-Game-At-A-Time Rule",
            "## Slug And Directory Rules",
            "## Allowed Shared Touchpoints",
            "## Generated Index Contract",
            "## How To Add A New Game",
            "## How To Improve An Existing Game",
            "## Harness Maintenance Is Explicit",
        ]

        for heading in required_headings:
            with self.subTest(heading=heading):
                self.assertIn(heading, text)

    def test_relevant_entrypoints_reference_workspace_rules(self) -> None:
        for path in ENTRYPOINTS_THAT_MUST_REFERENCE_RULES:
            with self.subTest(path=path.name):
                self.assertIn("rules.md", path.read_text(encoding="utf-8"))

    def test_relevant_roles_reference_workspace_rules(self) -> None:
        for path in ROLES_THAT_MUST_REFERENCE_RULES:
            with self.subTest(path=path.name):
                self.assertIn("rules.md", path.read_text(encoding="utf-8"))

    def test_old_default_self_improvement_framing_is_removed(self) -> None:
        research_text = (REPO_ROOT / "agents" / "entrypoints" / "_research.md").read_text(encoding="utf-8")
        analyze_text = (REPO_ROOT / "agents" / "roles" / "analyze.md").read_text(encoding="utf-8")

        self.assertNotIn("For self-improvement prompts specifically", research_text)
        self.assertNotIn("For self-improvement prompts specifically", analyze_text)

    def test_manager_outputs_to_taskspending_not_directly_to_backlog(self) -> None:
        manage_text = (REPO_ROOT / "agents" / "entrypoints" / "_manage.md").read_text(encoding="utf-8")

        self.assertIn("agents/work/taskspending.md", manage_text)
        self.assertIn("Insert cards into `agents/work/taskspending.md`", manage_text)


if __name__ == "__main__":
    unittest.main()
