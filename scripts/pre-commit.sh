#!/usr/bin/env bash
# Pre-commit: fast format check only (path-aware).
#
# The slower analyze + test gate runs on PRE-PUSH (scripts/pre-push.sh), so
# commits stay fast. Formatting is cheap (~1s) and worth catching immediately.
#
# Run manually:        ./scripts/pre-commit.sh
# Force (ignore index):./scripts/pre-commit.sh --all
# Install as git hook: ./scripts/install-hooks.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

failed=0

force_all=0
[ "${1:-}" = "--all" ] && force_all=1
staged="$(git diff --cached --name-only --diff-filter=ACMR || true)"

run_mobile=0
run_api=0
if [ "$force_all" -eq 1 ] || [ -z "$staged" ]; then
  run_mobile=1
  run_api=1
else
  if echo "$staged" | grep -qE '^(apps/mobile_app/.*\.(dart|arb)|apps/mobile_app/(pubspec\.yaml|analysis_options\.yaml|l10n\.yaml)|packages/.*\.dart|packages/[^/]+/pubspec\.yaml|pubspec\.yaml|analysis_options\.yaml)$'; then
    run_mobile=1
  fi
  if echo "$staged" | grep -qE '^services/api/'; then
    run_api=1
  fi
fi

if [ "$run_mobile" -eq 1 ] && command -v dart >/dev/null 2>&1; then
  echo "==> [mobile] dart format"
  (cd apps/mobile_app && dart format --output=none --set-exit-if-changed lib test) || failed=1
else
  echo "==> [mobile] no relevant changes staged – skipping format"
fi

if [ "$run_api" -eq 1 ] && [ -d services/api ] && command -v dart >/dev/null 2>&1; then
  echo "==> [api] dart format"
  (cd services/api && dart format --output=none --set-exit-if-changed .) || failed=1
else
  echo "==> [api] no services/api changes staged – skipping format"
fi

if [ "$failed" -ne 0 ]; then
  echo ""
  echo "✗ Formatting check failed. Run 'dart format .' and re-stage."
  exit 1
fi

echo ""
echo "✓ Pre-commit format check passed (analyze + test run on push)."
