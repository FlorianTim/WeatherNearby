#!/usr/bin/env bash
# Produce app screenshots - either by hand from a running device/emulator, or
# automatically from the screenshot integration test.
#
# The full walkthrough (store sizes, which route to pick, how to add a new
# screenshot step) is in docs/operations/screenshots.md.
#
# Usage:
#   scripts/dev/screenshots.sh <command> [args]
#
# Commands:
#   capture <name>      grab the current screen from the attached device into
#                       design/screenshots/<profile>/<name>.png
#     --profile <p>     subfolder, default: the device model (e.g. pixel_7)
#     --delay <sec>     wait before grabbing - time to open the right screen
#   auto                run the screenshot integration test (all profiles from
#                       docs/public-site/screenshot-profiles.json) and
#                       collect the results into design/screenshots/
#   list                show what has been captured so far
#   clean               delete every screenshot under design/screenshots/
#
# Options:
#   --yes               skip the confirmation prompt of 'clean'
#
# Examples:
#   scripts/dev/screenshots.sh capture 01-greeting --delay 3
#   scripts/dev/screenshots.sh auto
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; }

SHOT_DIR="$REPO_ROOT/design/screenshots"
TEST_RESULTS="$(app_dir)/test_results/screenshots"
PROFILE=""
DELAY=0

[ $# -gt 0 ] || { usage; exit 1; }
case "${1:-}" in -h|--help) usage; exit 0 ;; esac
CMD="$1"; shift

declare -a POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:?--profile needs a name}"; shift ;;
    --delay)   DELAY="${2:?--delay needs seconds}"; shift ;;
    --yes|-y)  ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *)         POSITIONAL+=("$1") ;;
  esac
  shift
done
set -- ${POSITIONAL[@]+"${POSITIONAL[@]}"}

case "$CMD" in
  capture)
    name="${1:?usage: screenshots.sh capture <name>}"
    ADB="$(adb_bin)" || die "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT."
    DEVICE="$(adb_device)"

    if [ -z "$PROFILE" ]; then
      # Device model as a slug, so shots from different form factors stay apart.
      PROFILE="$("$ADB" -s "$DEVICE" shell getprop ro.product.model 2>/dev/null \
        | tr -d '\r' | tr '[:upper:] ' '[:lower:]_' | tr -cd 'a-z0-9_-')"
      PROFILE="${PROFILE:-device}"
    fi

    if [ "$DELAY" -gt 0 ] 2>/dev/null; then
      step "Capturing in ${DELAY}s - bring the right screen up now"
      sleep "$DELAY"
    fi

    out="$SHOT_DIR/$PROFILE/$name.png"
    mkdir -p "$(dirname "$out")"
    "$ADB" -s "$DEVICE" exec-out screencap -p > "$out"
    size="$("$ADB" -s "$DEVICE" shell wm size 2>/dev/null | tr -d '\r' | awk -F': ' '/Physical/ {print $2}')"
    ok "${out#"$REPO_ROOT"/} ($size)"
    ;;

  auto)
    step "Running the screenshot integration test"
    info "This drives the app through integration_test/app_screenshots_test.dart"
    info "for every profile in docs/public-site/screenshot-profiles.json."
    # run_web_tests.sh needs Xvfb + chromedriver, which is what the compose
    # service provides - running it on a bare host is not a useful fallback.
    have docker || die "docker not found. Install Docker Desktop, or capture by hand: scripts/dev/screenshots.sh capture <name>"
    bash "$REPO_ROOT/scripts/build.sh" integration-web

    [ -d "$TEST_RESULTS" ] || die "no screenshots produced in ${TEST_RESULTS#"$REPO_ROOT"/}"
    step "Collecting into ${SHOT_DIR#"$REPO_ROOT"/}"
    mkdir -p "$SHOT_DIR"
    cp -R "$TEST_RESULTS/." "$SHOT_DIR/"
    ok "collected $(find "$SHOT_DIR" -name '*.png' | wc -l | tr -d ' ') screenshot(s)"
    ;;

  list)
    step "design/screenshots"
    if ! find "$SHOT_DIR" -name '*.png' -print 2>/dev/null | grep -q .; then
      info "none yet - see docs/operations/screenshots.md"
      exit 0
    fi
    find "$SHOT_DIR" -name '*.png' -print0 \
      | sort -z \
      | while IFS= read -r -d '' f; do
          printf '  %s\n' "${f#"$SHOT_DIR"/}"
        done
    ;;

  clean)
    confirm "Delete every screenshot under design/screenshots/?" || die "aborted."
    # .gitkeep is what keeps the directory in git - never sweep it away.
    find "${SHOT_DIR:?}" -mindepth 1 -not -name '.gitkeep' -delete 2>/dev/null || true
    ok "screenshots removed"
    ;;

  *)
    usage
    die "unknown command: $CMD"
    ;;
esac
