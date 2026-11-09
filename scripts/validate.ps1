<#
.SYNOPSIS
  Run local validation checks (format + analyze + test) using Melos.
.DESCRIPTION
  Requires Flutter SDK and Melos.
  Install Melos with: dart pub global activate melos
  Mirrors the checks run by the CI workflow.
.EXAMPLE
  .\scripts\validate.ps1
#>
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  if (-not (Get-Command melos -ErrorAction SilentlyContinue)) {
    Write-Error "melos not found. Install with: dart pub global activate melos"
    exit 1
  }

  Write-Host "==> VERSION consistency"
  $versionFile = (Get-Content VERSION -Raw).Trim()
  $pubspecVersion = (Select-String -Path "apps/mobile_app/pubspec.yaml" -Pattern '^version:').Line `
    -replace 'version:\s*', '' -replace '\+.*$', ''
  if ($versionFile -ne $pubspecVersion) {
    Write-Error ("VERSION ($versionFile) != apps/mobile_app/pubspec.yaml version ($pubspecVersion). " +
      "Keep both in sync (VERSION holds the semver without build number).")
    exit 1
  }
  Write-Host "VERSION and pubspec.yaml agree: $versionFile"

  Write-Host "==> OpenSpec validation"
  & "$PSScriptRoot\validate_openspec.ps1"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host "==> Format check"
  melos run format:check

  Write-Host "==> Analyze"
  melos run analyze

  Write-Host "==> Tests"
  melos run test

  Write-Host ""
  Write-Host "$([char]0x2713) All checks passed."
}
finally {
  Exit-RepoRoot
}
