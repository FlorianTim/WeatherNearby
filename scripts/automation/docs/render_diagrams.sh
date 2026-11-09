#!/usr/bin/env bash
# Render diagrams from source to SVG
# Supports: draw.io, PlantUML, Mermaid
# Requires: docker
# Usage: ./scripts/automation/docs/render_diagrams.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SRC_DIR="$REPO_ROOT/docs/architecture/diagrams/src"
OUT_DIR="$REPO_ROOT/docs/architecture/generated/diagrams"

mkdir -p "$OUT_DIR"

# --- draw.io ---
DRAWIO_DIR="$SRC_DIR/drawio"
if [ -d "$DRAWIO_DIR" ] && ls "$DRAWIO_DIR"/*.drawio 1>/dev/null 2>&1; then
  echo "Rendering draw.io diagrams..."
  for f in "$DRAWIO_DIR"/*.drawio; do
    name="$(basename "$f" .drawio)"
    docker run --rm \
      -v "$REPO_ROOT:/workspace" \
      rlespinasse/drawio-export:latest \
      --fileext svg \
      --output "/workspace/docs/architecture/generated/diagrams/" \
      "/workspace/docs/architecture/diagrams/src/drawio/$name.drawio"
    echo "  Rendered: $name.svg"
  done
else
  echo "No draw.io files found in $DRAWIO_DIR"
fi

# --- PlantUML ---
PUML_DIR="$SRC_DIR/plantuml"
if [ -d "$PUML_DIR" ] && ls "$PUML_DIR"/*.puml 1>/dev/null 2>&1; then
  echo "Rendering PlantUML diagrams..."
  docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    plantuml/plantuml \
    -tsvg \
    -o /workspace/docs/architecture/generated/diagrams/ \
    "/workspace/docs/architecture/diagrams/src/plantuml/*.puml"
  echo "  PlantUML diagrams rendered."
else
  echo "No PlantUML files found in $PUML_DIR"
fi

# --- Mermaid ---
MERMAID_DIR="$SRC_DIR/mermaid"
if [ -d "$MERMAID_DIR" ] && ls "$MERMAID_DIR"/*.mmd 1>/dev/null 2>&1; then
  echo "Rendering Mermaid diagrams..."
  for f in "$MERMAID_DIR"/*.mmd; do
    name="$(basename "$f" .mmd)"
    docker run --rm \
      -v "$REPO_ROOT:/workspace" \
      minlag/mermaid-cli:latest \
      -i "/workspace/docs/architecture/diagrams/src/mermaid/$name.mmd" \
      -o "/workspace/docs/architecture/generated/diagrams/$name.svg" \
      --backgroundColor transparent
    echo "  Rendered: $name.svg"
  done
else
  echo "No Mermaid files found in $MERMAID_DIR"
fi

echo "All diagrams rendered to: $OUT_DIR"
