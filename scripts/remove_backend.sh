#!/usr/bin/env bash
# Remove every backend component (backend/, services/api/, CI workflows,
# compose services, workspace tasks) in one operation.
#
# Usage:
#   ./scripts/remove_backend.sh [--dry-run]
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

if ! command -v dart >/dev/null 2>&1; then
  echo "dart is required (comes with the Flutter SDK)." >&2
  exit 1
fi

dart tools/remove_backend.dart "$@"
