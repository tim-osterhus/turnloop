#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
cd "$REPO_ROOT"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

snapshot_repo_file() {
  local rel_path="$1"
  local snapshot_dir="$2"
  local snapshot_path="${snapshot_dir}/${rel_path//\//__}"
  cp "$REPO_ROOT/$rel_path" "$snapshot_path"
}

assert_repo_file_unchanged() {
  local rel_path="$1"
  local snapshot_dir="$2"
  local snapshot_path="${snapshot_dir}/${rel_path//\//__}"
  cmp -s "$REPO_ROOT/$rel_path" "$snapshot_path" || fail "repo-root file changed: $rel_path"
}

WORK_ROOT="$(mktemp -d "${REPO_ROOT}/agents/.tmp/orchestrate-quickfix-demotion.XXXXXX")"
trap 'rm -rf "$WORK_ROOT"' EXIT

mkdir -p \
  "$WORK_ROOT/agents/.tmp" \
  "$WORK_ROOT/agents/logs" \
  "$WORK_ROOT/agents/work/finished" \
  "$WORK_ROOT/agents/work/prompts"

active_title="2026-03-06 — Quickfix Demotion Candidate"
queued_title="2026-03-07 — Queued Follow-Up Card"
active_prompt_rel="agents/work/prompts/930-quickfix-demotion-candidate.md"
queued_prompt_rel="agents/work/prompts/931-queued-follow-up.md"
active_prompt_path="$WORK_ROOT/$active_prompt_rel"
queued_prompt_path="$WORK_ROOT/$queued_prompt_rel"

cat > "$WORK_ROOT/agents/work/task.md" <<EOF
## ${active_title}
Goal: Prove two failed quickfix loops auto-demote the isolated active task.
Prompt: ${active_prompt_rel}
Verification commands:
- bash agents/scripts/test_orchestrate_quickfix_demotion.sh
EOF

cat > "$WORK_ROOT/agents/work/tasksbacklog.md" <<EOF
# Tasks Backlog

## ${queued_title}
Goal: Stay queued while the isolated active task is auto-demoted.
Prompt: ${queued_prompt_rel}
Verification commands:
- bash agents/scripts/test_orchestrate_quickfix_demotion.sh
EOF

: > "$WORK_ROOT/agents/work/tasksarchive.md"
: > "$WORK_ROOT/agents/work/tasksbackburner.md"
: > "$WORK_ROOT/agents/work/quickfix.md"
: > "$WORK_ROOT/agents/historylog.md"
printf '### IDLE\n' > "$WORK_ROOT/agents/orchestrate_status.md"

cat > "$active_prompt_path" <<'EOF'
<prompt id="930-quickfix-demotion-candidate" task="Quickfix Demotion Candidate">
  <objective>
    Stub prompt for the isolated quickfix auto-demotion harness card.
  </objective>
</prompt>
EOF

cat > "$queued_prompt_path" <<'EOF'
<prompt id="931-queued-follow-up" task="Queued Follow-Up Card">
  <objective>
    Stub prompt for the queued follow-up harness card.
  </objective>
</prompt>
EOF

snapshot_dir="$WORK_ROOT/agents/.tmp/repo-root-snapshots"
mkdir -p "$snapshot_dir"
for rel_path in \
  "agents/work/task.md" \
  "agents/work/tasksbacklog.md" \
  "agents/work/tasksbackburner.md" \
  "agents/work/tasksarchive.md" \
  "agents/work/quickfix.md" \
  "agents/historylog.md" \
  "agents/orchestrate_status.md"; do
  snapshot_repo_file "$rel_path" "$snapshot_dir"
done

runner_stub="$WORK_ROOT/agents/.tmp/orchestrate_quickfix_runner_stub.sh"
stage_log="$WORK_ROOT/agents/.tmp/stage_order.log"
instruction_log="$WORK_ROOT/agents/.tmp/runner_instructions.log"

cat > "$runner_stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

instruction="$*"
work_root="${TURNLOOP_WORK_ROOT:?missing TURNLOOP_WORK_ROOT}"
status_file="${work_root}/agents/orchestrate_status.md"
stage_log="${work_root}/agents/.tmp/stage_order.log"
instruction_log="${work_root}/agents/.tmp/runner_instructions.log"

printf '%s\n' "$instruction" >> "$instruction_log"

case "$instruction" in
  *"_start.md"*)
    printf '_start\n' >> "$stage_log"
    printf '### BUILDER_COMPLETE\n' > "$status_file"
    ;;
  *"_check.md"*)
    printf '_check\n' >> "$stage_log"
    printf '### QUICKFIX_NEEDED\n' > "$status_file"
    ;;
  *"_update.md"*)
    printf '_update\n' >> "$stage_log"
    printf 'unexpected update invocation\n' >&2
    exit 1
    ;;
  *"_troubleshoot.md"*)
    printf '_troubleshoot\n' >> "$stage_log"
    printf 'unexpected troubleshoot invocation\n' >&2
    exit 1
    ;;
  *)
    printf 'unexpected instruction: %s\n' "$instruction" >&2
    exit 1
    ;;
esac
EOF

chmod +x "$runner_stub"

TURNLOOP_WORK_ROOT="$WORK_ROOT" \
TURNLOOP_RUNNER="$runner_stub" \
TURNLOOP_DAEMON_MODE=false \
TURNLOOP_PROMOTE_DELAY_SECS=0 \
TURNLOOP_IDLE_POLL_SECS=0 \
bash agents/scripts/orchestrate_loop.sh

[ -f "$stage_log" ] || fail "runner stub did not record any stage invocations"
[ -f "$instruction_log" ] || fail "runner stub did not capture instructions"

stage_count="$(wc -l < "$stage_log" | tr -d ' ')"
[ "$stage_count" = "6" ] || fail "expected three start/check pairs before demotion, saw $stage_count stage calls"

printf '_start\n_check\n_start\n_check\n_start\n_check\n' > "$WORK_ROOT/agents/.tmp/expected_stage_order.log"
cmp -s "$stage_log" "$WORK_ROOT/agents/.tmp/expected_stage_order.log" || fail "unexpected quickfix stage order"

[ ! -s "$WORK_ROOT/agents/work/task.md" ] || fail "isolated active task was not cleared after auto-demotion"
grep -Fxq '### IDLE' "$WORK_ROOT/agents/orchestrate_status.md" || fail "isolated orchestrate status did not return to IDLE"

backburner_file="$WORK_ROOT/agents/work/tasksbackburner.md"
backlog_file="$WORK_ROOT/agents/work/tasksbacklog.md"
archive_file="$WORK_ROOT/agents/work/tasksarchive.md"

[ -f "$backburner_file" ] || fail "isolated backburner file is missing"
grep -Fq "$active_title" "$backburner_file" || fail "auto-demoted task was not appended to the isolated backburner"
grep -Fq '(Auto-demoted)' "$backburner_file" || fail "backburner entry is missing the auto-demotion marker"
grep -Fq 'Goal: Prove two failed quickfix loops auto-demote the isolated active task.' "$backburner_file" || fail "backburner entry did not preserve the task body"

grep -Fq "$queued_title" "$backlog_file" || fail "queued backlog task was not preserved"
[ ! -s "$archive_file" ] || fail "isolated archive should stay empty during quickfix auto-demotion"
[ -f "$active_prompt_path" ] || fail "active prompt should remain in isolated prompts after demotion"
[ -f "$queued_prompt_path" ] || fail "queued prompt should remain in isolated prompts"
[ ! -f "$WORK_ROOT/agents/work/finished/930-quickfix-demotion-candidate.md" ] || fail "active prompt was incorrectly moved to finished"
[ ! -f "$WORK_ROOT/agents/work/finished/931-queued-follow-up.md" ] || fail "queued prompt was incorrectly moved to finished"

quickfix_count_file="$WORK_ROOT/agents/.tmp/quickfix_count.txt"
[ -f "$quickfix_count_file" ] || fail "quickfix counter file was not created"
grep -Fxq '0' "$quickfix_count_file" || fail "quickfix counter was not reset after demotion"

if grep -Fq '_update' "$stage_log"; then
  fail "quickfix auto-demotion run unexpectedly invoked update"
fi
if grep -Fq '_troubleshoot' "$stage_log"; then
  fail "quickfix auto-demotion run unexpectedly invoked troubleshoot"
fi
grep -Fq '_start.md' "$instruction_log" || fail "runner instructions did not include _start.md"
grep -Fq '_check.md' "$instruction_log" || fail "runner instructions did not include _check.md"

for rel_path in \
  "agents/work/task.md" \
  "agents/work/tasksbacklog.md" \
  "agents/work/tasksbackburner.md" \
  "agents/work/tasksarchive.md" \
  "agents/work/quickfix.md" \
  "agents/historylog.md" \
  "agents/orchestrate_status.md"; do
  assert_repo_file_unchanged "$rel_path" "$snapshot_dir"
done

printf 'PASS: quickfix auto-demotion appended %s to the isolated backburner.\n' "$active_title"
printf 'PASS: isolated active task cleared, quickfix counter reset, and orchestrate status returned to IDLE.\n'
printf 'PASS: queued backlog/prompt state and repo-root workspace files remained unchanged.\n'
