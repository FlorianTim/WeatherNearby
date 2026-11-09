#!/usr/bin/env bash
# Run documentation generation tasks locally via Docker.
# Usage:
#   ./scripts/generate.sh              # run all tasks
#   ./scripts/generate.sh glossary     # glossary only
#   ./scripts/generate.sh pdf          # PDF only
#   ./scripts/generate.sh diagrams     # all diagram renderers
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

run_glossary()  { docker compose run --rm glossary; }
run_pdf()       { docker compose run --rm pdf; }
run_diagrams()  {
  docker compose run --rm diagrams-drawio
  docker compose run --rm diagrams-plantuml
  sh scripts/automation/docs/render_mermaid_inner.sh
}

case "${1:-all}" in
  glossary)  run_glossary ;;
  pdf)       run_pdf ;;
  diagrams)  run_diagrams ;;
  all)
    run_glossary
    run_pdf
    run_diagrams
    echo ""
    echo "✓ All generation tasks finished."
    ;;
  *)
    echo "Usage: $0 {glossary|pdf|diagrams|all}" >&2
    exit 1
    ;;
esac
