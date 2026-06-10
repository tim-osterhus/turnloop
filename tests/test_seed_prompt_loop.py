import os
import subprocess
import tempfile
import textwrap
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SEED_LOOP_SCRIPT = REPO_ROOT / "agents" / "scripts" / "seed_prompt_loop.sh"
SEED_SCRIPT = REPO_ROOT / "agents" / "scripts" / "seed_prompt.sh"


def run_seed_loop(env: dict[str, str], timeout_secs: int) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["timeout", str(timeout_secs), "bash", str(SEED_LOOP_SCRIPT)],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        env={**os.environ, **env},
    )


def run_seed(env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(SEED_SCRIPT)],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=True,
        env={**os.environ, **env},
    )


class SeedPromptLoopTests(unittest.TestCase):
    def write_config(
        self,
        root: Path,
        prompt_dir: Path,
        *,
        interval_secs: int,
        min_interval_secs: int,
        failure_behavior: str = "continue",
        usage_source: str = "none",
    ) -> Path:
        config_path = root / "seed_config.env"
        config_path.write_text(
            textwrap.dedent(
                f"""\
                SEED_PROMPTS_DIR={prompt_dir}
                SEED_INTERVAL_SECS={interval_secs}
                SEED_MIN_INTERVAL_SECS={min_interval_secs}
                SEED_USAGE_SOURCE={usage_source}
                SEED_USAGE_FAILURE_BEHAVIOR={failure_behavior}
                SEED_USAGE_UNKNOWN_RETRY_SECS=2
                SEED_USAGE_LOW_RETRY_SECS=2
                SEED_ERROR_RETRY_SECS=2
                """
            ),
            encoding="utf-8",
        )
        return config_path

    def test_worker_ticks_immediately_without_last_attempt(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()
            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")

            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=2,
                min_interval_secs=0,
            )

            completed = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )

            self.assertEqual(completed.returncode, 124)
            self.assertIn("Seed prompt loop tick", completed.stdout)

    def test_worker_defers_tick_until_interval_after_last_seed(self) -> None:
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

            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=2,
                min_interval_secs=0,
            )

            completed = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )

            self.assertEqual(completed.returncode, 124)
            self.assertNotIn("Seed prompt loop tick", completed.stdout)

    def test_worker_waits_for_retry_epoch_after_non_seeding_due_time_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()
            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            now = int(time.time())
            (state_dir / "last_seed_epoch.txt").write_text(str(now - 10), encoding="utf-8")
            (state_dir / "next_seed_retry_epoch.txt").write_text(str(now + 2), encoding="utf-8")

            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=3,
                min_interval_secs=3,
            )

            completed = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )

            self.assertEqual(completed.returncode, 124)
            self.assertNotIn("Seed prompt loop tick", completed.stdout)

    def test_worker_prefers_new_manual_seed_cadence_over_stale_retry_epoch(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()
            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            now = int(time.time())
            (state_dir / "last_seed_epoch.txt").write_text(str(now), encoding="utf-8")
            (state_dir / "next_seed_retry_epoch.txt").write_text(str(now + 1), encoding="utf-8")

            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=5,
                min_interval_secs=5,
            )

            completed = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=2,
            )

            self.assertEqual(completed.returncode, 124)
            self.assertNotIn("Seed prompt loop tick", completed.stdout)

    def test_restart_near_due_boundary_does_not_push_seed_out_by_full_interval(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()
            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")

            now = int(time.time())
            (state_dir / "last_seed_epoch.txt").write_text(str(now - 8), encoding="utf-8")
            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=10,
                min_interval_secs=10,
            )

            first = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )
            self.assertEqual(first.returncode, 124)
            self.assertNotIn("Seed prompt loop tick", first.stdout)

            time.sleep(3)

            second = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=2,
            )
            self.assertEqual(second.returncode, 124)
            self.assertIn("Seed prompt loop tick", second.stdout)

    def test_manual_seed_before_restart_sets_next_due_from_real_seed(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()
            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")

            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=5,
                min_interval_secs=5,
            )

            run_seed(
                {
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_USAGE_REMAINING_PCT": "80",
                }
            )

            restarted = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=2,
            )
            self.assertEqual(restarted.returncode, 124)
            self.assertNotIn("Seed prompt loop tick", restarted.stdout)

            time.sleep(4)

            due = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=2,
            )
            self.assertEqual(due.returncode, 124)
            self.assertIn("Seed prompt loop tick", due.stdout)

    def test_usage_unknown_retries_on_short_retry_cadence(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            prompt_dir = root / "prompts"
            inbox_dir = root / "inbox"
            state_dir = root / "state"
            prompt_dir.mkdir()
            inbox_dir.mkdir()
            state_dir.mkdir()
            (prompt_dir / "1-corebound.md").write_text("corebound prompt\n", encoding="utf-8")
            (state_dir / "last_seed_epoch.txt").write_text(str(int(time.time()) - 10), encoding="utf-8")

            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=3,
                min_interval_secs=3,
                failure_behavior="skip",
                usage_source="none",
            )

            first = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )
            self.assertEqual(first.returncode, 124)
            self.assertIn("Seed prompt loop tick", first.stdout)
            self.assertTrue((state_dir / "next_seed_retry_epoch.txt").exists())

            immediate_restart = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )
            self.assertEqual(immediate_restart.returncode, 124)
            self.assertNotIn("Seed prompt loop tick", immediate_restart.stdout)

            time.sleep(2.2)

            retried = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )
            self.assertEqual(retried.returncode, 124)
            self.assertIn("Seed prompt loop tick", retried.stdout)

    def test_config_interval_change_is_applied_on_next_restart_recompute(self) -> None:
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

            config_path = self.write_config(
                root,
                prompt_dir,
                interval_secs=10,
                min_interval_secs=0,
            )

            first = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=1,
            )
            self.assertEqual(first.returncode, 124)
            self.assertNotIn("Seed prompt loop tick", first.stdout)

            config_path.write_text(
                config_path.read_text(encoding="utf-8").replace("SEED_INTERVAL_SECS=10", "SEED_INTERVAL_SECS=1"),
                encoding="utf-8",
            )

            time.sleep(1.1)

            second = run_seed_loop(
                {
                    "TURNLOOP_RUNTIME_CHILD": "1",
                    "TURNLOOP_WORK_ROOT": str(root),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_INBOX_DIR": str(inbox_dir),
                    "TURNLOOP_SEED_CONFIG_FILE": str(config_path),
                    "RUNTIME_REEXEC_ON_DRIFT": "false",
                    "RUNTIME_HEARTBEAT_ENABLED": "false",
                    "RUNTIME_SLEEP_SLICE_SECS": "1",
                },
                timeout_secs=2,
            )
            self.assertEqual(second.returncode, 124)
            self.assertIn("Seed prompt loop tick", second.stdout)


if __name__ == "__main__":
    unittest.main()
