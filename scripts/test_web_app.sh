#!/usr/bin/env bash
# Start Flutter web app local development server and run integration tests.
#
# Usage:
#   ./scripts/test_web_app.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
require_dart_sdk
cd "$(app_dir)"

echo "🌐 Starting Flutter web app on http://localhost:8080"
echo "📝 Open your browser to manually test and take screenshots"
echo "   Press Ctrl+C to stop the server"
echo ""

# Start web server on port 8080
flutter run -d web-server --web-port=8080
