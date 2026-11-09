#!/usr/bin/env bash
# Upgrade all pub dependencies across the monorepo to their latest compatible
# versions and widen version constraints in pubspec.yaml where necessary.
#
# Equivalent to running `flutter pub upgrade --major-versions` /
# `dart pub upgrade --major-versions` in each package directory.
#
# Usage:
#   ./scripts/deps/upgrade_deps.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

upgrade_flutter() {
  local dir="$1"
  echo ""
  echo "--- flutter pub upgrade --major-versions: $dir ---"
  (cd "$dir" && flutter pub upgrade --major-versions)
}

upgrade_dart() {
  local dir="$1"
  echo ""
  echo "--- dart pub upgrade --major-versions: $dir ---"
  (cd "$dir" && dart pub upgrade --major-versions)
}

upgrade_flutter "$REPO_ROOT/apps/mobile_app"

# Packages (Flutter or plain Dart — detect by presence of flutter SDK dep)
for pkg in "$REPO_ROOT/packages"/*/; do
  if grep -q "sdk: flutter" "$pkg/pubspec.yaml" 2>/dev/null; then
    upgrade_flutter "$pkg"
  else
    upgrade_dart "$pkg"
  fi
done

if [ -d "$REPO_ROOT/services/api" ]; then
  upgrade_dart "$REPO_ROOT/services/api"
fi

echo ""
echo "All dependencies upgraded. Review pubspec.yaml changes before committing."
echo "Run 'flutter pub outdated' in each directory to check remaining constraints."
