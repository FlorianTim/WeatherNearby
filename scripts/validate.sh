#!/usr/bin/env bash
# Run local validation checks (format + analyze + test) using Melos.
# Requires the Flutter SDK; Melos is used globally when installed and via
# `dart run melos` otherwise.
#
# Usage: ./scripts/validate.sh   (runs from anywhere)
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

echo "==> VERSION consistency"
version_file="$(tr -d '[:space:]' < VERSION)"
pubspec_version="$(grep -E '^version:' apps/mobile_app/pubspec.yaml | sed -E 's/version:[[:space:]]*//' | cut -d+ -f1)"
if [ "$version_file" != "$pubspec_version" ]; then
  echo "ERROR: VERSION ($version_file) != apps/mobile_app/pubspec.yaml version ($pubspec_version)." >&2
  echo "Keep both in sync (VERSION holds the semver without build number)." >&2
  exit 1
fi
echo "VERSION and pubspec.yaml agree: $version_file"

echo "==> OpenSpec validation"
bash scripts/validate_openspec.sh

echo "==> Format check"
melos_cmd run format:check

echo "==> Analyze"
melos_cmd run analyze

echo "==> Tests"
melos_cmd run test

# The bundled help is generated from docs/public-site/. Skipped when the
# synchronized baseline is absent, so a fresh checkout can still validate.
help_tool="$REPO_ROOT/.lumbrecode/tooling/docs/render_app_help.py"
if [ -f "$help_tool" ]; then
  echo "==> Generated help"
  python "$help_tool" --repo "$REPO_ROOT"     --out apps/mobile_app/assets/help     --pattern '{document}_{locale}.md' --target app --check
else
  echo "==> Generated help: skipped (no .lumbrecode baseline in this checkout)"
fi

echo ""
echo "All checks passed."
