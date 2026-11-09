#!/usr/bin/env bash
# Bootstrap script for Linux platform
# Generates the linux/ directory with custom bundle ID.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/project.env"

# shellcheck source=lib/read_env.sh
source "$SCRIPT_DIR/lib/read_env.sh"
# shellcheck source=lib/bootstrap_platforms.sh
source "$SCRIPT_DIR/lib/bootstrap_platforms.sh"

if ! read_project_env "$ENV_FILE"; then
  echo "Error: Could not read ORG or PROJECT_NAME from $ENV_FILE" >&2
  exit 1
fi

bootstrap_platforms "$REPO_ROOT" "linux"

echo "Linux platform generated successfully!"
