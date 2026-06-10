import os
import subprocess
import tempfile
import textwrap
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SEED_SCRIPT = REPO_ROOT / "agents" / "scripts" / "seed_prompt.sh"


def run_seed(env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(SEED_SCRIPT)],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=True,
        env={**os.environ, **env},
    )


class SeedPromptTests(unittest.TestCase):
    def write_config(self, root: Path, prompt_dir: Path, *, failure_behavior: str = "skip", usage_source: str = "none") -> Path:
        config_path = root / "seed_config.env"
        config_path.write_text(
            textwrap.dedent(
                f"""\
                SEED_PROMPTS_DIR={prompt_dir}
                SEED_INTERVAL_SECS=1
                SEED_MIN_INTERVAL_SECS=0
                SEED_USAGE_SOURCE={usage_source}
                SEED_USAGE_FAILURE_BEHAVIOR={failure_behavior}
                """
            ),
            encoding="utf-8",
        )
        return config_path

    def read_result(self, state_dir: Path) -> str:
        return (state_dir / "last_seed_result.txt").read_text(encoding="utf-8").strip()

    def test_rotation_wraps_to_prompt_one_when_next_number_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            (prompt_dir / "2-new-browser-game.md").write_text("new game prompt\n", encoding="utf-8")
            (prompt_dir / "4-unused.md").write_text("unused prompt\n", encoding="utf-8")
            (state_dir / "seed_prompt_index.txt").write_text("2\n", encoding="utf-8")

            config_path = self.write_config(root, prompt_dir)
            run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_USAGE_REMAINING_PCT": "55",
                }
            )

            seeded_files = sorted(inbox_dir.glob("*.md"))
            self.assertEqual(len(seeded_files), 1)
            self.assertEqual(seeded_files[0].read_text(encoding="utf-8").strip(), "corebound prompt")
            self.assertEqual((state_dir / "seed_prompt_index.txt").read_text(encoding="utf-8").strip(), "1")
            self.assertEqual(self.read_result(state_dir), "seeded")

    def test_usage_check_failure_can_skip_tick(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            config_path = self.write_config(root, prompt_dir, failure_behavior="skip", usage_source="none")

            completed = run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                }
            )

            self.assertEqual(sorted(inbox_dir.glob("*.md")), [])
            self.assertIn("skipping seed tick", completed.stdout.lower())
            self.assertEqual(self.read_result(state_dir), "usage_unknown")

    def test_usage_check_failure_can_continue_anyway(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            config_path = self.write_config(root, prompt_dir, failure_behavior="continue", usage_source="none")

            completed = run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                }
            )

            seeded_files = sorted(inbox_dir.glob("*.md"))
            self.assertEqual(len(seeded_files), 1)
            self.assertEqual(seeded_files[0].read_text(encoding="utf-8").strip(), "corebound prompt")
            self.assertIn("continuing", completed.stdout.lower())
            self.assertEqual(self.read_result(state_dir), "seeded")

    def test_min_interval_skip_records_too_early_without_seeding(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            (state_dir / "last_seed_epoch.txt").write_text(str(int(time.time())), encoding="utf-8")
            config_path = self.write_config(root, prompt_dir, failure_behavior="continue", usage_source="none")
            config_path.write_text(
                config_path.read_text(encoding="utf-8") + "SEED_MIN_INTERVAL_SECS=30\n",
                encoding="utf-8",
            )

            completed = run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                }
            )

            self.assertEqual(sorted(inbox_dir.glob("*.md")), [])
            self.assertIn("waiting", completed.stdout.lower())
            self.assertEqual(self.read_result(state_dir), "too_early")

    def test_low_usage_skip_records_usage_below_threshold(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            config_path = self.write_config(root, prompt_dir, failure_behavior="skip", usage_source="none")

            completed = run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_USAGE_REMAINING_PCT": "9",
                }
            )

            self.assertEqual(sorted(inbox_dir.glob("*.md")), [])
            self.assertIn("skipping seed prompt", completed.stdout.lower())
            self.assertEqual(self.read_result(state_dir), "usage_below_threshold")

    def test_codex_source_falls_back_to_cached_usage_file_when_probe_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            (state_dir / "usage_remaining_pct.txt").write_text("64\n", encoding="utf-8")
            config_path = self.write_config(root, prompt_dir, failure_behavior="skip", usage_source="codex")

            completed = run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "PATH": "/usr/bin:/bin",
                }
            )

            seeded_files = sorted(inbox_dir.glob("*.md"))
            self.assertEqual(len(seeded_files), 1)
            self.assertEqual(seeded_files[0].read_text(encoding="utf-8").strip(), "corebound prompt")
            self.assertIn("usage remaining 64%", completed.stdout.lower())

    def test_missing_prompt_one_fails_fast_with_clear_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            (prompt_dir / "2-new-browser-game.md").write_text("new game prompt\n", encoding="utf-8")
            config_path = self.write_config(root, prompt_dir, failure_behavior="continue", usage_source="none")

            completed = subprocess.run(
                ["bash", str(SEED_SCRIPT)],
                cwd=REPO_ROOT,
                text=True,
                capture_output=True,
                env={
                    **os.environ,
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                },
            )

            self.assertNotEqual(completed.returncode, 0)
            combined_output = f"{completed.stdout}\n{completed.stderr}".lower()
            self.assertIn("expected a file numbered 1", combined_output)
            self.assertEqual(sorted(inbox_dir.glob("*.md")), [])
            self.assertEqual(self.read_result(state_dir), "error")

    def test_prompt_file_changes_are_picked_up_without_restart(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()

            prompt_path = prompt_dir / "1-corebound.md"
            prompt_path.write_text("first prompt\n", encoding="utf-8")
            config_path = self.write_config(root, prompt_dir, failure_behavior="continue", usage_source="none")

            run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                }
            )

            first_seed = sorted(inbox_dir.glob("*.md"))[-1]
            self.assertEqual(first_seed.read_text(encoding="utf-8").strip(), "first prompt")

            time.sleep(1.1)
            prompt_path.write_text("second prompt\n", encoding="utf-8")

            run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                }
            )

            seeded_files = sorted(inbox_dir.glob("*.md"))
            self.assertEqual(len(seeded_files), 2)
            self.assertEqual(seeded_files[-1].read_text(encoding="utf-8").strip(), "second prompt")
            self.assertEqual(self.read_result(state_dir), "seeded")


if __name__ == "__main__":
    unittest.main()
