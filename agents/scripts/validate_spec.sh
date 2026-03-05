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

count_occurrences() {
  local haystack="$1"
  local needle="$2"
  local count=0
  while [[ "$haystack" == *"$needle"* ]]; do
    haystack="${haystack#*"$needle"}"
    count=$((count + 1))
  done
  printf '%s' "$count"
}

declare -A found_headings=()
scope_heading_norm="$(normalize_heading "Scope (In / Out)")"
requirements_heading_norm="$(normalize_heading "Requirements")"
scope_has_in=false
scope_has_out=false
in_scope=false
scope_seen=false
in_requirements=false
requirements_seen=false
requirements_line_count=0
scope_label_prefix='^[[:space:]]*([-*+]|[0-9]+[.)])?[[:space:]]*'
requirements_line_pattern='^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]+'

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
    if [[ "$heading_norm" == "$requirements_heading_norm" ]]; then
      in_requirements=true
      requirements_seen=true
    else
      in_requirements=false
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

  if $in_requirements; then
    if [[ $line =~ $requirements_line_pattern ]]; then
      requirements_line_count=$((requirements_line_count + 1))
      shall_not_count="$(count_occurrences "$line" "SHALL NOT")"
      line_without_shall_not="${line//SHALL NOT/}"
      shall_count="$(count_occurrences "$line_without_shall_not" "SHALL")"
      total_shall_count=$((shall_not_count + shall_count))
      if (( total_shall_count != 1 )); then
        violations+=("Requirement line must contain exactly one SHALL or SHALL NOT: $line")
      fi
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

if $requirements_seen && (( requirements_line_count == 0 )); then
  violations+=("Requirements section must include at least one bullet or numbered line.")
fi

if (( ${#violations[@]} > 0 )); then
  {
    echo "Validation failed with ${#violations[@]} issue(s)."
    printf '%s\n' "${violations[@]}"
  } | tee "$report_path" >&2
  exit 1
fi

echo "OK: no validation violations."
