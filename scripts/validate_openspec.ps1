# Validate all OpenSpec app specifications (openspec/apps/*.openspec.yaml)
# against the rules in openspec/README.md. Line-based checks — the spec
# format is a flat, template-controlled YAML.
#
# Usage: .\scripts\validate_openspec.ps1

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  $script:fail = $false

  function Test-Scalar {
    param([string[]]$Lines, [string]$Key)
    $line = $Lines | Where-Object { $_ -match "^\s*$Key\s*:" } | Select-Object -First 1
    if (-not $line) { Write-Host "  MISSING: $Key"; return $false }
    $value = ($line -replace "^\s*$Key\s*:", '').Trim()
    if ($value -in @('', '""', "''", '[]')) { Write-Host "  EMPTY: $Key"; return $false }
    return $true
  }

  function Test-List {
    param([string[]]$Lines, [string]$Key)
    for ($i = 0; $i -lt $Lines.Count; $i++) {
      if ($Lines[$i] -match "^\s*$Key\s*:") {
        $value = ($Lines[$i] -replace "^\s*$Key\s*:", '').Trim()
        if ($value -and $value -ne '[]') { return $true }
        if ($i + 1 -lt $Lines.Count -and $Lines[$i + 1].Trim().StartsWith('-')) { return $true }
        Write-Host "  EMPTY: $Key (no list items)"
        return $false
      }
    }
    Write-Host "  MISSING: $Key"
    return $false
  }

  $specs = Get-ChildItem "openspec/apps/*.openspec.yaml" -ErrorAction SilentlyContinue
  if (-not $specs) {
    Write-Error "no OpenSpec files under openspec/apps/."
  }

  foreach ($spec in $specs) {
    Write-Host "==> $($spec.FullName)"
    $lines = Get-Content $spec.FullName
    $ok = $true

    foreach ($key in @('spec_version', 'app_name', 'app_display_name', 'app_slug',
        'short_description', 'backend_enabled', 'splash_screen_app_name',
        'replace_todo_app')) {
      if (-not (Test-Scalar $lines $key)) { $ok = $false }
    }
    foreach ($key in @('primary_platforms', 'core_features',
        'privacy_requirements', 'security_requirements')) {
      if (-not (Test-List $lines $key)) { $ok = $false }
    }

    $slugLine = $lines | Where-Object { $_ -match '^\s*app_slug\s*:' } | Select-Object -First 1
    if ($slugLine) {
      $slug = ($slugLine -replace '^\s*app_slug\s*:', '').Trim().Trim('"').Trim("'")
      if ($slug -and $slug -notmatch '^[a-z][a-z0-9_]*$') {
        Write-Host "  INVALID: app_slug '$slug' must match ^[a-z][a-z0-9_]*$"
        $ok = $false
      }
      if ($slug -in @('test', 'flutter', 'dart')) {
        Write-Host "  INVALID: app_slug '$slug' is a reserved word"
        $ok = $false
      }
    }

    if ($ok) { Write-Host "  OK" } else { $script:fail = $true }
  }

  if ($script:fail) {
    Write-Host ""
    Write-Error "OpenSpec validation FAILED."
  }

  Write-Host ""
  Write-Host "OpenSpec validation passed."
  exit 0
}
finally {
  Exit-RepoRoot
}
