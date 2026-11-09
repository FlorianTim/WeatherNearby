#!/usr/bin/env bash
# Run integration tests for both orientations and generate the versioned PDF report.
#
# Executes all three steps in sequence:
#   1. Integration tests – tablet (1280×1024) + phone portrait (390×844)
#   2. Generate Markdown report  →  docs/testing/integration-test-report.md
#   3. Generate versioned PDF    →  docs/testing/generated/integration-test-report-v<VERSION>.pdf
#
# Requires Docker.
#
# Usage:
#   ./scripts/automation/integration-test/integration_test_report.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

echo ""
echo "=== Step 1/3: Integration tests (tablet + phone portrait) ==="
docker compose run --rm mobile-integration-test-web

echo ""
echo "=== Step 2/3: Generate Markdown report ==="
bash "$SCRIPT_DIR/generate_test_docs.sh"

echo ""
echo "=== Step 3/3: Generate versioned PDF ==="
bash "$SCRIPT_DIR/generate_test_report_pdf.sh"

VERSION=$(cat "$REPO_ROOT/VERSION")
echo ""
echo "Done. PDF: docs/testing/generated/integration-test-report-v${VERSION}.pdf"
