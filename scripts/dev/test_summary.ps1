# Run the Flutter test suite (or a subset) and print a COMPACT result:
# one line on green, otherwise only failing test names plus the first
# exception. Token-saving wrapper for agents.
#
# Usage:
#   .\scripts\dev\test_summary.ps1 [flutter-test-args...]
#   .\scripts\dev\test_summary.ps1 test/features/todos

. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
Set-Location (Get-AppDir)

$log = New-TemporaryFile
try {
  flutter test @args *>$log
  $code = $LASTEXITCODE

  if ($code -eq 0) {
    Select-String -Path $log -Pattern "All tests passed" | Select-Object -Last 1 |
      ForEach-Object { $_.Line }
    exit 0
  }

  Write-Host "== TESTS FAILED (exit $code) =="
  $lines = Get-Content $log
  Write-Host "-- failing tests --"
  $inFail = $false
  foreach ($line in $lines) {
    if ($line -match '^Failing tests:') { $inFail = $true; continue }
    if ($inFail) {
      if ($line.Trim() -eq '') { break }
      Write-Host "  $line"
    }
  }
  Write-Host "-- first failure detail --"
  $lines | Select-String -Pattern 'EXCEPTION CAUGHT|TestFailure|Expected:|Actual:|Which:' -Context 0, 3 |
    Select-Object -First 10 | ForEach-Object { $_.Line }
  exit $code
} finally {
  Remove-Item $log -ErrorAction SilentlyContinue
  Exit-RepoRoot
}
