#!/usr/bin/env bash
# Pre-push gate: full format + analyze + test across the whole workspace.
#
# analyze and test run CONCURRENTLY (they are independent processes), so the
# test time hides under the longer analyze — the practical "Gradle-style"
# parallelism available here (flutter analyze itself has no -j; flutter test is
# already parallel; melos parallelizes across packages).
#
# Runs once per push (not per commit), so day-to-day commits stay fast.
# Emergency bypass:  git push --no-verify
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> format:check"
if ! melos_cmd run format:check >"$TMP/format.log" 2>&1; then
  cat "$TMP/format.log"
  echo ""
  echo "✗ Formatting check failed. Run 'melos run format:fix'."
  exit 1
fi
echo "✓ format ok"

echo "==> analyze + test (running in parallel)…"
melos_cmd run analyze >"$TMP/analyze.log" 2>&1 &
apid=$!
melos_cmd run test >"$TMP/test.log" 2>&1 &
tpid=$!

wait "$apid"; acode=$?
wait "$tpid"; tcode=$?

rc=0
if [ "$acode" -ne 0 ]; then
  echo ""
  echo "── analyze FAILED ──"
  tail -40 "$TMP/analyze.log"
  rc=1
else
  echo "✓ analyze passed"
fi
if [ "$tcode" -ne 0 ]; then
  echo ""
  echo "── test FAILED ──"
  tail -60 "$TMP/test.log"
  rc=1
else
  echo "✓ tests passed"
fi

if [ "$rc" -ne 0 ]; then
  echo ""
  echo "✗ Pre-push checks failed. Fix them, or bypass once with 'git push --no-verify'."
  exit 1
fi

echo ""
echo "✓ Pre-push checks passed."
