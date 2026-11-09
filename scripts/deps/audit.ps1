<#
.SYNOPSIS
  Check the resolved dependencies for known security vulnerabilities and, on
  request, pull in the fixes.
.DESCRIPTION
  Wraps tools/audit_deps.dart, which matches every hosted package in
  pubspec.lock against the OSV.dev advisory database (no account, no API key;
  only public package names and versions are sent).

  Exit code 0 = clean, 1 = vulnerabilities found, 2 = audit could not run.

  Related:
    scripts\deps\upgrade_deps.ps1     upgrade everything, incl. major versions
    scripts\deps\flutter_upgrade.ps1  upgrade the Flutter SDK itself
.EXAMPLE
  .\scripts\deps\audit.ps1                # report only
  .\scripts\deps\audit.ps1 -Fix           # report, then upgrade affected packages
  .\scripts\deps\audit.ps1 -Outdated      # also show how far behind the tree is
  .\scripts\deps\audit.ps1 -Json          # machine-readable (CI)
#>
param(
  [switch]$Fix,
  [switch]$Outdated,
  [switch]$Json,
  [switch]$Offline
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  if (-not (Test-Cmd dart)) { Write-Fail "dart not found. Install the Flutter SDK (it ships dart)." }

  if (-not (Test-Path (Join-Path $RepoRoot "pubspec.lock"))) {
    Write-Step "No pubspec.lock yet - resolving dependencies first"
    Invoke-Melos bs
  }

  $toolArgs = @()
  if ($Fix) { $toolArgs += "--fix" }
  if ($Outdated) { $toolArgs += "--outdated" }
  if ($Json) { $toolArgs += "--json" }
  if ($Offline) { $toolArgs += "--offline" }

  Write-Step "Auditing dependencies against OSV.dev"
  & dart tools/audit_deps.dart @toolArgs
  $code = $LASTEXITCODE

  switch ($code) {
    0 { Write-Ok "no known vulnerabilities" }
    1 { Write-Warn "vulnerable dependencies found - see the report above" }
    default { Write-Fail "audit could not complete (exit $code)" }
  }

  # Android's native dependencies are not covered by pub - remind once, cheaply.
  if ($code -ne 0) {
    Write-Info "Native Android dependencies are not part of this audit."
    Write-Info "Check them with: cd apps\mobile_app\android; .\gradlew dependencyUpdates"
  }

  exit $code
}
finally {
  Exit-RepoRoot
}
