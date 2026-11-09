#!/usr/bin/env bash
# Install git hooks for this repository.
# Usage:  ./scripts/install-hooks.sh
#
#   pre-commit -> scripts/pre-commit.sh  (fast, format-only, path-aware)
#   pre-push   -> scripts/pre-push.sh    (full analyze + test, parallel)
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

install_hook() {
  local name="$1" target="$2"
  local hook=".git/hooks/$name"
  cat > "$hook" << EOF
#!/usr/bin/env bash
# Installed by scripts/install-hooks.sh
exec ./scripts/$target "\$@"
EOF
  chmod +x "$hook"
  echo "✓ Git $name hook installed."
}

install_hook pre-commit pre-commit.sh
install_hook pre-push pre-push.sh
