#!/usr/bin/env bash
# Upgrade the local Flutter SDK and refresh the dependencies:
#   1. flutter upgrade      - pulls the latest SDK on the current channel
#   2. reports how CI relates to the new local version
#   3. flutter pub upgrade  - refreshes dependencies in app and packages
#
# Usage:
#   ./scripts/deps/flutter_upgrade.sh
#
# On CI pins: the workflows request `flutter-version: 3.x`, so patch and minor
# releases reach CI on their own and there is nothing to sync here. Should
# someone re-pin an exact version, this script notices and rewrites it, so the
# two cannot drift apart silently.
#
# Note: review and commit the resulting pubspec.yaml changes afterwards.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
WORKFLOWS_DIR="$REPO_ROOT/.github/workflows"

require_cmd flutter "Install the Flutter SDK and put it on PATH."

# An exact x.y.z pin in any workflow - empty when they all float on 3.x.
OLD_VERSION="$(grep -rhE '^\s*flutter-version:' "$WORKFLOWS_DIR"/*.yml 2>/dev/null \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"

step "Upgrading the Flutter SDK"
flutter upgrade

NEW_VERSION="$(flutter --version 2>&1 | grep "^Flutter" | awk '{print $2}')"
ok "local Flutter is now $NEW_VERSION"

if [ -z "$OLD_VERSION" ]; then
  wildcard="$(grep -rhE '^\s*flutter-version:' "$WORKFLOWS_DIR"/*.yml 2>/dev/null \
    | head -1 | sed 's/.*flutter-version:[[:space:]]*//' || true)"
  info "CI requests '${wildcard:-<none>}' - it follows along on its own, nothing to sync."
elif [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  info "CI already pins $NEW_VERSION exactly - nothing to sync."
else
  step "Re-pinning the workflows: $OLD_VERSION -> $NEW_VERSION"
  for workflow in "$WORKFLOWS_DIR"/*.yml; do
    if grep -q "flutter-version: $OLD_VERSION" "$workflow"; then
      sed -i "s/flutter-version: $OLD_VERSION/flutter-version: $NEW_VERSION/g" "$workflow"
      info "updated $(basename "$workflow")"
    fi
  done
fi

step "Upgrading pub dependencies"
bash scripts/deps/upgrade_deps.sh

echo ""
ok "Flutter SDK upgraded to $NEW_VERSION"
info "Review the changes and commit. Then check for advisories: scripts/deps/audit.sh"
