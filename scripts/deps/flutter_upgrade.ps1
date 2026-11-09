<#
.SYNOPSIS
  Upgrade the local Flutter SDK and refresh the dependencies.
.DESCRIPTION
  1. flutter upgrade      - pulls the latest SDK on the current channel
  2. reports how CI relates to the new local version
  3. flutter pub upgrade  - refreshes dependencies via upgrade_deps.ps1

  On CI pins: the workflows request `flutter-version: 3.x`, so patch and minor
  releases reach CI on their own and there is nothing to sync here. Should
  someone re-pin an exact version, this script notices and rewrites it, so the
  two cannot drift apart silently.

  Note: review and commit the resulting pubspec.yaml changes afterwards.
.EXAMPLE
  .\scripts\deps\flutter_upgrade.ps1
#>

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  if (-not (Test-Cmd flutter)) { Write-Fail "flutter not found. Install the Flutter SDK and put it on PATH." }

  $workflowsDir = Join-Path $RepoRoot ".github\workflows"

  # An exact x.y.z pin in any workflow - $null when they all float on 3.x.
  $oldVersion = Get-ChildItem $workflowsDir -Filter "*.yml" |
    Select-String -Pattern '^\s*flutter-version:\s*(\d+\.\d+\.\d+)' |
    Select-Object -First 1 |
    ForEach-Object { $_.Matches[0].Groups[1].Value }

  Write-Step "Upgrading the Flutter SDK"
  & flutter upgrade

  $versionLine = & flutter --version 2>&1 | Where-Object { $_ -match "^Flutter\s" } | Select-Object -First 1
  $newVersion = ($versionLine -replace "^Flutter\s+(\S+).*", '$1').Trim()
  Write-Ok "local Flutter is now $newVersion"

  if (-not $oldVersion) {
    $wildcard = Get-ChildItem $workflowsDir -Filter "*.yml" |
      Select-String -Pattern '^\s*flutter-version:\s*(\S+)' |
      Select-Object -First 1 |
      ForEach-Object { $_.Matches[0].Groups[1].Value }
    Write-Info "CI requests '$wildcard' - it follows along on its own, nothing to sync."
  }
  elseif ($oldVersion -eq $newVersion) {
    Write-Info "CI already pins $newVersion exactly - nothing to sync."
  }
  else {
    Write-Step "Re-pinning the workflows: $oldVersion -> $newVersion"
    Get-ChildItem $workflowsDir -Filter "*.yml" | ForEach-Object {
      $content = Get-Content $_.FullName -Raw
      $needle = "flutter-version: $oldVersion"
      if ($content -match [regex]::Escape($needle)) {
        ($content -replace [regex]::Escape($needle), "flutter-version: $newVersion") |
          Set-Content $_.FullName -NoNewline
        Write-Info "updated $($_.Name)"
      }
    }
  }

  Write-Step "Upgrading pub dependencies"
  & "$PSScriptRoot\upgrade_deps.ps1"

  Write-Host ""
  Write-Ok "Flutter SDK upgraded to $newVersion"
  Write-Info "Review the changes and commit. Then check for advisories: .\scripts\deps\audit.ps1"
}
finally {
  Exit-RepoRoot
}
