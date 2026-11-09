<#
.SYNOPSIS
  Generate one versioned PDF per screen profile from the integration test screenshots.
.DESCRIPTION
  Requires Docker. Produces one PDF per profile with screenshots:
    docs/testing/generated/integration-test-report-<profile>-v<VERSION>.pdf
  Profile config: scripts\automation\integration-test\profiles.json
.EXAMPLE
  .\scripts\automation\integration-test\generate_test_report_pdf.ps1
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))
# Screen profiles are a shared LumbreCode contract, not a local choice.
$ProfilesFile = Join-Path $RepoRoot "docs\public-site\screenshot-profiles.json"
$Version = (Get-Content (Join-Path $RepoRoot "VERSION")).Trim()
$ScreenshotBase = "apps/mobile_app/test_results/screenshots"
$OutputDir = "docs/testing/generated"
$Today = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")

New-Item -ItemType Directory -Path (Join-Path $RepoRoot $OutputDir) -Force | Out-Null

$profiles = (Get-Content $ProfilesFile -Raw | ConvertFrom-Json).profiles

foreach ($p in $profiles) {
  $profile = $p.name
  $label   = $p.label
  $screenshotDir = Join-Path $RepoRoot ($ScreenshotBase -replace '/', '\') | Join-Path -ChildPath $profile
  $outputFile = "$OutputDir/integration-test-report-${profile}-v${Version}.pdf"
  $tempMdRelative = "$OutputDir/report-${profile}.tmp.md"
  $tempMdAbsolute = Join-Path $RepoRoot ($tempMdRelative -replace '/', '\')

  $pngs = Get-ChildItem $screenshotDir -Filter "*.png" -ErrorAction SilentlyContinue
  if (-not (Test-Path $screenshotDir) -or $pngs.Count -eq 0) {
    Write-Host "No screenshots for '$profile', skipping."
    continue
  }

  # Build a minimal per-profile markdown (image paths relative to repo root)
  $md = [System.Text.StringBuilder]::new()
  $null = $md.AppendLine("---")
  $null = $md.AppendLine("header-includes:")
  $null = $md.AppendLine("  - '\usepackage{float}'")
  $null = $md.AppendLine("  - '\floatplacement{figure}{H}'")
  $null = $md.AppendLine("---")
  $null = $md.AppendLine("")
  $null = $md.AppendLine("# Integration Test Report")
  $null = $md.AppendLine("")
  $null = $md.AppendLine("**Profil:** $label  ")
  $null = $md.AppendLine("**Version:** $Version  ")
  $null = $md.AppendLine("**Generated:** $Today")
  $null = $md.AppendLine("")
  $null = $md.AppendLine("## Screenshots")
  $null = $md.AppendLine("")

  foreach ($png in ($pngs | Sort-Object Name)) {
    $name = $png.BaseName
    $description = ($name -replace '-', ' ').Split(' ') | ForEach-Object {
      $_.Substring(0, 1).ToUpper() + $_.Substring(1)
    }
    $description = $description -join ' '
    $relPath = "$ScreenshotBase/$profile/$($png.Name)"

    # Read optional sidecar metadata (title, description, useCase)
    $jsonPath = Join-Path $screenshotDir "$name.json"
    $meta = $null
    if (Test-Path $jsonPath) {
      $meta = Get-Content $jsonPath -Raw | ConvertFrom-Json
    }

    $heading = if ($meta -and $meta.title) { $meta.title } else { $description }
    $null = $md.AppendLine("### $heading")
    $null = $md.AppendLine("")

    if ($meta) {
      if ($meta.description) {
        $null = $md.AppendLine($meta.description)
        $null = $md.AppendLine("")
      }
      if ($meta.useCase) {
        $null = $md.AppendLine("_Use Case: $($meta.useCase)_")
        $null = $md.AppendLine("")
      }
    }

    $null = $md.AppendLine("![$heading]($relPath)")
    $null = $md.AppendLine("")
  }

  [System.IO.File]::WriteAllText($tempMdAbsolute, $md.ToString())

  Write-Host "Building PDF: $outputFile  ($label, v$Version)..."

  $dockerArgs = @(
    'run', '--rm',
    '-v', "${RepoRoot}:/workspace",
    '-w', '/workspace',
    'pandoc/extra:latest',
    '-f', 'markdown',
    '--resource-path=.',
    '-V', 'geometry:margin=2.5cm',
    '-V', 'float-placement-figure=H',
    '-V', "title=Integration Test Report",
    '-V', "subtitle=$label - v$Version",
    '-V', "date=$Today",
    '-o', $outputFile,
    $tempMdRelative
  )
  & docker @dockerArgs

  Remove-Item $tempMdAbsolute -Force
  Write-Host "PDF generated: $(Join-Path $RepoRoot ($outputFile -replace '/', '\'))"
}

