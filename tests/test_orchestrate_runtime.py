import os
import subprocess
import tempfile
import textwrap
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ORCHESTRATE_SCRIPT = REPO_ROOT / "agents" / "scripts" / "orchestrate_loop.sh"


def run_orchestrate_helper(script_body: str, env: dict[str, str] | None = None) -> str:
    completed = subprocess.run(
        ["bash", "-lc", script_body],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=True,
        env={**os.environ, **(env or {})},
    )
    return completed.stdout


class OrchestrateRuntimeTests(unittest.TestCase):
    def test_append_archive_keeps_single_task_heading(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "task.md").write_text(
                textwrap.dedent(
                    """\
                    ## 2026-03-07 — Sample Task

                    - Goal: Verify archive formatting.
                    - Verification commands:
                      - `echo ok`
                    """
                ),
                encoding="utf-8",
            )
            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                append_archive
                cat "{tmp_root / 'agents' / 'work' / 'tasksarchive.md'}"
                """
            )

            archive_text = run_orchestrate_helper(script)

        self.assertIn("# Tasks Archive", archive_text)
        self.assertEqual(archive_text.count("## 2026-03-07 — Sample Task"), 1)

    def test_append_backburner_keeps_single_task_heading(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "task.md").write_text(
                textwrap.dedent(
                    """\
                    ## 2026-03-07 — Sample Task

                    - Goal: Verify backburner formatting.
                    - Verification commands:
                      - `echo ok`
                    """
                ),
                encoding="utf-8",
            )
            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                append_backburner
                cat "{tmp_root / 'agents' / 'work' / 'tasksbackburner.md'}"
                """
            )

            backburner_text = run_orchestrate_helper(script)

        self.assertIn("# Tasks Backburner", backburner_text)
        self.assertEqual(
            backburner_text.count("## 2026-03-07 — Sample Task (Auto-demoted)"),
            1,
        )
        self.assertEqual(backburner_text.count("## 2026-03-07 — Sample Task\n"), 0)

    def test_pending_queue_handoff_moves_cards_into_backlog_then_task(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### IDLE\n", encoding="utf-8")
            (tmp_root / "agents" / "work" / "taskspending.md").write_text(
                textwrap.dedent(
                    """\
                    # Tasks Pending

                    ## 2026-03-07 — First Pending Task

                    - Goal: Promote the oldest pending task first.

                    ## 2026-03-07 — Second Pending Task

                    - Goal: Leave the second task in backlog.
                    """
                ),
                encoding="utf-8",
            )
            (tmp_root / "agents" / "work" / "tasksbacklog.md").write_text("# Tasks Backlog\n", encoding="utf-8")
            (tmp_root / "agents" / "work" / "task.md").write_text("## No active task\nNo active task.\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                RUNTIME_SLEEP_SLICE_SECS=1
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                hydrate_backlog_from_pending
                runtime_wait "$BACKLOG_PROMOTE_DELAY_SECS" "promote_delay" "backlog has tasks"
                promote_next_task
                """
            )

            started = time.monotonic()
            run_orchestrate_helper(
                script,
                env={
                    "TURNLOOP_PENDING_TRANSFER_DELAY_SECS": "1",
                    "TURNLOOP_BACKLOG_PROMOTE_DELAY_SECS": "1",
                    "TURNLOOP_PROMOTE_DELAY_SECS": "1",
                },
            )
            elapsed = time.monotonic() - started

            task_text = (tmp_root / "agents" / "work" / "task.md").read_text(encoding="utf-8")
            backlog_text = (tmp_root / "agents" / "work" / "tasksbacklog.md").read_text(encoding="utf-8")
            pending_text = (tmp_root / "agents" / "work" / "taskspending.md").read_text(encoding="utf-8")

        self.assertGreaterEqual(elapsed, 2.0)
        self.assertIn("## 2026-03-07 — First Pending Task", task_text)
        self.assertNotIn("## 2026-03-07 — First Pending Task", backlog_text)
        self.assertIn("## 2026-03-07 — Second Pending Task", backlog_text)
        self.assertTrue(backlog_text.startswith("# Tasks Backlog"))
        self.assertNotIn("# Tasks Pending", backlog_text)
        self.assertEqual(pending_text, "# Tasks Pending\n")

    def test_run_entrypoint_retries_after_connectivity_recovers(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            online_marker = tmp_root / "online"
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                RUNTIME_CONNECTIVITY_RETRY_ENABLED=true
                RUNTIME_CONNECTIVITY_BACKOFF_INITIAL_SECS=1
                RUNTIME_CONNECTIVITY_BACKOFF_SECOND_SECS=2
                RUNTIME_CONNECTIVITY_BACKOFF_STEADY_SECS=3
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                attempt_file="{tmp_root / 'attempts.txt'}"
                invoke_runner() {{
                  local runner="$1"
                  local instruction="$2"
                  local model="$3"
                  local effort="$4"
                  local log_file="$5"
                  local count=0
                  if [ -f "$attempt_file" ]; then
                    count="$(cat "$attempt_file")"
                  fi
                  count=$((count + 1))
                  printf '%s\\n' "$count" > "$attempt_file"
                  if [ "$count" -lt 2 ]; then
                    return 1
                  fi
                  return 0
                }}
                turnloop_runtime_connectivity_probe() {{
                  test -f "{online_marker}"
                }}
                (
                  sleep 1.5
                  touch "{online_marker}"
                ) &
                set +e
                run_entrypoint "$ENTRY_START" "codex" "test-model" "medium" "" ""
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'attempts=%s\\n' "$(cat "$attempt_file")"
                printf 'status=%s\\n' "$(get_status)"
                """
            )

            started = time.monotonic()
            output = run_orchestrate_helper(script)
            elapsed = time.monotonic() - started

        self.assertIn("rc=0", output)
        self.assertIn("attempts=2", output)
        self.assertIn("status=### IDLE", output)
        self.assertGreaterEqual(elapsed, 3.0)

    def test_run_entrypoint_preserves_status_set_before_runner_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                invoke_runner() {{
                  write_status "### BUILDER_COMPLETE"
                  return 1
                }}
                set +e
                run_entrypoint "$ENTRY_START" "codex" "test-model" "medium" "" ""
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'status=%s\\n' "$(get_status)"
                """
            )

            output = run_orchestrate_helper(script)

        self.assertIn("rc=0", output)
        self.assertIn("status=### BUILDER_COMPLETE", output)

    def test_run_entrypoint_preserves_rewritten_same_status_before_runner_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                invoke_runner() {{
                  write_status "### IDLE"
                  return 1
                }}
                set +e
                run_entrypoint "$ENTRY_START" "codex" "test-model" "medium" "" ""
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'status=%s\\n' "$(get_status)"
                """
            )

            output = run_orchestrate_helper(script)

        self.assertIn("rc=0", output)
        self.assertIn("status=### IDLE", output)

    def test_run_entrypoint_retries_probable_codex_startup_fault(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                RUNTIME_CODEX_INFRA_RETRY_ENABLED=true
                RUNTIME_CODEX_INFRA_RETRY_MAX_ATTEMPTS=2
                RUNTIME_CODEX_INFRA_BACKOFF_INITIAL_SECS=1
                RUNTIME_CODEX_INFRA_BACKOFF_SECOND_SECS=1
                RUNTIME_CODEX_INFRA_BACKOFF_STEADY_SECS=1
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                attempt_file="{tmp_root / 'attempts.txt'}"
                runtime_wait() {{ :; }}
                invoke_runner() {{
                  local runner="$1"
                  local instruction="$2"
                  local model="$3"
                  local effort="$4"
                  local log_file="$5"
                  local count=0
                  if [ -f "$attempt_file" ]; then
                    count="$(cat "$attempt_file")"
                  fi
                  count=$((count + 1))
                  printf '%s\\n' "$count" > "$attempt_file"
                  if [ "$count" -eq 1 ]; then
                    printf 'Error: No such file or directory (os error 2)\\n' >> "$log_file"
                    printf 'Error: No such file or directory (os error 2)\\n' >> "$log_file"
                    return 1
                  fi
                  write_status "### BUILDER_COMPLETE"
                  return 0
                }}
                set +e
                run_entrypoint "$ENTRY_START" "codex" "test-model" "medium" "" ""
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'attempts=%s\\n' "$(cat "$attempt_file")"
                printf 'status=%s\\n' "$(get_status)"
                printf 'summary=%s\\n' "$(entrypoint_finish_summary)"
                """
            )

            output = run_orchestrate_helper(script)

        self.assertIn("rc=0", output)
        self.assertIn("attempts=2", output)
        self.assertIn("status=### BUILDER_COMPLETE", output)
        self.assertIn("codex_infra_retries=1", output)

    def test_run_entrypoint_preserves_fallback_status_set_before_runner_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                invoke_runner() {{
                  local runner="$1"
                  if [ "$runner" = "gemini" ]; then
                    return 11
                  fi
                  write_status "### BUILDER_COMPLETE"
                  return 1
                }}
                set +e
                run_entrypoint "$ENTRY_START" "gemini" "test-model" "medium" "codex" "fallback-model"
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'status=%s\\n' "$(get_status)"
                """
            )

            output = run_orchestrate_helper(script)

        self.assertIn("rc=0", output)
        self.assertIn("status=### BUILDER_COMPLETE", output)

    def test_prepare_update_cycle_resets_task_to_placeholder(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "task.md").write_text(
                textwrap.dedent(
                    """\
                    ## 2026-03-07 — Sample Task

                    - Goal: Verify cleanup formatting.
                    """
                ),
                encoding="utf-8",
            )

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                prepare_update_cycle
                cat "{tmp_root / 'agents' / 'work' / 'task.md'}"
                printf 'status=%s\\n' "$(get_status)"
                """
            )

            output = run_orchestrate_helper(script)

        self.assertIn("## No active task", output)
        self.assertIn("No active task.", output)
        self.assertIn("status=### UPDATE_PENDING", output)

    def test_pending_queue_handoff_preserves_body_headings_inside_task(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### IDLE\n", encoding="utf-8")
            (tmp_root / "agents" / "work" / "taskspending.md").write_text(
                textwrap.dedent(
                    """\
                    # Tasks Pending

                    ## 2026-03-07 — First Pending Task

                    - Goal: Preserve internal headings.

                    ## Notes
                    - This heading belongs to the task body and must not split the card.

                    ## 2026-03-07 — Second Pending Task

                    - Goal: Remain queued after promotion.
                    """
                ),
                encoding="utf-8",
            )
            (tmp_root / "agents" / "work" / "tasksbacklog.md").write_text("# Tasks Backlog\n", encoding="utf-8")
            (tmp_root / "agents" / "work" / "task.md").write_text("## No active task\nNo active task.\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                transfer_pending_to_backlog
                promote_next_task
                cat "{tmp_root / 'agents' / 'work' / 'task.md'}"
                printf '\\n===BACKLOG===\\n'
                cat "{tmp_root / 'agents' / 'work' / 'tasksbacklog.md'}"
                """
            )

            output = run_orchestrate_helper(script)

        task_text, backlog_text = output.split("\n===BACKLOG===\n", maxsplit=1)
        self.assertIn("## Notes", task_text)
        self.assertIn("Second Pending Task", backlog_text)
        self.assertNotIn("## Notes\n- This heading belongs to the task body and must not split the card.\n\n## 2026-03-07 — Second Pending Task", task_text)

    def test_quickfix_cycle_skips_qa_when_builder_blocks(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "prompts").mkdir(parents=True)
            (tmp_root / "agents" / "work" / "finished").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "orchestrate_status.md").write_text("### QUICKFIX_NEEDED\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                RUNTIME_HEARTBEAT_ENABLED=false
                RUNTIME_REEXEC_ON_DRIFT=false
                declare -a TURNLOOP_RUNTIME_WATCH_FILES=()
                TURNLOOP_RUNTIME_LAST_STATUS=""
                TURNLOOP_RUNTIME_STATE_FILE=""
                TURNLOOP_RUNTIME_LOOP_NAME="test"
                TURNLOOP_RUNTIME_BASELINE_HASH=""
                reload_loop_config
                reload_model_config
                call_log="{tmp_root / 'calls.txt'}"
                run_entrypoint() {{
                  local entry="$1"
                  printf '%s\\n' "$(basename "$entry")" >> "$call_log"
                  if [ "$(basename "$entry")" = "_start.md" ]; then
                    write_status "### BLOCKED"
                    return 1
                  fi
                  write_status "### QA_COMPLETE"
                  return 0
                }}
                run_quickfix_cycle
                printf 'status=%s\\n' "$(get_status)"
                printf 'quickfix_count=%s\\n' "$(get_quickfix_count)"
                printf 'calls=%s\\n' "$(paste -sd, "$call_log")"
                """
            )

            output = run_orchestrate_helper(script)

        self.assertIn("status=### BLOCKED", output)
        self.assertIn("quickfix_count=1", output)
        self.assertIn("calls=_start.md", output)
        self.assertNotIn("_check.md", output)


if __name__ == "__main__":
    unittest.main()
