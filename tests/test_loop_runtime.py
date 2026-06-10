import json
import os
import subprocess
import tempfile
import textwrap
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
RUNTIME_HELPER = REPO_ROOT / "agents" / "scripts" / "loop_runtime.sh"


def write_harness_script(root: Path) -> Path:
    script_path = root / "runtime_harness.sh"
    script_path.write_text(
        textwrap.dedent(
            f"""\
            #!/usr/bin/env bash
            set -Eeuo pipefail

            SCRIPT_PATH="$0"
            REPO_ROOT="${{TURNLOOP_TEST_ROOT:?}}"
            WORK_ROOT="$REPO_ROOT"
            RUNTIME_CONFIG_FILE="${{TURNLOOP_RUNTIME_CONFIG_FILE:?}}"
            STATE_DIR="${{TURNLOOP_STATE_DIR:?}}"

            # shellcheck disable=SC1091
            source "{RUNTIME_HELPER}"

            if ! turnloop_runtime_is_sourced && [ "${{TURNLOOP_RUNTIME_CHILD:-0}}" != "1" ]; then
              turnloop_runtime_supervise "harness" "$SCRIPT_PATH" "$REPO_ROOT" "$WORK_ROOT" "$RUNTIME_CONFIG_FILE" "$STATE_DIR"
              exit $?
            fi

            turnloop_runtime_init_worker "harness" "$SCRIPT_PATH" "$REPO_ROOT" "$WORK_ROOT" "$RUNTIME_CONFIG_FILE" "$STATE_DIR" "$SCRIPT_PATH" "$RUNTIME_CONFIG_FILE"
            trap 'turnloop_runtime_on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

            echo "start" >> "$WORK_ROOT/starts.log"

            case "${{TURNLOOP_TEST_MODE:?}}" in
              retry)
                if [ ! -f "$WORK_ROOT/fail_once" ]; then
                  touch "$WORK_ROOT/fail_once"
                  false
                fi
                turnloop_runtime_touch "done" "worker completed after retry" ""
                ;;
              drift)
                if [ ! -f "$WORK_ROOT/drift_once" ]; then
                  touch "$WORK_ROOT/drift_once"
                  (
                    sleep 1
                    printf '\\n# drift\\n' >> "$RUNTIME_CONFIG_FILE"
                  ) &
                  turnloop_runtime_wait 5 "waiting_for_drift" "waiting for watched file change" ""
                fi
                turnloop_runtime_touch "done" "worker completed after drift restart" ""
                ;;
              *)
                echo "Unknown test mode: $TURNLOOP_TEST_MODE" >&2
                exit 2
                ;;
            esac
            """
        ),
        encoding="utf-8",
    )
    script_path.chmod(0o755)
    return script_path


class LoopRuntimeTests(unittest.TestCase):
    def test_supervisor_retries_after_unexpected_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            config_path = root / "runtime_config.env"
            state_dir = root / "runtime_state"
            config_path.write_text(
                textwrap.dedent(
                    """\
                    RUNTIME_RETRY_DELAY_SECS=1
                    RUNTIME_SLEEP_SLICE_SECS=1
                    RUNTIME_REEXEC_ON_DRIFT=true
                    RUNTIME_HEARTBEAT_ENABLED=true
                    RUNTIME_REEXEC_EXIT_CODE=75
                    """
                ),
                encoding="utf-8",
            )
            harness = write_harness_script(root)

            completed = subprocess.run(
                ["bash", str(harness)],
                cwd=REPO_ROOT,
                text=True,
                capture_output=True,
                check=True,
                env={
                    **os.environ,
                    "TURNLOOP_TEST_ROOT": str(root),
                    "TURNLOOP_RUNTIME_CONFIG_FILE": str(config_path),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_TEST_MODE": "retry",
                },
            )

            self.assertEqual(completed.returncode, 0)
            starts = (root / "starts.log").read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(starts, ["start", "start"])

            state = json.loads((state_dir / "harness.json").read_text(encoding="utf-8"))
            self.assertEqual(state["phase"], "stopped")
            self.assertEqual(state["mode"], "supervisor")

    def test_supervisor_restarts_when_watched_file_changes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            config_path = root / "runtime_config.env"
            state_dir = root / "runtime_state"
            config_path.write_text(
                textwrap.dedent(
                    """\
                    RUNTIME_RETRY_DELAY_SECS=1
                    RUNTIME_SLEEP_SLICE_SECS=1
                    RUNTIME_REEXEC_ON_DRIFT=true
                    RUNTIME_HEARTBEAT_ENABLED=true
                    RUNTIME_REEXEC_EXIT_CODE=75
                    """
                ),
                encoding="utf-8",
            )
            harness = write_harness_script(root)

            completed = subprocess.run(
                ["bash", str(harness)],
                cwd=REPO_ROOT,
                text=True,
                capture_output=True,
                check=True,
                env={
                    **os.environ,
                    "TURNLOOP_TEST_ROOT": str(root),
                    "TURNLOOP_RUNTIME_CONFIG_FILE": str(config_path),
                    "TURNLOOP_STATE_DIR": str(state_dir),
                    "TURNLOOP_TEST_MODE": "drift",
                },
            )

            self.assertEqual(completed.returncode, 0)
            starts = (root / "starts.log").read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(starts, ["start", "start"])

            state = json.loads((state_dir / "harness.json").read_text(encoding="utf-8"))
            self.assertEqual(state["phase"], "stopped")
            self.assertGreaterEqual(state["restart_count"], 1)

    def test_connectivity_wait_returns_false_when_probe_already_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            config_path = root / "runtime_config.env"
            config_path.write_text(
                textwrap.dedent(
                    """\
                    RUNTIME_CONNECTIVITY_RETRY_ENABLED=true
                    RUNTIME_CONNECTIVITY_CHECK_COMMAND=true
                    RUNTIME_CONNECTIVITY_BACKOFF_INITIAL_SECS=1
                    RUNTIME_CONNECTIVITY_BACKOFF_SECOND_SECS=2
                    RUNTIME_CONNECTIVITY_BACKOFF_STEADY_SECS=3
                    """
                ),
                encoding="utf-8",
            )
            script = textwrap.dedent(
                f"""\
                source "{RUNTIME_HELPER}"
                export TURNLOOP_RUNTIME_CONFIG_FILE="{config_path}"
                turnloop_runtime_load_config "$TURNLOOP_RUNTIME_CONFIG_FILE"
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                if turnloop_runtime_wait_for_connectivity_recovery ""; then
                  echo waited
                else
                  echo no_wait
                fi
                """
            )

            completed = subprocess.run(
                ["bash", "-lc", script],
                cwd=REPO_ROOT,
                text=True,
                capture_output=True,
                check=True,
                env=os.environ.copy(),
            )

        self.assertEqual(completed.stdout.strip(), "no_wait")

    def test_connectivity_wait_uses_backoff_until_probe_recovers(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            config_path = root / "runtime_config.env"
            online_marker = root / "online"
            config_path.write_text(
                textwrap.dedent(
                    """\
                    RUNTIME_SLEEP_SLICE_SECS=1
                    RUNTIME_REEXEC_ON_DRIFT=false
                    RUNTIME_HEARTBEAT_ENABLED=false
                    RUNTIME_CONNECTIVITY_RETRY_ENABLED=true
                    RUNTIME_CONNECTIVITY_CHECK_COMMAND='test -f "$TURNLOOP_TEST_ONLINE_MARKER"'
                    RUNTIME_CONNECTIVITY_BACKOFF_INITIAL_SECS=1
                    RUNTIME_CONNECTIVITY_BACKOFF_SECOND_SECS=2
                    RUNTIME_CONNECTIVITY_BACKOFF_STEADY_SECS=3
                    """
                ),
                encoding="utf-8",
            )
            script = textwrap.dedent(
                f"""\
                source "{RUNTIME_HELPER}"
                export TURNLOOP_RUNTIME_CONFIG_FILE="{config_path}"
                export TURNLOOP_TEST_ONLINE_MARKER="{online_marker}"
                turnloop_runtime_load_config "$TURNLOOP_RUNTIME_CONFIG_FILE"
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                (
                  sleep 1.5
                  touch "{online_marker}"
                ) &
                if turnloop_runtime_wait_for_connectivity_recovery ""; then
                  echo recovered
                else
                  echo no_wait
                fi
                """
            )

            started = time.monotonic()
            completed = subprocess.run(
                ["bash", "-lc", script],
                cwd=REPO_ROOT,
                text=True,
                capture_output=True,
                check=True,
                env=os.environ.copy(),
            )
            elapsed = time.monotonic() - started

        self.assertEqual(completed.stdout.strip().splitlines()[-1], "recovered")
        self.assertGreaterEqual(elapsed, 3.0)


if __name__ == "__main__":
    unittest.main()
