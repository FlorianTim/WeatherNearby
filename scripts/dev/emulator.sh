#!/usr/bin/env bash
# Create, start and stop Android emulators without opening Android Studio.
#
# Usage:
#   scripts/dev/emulator.sh <command> [args]
#
# Commands:
#   list                       installed AVDs and their state
#   create [name]              create an AVD (default name: template-api<API>)
#     --api <level>            API level, default 35
#     --device <profile>       hardware profile, default pixel_7
#     --devices                list the available hardware profiles and exit
#   start [name]               boot an AVD and wait until it is really usable
#     --wipe                   factory reset before boot (fresh-install state)
#     --cold                   cold boot, ignore the saved snapshot
#     --headless               no emulator window (CI, screenshots)
#   wait                       wait for the attached device to finish booting
#   stop [name|all]            shut the emulator down cleanly
#   delete <name>              remove an AVD and its data
#     --yes                    skip the confirmation prompt
#
# Requires the Android SDK. "create" additionally needs the SDK Command-line
# Tools (Android Studio > SDK Manager > SDK Tools > Android SDK Command-line
# Tools) - the script says so if they are missing.
#
# Examples:
#   scripts/dev/emulator.sh create --api 35 --device pixel_7
#   scripts/dev/emulator.sh start template-api35 --wipe
#   scripts/dev/emulator.sh stop all
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

usage() { sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'; }

API_LEVEL=35
DEVICE_PROFILE="pixel_7"
WIPE=0
COLD=0
HEADLESS=0
LIST_DEVICES=0

[ $# -gt 0 ] || { usage; exit 1; }
case "${1:-}" in -h|--help) usage; exit 0 ;; esac
CMD="$1"; shift

declare -a POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --api)      API_LEVEL="${2:?--api needs a level}"; shift ;;
    --device)   DEVICE_PROFILE="${2:?--device needs a profile}"; shift ;;
    --devices)  LIST_DEVICES=1 ;;
    --wipe)     WIPE=1 ;;
    --cold)     COLD=1 ;;
    --headless) HEADLESS=1 ;;
    --yes|-y)   ASSUME_YES=1 ;;
    -h|--help)  usage; exit 0 ;;
    *)          POSITIONAL+=("$1") ;;
  esac
  shift
done
set -- ${POSITIONAL[@]+"${POSITIONAL[@]}"}

EMULATOR="$(emulator_bin)" || die "emulator binary not found. Install the Android SDK or set ANDROID_SDK_ROOT."
ADB="$(adb_bin)" || die "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT."

require_cmdline_tools() {
  avdmanager_bin >/dev/null 2>&1 || die "avdmanager not found. Install it via Android Studio > SDK Manager > SDK Tools > Android SDK Command-line Tools (latest), then re-run."
}

list_avds() { "$EMULATOR" -list-avds 2>/dev/null | tr -d '\r' | grep -v '^$' || true; }

# Serials of all currently attached emulators.
running_emulators() {
  "$ADB" devices | awk 'NR>1 && $1 ~ /^emulator-/ && $2=="device" {print $1}'
}

# The AVD name behind an emulator serial.
avd_name_of() {
  "$ADB" -s "$1" emu avd name 2>/dev/null | head -1 | tr -d '\r'
}

# Blocks until the device finished booting AND the package manager answers -
# an emulator shows up in `flutter devices` long before installs actually work.
wait_for_boot() {
  local serial="$1" timeout="${2:-180}"
  [ -n "$serial" ] || die "wait_for_boot needs a device serial."
  # Separate statement on purpose: `local` expands every word before it
  # assigns any of them, so $timeout would still be unset here.
  local deadline=$((SECONDS + timeout))
  step "Waiting for $serial to finish booting (up to ${timeout}s)"
  "$ADB" -s "$serial" wait-for-device
  while [ "$SECONDS" -lt "$deadline" ]; do
    local booted pm
    booted="$("$ADB" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | tr -d '[:space:]')"
    if [ "$booted" = "1" ]; then
      pm="$("$ADB" -s "$serial" shell pm path android 2>/dev/null | tr -d '\r')"
      if [ -n "$pm" ]; then
        # Dismiss the lock screen so the app is visible right away.
        "$ADB" -s "$serial" shell input keyevent 82 >/dev/null 2>&1 || true
        ok "$serial is ready"
        return 0
      fi
    fi
    sleep 3
  done
  die "$serial did not become ready within ${timeout}s."
}

case "$CMD" in
  list)
    step "Installed AVDs"
    running="$(running_emulators || true)"
    found=0
    while read -r avd; do
      [ -n "$avd" ] || continue
      state="stopped"
      for serial in $running; do
        [ "$(avd_name_of "$serial")" = "$avd" ] && state="running ($serial)"
      done
      printf '  %-32s %s\n' "$avd" "$state"
      found=1
    done < <(list_avds)
    [ "$found" = "1" ] || info "none - create one with: scripts/dev/emulator.sh create"
    ;;

  create)
    require_cmdline_tools
    AVDMANAGER="$(avdmanager_bin)"
    if [ "$LIST_DEVICES" = "1" ]; then
      "$AVDMANAGER" list device
      exit 0
    fi

    name="${1:-template-api$API_LEVEL}"
    image="system-images;android-$API_LEVEL;google_apis;x86_64"

    if list_avds | grep -qx "$name"; then
      die "AVD '$name' already exists. Delete it first: scripts/dev/emulator.sh delete $name"
    fi

    if SDKMANAGER="$(sdkmanager_bin)"; then
      step "Ensuring system image $image is installed"
      # Licences are accepted interactively on a fresh SDK; piping yes keeps a
      # repeat run from blocking on the already-accepted prompt.
      yes 2>/dev/null | "$SDKMANAGER" --install "$image" || die "could not install $image"
    else
      warn "sdkmanager not found - assuming $image is already installed."
    fi

    step "Creating AVD '$name' ($DEVICE_PROFILE, API $API_LEVEL)"
    echo "no" | "$AVDMANAGER" create avd \
      --name "$name" \
      --package "$image" \
      --device "$DEVICE_PROFILE" \
      --force
    ok "AVD '$name' created - start it with: scripts/dev/emulator.sh start $name"
    ;;

  start)
    name="${1:-}"
    if [ -z "$name" ]; then
      name="$(list_avds | head -1)"
      [ -n "$name" ] || die "no AVD available. Create one: scripts/dev/emulator.sh create"
      info "no name given, using '$name'"
    fi
    list_avds | grep -qx "$name" || die "unknown AVD '$name'. See: scripts/dev/emulator.sh list"

    before=" $(running_emulators | tr '\n' ' ')"

    declare -a flags=()
    [ "$WIPE" = "1" ]     && flags+=(-wipe-data)
    [ "$COLD" = "1" ]     && flags+=(-no-snapshot-load)
    [ "$HEADLESS" = "1" ] && flags+=(-no-window -no-audio -gpu swiftshader_indirect)

    step "Booting '$name' ${flags[*]-}"
    # The emulator outlives this script (like Android Studio's runner), but its
    # output is kept: a failed launch dies within a second and the reason is
    # only in there - "PANIC: Cannot find AVD system path", a missing system
    # image, a busy port.
    emu_log="$(mktemp)"
    "$EMULATOR" -avd "$name" ${flags[@]+"${flags[@]}"} >"$emu_log" 2>&1 &
    emu_pid=$!
    disown || true

    step "Waiting for the emulator to register with adb"
    serial=""
    deadline=$((SECONDS + 120))
    while [ "$SECONDS" -lt "$deadline" ]; do
      for s in $(running_emulators); do
        case "$before" in *" $s "*) continue ;; esac
        serial="$s"
        break
      done
      [ -n "$serial" ] && break
      # Fail fast instead of waiting out the timeout on a launch that is over.
      if ! kill -0 "$emu_pid" 2>/dev/null; then
        warn "the emulator process exited immediately. Its output:"
        sed 's/^/    /' "$emu_log" | tail -15
        rm -f "$emu_log"
        die "'$name' could not start. A missing system image is the usual cause - open Android Studio > Device Manager and check the AVD, or recreate it: scripts/dev/emulator.sh create"
      fi
      sleep 2
    done
    if [ -z "$serial" ]; then
      sed 's/^/    /' "$emu_log" | tail -15
      rm -f "$emu_log"
      die "emulator did not show up in 'adb devices' within 120s."
    fi
    rm -f "$emu_log"

    wait_for_boot "$serial"
    info "run the app on it with: scripts/dev/adb.sh run --device $serial"
    ;;

  wait)
    # Assigned first, not passed inline: `die` inside a command substitution
    # only ends the subshell, so an inline "$(adb_device)" would hand an empty
    # serial to adb and block forever.
    serial="$(adb_device)"
    wait_for_boot "$serial"
    ;;

  stop)
    target="${1:-all}"
    stopped=0
    for serial in $(running_emulators); do
      name="$(avd_name_of "$serial")"
      if [ "$target" = "all" ] || [ "$target" = "$name" ] || [ "$target" = "$serial" ]; then
        "$ADB" -s "$serial" emu kill >/dev/null 2>&1 || true
        ok "stopped $name ($serial)"
        stopped=$((stopped + 1))
      fi
    done
    [ "$stopped" -gt 0 ] || info "no matching emulator was running"
    ;;

  delete)
    require_cmdline_tools
    name="${1:?usage: emulator.sh delete <name>}"
    confirm "Delete AVD '$name' including all its data?" || die "aborted."
    "$(avdmanager_bin)" delete avd --name "$name"
    ok "AVD '$name' deleted"
    ;;

  *)
    usage
    die "unknown command: $CMD"
    ;;
esac
