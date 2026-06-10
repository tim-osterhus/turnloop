import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
RESEARCH_SCRIPT = REPO_ROOT / "agents" / "scripts" / "research_loop.sh"


def run_research_helper(script_body: str, env: dict[str, str] | None = None) -> str:
    completed = subprocess.run(
        ["bash", "-lc", script_body],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=True,
        env={**os.environ, **(env or {})},
    )
    return completed.stdout


class ResearchRuntimeTests(unittest.TestCase):
    def test_invoke_runner_exports_repo_and_work_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "ideas" / "inbox").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "processed").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "staging").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "specs").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "nonviable").mkdir(parents=True)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "research_status.md").write_text("### IDLE\n", encoding="utf-8")
            runner = tmp_root / "capture-env.sh"
            runner.write_text(
                "#!/usr/bin/env bash\n"
                "printf 'repo=%s\\n' \"${TURNLOOP_REPO_ROOT:-}\"\n"
                "printf 'work=%s\\n' \"${TURNLOOP_WORK_ROOT:-}\"\n",
                encoding="utf-8",
            )
            runner.chmod(0o755)

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
                log_file="{tmp_root / 'agents' / 'logs' / 'runner.log'}"
                invoke_runner "{runner}" "ignored" "test-model" "medium" "$log_file"
                cat "$log_file"
                """
            )

            output = run_research_helper(script)

        self.assertIn(f"repo={REPO_ROOT}", output)
        self.assertIn(f"work={tmp_root}", output)

    def test_run_entrypoint_retries_probable_codex_startup_fault(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "ideas" / "inbox").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "processed").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "staging").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "specs").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "nonviable").mkdir(parents=True)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "research_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
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
                  write_status "### IDLE"
                  return 0
                }}
                set +e
                run_entrypoint "$ENTRY_RESEARCH" "codex" "test-model" "medium" "" ""
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'attempts=%s\\n' "$(cat "$attempt_file")"
                printf 'status=%s\\n' "$(get_status)"
                printf 'summary=%s\\n' "$(entrypoint_finish_summary)"
                """
            )

            output = run_research_helper(script)

        self.assertIn("rc=0", output)
        self.assertIn("attempts=2", output)
        self.assertIn("status=### IDLE", output)
        self.assertIn("codex_infra_retries=1", output)

    def test_run_entrypoint_preserves_rewritten_same_status_before_runner_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "ideas" / "inbox").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "processed").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "staging").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "specs").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "nonviable").mkdir(parents=True)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "research_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
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
                run_entrypoint "$ENTRY_RESEARCH" "codex" "test-model" "medium" "" ""
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'status=%s\\n' "$(get_status)"
                """
            )

            output = run_research_helper(script)

        self.assertIn("rc=0", output)
        self.assertIn("status=### IDLE", output)

    def test_run_entrypoint_preserves_fallback_status_set_before_runner_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            (tmp_root / "agents" / "ideas" / "inbox").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "processed").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "staging").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "specs").mkdir(parents=True)
            (tmp_root / "agents" / "ideas" / "nonviable").mkdir(parents=True)
            (tmp_root / "agents" / "work").mkdir(parents=True)
            (tmp_root / "agents" / ".tmp").mkdir(parents=True)
            (tmp_root / "agents" / "logs").mkdir(parents=True)
            (tmp_root / "agents" / "research_status.md").write_text("### IDLE\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                TURNLOOP_WORK_ROOT="{tmp_root}" source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
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
                  write_status "### IDLE"
                  return 1
                }}
                set +e
                run_entrypoint "$ENTRY_RESEARCH" "gemini" "test-model" "medium" "codex" "fallback-model"
                rc="$?"
                set -e
                printf 'rc=%s\\n' "$rc"
                printf 'status=%s\\n' "$(get_status)"
                """
            )

            output = run_research_helper(script)

        self.assertIn("rc=0", output)
        self.assertIn("status=### IDLE", output)


if __name__ == "__main__":
    unittest.main()
