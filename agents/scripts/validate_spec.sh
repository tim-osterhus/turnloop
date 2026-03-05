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
report_path="$reports_dir/${spec_stem}.validation.md"

violations=()

required_headings=(
  "Summary"
  "Problem statement"
  "Scope (In / Out)"
  "Constraints"
  "Requirements"
  "Verification plan"
  "Assumptions"
  "Open questions"
)

normalize_heading() {
  local value="$1"
  value="$(printf '%s' "$value" | sed -E 's/[[:space:]]*#+[[:space:]]*$//')"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value" | tr '[:upper:]' '[:lower:]'
}

declare -A found_headings=()
scope_heading_norm="$(normalize_heading "Scope (In / Out)")"
scope_has_in=false
scope_has_out=false
in_scope=false
scope_seen=false
scope_label_prefix='^[[:space:]]*([-*+]|[0-9]+[.)])?[[:space:]]*'

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ $line =~ ^[[:space:]]*#{1,6}[[:space:]]+(.+)$ ]]; then
    heading_raw="${BASH_REMATCH[1]}"
    heading_norm="$(normalize_heading "$heading_raw")"
    found_headings["$heading_norm"]=1
    if [[ "$heading_norm" == "$scope_heading_norm" ]]; then
      in_scope=true
      scope_seen=true
    else
      in_scope=false
    fi
    continue
  fi

  if $in_scope; then
    if [[ $line =~ ${scope_label_prefix}In: ]]; then
      scope_has_in=true
    fi
    if [[ $line =~ ${scope_label_prefix}Out: ]]; then
      scope_has_out=true
    fi
  fi
done < "$spec_path"

for heading in "${required_headings[@]}"; do
  heading_norm="$(normalize_heading "$heading")"
  if [[ -z "${found_headings[$heading_norm]+x}" ]]; then
    violations+=("Missing required heading: $heading")
  fi
done

if $scope_seen; then
  if ! $scope_has_in; then
    violations+=("Missing Scope (In / Out) label: In:")
  fi
  if ! $scope_has_out; then
    violations+=("Missing Scope (In / Out) label: Out:")
  fi
fi

if (( ${#violations[@]} > 0 )); then
  {
    echo "Validation failed with ${#violations[@]} issue(s)."
    printf '%s\n' "${violations[@]}"
  } | tee "$report_path" >&2
  exit 1
fi

echo "OK: no validation violations."
