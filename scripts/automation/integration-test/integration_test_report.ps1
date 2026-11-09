<#
.SYNOPSIS
  Run integration tests for both orientations and generate the versioned PDF report.
.DESCRIPTION
  Executes all three steps in sequence:
    1. Integration tests – tablet (1280×1024) + phone portrait (390×844)
    2. Generate Markdown report  →  docs/testing/integration-test-report.md
    3. Generate versioned PDF    →  docs/testing/generated/integration-test-report-v<VERSION>.pdf

  Requires Docker.
.EXAMPLE
  .\scripts\automation\integration-test\integration_test_report.ps1
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))
Set-Location $RepoRoot

Write-Host ""
Write-Host "=== Step 1/3: Integration tests (tablet + phone portrait) ==="
docker compose run --rm mobile-integration-test-web

Write-Host ""
Write-Host "=== Step 2/3: Generate Markdown report ==="
& "$ScriptDir\generate_test_docs.ps1"

Write-Host ""
Write-Host "=== Step 3/3: Generate versioned PDF ==="
& "$ScriptDir\generate_test_report_pdf.ps1"

$Version = (Get-Content (Join-Path $RepoRoot "VERSION")).Trim()
$PdfPath = Join-Path $RepoRoot "docs\testing\generated\integration-test-report-v$Version.pdf"

Write-Host ""
Write-Host "Done. PDF: $PdfPath"
