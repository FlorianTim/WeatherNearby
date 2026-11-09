#!/usr/bin/env bash
# Remove Docker resources created by the local generation services.
# Usage:
#   ./scripts/docker-cleanup.sh          # stop containers, remove volumes
#   ./scripts/docker-cleanup.sh --prune  # also remove pulled images
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

echo "Stopping containers and removing volumes..."
docker compose down --remove-orphans -v

if [ "${1:-}" = "--prune" ]; then
  echo "Removing generation images..."
  images=(
    "python:3.12-slim"
    "pandoc/extra:latest"
    "rlespinasse/drawio-export:latest"
    "plantuml/plantuml:latest"
    "minlag/mermaid-cli:latest"
    "ghcr.io/cirruslabs/flutter:stable"
  )
  for img in "${images[@]}"; do
    if docker image inspect "$img" >/dev/null 2>&1; then
      docker rmi "$img"
      echo "  Removed $img"
    fi
  done
fi

echo "Docker cleanup complete."
