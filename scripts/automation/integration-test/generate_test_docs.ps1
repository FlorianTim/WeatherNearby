# Generate test documentation from integration test screenshots.
#
# Expects screenshots in subdirectories defined by the screen profiles:
#   apps\mobile_app\test_results\screenshots\<profile>\
#
# Profile config: scripts\automation\integration-test\profiles.json
#
# Usage:
#   .\scripts\automation\integration-test\generate_test_docs.ps1
#
# Output:
#   docs/testing/integration-test-report.md

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))
# Screen profiles are a shared LumbreCode contract, not a local choice.
$ProfilesFile = Join-Path $RepoRoot "docs\public-site\screenshot-profiles.json"
$ScreenshotBase = Join-Path $RepoRoot "apps\mobile_app\test_results\screenshots"
$OutputDir  = Join-Path $RepoRoot "docs\testing"
$OutputFile = Join-Path $OutputDir "integration-test-report.md"
$Version    = (Get-Content (Join-Path $RepoRoot "VERSION")).Trim()

Set-Location $RepoRoot
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$profiles = (Get-Content $ProfilesFile -Raw | ConvertFrom-Json).profiles
$anyFound = $profiles | Where-Object {
    $dir = Join-Path $ScreenshotBase $_.name
    (Test-Path $dir) -and ((Get-ChildItem $dir -Filter "*.png" -ErrorAction SilentlyContinue).Count -gt 0)
}
if (-not $anyFound) {
    Write-Error "No screenshots found in $ScreenshotBase\*\`nRun integration tests first: .\scripts\build.ps1 integration-web"
}

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss UTC")

@"
# Integration Test Report

**Generated:** $timestamp

**Version:** $Version

## Counter App Tests

This report contains screenshots captured during automated integration tests of the Flutter counter application.

"@ | Set-Content $OutputFile

# ── helper: append one profile section ──────────────────────────────────────
function Add-ProfileSection {
    param([string]$Dir, [string]$SubDir, [string]$Heading)

    @"

## $Heading

### Test Screenshots

"@ | Add-Content $OutputFile

    if (-not (Test-Path $Dir) -or (Get-ChildItem $Dir -Filter "*.png" -ErrorAction SilentlyContinue).Count -eq 0) {
        "*(No screenshots found for this profile.)*`n" | Add-Content $OutputFile
        return
    }

    Get-ChildItem $Dir -Filter "*.png" | Sort-Object Name | ForEach-Object {
        $filename    = $_.Name
        $name        = $_.BaseName
        $description = ($name -replace '-', ' ').Split(' ') | ForEach-Object {
            $_.Substring(0,1).ToUpper() + $_.Substring(1)
        }
        $description = $description -join ' '
        $relPath = "../../apps/mobile_app/test_results/screenshots/$SubDir/$filename"

        @"

#### $description

![$description]($relPath)

"@ | Add-Content $OutputFile
    }
}

foreach ($p in $profiles) {
    $dir = Join-Path $ScreenshotBase $p.name
    Add-ProfileSection -Dir $dir -SubDir $p.name -Heading "$($p.label) Screenshots"
}

@"

## Test Summary

The integration tests verify:
- [x] Initial application state
- [x] Counter increment functionality
- [x] UI element presence and layout
- [x] Button tooltip functionality
- [x] State persistence across interactions

## Running Tests

To regenerate this report:

``````powershell
# Run integration tests (all profiles)
.\scripts\build.ps1 integration-web

# Generate documentation
.\scripts\automation\integration-test\generate_test_docs.ps1

# Generate versioned PDF
.\scripts\automation\integration-test\generate_test_report_pdf.ps1
``````
"@ | Add-Content $OutputFile

Write-Host "Integration test report generated: $OutputFile"
foreach ($p in $profiles) {
    $dir = Join-Path $ScreenshotBase $p.name
    $count = if (Test-Path $dir) { (Get-ChildItem $dir -Filter "*.png" -ErrorAction SilentlyContinue).Count } else { 0 }
    Write-Host "  $($p.name): $count screenshots"
}

