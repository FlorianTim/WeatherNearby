#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/project.env"

# shellcheck source=lib/read_env.sh
source "$SCRIPT_DIR/lib/read_env.sh"
# shellcheck source=lib/bootstrap_platforms.sh
source "$SCRIPT_DIR/lib/bootstrap_platforms.sh"

if ! read_project_env "$ENV_FILE"; then
  exit 1
fi

bootstrap_platforms "$REPO_ROOT" "web"

echo "Done. web/ folder is ready."
