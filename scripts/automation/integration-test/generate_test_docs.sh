#!/usr/bin/env bash
# Generate test documentation from integration test screenshots.
#
# Expects screenshots in subdirectories defined by the screen profiles:
#   apps/mobile_app/test_results/screenshots/<profile>/
#
# Profile config: docs/public-site/screenshot-profiles.json
#
# Usage:
#   ./scripts/automation/integration-test/generate_test_docs.sh
#
# Output:
#   docs/testing/integration-test-report.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# Screen profiles are a shared LumbreCode contract, not a local choice:
# the same file drives the web template's Playwright capture.
PROFILES_FILE="$REPO_ROOT/docs/public-site/screenshot-profiles.json"
SCREENSHOT_BASE="$REPO_ROOT/apps/mobile_app/test_results/screenshots"
OUTPUT_DIR="$REPO_ROOT/docs/testing"
OUTPUT_FILE="$OUTPUT_DIR/integration-test-report.md"
VERSION=$(cat "$REPO_ROOT/VERSION")

cd "$REPO_ROOT"

mkdir -p "$OUTPUT_DIR"

# Read profiles and verify at least one has screenshots
profiles=$(python3 -c "
import json
for p in json.load(open('$PROFILES_FILE'))['profiles']:
    print(p['name'] + '|' + p['label'])
")

any_found=false
while IFS='|' read -r profile _label; do
  dir="$SCREENSHOT_BASE/$profile"
  if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
    any_found=true; break
  fi
done <<< "$profiles"

if [ "$any_found" = false ]; then
  echo "No screenshots found in $SCREENSHOT_BASE/*/"
  echo "Run integration tests first: ./scripts/build.sh integration-web"
  exit 1
fi

# ── helper: append screenshots for one profile ─────────────────────────────
append_profile_section() {
  local dir="$1"
  local subdir="$2"   # tablet  |  phone-portrait

  if [ ! -d "$dir" ] || [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    echo "*(No screenshots found for this profile.)*" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    return
  fi

  for screenshot in "$dir"/*.png; do
    [ -f "$screenshot" ] || continue
    filename=$(basename "$screenshot")
    name="${filename%.*}"
    rel_path="../../apps/mobile_app/test_results/screenshots/$subdir/$filename"

    # Read optional sidecar metadata (title, description)
    json_file="${dir}/${name}.json"
    heading=""
    meta_description=""
    if [ -f "$json_file" ]; then
      heading=$(python3 -c \
        "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('title',''))" \
        "$json_file" 2>/dev/null || true)
      meta_description=$(python3 -c \
        "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('description',''))" \
        "$json_file" 2>/dev/null || true)
    fi
    # Fall back to filename-derived heading
    [ -z "$heading" ] && heading=$(echo "$name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

    echo "#### $heading" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    [ -n "$meta_description" ] && echo "$meta_description" >> "$OUTPUT_FILE" && echo "" >> "$OUTPUT_FILE"
    echo "![${heading}]($rel_path)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
  done
}

# ── write report ────────────────────────────────────────────────────────────
{
  echo "# Integration Test Report"
  echo ""
  echo "**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo ""
  echo "**Version:** $VERSION"
  echo ""
  echo "## Counter App Tests"
  echo ""
  echo "This report contains screenshots captured during automated integration"
  echo "tests of the Flutter counter application."
  echo ""
} > "$OUTPUT_FILE"

# ── Profile sections ────────────────────────────────────────────────────────
while IFS='|' read -r profile label; do
  {
    echo "## $label Screenshots"
    echo ""
    echo "### Test Screenshots"
    echo ""
  } >> "$OUTPUT_FILE"
  append_profile_section "$SCREENSHOT_BASE/$profile" "$profile"
done <<< "$profiles"

# ── Summary and instructions ─────────────────────────────────────────────────
cat >> "$OUTPUT_FILE" << 'ENDDOC'
## Test Summary

The integration tests verify:
- [x] Initial application state
- [x] Counter increment functionality
- [x] UI element presence and layout
- [x] Button tooltip functionality
- [x] State persistence across interactions

## Running Tests

To regenerate this report:

```bash
# Run integration tests (all profiles)
./scripts/build.sh integration-web

# Generate documentation
./scripts/automation/integration-test/generate_test_docs.sh

# Generate versioned PDF
./scripts/automation/integration-test/generate_test_report_pdf.sh
```
ENDDOC

echo "Integration test report generated: $OUTPUT_FILE"
while IFS='|' read -r profile _label; do
  count=$(find "$SCREENSHOT_BASE/$profile" -name "*.png" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  echo "  $profile: $count screenshots"
done <<< "$profiles"

