#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <spec-file>" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

spec_path="$1"

if [[ ! -f "$spec_path" ]]; then
  echo "Spec file not found: $spec_path" >&2
  exit 3
fi

reports_dir="agents/ideas/validation_reports"
mkdir -p "$reports_dir"

spec_base="$(basename "$spec_path")"
spec_stem="${spec_base%.*}"
report_path="$reports_dir/${spec_stem}.report.txt"

violations=()

# Placeholder for future validation rules.

if (( ${#violations[@]} > 0 )); then
  {
    echo "Validation failed with ${#violations[@]} issue(s)."
    printf '%s\n' "${violations[@]}"
  } | tee "$report_path" >&2
  exit 1
fi

echo "OK: no validation violations."
