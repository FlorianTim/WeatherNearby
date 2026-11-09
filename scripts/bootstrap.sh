#!/usr/bin/env bash
# Bootstrap a freshly cloned checkout: generate the mobile platform folders and
# resolve the backend dependencies.
#
# Usage: ./scripts/bootstrap.sh   (runs from anywhere)
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

bash "$REPO_ROOT/scripts/bootstrap_mobile.sh"

if [ -d services/api ] && have dart; then
  (cd services/api && dart pub get)
fi

ok "Bootstrap finished."
