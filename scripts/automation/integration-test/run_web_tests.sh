#!/usr/bin/env bash
# Run Flutter web integration tests for all screen profiles defined in profiles.json.
#
# Called from the docker-compose mobile-integration-test-web service.
# Working directory when called: /workspace/apps/mobile_app
#
# Profile config: docs/public-site/screenshot-profiles.json
#
# Usage (inside Docker container):
#   bash /workspace/scripts/automation/integration-test/run_web_tests.sh
set -euo pipefail

XVFB_PID=""
DRIVER_PID=""
cleanup_profile() {
  if [ -n "$DRIVER_PID" ]; then kill "$DRIVER_PID" 2>/dev/null || true; fi
  if [ -n "$XVFB_PID" ]; then kill "$XVFB_PID" 2>/dev/null || true; fi
  DRIVER_PID=""
  XVFB_PID=""
}
trap cleanup_profile EXIT INT TERM

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# Screen profiles are a shared LumbreCode contract, not a local choice:
# the same file drives the web template's Playwright capture.
PROFILES_FILE="$REPO_ROOT/docs/public-site/screenshot-profiles.json"

# Single place that defines the screenshot test target. Keep the file name
# neutral (app_screenshots_test.dart); swap the flow inside the file per app.
TEST_TARGET="integration_test/app_screenshots_test.dart"

flutter pub get
if [ ! -d web ]; then
  echo "Bootstrapping web platform (org/name from project.env)..."
  bash "$SCRIPT_DIR/../../bootstrap_web.sh"
fi

profiles=$(python3 -c "
import json
for p in json.load(open('$PROFILES_FILE'))['profiles']:
    print(p['name'] + ' ' + str(p['width']) + ' ' + str(p['height']))
")

while IFS=' ' read -r name width height; do
  mkdir -p "test_results/screenshots/$name"
  echo ""
  echo "=== Profile: $name (${width}x${height}) ==="

  Xvfb :99 -screen 0 "${width}x${height}x24" &
  XVFB_PID=$!
  chromedriver --port=4444 --whitelisted-ips= &
  DRIVER_PID=$!
  sleep 2

  if timeout --signal=TERM --kill-after=10s 8m env SCREEN_PROFILE="$name" flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="$TEST_TARGET" \
    -d web-server \
    --dart-define=SCREEN_PROFILE="$name" --dart-define=SCREEN_WIDTH="$width" --dart-define=SCREEN_HEIGHT="$height" --dart-define=SCREENSHOT_DRIVER=true \
    --web-browser-flag="--headless=new" \
    --web-browser-flag="--disable-gpu" \
    --web-browser-flag="--no-sandbox" \
    --web-browser-flag="--disable-dev-shm-usage" \
    --web-browser-flag="--disable-software-rasterizer" \
    --web-browser-flag="--window-size=${width},${height}"; then
    :
  else
    status=$?
    echo "Integration profile $name failed (exit $status)." >&2
    exit "$status"
  fi

  cleanup_profile
  sleep 2
  echo "Screenshots: test_results/screenshots/$name/"
done <<< "$profiles"

echo ""
echo "Integration tests complete for all profiles."
