#!/bin/sh
# Helper: render all .mmd files via the mermaid-cli Docker image.
# Runs on the HOST, not inside the container.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../../.."

SRC="docs/architecture/diagrams/src/mermaid"
OUT="docs/architecture/generated/diagrams"
mkdir -p "$OUT"

found=0
for f in "$SRC"/*.mmd; do
  [ -f "$f" ] || continue
  found=1
  name=$(basename "$f" .mmd)
  docker compose run --rm diagrams-mermaid \
    -i "/workspace/$f" \
    -o "/workspace/$OUT/$name.svg" \
    --backgroundColor transparent
done

if [ "$found" = 0 ]; then
  echo "No Mermaid files found."
else
  echo "Mermaid diagrams rendered."
fi
