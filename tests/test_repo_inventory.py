import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "agents" / "scripts" / "repo_inventory.py"


def run(cmd: list[str], cwd: Path) -> None:
    subprocess.run(cmd, cwd=cwd, text=True, check=True, capture_output=True)


def git(cwd: Path, *args: str) -> None:
    run(["git", *args], cwd=cwd)


class RepoInventoryTests(unittest.TestCase):
    def test_changed_only_lists_root_and_nested_repos_needing_attention(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            root_remote = root / "root-remote.git"
            nested_remote = root / "nested-remote.git"
            root_repo = root / "workspace"
            nested_repo = root_repo / "games"

            git(root, "init", "--bare", str(root_remote))
            git(root, "init", "--bare", str(nested_remote))

            root_repo.mkdir()
            git(root_repo, "init")
            git(root_repo, "config", "user.name", "Test User")
            git(root_repo, "config", "user.email", "test@example.com")
            (root_repo / ".gitignore").write_text("games/\n", encoding="utf-8")
            (root_repo / "README.md").write_text("root\n", encoding="utf-8")
            git(root_repo, "add", ".gitignore", "README.md")
            git(root_repo, "commit", "-m", "root init")
            git(root_repo, "branch", "-M", "main")
            git(root_repo, "remote", "add", "origin", str(root_remote))
            git(root_repo, "push", "-u", "origin", "main")

            nested_repo.mkdir()
            git(nested_repo, "init")
            git(nested_repo, "config", "user.name", "Test User")
            git(nested_repo, "config", "user.email", "test@example.com")
            (nested_repo / "README.md").write_text("nested\n", encoding="utf-8")
            git(nested_repo, "add", "README.md")
            git(nested_repo, "commit", "-m", "nested init")
            git(nested_repo, "branch", "-M", "main")
            git(nested_repo, "remote", "add", "origin", str(nested_remote))
            git(nested_repo, "push", "-u", "origin", "main")

            (root_repo / "README.md").write_text("root changed\n", encoding="utf-8")
            git(root_repo, "add", "README.md")
            git(root_repo, "commit", "-m", "root ahead")

            (nested_repo / "README.md").write_text("nested dirty\n", encoding="utf-8")

            completed = subprocess.run(
                [
                    "python3",
                    str(SCRIPT),
                    "--root",
                    str(root_repo),
                    "--changed-only",
                ],
                cwd=REPO_ROOT,
                text=True,
                capture_output=True,
                check=True,
            )
            repos = json.loads(completed.stdout)

        self.assertEqual([repo["path"] for repo in repos], [".", "games"])
        root_state = repos[0]
        nested_state = repos[1]

        self.assertFalse(root_state["dirty"])
        self.assertTrue(root_state["needs_push"])
        self.assertGreater(root_state["ahead"], 0)

        self.assertTrue(nested_state["dirty"])
        self.assertFalse(nested_state["needs_push"])
        self.assertIn(" M README.md", nested_state["status"])


if __name__ == "__main__":
    unittest.main()
