<#
.SYNOPSIS
  Build and quality-check the app locally via Docker.
.DESCRIPTION
  No local Flutter/Dart SDK required - everything runs inside containers.
.EXAMPLE
  .\scripts\build.ps1 web              # Flutter web release build
  .\scripts\build.ps1 android          # Flutter APK release build
  .\scripts\build.ps1 analyze          # analyze mobile + API
  .\scripts\build.ps1 test             # test mobile + API
  .\scripts\build.ps1 integration-test # integration tests (mobile)
  .\.\scripts\build.ps1 integration-web  # integration tests (web, both orientations)  .\.\scripts\build.ps1 upgrade-deps     # upgrade all pub dependencies  .\scripts\build.ps1 format           # check formatting
  .\scripts\build.ps1 ci               # format + analyze + test (full CI)
  .\scripts\build.ps1 api              # start API server on :8080
#>
param(
  [Parameter(Mandatory)]
  [ValidateSet("web", "android", "analyze", "test", "integration-test", "integration-web", "format", "ci", "api", "generate-test-report", "generate-test-pdf", "integration-test-report", "upgrade-deps", "flutter-upgrade")]
  [string]$Task
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  function Test-Backend {
    return (Test-Path "services\api")
  }

  function Run-Analyze {
    docker compose run --rm mobile-analyze
    if (Test-Backend) { docker compose run --rm api-analyze }
  }

  function Run-Test {
    docker compose run --rm mobile-test
    if (Test-Backend) { docker compose run --rm api-test }
  }

  function Run-Format {
    docker compose run --rm mobile-format-check
    if (Test-Backend) { docker compose run --rm api-format-check }
  }

  switch ($Task) {
    "web" { docker compose run --rm mobile-build-web }
    "android" { docker compose run --rm mobile-build-android }
    "analyze" { Run-Analyze }
    "test" { Run-Test }
    "integration-test" { docker compose run --rm mobile-integration-test }
    "integration-web" { docker compose run --rm mobile-integration-test-web }
    "generate-test-report" { & "$PSScriptRoot\automation\integration-test\generate_test_docs.ps1" }
    "generate-test-pdf" { & "$PSScriptRoot\automation\integration-test\generate_test_report_pdf.ps1" }
    "integration-test-report" { & "$PSScriptRoot\automation\integration-test\integration_test_report.ps1" }
    "upgrade-deps" { & "$PSScriptRoot\deps\upgrade_deps.ps1" }
    "flutter-upgrade" { & "$PSScriptRoot\deps\flutter_upgrade.ps1" }
    "format" { Run-Format }
    "ci" {
      Run-Format
      Run-Analyze
      Run-Test
      Write-Host ""
      Write-Host "All CI checks passed."
    }
    "api" {
      if (-not (Test-Backend)) {
        Write-Error "No backend present (services/api was removed)."
      }
      docker compose up api-server
    }
  }
}
finally {
  Exit-RepoRoot
}
