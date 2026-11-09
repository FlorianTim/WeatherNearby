#!/usr/bin/env bash
# Copies the Android-only branding resources into the freshly created
# android/ folder and applies the backup policy to the manifest.
#
# WHY a script and not committed files: android/ is never committed in this
# template (it would carry a stale application id). Everything that Flutter
# can produce itself is produced by Flutter - launcher icons come from
# flutter_launcher_icons, the in-app splash is a widget. What remains here is
# the small set of resources the OS reads BEFORE the Flutter engine runs, and
# those exist only as Android theme XML.
#
# Idempotent: safe to run after every bootstrap.
#
# Usage:
#   source "scripts/lib/apply_android_branding.sh"
#   apply_android_branding "/path/to/repo"

apply_android_branding() {
  local repo_root="$1"
  local src="$repo_root/scripts/bootstrap/android-res"
  local android_main="$repo_root/apps/mobile_app/android/app/src/main"
  local res="$android_main/res"

  if [ ! -d "$android_main" ]; then
    echo "  android/ not found - skipping branding (run the bootstrap first)." >&2
    return 0
  fi
  if [ ! -d "$src" ]; then
    echo "ERROR: resource templates missing at $src" >&2
    return 1
  fi

  local dir
  for dir in values values-night values-v31 values-night-v31 drawable drawable-v21; do
    if [ -d "$src/$dir" ]; then
      mkdir -p "$res/$dir"
      cp "$src/$dir/"*.xml "$res/$dir/"
    fi
  done
  echo "  applied android branding resources (splash background + themes)"

  _apply_backup_policy "$android_main/AndroidManifest.xml"
  _apply_channel_support \
    "$repo_root/apps/mobile_app/android/app/build.gradle.kts" \
    "$android_main/AndroidManifest.xml"
}

# Sets android:allowBackup on the <application> tag.
#
# The default is FALSE, deliberately: without the attribute Android's own
# default applies, which can upload the app's database to the user's Google
# account. For an app that tells its users their data stays on the device,
# that is a promise broken silently. Turning it off makes the claim true; the
# price is that a device change loses the data unless the app ships its own
# backup (see docs/architecture/patterns/backup-restore.md).
#
# An app that WANTS platform backup flips the value here and says so in its
# privacy policy - the point is that it becomes a decision, not an inheritance.
_apply_backup_policy() {
  local manifest="$1"
  local value="false"

  if [ ! -f "$manifest" ]; then
    echo "  AndroidManifest.xml not found - skipping backup policy." >&2
    return 0
  fi

  if grep -q 'android:allowBackup' "$manifest"; then
    echo "  backup policy already present - left unchanged"
    return 0
  fi

  # Flutter's generated manifest has `    <application` on its own line.
  local tmp
  tmp="$(mktemp)"
  awk -v val="$value" '
    /^[[:space:]]*<application/ && !done {
      print
      print "        android:allowBackup=" "\"" val "\""
      done = 1
      next
    }
    { print }
  ' "$manifest" > "$tmp"

  if grep -q 'android:allowBackup' "$tmp"; then
    mv "$tmp" "$manifest"
    echo "  set android:allowBackup=\"$value\" (see scripts/lib/apply_android_branding.sh)"
  else
    rm -f "$tmp"
    echo "  WARNING: could not set android:allowBackup - add it by hand." >&2
  fi
}

# Lets a snapshot or pre-release install NEXT TO the release (spec 0008).
#
# Without it every flavor shares one application id, so installing a
# snapshot replaces the release - and with it the release's data. With
# `APP_FLAVOR=snapshot` (or `prerelease`) in the build environment the build
# gets the id suffix `.snapshot` and the launcher name "<name> (Snapshot)".
# The release and every other build keep id and name exactly as before.
#
# The label moves from the manifest into a generated string resource
# (`app_label`, set in build.gradle.kts), because a manifest cannot compute it.
# The flavor must ALSO be passed to Dart: `--dart-define=APP_FLAVOR=<name>`
# (it names the database and the preferences, see AppFlavor in app_core).
#
# Idempotent: a build.gradle.kts that already mentions APP_FLAVOR is left alone.
_apply_channel_support() {
  local gradle="$1"
  local manifest="$2"

  if [ ! -f "$gradle" ] || [ ! -f "$manifest" ]; then
    echo "  build.gradle.kts or AndroidManifest.xml not found - skipping channel support." >&2
    return 0
  fi
  if grep -q 'APP_FLAVOR' "$gradle"; then
    echo "  channel support already present - left unchanged"
    return 0
  fi

  local label
  label="$(sed -n 's/.*android:label="\([^"]*\)".*/\1/p' "$manifest" | head -1)"
  if [ -z "$label" ] || [ "${label#@string/}" != "$label" ]; then
    echo "  WARNING: android:label is missing or already a resource - channel support not applied." >&2
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v label="$label" '
    /^android \{/ && !features {
      print
      print "    // resValue() below needs this; AGP 9 has it off by default."
      print "    buildFeatures {"
      print "        resValues = true"
      print "    }"
      print ""
      features = 1
      next
    }
    /versionName = flutter\.versionName/ && !done {
      print
      print ""
      print "        // Build channel (APP_FLAVOR): a snapshot or pre-release installs next to the"
      print "        // release under its own application id and name. See apply_android_branding.sh."
      print "        val appFlavor = (System.getenv(\"APP_FLAVOR\") ?: \"\").lowercase()"
      print "        val flavorLabel = when (appFlavor) {"
      print "            \"snapshot\" -> \" (Snapshot)\""
      print "            \"prerelease\" -> \" (Pre-release)\""
      print "            else -> \"\""
      print "        }"
      print "        if (flavorLabel.isNotEmpty()) {"
      print "            applicationIdSuffix = \".$appFlavor\""
      print "        }"
      print "        resValue(\"string\", \"app_label\", \"" label "$flavorLabel\")"
      done = 1
      next
    }
    { print }
  ' "$gradle" > "$tmp"

  if ! grep -q 'APP_FLAVOR' "$tmp"; then
    rm -f "$tmp"
    echo "  WARNING: could not add channel support to build.gradle.kts - add it by hand." >&2
    return 0
  fi
  mv "$tmp" "$gradle"
  sed -i 's#android:label="[^"]*"#android:label="@string/app_label"#' "$manifest"
  echo "  added channel support (APP_FLAVOR=snapshot|prerelease -> own id suffix and name)"
}
