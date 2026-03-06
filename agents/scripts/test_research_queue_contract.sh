#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
cd "$REPO_ROOT"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

create_spec() {
  local path="$1"
  local name="$2"
  cat > "$path" <<EOF
# Summary
Exercise oldest-only queue selection for ${name}.

# Problem statement
The harness needs a valid staged spec so the research loop can reach the manage-ready path locally.

# Scope (In / Out)
In: Local queue-contract coverage for ${name}.
Out: External services or broader integration coverage.

# Constraints
- Keep the fixture valid for the existing shell validator.

# Requirements
- The harness SHALL keep ${name} deterministic for queue-order assertions.

# Verification plan
- Run the local queue-contract harness and inspect the captured selected path.

# Assumptions
- Local stubs are acceptable for runner and validator behavior in this regression harness.

# Open questions
- None.
EOF
}

WORK_ROOT="$(mktemp -d "${REPO_ROOT}/agents/.tmp/research-queue-contract.XXXXXX")"
trap 'rm -rf "$WORK_ROOT"' EXIT

mkdir -p \
  "$WORK_ROOT/agents/.tmp" \
  "$WORK_ROOT/agents/entrypoints" \
  "$WORK_ROOT/agents/ideas/inbox" \
  "$WORK_ROOT/agents/ideas/nonviable" \
  "$WORK_ROOT/agents/ideas/processed" \
  "$WORK_ROOT/agents/ideas/specs" \
  "$WORK_ROOT/agents/ideas/staging" \
  "$WORK_ROOT/agents/logs"

printf '# stub\n' > "$WORK_ROOT/agents/entrypoints/_manage.md"
printf '# stub\n' > "$WORK_ROOT/agents/entrypoints/_mechanic.md"
printf '# stub\n' > "$WORK_ROOT/agents/entrypoints/_research.md"

validator_stub="$WORK_ROOT/agents/.tmp/validate_spec_stub.sh"
runner_stub="$WORK_ROOT/agents/.tmp/runner_stub.sh"
validated_log="$WORK_ROOT/agents/.tmp/validated_specs.log"
managed_log="$WORK_ROOT/agents/.tmp/manage_targets.log"
instruction_log="$WORK_ROOT/agents/.tmp/runner_instructions.log"

cat > "$validator_stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
stub_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
printf '%s\n' "$1" >> "$stub_dir/validated_specs.log"
exit 0
EOF

cat > "$runner_stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
stub_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
printf '%s\n' "$*" >> "$stub_dir/runner_instructions.log"
if [ -z "${TURNLOOP_STAGING_SPEC:-}" ]; then
  exit 0
fi
printf '%s\n' "$TURNLOOP_STAGING_SPEC" >> "$stub_dir/manage_targets.log"
mv "${TURNLOOP_WORK_ROOT}/${TURNLOOP_STAGING_SPEC}" "${TURNLOOP_WORK_ROOT}/agents/ideas/specs/"
printf '### IDLE\n' > "${TURNLOOP_WORK_ROOT}/agents/research_status.md"
exit 0
EOF

chmod +x "$validator_stub" "$runner_stub"

older_rel="agents/ideas/staging/001-oldest.md"
newer_rel="agents/ideas/staging/002-newer.md"
older_path="$WORK_ROOT/$older_rel"
newer_path="$WORK_ROOT/$newer_rel"

create_spec "$older_path" "the oldest spec"
create_spec "$newer_path" "the newer spec"

touch -d '2026-03-05 00:00:00 UTC' "$older_path"
touch -d '2026-03-05 00:01:00 UTC' "$newer_path"

TURNLOOP_WORK_ROOT="$WORK_ROOT" \
TURNLOOP_VALIDATE_SPEC_SCRIPT="$validator_stub" \
TURNLOOP_RUNNER="$runner_stub" \
TURNLOOP_DAEMON_MODE=false \
TURNLOOP_POLL_SECS=0 \
TURNLOOP_PROMOTE_DELAY_SECS=0 \
bash agents/scripts/research_loop.sh

[ -f "$validated_log" ] || fail "validator stub did not capture a selected staging spec"
[ -f "$managed_log" ] || fail "runner stub did not capture a dispatched staging spec"

validated_count="$(wc -l < "$validated_log" | tr -d ' ')"
managed_count="$(wc -l < "$managed_log" | tr -d ' ')"

[ "$validated_count" = "1" ] || fail "expected exactly one validation target, saw $validated_count"
[ "$managed_count" = "1" ] || fail "expected exactly one manage target, saw $managed_count"

grep -Fxq "$older_rel" "$validated_log" || fail "validator did not target the oldest spec"
grep -Fxq "$older_rel" "$managed_log" || fail "manager dispatch did not target the oldest spec"

if grep -Fxq "$newer_rel" "$validated_log"; then
  fail "validator selected the newer spec"
fi
if grep -Fxq "$newer_rel" "$managed_log"; then
  fail "manager dispatch selected the newer spec"
fi

grep -Fq "Use the already-selected staging spec at $older_rel for this run." "$instruction_log" || fail "runner instruction did not include the selected oldest staging spec"

[ ! -f "$older_path" ] || fail "oldest spec remained in staging after the simulated manage run"
[ -f "$WORK_ROOT/agents/ideas/specs/001-oldest.md" ] || fail "oldest spec was not moved into specs by the simulated manage run"
[ -f "$newer_path" ] || fail "newer spec did not remain queued in staging"

printf 'PASS: one manage-ready cycle validated and dispatched only %s; %s remained queued.\n' "$older_rel" "$newer_rel"
