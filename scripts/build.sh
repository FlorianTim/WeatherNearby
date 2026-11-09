#!/usr/bin/env bash
# Build and quality-check the app locally via Docker.
# No local Flutter/Dart SDK required — everything runs inside containers.
#
# Usage:
#   ./scripts/build.sh web                    # Flutter web release build
#   ./scripts/build.sh android                # Flutter APK release build
#   ./scripts/build.sh analyze                # analyze mobile + API
#   ./scripts/build.sh test                   # test mobile + API
#   ./scripts/build.sh integration-test       # integration tests (mobile)
#   ./scripts/build.sh integration-web        # integration tests (web, both orientations)
#   ./scripts/build.sh integration-test-report # tests + report + PDF in one go
#   ./scripts/build.sh audit                  # scan dependencies for CVEs
#   ./scripts/build.sh upgrade-deps           # upgrade all pub dependencies
#   ./scripts/build.sh flutter-upgrade        # upgrade the local Flutter SDK
#   ./scripts/build.sh format                 # check formatting
#   ./scripts/build.sh ci                     # format + analyze + test (full CI)
#   ./scripts/build.sh api                    # start API server on :8080
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

has_backend() { [ -d services/api ]; }

run_analyze() {
  docker compose run --rm mobile-analyze
  if has_backend; then docker compose run --rm api-analyze; fi
}

run_test() {
  docker compose run --rm mobile-test
  if has_backend; then docker compose run --rm api-test; fi
}

run_format() {
  docker compose run --rm mobile-format-check
  if has_backend; then docker compose run --rm api-format-check; fi
}

case "${1:-}" in
  web)              docker compose run --rm mobile-build-web ;;
  android)          docker compose run --rm mobile-build-android ;;
  analyze)          run_analyze ;;
  test)             run_test ;;
  integration-test)        docker compose run --rm mobile-integration-test ;;
  integration-web)         docker compose run --rm mobile-integration-test-web ;;
  integration-test-report) bash scripts/automation/integration-test/integration_test_report.sh ;;
  audit)                   bash scripts/deps/audit.sh ;;
  upgrade-deps)            bash scripts/deps/upgrade_deps.sh ;;
  flutter-upgrade)         bash scripts/deps/flutter_upgrade.sh ;;
  format)                  run_format ;;
  ci)
    run_format
    run_analyze
    run_test
    echo ""
    echo "✓ All CI checks passed."
    ;;
  api)
    if ! has_backend; then
      echo "No backend present (services/api was removed)." >&2
      exit 1
    fi
    docker compose up api-server
    ;;
  *)
    echo "Usage: $0 {web|android|analyze|test|integration-test|integration-web|integration-test-report|audit|upgrade-deps|flutter-upgrade|format|ci|api}" >&2
    exit 1
    ;;
esac
