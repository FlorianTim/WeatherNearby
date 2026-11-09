#!/usr/bin/env bash
# Validate all OpenSpec app specifications (openspec/apps/*.openspec.yaml)
# against the rules in openspec/README.md. Line-based checks — the spec
# format is a flat, template-controlled YAML.
#
# Usage: ./scripts/validate_openspec.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

fail=0

check_scalar() {
  # key must exist and have a non-empty value ('' / "" / [] count as empty
  # for scalar fields; block scalars '>'/'|' count as non-empty)
  local file="$1" key="$2"
  local line
  line="$(grep -E "^\s*$key:" "$file" | head -1 || true)"
  if [ -z "$line" ]; then
    echo "  MISSING: $key"
    return 1
  fi
  local value="${line#*:}"
  value="$(echo "$value" | tr -d '[:space:]')"
  if [ -z "$value" ] || [ "$value" = '""' ] || [ "$value" = "''" ] || [ "$value" = "[]" ]; then
    echo "  EMPTY: $key"
    return 1
  fi
  return 0
}

check_list() {
  # key must exist and be a non-empty inline list OR followed by "- " items
  local file="$1" key="$2"
  local line
  line="$(grep -nE "^\s*$key:" "$file" | head -1 || true)"
  if [ -z "$line" ]; then
    echo "  MISSING: $key"
    return 1
  fi
  local lineno="${line%%:*}"
  local value="${line#*:}"
  value="${value#*:}"
  value="$(echo "$value" | tr -d '[:space:]')"
  if [ -n "$value" ] && [ "$value" != "[]" ]; then
    return 0
  fi
  local next
  next="$(sed -n "$((lineno + 1))p" "$file" | tr -d '[:space:]')"
  if [[ "$next" == -* ]]; then
    return 0
  fi
  echo "  EMPTY: $key (no list items)"
  return 1
}

specs=(openspec/apps/*.openspec.yaml)
if [ ! -e "${specs[0]}" ]; then
  echo "ERROR: no OpenSpec files under openspec/apps/." >&2
  exit 1
fi

for spec in "${specs[@]}"; do
  echo "==> $spec"
  ok=1

  check_scalar "$spec" "spec_version" || ok=0
  for key in app_name app_display_name app_slug short_description \
             backend_enabled splash_screen_app_name replace_todo_app; do
    check_scalar "$spec" "$key" || ok=0
  done
  for key in primary_platforms core_features privacy_requirements \
             security_requirements; do
    check_list "$spec" "$key" || ok=0
  done

  slug="$(grep -E '^\s*app_slug:' "$spec" | head -1 | sed -E 's/.*app_slug:\s*//' | tr -d '"'"'"' ' || true)"
  if [ -n "$slug" ]; then
    if ! echo "$slug" | grep -qE '^[a-z][a-z0-9_]*$'; then
      echo "  INVALID: app_slug '$slug' must match ^[a-z][a-z0-9_]*\$"
      ok=0
    fi
    case "$slug" in
      test|flutter|dart)
        echo "  INVALID: app_slug '$slug' is a reserved word"
        ok=0
        ;;
    esac
  fi

  if [ "$ok" -eq 1 ]; then
    echo "  OK"
  else
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "OpenSpec validation FAILED." >&2
  exit 1
fi

echo ""
echo "OpenSpec validation passed."
