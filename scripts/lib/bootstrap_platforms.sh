#!/usr/bin/env bash
# Shared shell function to (re)generate Flutter platform folders SAFELY.
#
# IMPORTANT: never run `flutter create . --overwrite` inside apps/mobile_app —
# it overwrites pubspec.yaml (all dependencies gone), lib/main.dart,
# test/widget_test.dart, README.md, analysis_options.yaml and .gitignore.
#
# Instead, `flutter create` runs in a throw-away temp directory and ONLY the
# requested platform folders (android/, ios/, web/, linux/, ...) are copied
# into apps/mobile_app. All app files stay untouched.
#
# Usage:
#   source "scripts/lib/read_env.sh"
#   source "scripts/lib/bootstrap_platforms.sh"
#   read_project_env "/path/to/project.env"
#   bootstrap_platforms "/path/to/repo" "android,web"

bootstrap_platforms() {
  local repo_root="$1"
  local platforms="$2" # comma-separated, e.g. "android,web"
  local project_dir="$repo_root/apps/mobile_app"

  if ! command -v flutter >/dev/null 2>&1; then
    echo "Flutter is not installed or not on PATH." >&2
    return 1
  fi

  local tmp
  tmp="$(mktemp -d)"

  echo "Generating platforms [$platforms] for org=$ORG project_name=$PROJECT_NAME"
  if ! (cd "$tmp" && flutter create \
      --org "$ORG" \
      --project-name "$PROJECT_NAME" \
      --platforms="$platforms" \
      app); then
    rm -rf "$tmp"
    echo "flutter create failed." >&2
    return 1
  fi

  local p
  local has_android=0
  for p in ${platforms//,/ }; do
    rm -rf "$project_dir/$p"
    cp -R "$tmp/app/$p" "$project_dir/$p"
    echo "  refreshed $p/"
    [ "$p" = "android" ] && has_android=1
  done
  rm -rf "$tmp"

  # The generated android/ carries Flutter's white launch screen and no backup
  # policy. Put the Android-only branding resources back in place - everything
  # Flutter can do itself stays with Flutter (see the helper's header).
  if [ "$has_android" = "1" ]; then
    # shellcheck source=apply_android_branding.sh
    source "$repo_root/scripts/lib/apply_android_branding.sh"
    apply_android_branding "$repo_root" || return 1
  fi

  (cd "$project_dir" && flutter pub get)
}
