#!/usr/bin/env bash
# Convenience wrapper — generates both Android and iOS platforms.
# Edit project.env in the repo root to change ORG / PROJECT_NAME.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPT_DIR/bootstrap_android.sh"
"$SCRIPT_DIR/bootstrap_ios.sh"

echo "Done. Android and iOS folders are ready."
