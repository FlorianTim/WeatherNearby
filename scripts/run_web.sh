#!/usr/bin/env bash
# Run the Flutter web app locally (requires Flutter SDK on PATH).
#
# Usage:
#   ./scripts/run_web.sh chrome    # hot-reload dev build in Chrome
#   ./scripts/run_web.sh firefox   # dev server on :8080, open in Firefox
#   ./scripts/run_web.sh headless  # dev server on :8080, no browser window
#                                  # useful for headless Chromium / automated tests
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
require_dart_sdk
cd "$(app_dir)"

PORT=8080

open_browser() {
  local url="$1"
  local browser="$2"
  # Try the requested binary, then fall back to xdg-open / open
  if command -v "$browser" >/dev/null 2>&1; then
    "$browser" "$url" &
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" &
  elif command -v open >/dev/null 2>&1; then
    open "$url" &
  else
    echo "Could not open browser automatically. Visit $url manually."
  fi
}

case "${1:-}" in
  chrome)
    echo "▶  Starting app in Chrome (hot reload enabled)..."
    flutter run -d chrome
    ;;

  firefox)
    echo "▶  Starting Flutter dev server on http://localhost:$PORT ..."
    flutter run -d web-server --web-port="$PORT" &
    SERVER_PID=$!

    # Give the dev server a moment to compile and bind
    sleep 4

    echo "▶  Opening Firefox at http://localhost:$PORT"
    open_browser "http://localhost:$PORT" "firefox"

    # Keep running until the flutter server exits (Ctrl-C)
    wait "$SERVER_PID"
    ;;

  headless)
    echo "▶  Starting Flutter web-server on http://localhost:$PORT (no browser window)."
    echo "   Example headless test with Chromium:"
    echo "     chromium --headless --screenshot http://localhost:$PORT"
    echo "   Press Ctrl-C to stop."
    flutter run -d web-server --web-port="$PORT"
    ;;

  *)
    echo "Usage: $0 {chrome|firefox|headless}" >&2
    exit 1
    ;;
esac
