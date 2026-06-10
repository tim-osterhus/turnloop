import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ORCHESTRATE_SCRIPT = REPO_ROOT / "agents" / "scripts" / "orchestrate_loop.sh"
RESEARCH_SCRIPT = REPO_ROOT / "agents" / "scripts" / "research_loop.sh"


def run_shell(script: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", "-lc", script],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=True,
        env=os.environ.copy(),
    )


class LoopConfigTests(unittest.TestCase):
    def test_research_oldest_eligible_file_ignores_gitkeep(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            staging_dir = tmp_root / "agents" / "ideas" / "staging"
            staging_dir.mkdir(parents=True)
            (staging_dir / ".gitkeep").write_text("\n", encoding="utf-8")
            (staging_dir / "spec.md").write_text("spec\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                export TURNLOOP_WORK_ROOT="{tmp_root}"
                source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
                oldest_eligible_file "{staging_dir}"
                """
            )

            completed = run_shell(script)

        self.assertEqual(completed.stdout.strip(), str(staging_dir / "spec.md"))

    def test_research_move_offending_to_nonviable_preserves_gitkeep(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            staging_dir = tmp_root / "agents" / "ideas" / "staging"
            nonviable_dir = tmp_root / "agents" / "ideas" / "nonviable"
            staging_dir.mkdir(parents=True)
            nonviable_dir.mkdir(parents=True)
            (staging_dir / ".gitkeep").write_text("\n", encoding="utf-8")
            (staging_dir / "spec.md").write_text("spec\n", encoding="utf-8")
            (nonviable_dir / ".gitkeep").write_text("\n", encoding="utf-8")

            script = textwrap.dedent(
                f"""\
                export TURNLOOP_WORK_ROOT="{tmp_root}"
                source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
                move_offending_to_nonviable manage
                """
            )

            completed = run_shell(script)

            self.assertEqual(completed.stdout.strip(), "")
            self.assertTrue((staging_dir / ".gitkeep").exists())
            self.assertFalse((staging_dir / "spec.md").exists())
            self.assertTrue((nonviable_dir / "spec.md").exists())

    def test_orchestrate_reload_loop_config_picks_up_live_changes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            loop_config = tmp_root / "loop_config.env"
            loop_config.write_text(
                textwrap.dedent(
                    """\
                    ORCH_ENTRY_START=agents/entrypoints/custom_start.md
                    ORCH_IDLE_POLL_SECS=7
                    ORCH_PENDING_TRANSFER_DELAY_SECS=5
                    ORCH_BACKLOG_PROMOTE_DELAY_SECS=9
                    ORCH_QUICKFIX_MAX_ATTEMPTS=4
                    ORCH_UPDATE_MAX_ATTEMPTS=3
                    ORCH_TROUBLESHOOT_MAX_ATTEMPTS=6
                    ORCH_TROUBLESHOOT_ON_BLOCKED=false
                    ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS=false
                    """
                ),
                encoding="utf-8",
            )

            script = textwrap.dedent(
                f"""\
                export TURNLOOP_WORK_ROOT="{tmp_root}"
                export TURNLOOP_LOOP_CONFIG_FILE="{loop_config}"
                source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                reload_loop_config
                printf 'first|%s|%s|%s|%s|%s|%s|%s\\n' \
                  "$ENTRY_START" "$IDLE_POLL_SECS" "$PENDING_TRANSFER_DELAY_SECS" "$BACKLOG_PROMOTE_DELAY_SECS" \
                  "$ORCH_QUICKFIX_MAX_ATTEMPTS" "$ORCH_TROUBLESHOOT_ON_BLOCKED" "$ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS"
                cat > "{loop_config}" <<'EOF'
                ORCH_ENTRY_START=agents/entrypoints/alt_start.md
                ORCH_IDLE_POLL_SECS=11
                ORCH_PENDING_TRANSFER_DELAY_SECS=8
                ORCH_BACKLOG_PROMOTE_DELAY_SECS=13
                ORCH_QUICKFIX_MAX_ATTEMPTS=2
                ORCH_UPDATE_MAX_ATTEMPTS=5
                ORCH_TROUBLESHOOT_MAX_ATTEMPTS=1
                ORCH_TROUBLESHOOT_ON_BLOCKED=true
                ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS=true
                EOF
                reload_loop_config
                printf 'second|%s|%s|%s|%s|%s|%s|%s\\n' \
                  "$ENTRY_START" "$IDLE_POLL_SECS" "$PENDING_TRANSFER_DELAY_SECS" "$BACKLOG_PROMOTE_DELAY_SECS" \
                  "$ORCH_QUICKFIX_MAX_ATTEMPTS" "$ORCH_TROUBLESHOOT_ON_BLOCKED" "$ORCH_TROUBLESHOOT_ON_UNEXPECTED_STATUS"
                """
            )

            completed = run_shell(script)
            lines = completed.stdout.strip().splitlines()

        self.assertEqual(len(lines), 2)
        self.assertIn("/agents/entrypoints/custom_start.md", lines[0])
        self.assertIn("|7|5|9|4|false|false", lines[0])
        self.assertIn("/agents/entrypoints/alt_start.md", lines[1])
        self.assertIn("|11|8|13|2|true|true", lines[1])

    def test_research_reload_loop_config_picks_up_live_changes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            loop_config = tmp_root / "loop_config.env"
            loop_config.write_text(
                textwrap.dedent(
                    """\
                    RESEARCH_ENTRY_MANAGE=agents/entrypoints/custom_manage.md
                    RESEARCH_POLL_SECS=14
                    RESEARCH_RESEARCH_DELAY_SECS=6
                    RESEARCH_MANAGE_DELAY_SECS=8
                    RESEARCH_MECHANIC_MAX_ATTEMPTS=5
                    RESEARCH_MECHANIC_ON_BLOCKED=false
                    RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS=false
                    """
                ),
                encoding="utf-8",
            )

            script = textwrap.dedent(
                f"""\
                export TURNLOOP_WORK_ROOT="{tmp_root}"
                export TURNLOOP_LOOP_CONFIG_FILE="{loop_config}"
                source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
                reload_loop_config
                printf 'first|%s|%s|%s|%s|%s|%s|%s\\n' \
                  "$ENTRY_MANAGE" "$POLL_SECS" "$RESEARCH_DELAY_SECS" "$MANAGE_DELAY_SECS" \
                  "$RESEARCH_MECHANIC_MAX_ATTEMPTS" "$RESEARCH_MECHANIC_ON_BLOCKED" "$RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS"
                cat > "{loop_config}" <<'EOF'
                RESEARCH_ENTRY_MANAGE=agents/entrypoints/alt_manage.md
                RESEARCH_POLL_SECS=21
                RESEARCH_RESEARCH_DELAY_SECS=12
                RESEARCH_MANAGE_DELAY_SECS=15
                RESEARCH_MECHANIC_MAX_ATTEMPTS=3
                RESEARCH_MECHANIC_ON_BLOCKED=true
                RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS=true
                EOF
                reload_loop_config
                printf 'second|%s|%s|%s|%s|%s|%s|%s\\n' \
                  "$ENTRY_MANAGE" "$POLL_SECS" "$RESEARCH_DELAY_SECS" "$MANAGE_DELAY_SECS" \
                  "$RESEARCH_MECHANIC_MAX_ATTEMPTS" "$RESEARCH_MECHANIC_ON_BLOCKED" "$RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS"
                """
            )

            completed = run_shell(script)
            lines = completed.stdout.strip().splitlines()

        self.assertEqual(len(lines), 2)
        self.assertIn("/agents/entrypoints/custom_manage.md", lines[0])
        self.assertIn("|14|6|8|5|false|false", lines[0])
        self.assertIn("/agents/entrypoints/alt_manage.md", lines[1])
        self.assertIn("|21|12|15|3|true|true", lines[1])

    def test_missing_or_invalid_loop_config_falls_back_to_safe_defaults(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            loop_config = tmp_root / "loop_config.env"
            loop_config.write_text(
                textwrap.dedent(
                    """\
                    ORCH_IDLE_POLL_SECS=bogus
                    ORCH_QUICKFIX_MAX_ATTEMPTS=bad
                    ORCH_TROUBLESHOOT_ON_BLOCKED=maybe
                    RESEARCH_POLL_SECS=broken
                    RESEARCH_MECHANIC_MAX_ATTEMPTS=nope
                    RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS=???
                    """
                ),
                encoding="utf-8",
            )

            script = textwrap.dedent(
                f"""\
                export TURNLOOP_WORK_ROOT="{tmp_root}"
                export TURNLOOP_LOOP_CONFIG_FILE="{loop_config}"
                source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{ORCHESTRATE_SCRIPT}")
                reload_loop_config
                printf 'orch|%s|%s|%s\\n' "$IDLE_POLL_SECS" "$ORCH_QUICKFIX_MAX_ATTEMPTS" "$ORCH_TROUBLESHOOT_ON_BLOCKED"
                source <(awk 'BEGIN{{done=0}} /^while true; do$/{{done=1}} !done{{print}}' "{RESEARCH_SCRIPT}")
                reload_loop_config
                printf 'research|%s|%s|%s\\n' "$POLL_SECS" "$RESEARCH_MECHANIC_MAX_ATTEMPTS" "$RESEARCH_MECHANIC_ON_UNEXPECTED_STATUS"
                """
            )

            completed = run_shell(script)
            lines = completed.stdout.strip().splitlines()

        self.assertEqual(lines[0], "orch|120|2|true")
        self.assertEqual(lines[1], "research|120|2|true")


if __name__ == "__main__":
    unittest.main()
