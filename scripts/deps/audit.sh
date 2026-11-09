#!/usr/bin/env bash
# Check the resolved dependencies for known security vulnerabilities and, on
# request, pull in the fixes.
#
# Wraps tools/audit_deps.dart, which matches every hosted package in
# pubspec.lock against the OSV.dev advisory database (no account, no API key;
# only public package names and versions are sent).
#
# Usage:
#   scripts/deps/audit.sh                 # report only, exit 1 on findings
#   scripts/deps/audit.sh --fix           # report, then upgrade affected packages
#   scripts/deps/audit.sh --outdated      # also show how far behind the tree is
#   scripts/deps/audit.sh --json          # machine-readable (CI)
#   scripts/deps/audit.sh --offline       # skip the network call
#
# Related:
#   scripts/deps/upgrade_deps.sh     upgrade everything, including major versions
#   scripts/deps/flutter_upgrade.sh  upgrade the Flutter SDK itself
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

require_cmd dart "Install the Flutter SDK (it ships dart)."

[ -f pubspec.lock ] || {
  step "No pubspec.lock yet - resolving dependencies first"
  melos_cmd bs
}

step "Auditing dependencies against OSV.dev"
set +e
dart tools/audit_deps.dart "$@"
code=$?
set -e

case "$code" in
  0) ok "no known vulnerabilities" ;;
  1) warn "vulnerable dependencies found - see the report above" ;;
  *) die "audit could not complete (exit $code)" ;;
esac

# Android's native dependencies are not covered by pub - remind once, cheaply.
if [ "$code" != "0" ] || [ "${VERBOSE:-0}" = "1" ]; then
  info "Native Android dependencies are not part of this audit."
  info "Check them with: cd apps/mobile_app/android && ./gradlew dependencyUpdates"
fi

exit "$code"
