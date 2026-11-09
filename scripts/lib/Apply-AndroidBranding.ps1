# Copies the Android-only branding resources into the freshly created
# android/ folder and applies the backup policy to the manifest.
#
# WHY a script and not committed files: android/ is never committed in this
# template (it would carry a stale application id). Everything Flutter can
# produce itself is produced by Flutter - launcher icons come from
# flutter_launcher_icons, the in-app splash is a widget. What remains here is
# the small set of resources the OS reads BEFORE the Flutter engine runs, and
# those exist only as Android theme XML.
#
# Idempotent: safe to run after every bootstrap.
#
# Usage:
#   . scripts/lib/Apply-AndroidBranding.ps1
#   Invoke-AndroidBranding -RepoRoot $RepoRoot

function Invoke-AndroidBranding {
  param(
    [Parameter(Mandatory)] [string]$RepoRoot
  )

  $src = Join-Path $RepoRoot "scripts\bootstrap\android-res"
  $androidMain = Join-Path $RepoRoot "apps\mobile_app\android\app\src\main"
  $res = Join-Path $androidMain "res"

  if (-not (Test-Path $androidMain)) {
    Write-Warning "android/ not found - skipping branding (run the bootstrap first)."
    return
  }
  if (-not (Test-Path $src)) {
    throw "Resource templates missing at $src"
  }

  foreach ($dir in @("values", "values-night", "values-v31", "values-night-v31", "drawable", "drawable-v21")) {
    $from = Join-Path $src $dir
    if (-not (Test-Path $from)) { continue }
    $to = Join-Path $res $dir
    if (-not (Test-Path $to)) { New-Item -ItemType Directory -Path $to -Force | Out-Null }
    Copy-Item (Join-Path $from "*.xml") $to -Force
  }
  Write-Host "  applied android branding resources (splash background + themes)"

  Set-BackupPolicy -ManifestPath (Join-Path $androidMain "AndroidManifest.xml")
  Set-ChannelSupport `
    -GradlePath (Join-Path $RepoRoot "apps\mobile_app\android\app\build.gradle.kts") `
    -ManifestPath (Join-Path $androidMain "AndroidManifest.xml")
}

# Lets a snapshot or pre-release install NEXT TO the release (spec 0008).
#
# Without it every flavor shares one application id, so installing a
# snapshot replaces the release - and with it the release's data. With
# APP_FLAVOR=snapshot (or prerelease) in the build environment the build gets
# the id suffix ".snapshot" and the launcher name "<name> (Snapshot)". The
# release and every other build keep id and name exactly as before.
#
# The label moves from the manifest into a generated string resource
# (app_label, set in build.gradle.kts), because a manifest cannot compute it.
# The flavor must ALSO be passed to Dart: --dart-define=APP_FLAVOR=<name>
# (it names the database and the preferences, see AppFlavor in app_core).
#
# Idempotent: a build.gradle.kts that already mentions APP_FLAVOR is left alone.
# Twin of _apply_channel_support in apply_android_branding.sh.
function Set-ChannelSupport {
  param(
    [Parameter(Mandatory)] [string]$GradlePath,
    [Parameter(Mandatory)] [string]$ManifestPath
  )

  if (-not (Test-Path $GradlePath) -or -not (Test-Path $ManifestPath)) {
    Write-Warning "build.gradle.kts or AndroidManifest.xml not found - skipping channel support."
    return
  }

  $gradle = Get-Content $GradlePath
  if ($gradle -match 'APP_FLAVOR') {
    Write-Host "  channel support already present - left unchanged"
    return
  }

  $manifest = Get-Content $ManifestPath -Raw
  $found = [regex]::Match($manifest, 'android:label="([^"]*)"')
  if (-not $found.Success -or $found.Groups[1].Value.StartsWith('@string/')) {
    Write-Warning "android:label is missing or already a resource - channel support not applied."
    return
  }
  $label = $found.Groups[1].Value

  $block = @(
    '',
    '        // Build channel (APP_FLAVOR): a snapshot or pre-release installs next to the',
    '        // release under its own application id and name. See Apply-AndroidBranding.ps1.',
    '        val appFlavor = (System.getenv("APP_FLAVOR") ?: "").lowercase()',
    '        val flavorLabel = when (appFlavor) {',
    '            "snapshot" -> " (Snapshot)"',
    '            "prerelease" -> " (Pre-release)"',
    '            else -> ""',
    '        }',
    '        if (flavorLabel.isNotEmpty()) {',
    '            applicationIdSuffix = ".$appFlavor"',
    '        }',
    ('        resValue("string", "app_label", "' + $label + '$flavorLabel")')
  )

  $output = New-Object System.Collections.Generic.List[string]
  $done = $false
  foreach ($line in $gradle) {
    $output.Add($line)
    if (-not $done -and $line -match 'versionName = flutter\.versionName') {
      foreach ($added in $block) { $output.Add($added) }
      $done = $true
    }
  }

  if (-not $done) {
    Write-Warning "Could not add channel support to build.gradle.kts - add it by hand."
    return
  }

  Set-Content -Path $GradlePath -Value $output
  Set-Content -Path $ManifestPath -NoNewline -Value ($manifest -replace 'android:label="[^"]*"', 'android:label="@string/app_label"')
  Write-Host "  added channel support (APP_FLAVOR=snapshot|prerelease -> own id suffix and name)"
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
function Set-BackupPolicy {
  param(
    [Parameter(Mandatory)] [string]$ManifestPath
  )

  $value = "false"

  if (-not (Test-Path $ManifestPath)) {
    Write-Warning "AndroidManifest.xml not found - skipping backup policy."
    return
  }

  $lines = Get-Content $ManifestPath
  if ($lines -match 'android:allowBackup') {
    Write-Host "  backup policy already present - left unchanged"
    return
  }

  $output = New-Object System.Collections.Generic.List[string]
  $done = $false
  foreach ($line in $lines) {
    $output.Add($line)
    if (-not $done -and $line -match '^\s*<application') {
      $output.Add('        android:allowBackup="' + $value + '"')
      $done = $true
    }
  }

  if (-not $done) {
    Write-Warning "Could not set android:allowBackup - add it by hand."
    return
  }

  Set-Content -Path $ManifestPath -Value $output
  Write-Host ("  set android:allowBackup=" + '"' + $value + '"' + " (see scripts/lib/Apply-AndroidBranding.ps1)")
}
