#!/usr/bin/env bash
# Generate one versioned PDF per screen profile from the integration test screenshots.
#
# Requires: docker
# Usage:
#   ./scripts/automation/integration-test/generate_test_report_pdf.sh
#
# Output (one file per profile with screenshots):
#   docs/testing/generated/integration-test-report-tablet-v<VERSION>.pdf
#   docs/testing/generated/integration-test-report-phone-portrait-v<VERSION>.pdf
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# Screen profiles are a shared LumbreCode contract, not a local choice:
# the same file drives the web template's Playwright capture.
PROFILES_FILE="$REPO_ROOT/docs/public-site/screenshot-profiles.json"
VERSION=$(cat "$REPO_ROOT/VERSION")
SCREENSHOT_BASE="apps/mobile_app/test_results/screenshots"
OUTPUT_DIR="docs/testing/generated"
TODAY=$(date -u +"%Y-%m-%d")

mkdir -p "$REPO_ROOT/$OUTPUT_DIR"

profiles=$(python3 -c "
import json
for p in json.load(open('$PROFILES_FILE'))['profiles']:
    print(p['name'] + '|' + p['label'])
")

while IFS='|' read -r profile LABEL; do
  SCREENSHOT_DIR="$REPO_ROOT/$SCREENSHOT_BASE/$profile"

  if [ ! -d "$SCREENSHOT_DIR" ] || [ -z "$(ls -A "$SCREENSHOT_DIR" 2>/dev/null)" ]; then
    echo "No screenshots for '$profile', skipping."
    continue
  fi

  # LABEL already set from profiles read above
  TEMP_MD="$REPO_ROOT/$OUTPUT_DIR/report-${profile}.tmp.md"
  OUTPUT_FILE="$OUTPUT_DIR/integration-test-report-${profile}-v${VERSION}.pdf"

  # Build a minimal per-profile markdown (image paths are relative to repo root)
  {
    echo "---"
    echo "header-includes:"
    echo "  - '\\usepackage{float}'"
    echo "  - '\\floatplacement{figure}{H}'"
    echo "---"
    echo ""
    echo "# Integration Test Report"
    echo ""
    echo "**Profil:** $LABEL  "
    echo "**Version:** $VERSION  "
    echo "**Generated:** $TODAY"
    echo ""
    echo "## Screenshots"
    echo ""
    for screenshot in "$SCREENSHOT_DIR"/*.png; do
      [ -f "$screenshot" ] || continue
      filename=$(basename "$screenshot")
      name="${filename%.*}"

      # Read optional sidecar metadata (title, description, useCase)
      json_file="${SCREENSHOT_DIR}/${name}.json"
      heading=""
      meta_description=""
      use_case=""
      if [ -f "$json_file" ]; then
        heading=$(python3 -c \
          "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('title',''))" \
          "$json_file" 2>/dev/null || true)
        meta_description=$(python3 -c \
          "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('description',''))" \
          "$json_file" 2>/dev/null || true)
        use_case=$(python3 -c \
          "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('useCase',''))" \
          "$json_file" 2>/dev/null || true)
      fi
      # Fall back to filename-derived heading
      [ -z "$heading" ] && heading=$(echo "$name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

      echo "### $heading"
      echo ""
      [ -n "$meta_description" ] && echo "$meta_description" && echo ""
      [ -n "$use_case" ] && echo "_Use Case: ${use_case}_" && echo ""
      echo "![$heading]($SCREENSHOT_BASE/$profile/$filename)"
      echo ""
    done
  } > "$TEMP_MD"

  echo "Building PDF: $OUTPUT_FILE  ($LABEL, v$VERSION)..."

  docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace \
    pandoc/extra:latest \
      -f markdown \
      --resource-path="." \
      -V geometry:margin=2.5cm \
      -V float-placement-figure=H \
      -V "title=Integration Test Report" \
      -V "subtitle=$LABEL – v${VERSION}" \
      -V "date=$TODAY" \
      -o "$OUTPUT_FILE" \
      "$OUTPUT_DIR/report-${profile}.tmp.md"

  rm -f "$TEMP_MD"
  echo "PDF generated: $OUTPUT_FILE"
done <<< "$profiles"

