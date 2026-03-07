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

WORK_ROOT="$(mktemp -d "${REPO_ROOT}/agents/.tmp/orchestrate-happy-path.XXXXXX")"
trap 'rm -rf "$WORK_ROOT"' EXIT

mkdir -p \
  "$WORK_ROOT/agents/.tmp" \
  "$WORK_ROOT/agents/logs" \
  "$WORK_ROOT/agents/work/finished" \
  "$WORK_ROOT/agents/work/prompts"

: > "$WORK_ROOT/agents/work/task.md"
: > "$WORK_ROOT/agents/work/tasksarchive.md"
: > "$WORK_ROOT/agents/work/tasksbackburner.md"
: > "$WORK_ROOT/agents/work/quickfix.md"
: > "$WORK_ROOT/agents/historylog.md"
printf '### IDLE\n' > "$WORK_ROOT/agents/orchestrate_status.md"

older_title="2026-03-01 — Oldest Happy Path Card"
newer_title="2026-03-02 — Newer Happy Path Card"
older_prompt_rel="agents/work/prompts/901-oldest-happy-path.md"
newer_prompt_rel="agents/work/prompts/902-newer-happy-path.md"
older_prompt_path="$WORK_ROOT/$older_prompt_rel"
newer_prompt_path="$WORK_ROOT/$newer_prompt_rel"

cat > "$WORK_ROOT/agents/work/tasksbacklog.md" <<EOF
# Tasks Backlog

## ${older_title}
Goal: Prove the oldest backlog card is the only card completed in one non-daemon run.
Prompt: ${older_prompt_rel}
Verification commands:
- bash agents/scripts/test_orchestrate_happy_path.sh

## ${newer_title}
Goal: Stay queued after the happy-path harness consumes only the oldest card.
Prompt: ${newer_prompt_rel}
Verification commands:
- bash agents/scripts/test_orchestrate_happy_path.sh
EOF

cat > "$older_prompt_path" <<'EOF'
<prompt id="901-oldest-happy-path" task="Oldest Happy Path Card">
  <objective>
    Stub prompt for the oldest happy-path harness card.
  </objective>
</prompt>
EOF

cat > "$newer_prompt_path" <<'EOF'
<prompt id="902-newer-happy-path" task="Newer Happy Path Card">
  <objective>
    Stub prompt for the newer happy-path harness card.
  </objective>
</prompt>
EOF

snapshot_dir="$WORK_ROOT/agents/.tmp/repo-root-snapshots"
mkdir -p "$snapshot_dir"
for rel_path in \
  "agents/work/task.md" \
  "agents/work/tasksbacklog.md" \
  "agents/work/tasksbackburner.md" \
  "agents/work/tasksarchive.md"; do
  snapshot_repo_file "$rel_path" "$snapshot_dir"
done

runner_stub="$WORK_ROOT/agents/.tmp/orchestrate_runner_stub.sh"
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
    printf '### QA_COMPLETE\n' > "$status_file"
    ;;
  *"_update.md"*)
    printf '_update\n' >> "$stage_log"
    printf '### UPDATE_COMPLETE\n' > "$status_file"
    ;;
  *"_troubleshoot.md"*)
    printf '_troubleshoot\n' >> "$stage_log"
    printf '### BLOCKED\n' > "$status_file"
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
[ "$stage_count" = "3" ] || fail "expected exactly one start/check/update sequence, saw $stage_count stage calls"

printf '_start\n_check\n_update\n' > "$WORK_ROOT/agents/.tmp/expected_stage_order.log"
cmp -s "$stage_log" "$WORK_ROOT/agents/.tmp/expected_stage_order.log" || fail "unexpected stage order"

[ ! -s "$WORK_ROOT/agents/work/task.md" ] || fail "isolated active task was not cleared after the cycle"
[ ! -s "$WORK_ROOT/agents/work/tasksbackburner.md" ] || fail "isolated backburner should stay empty on the happy path"
grep -Fxq '### IDLE' "$WORK_ROOT/agents/orchestrate_status.md" || fail "isolated orchestrate status did not return to IDLE"

archive_file="$WORK_ROOT/agents/work/tasksarchive.md"
backlog_file="$WORK_ROOT/agents/work/tasksbacklog.md"
finished_oldest="$WORK_ROOT/agents/work/finished/901-oldest-happy-path.md"

[ -f "$archive_file" ] || fail "isolated archive file is missing"
grep -Fq "$older_title" "$archive_file" || fail "oldest card was not appended to the isolated archive"
if grep -Fq "$newer_title" "$archive_file"; then
  fail "newer card was incorrectly archived in the same run"
fi

grep -Fq "$newer_title" "$backlog_file" || fail "newer card did not remain queued in the isolated backlog"
if grep -Fq "$older_title" "$backlog_file"; then
  fail "oldest card remained in backlog after promotion"
fi

[ -f "$finished_oldest" ] || fail "oldest prompt was not moved into isolated finished prompts"
[ ! -f "$older_prompt_path" ] || fail "oldest prompt remained in isolated prompts after completion"
[ -f "$newer_prompt_path" ] || fail "newer prompt did not remain queued in isolated prompts"
[ ! -f "$WORK_ROOT/agents/work/finished/902-newer-happy-path.md" ] || fail "newer prompt was incorrectly moved to finished"

if grep -Fq '_troubleshoot' "$stage_log"; then
  fail "happy-path run unexpectedly invoked troubleshoot"
fi
grep -Fq '_start.md' "$instruction_log" || fail "runner instructions did not include _start.md"
grep -Fq '_check.md' "$instruction_log" || fail "runner instructions did not include _check.md"
grep -Fq '_update.md' "$instruction_log" || fail "runner instructions did not include _update.md"

for rel_path in \
  "agents/work/task.md" \
  "agents/work/tasksbacklog.md" \
  "agents/work/tasksbackburner.md" \
  "agents/work/tasksarchive.md"; do
  assert_repo_file_unchanged "$rel_path" "$snapshot_dir"
done

printf 'PASS: archive append check passed for %s.\n' "$older_title"
printf 'PASS: prompt-move check passed for %s while %s remained queued.\n' "$older_prompt_rel" "$newer_prompt_rel"
printf 'PASS: remaining-backlog check passed for %s, and repo-root queue files stayed unchanged.\n' "$newer_title"
