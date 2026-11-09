#!/usr/bin/env bash
# Build arc42 architecture documentation as PDF
# Requires: docker (uses pandoc/extra:latest)
# Usage: ./scripts/automation/docs/build_docs_pdf.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ARC42_DIR="$REPO_ROOT/docs/architecture/arc42"
ADR_DIR="$REPO_ROOT/docs/architecture/adr"
PANDOC_DIR="$REPO_ROOT/docs/architecture/pandoc"
OUTPUT_DIR="$REPO_ROOT/docs/architecture/generated"
OUTPUT_FILE="$OUTPUT_DIR/architecture.pdf"

mkdir -p "$OUTPUT_DIR"

# Collect arc42 chapters in order
ARC42_FILES=(
  "$ARC42_DIR/01-introduction-and-goals.md"
  "$ARC42_DIR/02-constraints.md"
  "$ARC42_DIR/03-context-and-scope.md"
  "$ARC42_DIR/04-solution-strategy.md"
  "$ARC42_DIR/05-building-block-view.md"
  "$ARC42_DIR/06-runtime-view.md"
  "$ARC42_DIR/07-deployment-view.md"
  "$ARC42_DIR/08-crosscutting-concepts.md"
  "$ARC42_DIR/09-architecture-decisions.md"
  "$ARC42_DIR/10-quality-requirements.md"
  "$ARC42_DIR/11-risks-and-technical-debt.md"
  "$ARC42_DIR/12-glossary.md"
)

# Collect ADR files in numeric order
ADR_FILES=()
if [ -d "$ADR_DIR" ]; then
  while IFS= read -r f; do
    ADR_FILES+=("$f")
  done < <(find "$ADR_DIR" -name '*.md' -not -name 'README.md' | sort)
fi

# Collect appendix files
APPENDIX_FILES=(
  "$ARC42_DIR/90-sources.md"
  "$ARC42_DIR/91-appendix.md"
  "$ARC42_DIR/92-document-history.md"
)

# Build full input list: arc42 chapters + ADRs + appendices
INPUT_FILES=()
for f in "${ARC42_FILES[@]}"; do
  [ -f "$f" ] && INPUT_FILES+=("/workspace/docs/architecture/arc42/$(basename "$f")")
done

# Add ADR separator page
if [ ${#ADR_FILES[@]} -gt 0 ]; then
  ADR_HEADER=$(mktemp /tmp/adr-header-XXXXXX.md)
  echo -e "\\\\newpage\n\n# Anhang: Architecture Decision Records\n" > "$ADR_HEADER"
  # We'll mount this via Docker
  DOCKER_ADR_HEADER="/tmp/adr-header.md"
fi

for f in "${ADR_FILES[@]}"; do
  INPUT_FILES+=("/workspace/docs/architecture/adr/$(basename "$f")")
done

for f in "${APPENDIX_FILES[@]}"; do
  [ -f "$f" ] && INPUT_FILES+=("/workspace/docs/architecture/arc42/$(basename "$f")")
done

echo "Building PDF from ${#INPUT_FILES[@]} input files..."

# Build using Docker
DOCKER_CMD=(
  docker run --rm
  -v "$REPO_ROOT:/workspace"
  -w /workspace
)

# Add ADR header if we have ADRs
if [ ${#ADR_FILES[@]} -gt 0 ]; then
  DOCKER_CMD+=(-v "$ADR_HEADER:$DOCKER_ADR_HEADER:ro")
fi

DOCKER_CMD+=(
  pandoc/extra:latest
  --defaults=/workspace/docs/architecture/pandoc/defaults.yaml
  --resource-path=/workspace/docs/architecture
  -o /workspace/docs/architecture/generated/architecture.pdf
)

# Insert ADR header before ADR files
FINAL_INPUTS=()
ADR_SECTION_STARTED=false
for f in "${INPUT_FILES[@]}"; do
  if [[ "$f" == */adr/* ]] && [ "$ADR_SECTION_STARTED" = false ]; then
    ADR_SECTION_STARTED=true
    if [ ${#ADR_FILES[@]} -gt 0 ]; then
      FINAL_INPUTS+=("$DOCKER_ADR_HEADER")
    fi
  fi
  FINAL_INPUTS+=("$f")
done

DOCKER_CMD+=("${FINAL_INPUTS[@]}")

"${DOCKER_CMD[@]}"

# Cleanup temp files
[ -f "${ADR_HEADER:-}" ] && rm -f "$ADR_HEADER"

echo "PDF generated: $OUTPUT_FILE"
