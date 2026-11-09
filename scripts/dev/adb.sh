#!/usr/bin/env bash
# Talk to a connected Android device or emulator without remembering adb
# syntax. The application id comes from project.env, the device is picked
# automatically when only one is attached.
#
# Usage:
#   scripts/dev/adb.sh <command> [args] [--device <serial>]
#
# Commands:
#   devices                 list attached devices with model and API level
#   install [--release]     build the APK and install it on the device
#   run [--release]         flutter run on the resolved device (hot reload)
#   logcat [--all|<tag>]    app-only logcat (default: this app's Flutter output)
#   screenshot [file]       save a PNG (default: design/screenshots/<ts>.png)
#   record [file]           screen recording, stop with Ctrl-C
#   deeplink <uri>          open a deep link / custom scheme in the app
#   permissions             show the app's runtime permission state
#   grant <perm>            grant a runtime permission (e.g. POST_NOTIFICATIONS)
#   revoke <perm>           revoke a runtime permission - the fastest way to
#                           re-test the permission rationale flow
#   clear                   wipe app data (fresh-install state, keeps the APK)
#   uninstall               remove the app
#   info                    application id, installed version, data dir
#   shell [args...]         raw adb shell passthrough on the resolved device
#
# Examples:
#   scripts/dev/adb.sh install --release
#   scripts/dev/adb.sh logcat
#   scripts/dev/adb.sh revoke POST_NOTIFICATIONS && scripts/dev/adb.sh clear
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

usage() { sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'; }

[ $# -gt 0 ] || { usage; exit 1; }
case "${1:-}" in -h|--help) usage; exit 0 ;; esac
CMD="$1"; shift

# --device <serial> may appear anywhere; strip it out before command parsing.
declare -a ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --device|-s) ANDROID_SERIAL="${2:?--device needs a serial}"; export ANDROID_SERIAL; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           ARGS+=("$1") ;;
  esac
  shift
done
set -- ${ARGS[@]+"${ARGS[@]}"}

ADB="$(adb_bin)" || die "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT."

# adb on the resolved device.
d() { "$ADB" -s "$DEVICE" "$@"; }

# Reject a typo before touching adb - otherwise an unknown command surfaces as
# "no device attached", which sends the reader hunting in the wrong place.
case "$CMD" in
  devices|install|run|logcat|screenshot|record|deeplink|permissions|grant|revoke|clear|uninstall|info|shell) ;;
  *) usage; die "unknown command: $CMD" ;;
esac

# Everything except `devices` needs a concrete target.
if [ "$CMD" != "devices" ]; then
  DEVICE="$(adb_device)"
  APP_ID="$(application_id)"
fi

case "$CMD" in
  devices)
    step "Attached devices"
    found=0
    while read -r serial; do
      [ -n "$serial" ] || continue
      model="$("$ADB" -s "$serial" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
      api="$("$ADB" -s "$serial" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')"
      rel="$("$ADB" -s "$serial" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
      printf '  %-24s %s (Android %s, API %s)\n' "$serial" "$model" "$rel" "$api"
      found=1
    done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
    [ "$found" = "1" ] || info "none - start one with scripts/dev/emulator.sh start"
    ;;

  install)
    require_dart_sdk
    mode="debug"; [ "${1:-}" = "--release" ] && mode="release"
    step "Building $mode APK"
    (cd "$(app_dir)" && flutter build apk "--$mode")
    apk="$(app_dir)/build/app/outputs/flutter-apk/app-$mode.apk"
    [ -f "$apk" ] || die "APK not found at $apk"
    step "Installing on $DEVICE"
    d install -r "$apk"
    ok "$APP_ID installed"
    ;;

  run)
    require_dart_sdk
    extra=(); [ "${1:-}" = "--release" ] && extra=(--release)
    step "flutter run on $DEVICE"
    (cd "$(app_dir)" && flutter run -d "$DEVICE" ${extra[@]+"${extra[@]}"})
    ;;

  logcat)
    d logcat -c || true
    case "${1:-}" in
      --all) step "logcat (everything)"; d logcat ;;
      "")
        step "logcat for $APP_ID (flutter + app tags, Ctrl-C to stop)"
        # Flutter writes to the "flutter" tag; app crashes land in
        # AndroidRuntime; everything else is silenced.
        d logcat flutter:V FlutterJNI:V AndroidRuntime:E "$APP_ID":V '*:S'
        ;;
      *) step "logcat tag: $1"; d logcat "$1:V" '*:S' ;;
    esac
    ;;

  screenshot)
    out="${1:-$REPO_ROOT/design/screenshots/$(date +%Y%m%d-%H%M%S).png}"
    mkdir -p "$(dirname "$out")"
    d exec-out screencap -p > "$out"
    ok "saved ${out#"$REPO_ROOT"/}"
    ;;

  record)
    out="${1:-$REPO_ROOT/design/screenshots/$(date +%Y%m%d-%H%M%S).mp4}"
    mkdir -p "$(dirname "$out")"
    remote="/sdcard/_rec_$$.mp4"
    step "Recording - press Ctrl-C to stop"
    # screenrecord stops on SIGINT and flushes the file on the device. The trap
    # keeps THIS script alive through that Ctrl-C so the pull below still runs.
    trap 'true' INT
    d shell screenrecord "$remote" || true
    trap - INT
    sleep 1
    d pull "$remote" "$out" >/dev/null
    d shell rm -f "$remote"
    ok "saved ${out#"$REPO_ROOT"/}"
    ;;

  deeplink)
    uri="${1:?usage: adb.sh deeplink <uri>}"
    step "Opening $uri in $APP_ID"
    d shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE \
      -d "$uri" "$APP_ID"
    ;;

  permissions)
    step "Runtime permissions of $APP_ID"
    d shell dumpsys package "$APP_ID" \
      | awk '/runtime permissions:/{f=1;next} f&&/^[[:space:]]*android\.permission/{print "  "$0} f&&/^[[:space:]]*$/{exit}' \
      | tr -d '\r'
    ;;

  grant|revoke)
    perm="${1:?usage: adb.sh $CMD <PERMISSION>}"
    [[ "$perm" == android.permission.* ]] || perm="android.permission.$perm"
    d shell pm "$CMD" "$APP_ID" "$perm"
    ok "$CMD $perm"
    ;;

  clear)
    d shell pm clear "$APP_ID"
    ok "app data of $APP_ID wiped"
    ;;

  uninstall)
    d uninstall "$APP_ID"
    ok "$APP_ID removed"
    ;;

  info)
    step "$APP_ID on $DEVICE"
    version="$(d shell dumpsys package "$APP_ID" | grep -m1 versionName | tr -d '\r' | sed 's/^[[:space:]]*//')"
    if [ -z "$version" ]; then
      info "not installed - run: scripts/dev/adb.sh install"
    else
      info "$version"
      info "data dir: /data/data/$APP_ID"
    fi
    ;;

  shell)
    d shell "$@"
    ;;

esac
