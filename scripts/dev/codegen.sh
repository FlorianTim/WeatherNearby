#!/usr/bin/env bash
# Run ALL code generation (build_runner + gen-l10n) via melos. Thin wrapper
# around `melos run codegen` so agents have one obvious command and never
# forget the l10n step.
#
# Usage: scripts/dev/codegen.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

if command -v melos >/dev/null 2>&1; then
  melos run codegen
else
  dart run melos run codegen
fi
