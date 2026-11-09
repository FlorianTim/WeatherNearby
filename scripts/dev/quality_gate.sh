#!/usr/bin/env bash
# Compact local quality gate: format check + analyze + tests for the mobile
# app, each step reduced to a pass/fail line (full output only on failure).
# Token-saving wrapper for agents.
#
# Usage: scripts/dev/quality_gate.sh
set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
cd "$(app_dir)"

fail=0
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

step() {
  local name="$1"; shift
  if "$@" >"$log" 2>&1; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    sed 's/^/    /' "$log" | tail -30
    fail=1
  fi
}

step "format" dart format --output=none --set-exit-if-changed lib test
step "analyze" flutter analyze --no-pub
step "test" flutter test

# The bundled help is generated from docs/public-site/. Checking it here
# means an edit to a generated file is caught before review, not after
# someone regenerates and wonders where their wording went.
#
# Skipped when the synchronized baseline is absent: a fresh checkout that has
# not run the baseline sync should still be able to run the gate.
help_check() {
  local tool="$REPO_ROOT/.lumbrecode/tooling/docs/render_app_help.py"
  if [ ! -f "$tool" ]; then
    echo "SKIP  help (no .lumbrecode baseline in this checkout)"
    return 0
  fi
  step "help" python "$tool" \
    --repo "$REPO_ROOT" \
    --out apps/mobile_app/assets/help \
    --pattern '{document}_{locale}.md' \
    --target app \
    --check
}
help_check

if [ "$fail" -ne 0 ]; then
  echo "== QUALITY GATE FAILED =="
  exit 1
fi
echo "== QUALITY GATE PASSED =="
