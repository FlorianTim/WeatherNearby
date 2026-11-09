<#
.SYNOPSIS
  Build and quality-check the app locally with the installed Flutter/Dart SDK.
.DESCRIPTION
  Local counterpart of build.ps1 (which runs everything in Docker).
  Requires Flutter 3.44+ on PATH; quality tasks additionally require Melos
  (dart pub global activate melos).
.EXAMPLE
  .\scripts\build-local.ps1 web        # Flutter web release build
  .\scripts\build-local.ps1 android    # Flutter APK release build
  .\scripts\build-local.ps1 analyze    # analyze all packages (melos)
  .\scripts\build-local.ps1 test       # test all packages (melos)
  .\scripts\build-local.ps1 format     # check formatting (melos)
  .\scripts\build-local.ps1 ci         # format + analyze + test (melos run ci)
  .\scripts\build-local.ps1 api        # start Dart API server on :8080
  .\scripts\build-local.ps1 serve-web  # web dev server on http://localhost:8080
#>
param(
  [Parameter(Mandatory)]
  [ValidateSet("web", "android", "analyze", "test", "format", "ci", "api", "serve-web")]
  [string]$Task
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  function Assert-Tool {
    param([string]$Name, [string]$Hint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
      Write-Error "'$Name' not found on PATH. $Hint"
    }
  }

  Assert-Tool flutter "Install Flutter 3.44+ (https://flutter.dev)."

  function Assert-Melos {
    Assert-Tool melos "Install with: dart pub global activate melos"
  }

  function Assert-Platform {
    param([string]$Platform)
    if (-not (Test-Path "apps\mobile_app\$Platform")) {
      Write-Host "Bootstrapping $Platform platform..."
      Push-Location apps\mobile_app
      try { flutter create . --platforms $Platform --project-name mobile_app }
      finally { Pop-Location }
    }
  }

  switch ($Task) {
    "web" {
      Assert-Melos
      Assert-Platform web
      melos run build:web
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      Write-Host "Web build complete: apps/mobile_app/build/web/"
    }
    "android" {
      Assert-Platform android
      Use-AndroidBuildWorkarounds
      Push-Location apps\mobile_app
      try { flutter build apk --release --dart-define=APP_FLAVOR=prod }
      finally { Pop-Location }
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      Write-Host "APK build complete: apps/mobile_app/build/app/outputs/flutter-apk/"
    }
    "analyze" { Assert-Melos; melos run analyze }
    "test" { Assert-Melos; melos run test }
    "format" { Assert-Melos; melos run format:check }
    "ci" {
      Assert-Melos
      melos run ci
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      Write-Host ""
      Write-Host "All CI checks passed."
    }
    "api" {
      if (-not (Test-Path "services\api")) {
        Write-Error "No backend present (services/api was removed)."
      }
      Push-Location services\api
      try { dart run bin/server.dart }
      finally { Pop-Location }
    }
    "serve-web" { & "$PSScriptRoot\test_web_app.ps1" }
  }

  exit $LASTEXITCODE
}
finally {
  Exit-RepoRoot
}
