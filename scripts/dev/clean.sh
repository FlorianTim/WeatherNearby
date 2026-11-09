#!/usr/bin/env bash
# Clean local build output and caches. Runs from anywhere - the shared helper
# switches to the repository root first.
#
# Usage:
#   scripts/dev/clean.sh [target ...] [options]
#
# Targets (default: build):
#   build       build/, .dart_tool/, coverage/ in every package  (safe, cheap)
#   deep        build + native caches: android/.gradle, ios/Pods, .symlinks,
#               desktop build dirs, .flutter-plugins*             (safe, slow to rebuild)
#   generated   delete generated Dart sources (*.g.dart, *.freezed.dart,
#               l10n/generated) and re-run codegen                (needs Flutter)
#   docker      stop compose services and drop volumes (scripts/docker-cleanup.sh)
#   all         build + deep + docker
#
# Options:
#   --dry-run   print what would be removed, delete nothing
#   --restore   run `melos bs` afterwards so the workspace is ready again
#   --yes       skip the confirmation prompt of destructive targets
#
# Examples:
#   scripts/dev/clean.sh                  # everyday cleanup
#   scripts/dev/clean.sh deep --restore   # full reset before a fresh build
#   scripts/dev/clean.sh generated        # rebuild all generated sources
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

DRY_RUN=0
RESTORE=0
declare -a TARGETS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --restore) RESTORE=1 ;;
    --yes|-y)  ASSUME_YES=1 ;;
    -h|--help) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    build|deep|generated|docker|all) TARGETS+=("$1") ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
  shift
done
[ "${#TARGETS[@]}" -gt 0 ] || TARGETS=(build)

# Package roots we ever clean inside. Deliberately explicit: a blind
# `find . -name build` would also hit node_modules and Flutter's own SDK cache.
package_roots() {
  printf '%s\n' "$REPO_ROOT"
  local d
  for d in "$REPO_ROOT"/apps/*/ "$REPO_ROOT"/packages/*/ "$REPO_ROOT"/services/*/; do
    [ -d "$d" ] && printf '%s\n' "${d%/}"
  done
}

removed=0
remove_path() {
  local path="$1"
  [ -e "$path" ] || return 0
  local rel="${path#"$REPO_ROOT"/}"
  if [ "$DRY_RUN" = "1" ]; then
    info "would remove $rel"
  else
    rm -rf "$path"
    info "removed $rel"
  fi
  removed=$((removed + 1))
}

clean_build() {
  step "Removing build output and Dart tool caches"
  local root
  while read -r root; do
    remove_path "$root/build"
    remove_path "$root/.dart_tool"
    remove_path "$root/coverage"
  done < <(package_roots)
}

clean_deep() {
  clean_build
  step "Removing native build caches"
  local app; app="$(app_dir)"
  remove_path "$app/android/.gradle"
  remove_path "$app/android/build"
  remove_path "$app/android/app/build"
  remove_path "$app/ios/Pods"
  remove_path "$app/ios/.symlinks"
  remove_path "$app/macos/Pods"
  remove_path "$app/macos/.symlinks"
  remove_path "$app/windows/build"
  remove_path "$app/linux/build"
  remove_path "$app/.flutter-plugins"
  remove_path "$app/.flutter-plugins-dependencies"
}

clean_generated() {
  step "Removing generated Dart sources"
  warn "Generated sources are committed - this only makes sense together with codegen."
  # Nothing is deleted on a dry run, so do not make it interactive.
  if [ "$DRY_RUN" != "1" ]; then
    confirm "Delete all *.g.dart / *.freezed.dart / l10n output and regenerate?" \
      || die "aborted."
  fi

  local root
  while read -r root; do
    [ -d "$root/lib" ] || continue
    while IFS= read -r -d '' f; do remove_path "$f"; done \
      < <(find "$root/lib" \( -name '*.g.dart' -o -name '*.freezed.dart' \) -print0)
  done < <(package_roots)
  remove_path "$(app_dir)/lib/core/l10n/generated"

  if [ "$DRY_RUN" = "1" ]; then
    info "would run: melos run codegen"
    return 0
  fi
  step "Regenerating (melos run codegen)"
  melos_cmd run codegen || die "codegen failed - the deleted sources are still missing."
}

clean_docker() {
  step "Cleaning Docker resources"
  have docker || { warn "docker not on PATH - skipping"; return 0; }
  if [ "$DRY_RUN" = "1" ]; then
    info "would run: scripts/docker-cleanup.sh"
    return 0
  fi
  bash "$REPO_ROOT/scripts/docker-cleanup.sh"
}

for target in "${TARGETS[@]}"; do
  case "$target" in
    build)     clean_build ;;
    deep)      clean_deep ;;
    generated) clean_generated ;;
    docker)    clean_docker ;;
    all)       clean_deep; clean_docker ;;
  esac
done

if [ "$RESTORE" = "1" ] && [ "$DRY_RUN" != "1" ]; then
  step "Restoring workspace (melos bs)"
  melos_cmd bs
fi

echo ""
if [ "$DRY_RUN" = "1" ]; then
  ok "dry run finished - $removed path(s) would be removed."
else
  ok "clean finished - $removed path(s) removed."
  [ "$RESTORE" = "1" ] || info "Run 'melos bs' (or scripts/dev/clean.sh --restore) before building again."
fi
