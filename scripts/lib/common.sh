#!/usr/bin/env bash
# Shared helpers for every script under scripts/.
#
# Source it as the FIRST statement of a script:
#
#   set -euo pipefail
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
#
# Sourcing it CHANGES THE WORKING DIRECTORY TO THE REPO ROOT, so every relative
# path inside a script is root-relative regardless of where the user invoked it
# from. $REPO_ROOT holds the root, $INVOCATION_DIR the caller's directory.
#
# Provides: logging (step/ok/warn/die), require_cmd/have, confirm,
# app_dir, load_project_env, application_id, melos_cmd, adb_bin, adb_device,
# android_build_workarounds.

# ── location ───────────────────────────────────────────────────────────────────

INVOCATION_DIR="$PWD"
# scripts/lib/common.sh -> repo root is two levels up. Works without git too
# (exported template copies, tarballs, containers).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT INVOCATION_DIR
cd "$REPO_ROOT"

# ── logging ────────────────────────────────────────────────────────────────────

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  _C_RESET=$'\033[0m'; _C_BOLD=$'\033[1m'; _C_DIM=$'\033[2m'
  _C_RED=$'\033[31m'; _C_GREEN=$'\033[32m'; _C_YELLOW=$'\033[33m'; _C_BLUE=$'\033[34m'
else
  _C_RESET=""; _C_BOLD=""; _C_DIM=""; _C_RED=""; _C_GREEN=""; _C_YELLOW=""; _C_BLUE=""
fi

step() { printf '%s==>%s %s\n' "$_C_BLUE$_C_BOLD" "$_C_RESET" "$*"; }
ok()   { printf '%s  OK%s %s\n' "$_C_GREEN" "$_C_RESET" "$*"; }
warn() { printf '%swarn%s %s\n' "$_C_YELLOW" "$_C_RESET" "$*" >&2; }
info() { printf '%s     %s%s\n' "$_C_DIM" "$*" "$_C_RESET"; }
die()  { printf '%sERROR%s %s\n' "$_C_RED$_C_BOLD" "$_C_RESET" "$*" >&2; exit 1; }

# ── tooling ────────────────────────────────────────────────────────────────────

have() { command -v "$1" >/dev/null 2>&1; }

# require_cmd <binary> [install hint]
require_cmd() {
  have "$1" || die "'$1' not found on PATH.${2:+ $2}"
}

# confirm "question"  -> 0 on yes. Auto-yes when $ASSUME_YES=1 or stdin is not a tty.
confirm() {
  if [ "${ASSUME_YES:-0}" = "1" ]; then return 0; fi
  if [ ! -t 0 ]; then
    warn "non-interactive shell, assuming 'no' for: $1 (use --yes to proceed)"
    return 1
  fi
  local reply
  read -rp "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy] ]]
}

# ── project layout / identity ──────────────────────────────────────────────────

# The Flutter app directory. Constant by convention; kept as a function so
# call sites stay readable and a future move is a one-line change.
app_dir() { printf '%s/apps/mobile_app' "$REPO_ROOT"; }

# Loads project.env into the environment ($ORG, $PROJECT_NAME, $APP_PACKAGE, ...).
load_project_env() {
  # shellcheck source=read_env.sh
  source "$REPO_ROOT/scripts/lib/read_env.sh"
  read_project_env "$REPO_ROOT/project.env" || die "could not read project.env"
}

# Android/iOS application id ("$ORG.$PROJECT_NAME"), derived from project.env.
application_id() {
  [ -n "${ORG:-}" ] || load_project_env
  printf '%s.%s' "$ORG" "$PROJECT_NAME"
}

# Fails early when the Dart SDK on PATH is older than the workspace requires.
# Without this, pub reports a bare "version solving failed", which sends the
# reader looking at the dependencies instead of at their shell - the usual
# cause is a terminal whose PATH still points at a previous SDK install.
require_dart_sdk() {
  have dart || die "dart not found on PATH. Install the Flutter SDK (it ships dart)."

  local required current lower
  # grep -o instead of a sed backreference: no capture group to escape, and
  # the first x.y.z on the line is the version in both inputs.
  required="$(grep -m1 -E '^[[:space:]]*sdk:' "$REPO_ROOT/pubspec.yaml" \
    | grep -oE '[0-9]+[.][0-9]+[.][0-9]+' | head -1)"
  current="$(dart --version 2>&1 | grep -oE '[0-9]+[.][0-9]+[.][0-9]+' | head -1)"
  # Unparseable on either side: say nothing and let pub speak.
  [ -n "$required" ] && [ -n "$current" ] || return 0

  # sort -V puts the lower version first; if that is not the requirement,
  # the SDK in this shell is too old for the workspace.
  lower="$({ echo "$required"; echo "$current"; } | sort -V | head -1)"
  if [ "$lower" != "$required" ]; then
    warn "Dart $current is older than the $required this workspace requires."
    info "dart:    $(command -v dart)"
    info "flutter: $(command -v flutter 2>/dev/null || echo 'not on PATH')"
    die "Open a fresh terminal (an old one keeps the PATH it started with), or upgrade the SDK: scripts/deps/flutter_upgrade.sh"
  fi
}

melos_cmd() {
  if have melos; then melos "$@"; else dart run melos "$@"; fi
}

# ── android ────────────────────────────────────────────────────────────────────

# Two host-specific Gradle startup problems seen on Windows (Git Bash /
# MSYS), see Common.ps1 for the full story. Process-local only.
#  1. AF_UNIX socket files refused under %LOCALAPPDATA% -> relocate the
#     JDK's socket scratch directory.
#  2. GRADLE_USER_HOME reached through junctions (Scoop) -> Kotlin DSL
#     scripts fail to compile; resolve to the real path first.
android_build_workarounds() {
  case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *) return 0 ;; esac
  case "${JAVA_TOOL_OPTIONS:-}" in *jdk.net.unixdomain.tmpdir*) ;; *)
    mkdir -p "$HOME/.java-ipc"
    local dir; dir="$(cygpath -w "$HOME/.java-ipc" 2>/dev/null || printf '%s' "$HOME/.java-ipc")"
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Djdk.net.unixdomain.tmpdir=$dir"
  ;; esac
  if [ -n "${GRADLE_USER_HOME:-}" ]; then
    local real
    real="$(cygpath -w "$(readlink -f "$(cygpath -u "$GRADLE_USER_HOME")")" 2>/dev/null || true)"
    if [ -n "$real" ] && [ "$real" != "$GRADLE_USER_HOME" ]; then
      info "GRADLE_USER_HOME resolved to $real (junction-free) for this build"
      export GRADLE_USER_HOME="$real"
      # Drop daemons that still hold the junction path (see Common.ps1) -
      # only when this project's wrapper distribution is already cached,
      # otherwise `gradlew --stop` would first download it.
      local wrapper="$(app_dir)/android/gradle/wrapper/gradle-wrapper.properties" dist
      if [ -f "$wrapper" ] && [ -d "$real/daemon" ]; then
        dist="$(sed -n 's/^distributionUrl=.*\///p' "$wrapper" | sed 's/\.zip$//')"
        if [ -n "$dist" ] && [ -d "$real/wrapper/dists/$dist" ]; then
          (cd "$(app_dir)/android" && timeout 60 ./gradlew --stop --quiet >/dev/null 2>&1 || true)
        fi
      fi
    fi
  fi
}

# Echoes the path to adb, searching PATH and the usual SDK locations.
adb_bin() {
  if have adb; then command -v adb; return 0; fi
  local candidate
  for candidate in \
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb" \
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb.exe" \
    "${ANDROID_HOME:-}/platform-tools/adb" \
    "${ANDROID_HOME:-}/platform-tools/adb.exe" \
    "${LOCALAPPDATA:-}/Android/Sdk/platform-tools/adb.exe" \
    "$HOME/Android/Sdk/platform-tools/adb" \
    "$HOME/Library/Android/sdk/platform-tools/adb"
  do
    [ -n "${candidate%/platform-tools/adb*}" ] && [ -x "$candidate" ] && { printf '%s' "$candidate"; return 0; }
  done
  return 1
}

# Echoes the target device serial: $ANDROID_SERIAL if set, the only attached
# device, or exits with a picker hint when several are attached.
adb_device() {
  local adb; adb="$(adb_bin)" || die "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT."
  if [ -n "${ANDROID_SERIAL:-}" ]; then printf '%s' "$ANDROID_SERIAL"; return 0; fi
  local -a serials
  mapfile -t serials < <("$adb" devices | awk 'NR>1 && $2=="device" {print $1}')
  case "${#serials[@]}" in
    0) die "no Android device attached. Start an emulator (scripts/dev/emulator.sh start) or connect a device." ;;
    1) printf '%s' "${serials[0]}" ;;
    *)
      warn "several devices attached: ${serials[*]}"
      die "pick one with ANDROID_SERIAL=<serial> or --device <serial>."
      ;;
  esac
}

# Echoes the Android SDK root, from the env vars or derived from adb's location.
android_sdk_root() {
  local candidate
  for candidate in \
    "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" \
    "${LOCALAPPDATA:-}/Android/Sdk" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"
  do
    [ -n "$candidate" ] && [ -d "$candidate" ] && { printf '%s' "$candidate"; return 0; }
  done
  local adb
  if adb="$(adb_bin)"; then dirname "$(dirname "$adb")"; return 0; fi
  return 1
}

# sdk_tool <name> <relative dir> [more dirs...]
# Echoes the path of an SDK binary, trying the platform's executable suffixes.
# cmdline-tools live under a version directory ("latest", "16.0", ...), so the
# lookup globs instead of hardcoding one layout.
sdk_tool() {
  local name="$1"; shift
  local sdk; sdk="$(android_sdk_root)" || return 1
  local dir ext candidate
  for dir in "$@"; do
    for candidate in "$sdk"/$dir; do
      for ext in "" ".exe" ".bat" ".cmd"; do
        [ -f "$candidate/$name$ext" ] && { printf '%s' "$candidate/$name$ext"; return 0; }
      done
    done
  done
  return 1
}

emulator_bin()   { sdk_tool emulator "emulator" "tools"; }
avdmanager_bin() { sdk_tool avdmanager "cmdline-tools/*/bin" "tools/bin"; }
sdkmanager_bin() { sdk_tool sdkmanager "cmdline-tools/*/bin" "tools/bin"; }
