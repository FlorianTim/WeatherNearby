#!/usr/bin/env bash
# Run the Flutter test suite (or a subset) and print a COMPACT result:
# one line on green, otherwise only the failing test names plus the first
# exception — instead of the full flutter-test log. Token-saving wrapper
# for agents.
#
# Usage:
#   scripts/dev/test_summary.sh [flutter-test-args...]
#   scripts/dev/test_summary.sh test/features/todos
set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
cd "$(app_dir)"

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

flutter test "$@" >"$log" 2>&1
code=$?

if [ $code -eq 0 ]; then
  grep -E "All tests passed" "$log" | tail -1
  exit 0
fi

echo "== TESTS FAILED (exit $code) =="
echo "-- failing tests --"
awk '/^Failing tests:/{f=1;next} f&&NF{print "  "$0} f&&!NF{exit}' "$log"
echo "-- first failure detail --"
awk '/EXCEPTION CAUGHT|TestFailure|Expected:|Actual:|Which:/{s=1} s{print;c++} c>40{exit}' "$log" | head -50
exit $code
