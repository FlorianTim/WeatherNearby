#!/usr/bin/env bash
# Run the Flutter app on Android (requires the Flutter SDK on PATH).
#
# Usage:
#   ./scripts/run_android.sh device [serial]   # hot reload on a connected device
#   ./scripts/run_android.sh emulator [avd]    # boot an AVD, then run
#
# Device and emulator plumbing lives in scripts/dev/adb.sh and
# scripts/dev/emulator.sh - this script is the two-step convenience path.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

require_cmd flutter "Install the Flutter SDK and put it on PATH."
require_dart_sdk
ADB="$(adb_bin)" || die "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT."

# Interactive device picker over `adb devices`; echoes the chosen serial.
# adb is the source of truth here - `flutter devices` needs JSON parsing and
# reports emulators as ready before their package manager is up.
pick_device() {
  local -a serials=() labels=()
  local serial model
  while read -r serial; do
    [ -n "$serial" ] || continue
    model="$("$ADB" -s "$serial" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
    serials+=("$serial")
    labels+=("$model ($serial)")
  done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')

  case "${#serials[@]}" in
    0) return 1 ;;
    1) info "Using ${labels[0]}" >&2; printf '%s' "${serials[0]}" ;;
    *)
      echo "Multiple devices found. Select one:" >&2
      local i=1
      for label in "${labels[@]}"; do
        echo "  [$i] $label" >&2
        ((i++))
      done
      local choice
      read -rp "Enter number: " choice
      [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "${#serials[@]}" ] \
        || die "invalid selection: $choice"
      printf '%s' "${serials[$((choice - 1))]}"
      ;;
  esac
}

case "${1:-}" in
  device)
    if [ -n "${2:-}" ]; then
      DEVICE_ID="$2"
    else
      step "Scanning for connected Android devices"
      info "(USB debugging must be enabled and the computer authorised.)"
      DEVICE_ID="$(pick_device)" || die "no Android device found. Connect one, or use: $0 emulator"
    fi
    ;;

  emulator)
    # emulator.sh boots the AVD and waits until the package manager answers,
    # which is what makes the first install succeed instead of racing the boot.
    bash "$REPO_ROOT/scripts/dev/emulator.sh" start ${2:+"$2"}
    DEVICE_ID="$(adb_device)"
    ;;

  *)
    echo "Usage: $0 {device|emulator} [name]" >&2
    exit 1
    ;;
esac

step "Starting the app on $DEVICE_ID (hot reload enabled)"
android_build_workarounds
cd "$(app_dir)"
flutter run -d "$DEVICE_ID"
