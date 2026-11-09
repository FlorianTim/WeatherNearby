# Compact local quality gate: format check + analyze + tests for the mobile
# app, each step reduced to a pass/fail line (full output only on failure).
# Token-saving wrapper for agents.
#
# Usage: .\scripts\dev\quality_gate.ps1

. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
Set-Location (Get-AppDir)

$script:fail = $false
$log = New-TemporaryFile

function Step {
  param([string]$Name, [scriptblock]$Action)
  & $Action *>$log
  if ($LASTEXITCODE -eq 0) {
    Write-Host "PASS  $Name"
  } else {
    Write-Host "FAIL  $Name"
    Get-Content $log | Select-Object -Last 30 | ForEach-Object { "    $_" }
    $script:fail = $true
  }
}

try {
  Step "format" { dart format --output=none --set-exit-if-changed lib test }
  Step "analyze" { & "$PSScriptRoot\analyze.ps1" }
  Step "test" { flutter test }

  # The bundled help is generated from docs/public-site/. Skipped when the
  # synchronized baseline is absent, so a fresh checkout can still run.
  $helpTool = Join-Path $RepoRoot ".lumbrecode/tooling/docs/render_app_help.py"
  if (Test-Path $helpTool) {
    Step "help" {
      python $helpTool --repo $RepoRoot --out apps/mobile_app/assets/help `
        --pattern '{document}_{locale}.md' --target app --check
    }
  } else {
    Write-Host "SKIP  help (no .lumbrecode baseline in this checkout)"
  }

  if ($script:fail) {
    Write-Host "== QUALITY GATE FAILED =="
    exit 1
  }
  Write-Host "== QUALITY GATE PASSED =="
} finally {
  Remove-Item $log -ErrorAction SilentlyContinue
  Exit-RepoRoot
}
