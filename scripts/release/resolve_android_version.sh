#!/usr/bin/env bash
# Resolve Android versionName + monotonic versionCode from a git ref.
#
# Accepted refs:
#   release/<maj.min>/<semver>   e.g. release/1.3/1.3.0-rc.1
#   v<semver> / refs/tags/v<semver>
#   <semver>                     e.g. 1.3.0-beta.2
#
# versionCode = major*10000000 + minor*100000 + patch*1000 + pre
#   pre: beta.N -> N (1..499), rc.N -> 500+N (N 1..498), final -> 999
#   => 1.3.0-beta.1 < 1.3.0-rc.1 < 1.3.0 and the Play limit (2.1e9) is
#      never reached (max 21x.xx.xx -> ~214 major versions).
#
# Output (stdout, and $GITHUB_OUTPUT when set):
#   version_name=<semver>
#   version_code=<int>
#
# Usage: resolve_android_version.sh [<ref>]   (default: current branch)
set -euo pipefail

ref="${1:-$(git rev-parse --abbrev-ref HEAD)}"

case "$ref" in
  refs/tags/v*) semver="${ref#refs/tags/v}" ;;
  refs/heads/*) semver="${ref#refs/heads/}"; semver="${semver##*/}" ;;
  release/*/*)  semver="${ref##*/}" ;;
  v[0-9]*)      semver="${ref#v}" ;;
  *)            semver="$ref" ;;
esac

if [[ ! "$semver" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-(beta|rc)\.([0-9]+))?$ ]]; then
  echo "ERROR: '$ref' does not resolve to a semver (got '$semver')." >&2
  echo "Expected release/<maj.min>/<semver>, v<semver> or <semver>." >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
pre_kind="${BASH_REMATCH[5]:-}"
pre_num="${BASH_REMATCH[6]:-}"

case "$pre_kind" in
  beta)
    if (( pre_num < 1 || pre_num > 499 )); then
      echo "ERROR: beta number must be 1..499 (got $pre_num)." >&2
      exit 1
    fi
    pre=$((pre_num))
    ;;
  rc)
    if (( pre_num < 1 || pre_num > 498 )); then
      echo "ERROR: rc number must be 1..498 (got $pre_num)." >&2
      exit 1
    fi
    pre=$((500 + pre_num))
    ;;
  *)
    pre=999
    ;;
esac

if (( minor > 99 || patch > 99 )); then
  echo "ERROR: minor/patch must be <= 99 for the versionCode scheme." >&2
  exit 1
fi

version_code=$((major * 10000000 + minor * 100000 + patch * 1000 + pre))

echo "version_name=$semver"
echo "version_code=$version_code"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "version_name=$semver"
    echo "version_code=$version_code"
  } >> "$GITHUB_OUTPUT"
fi
