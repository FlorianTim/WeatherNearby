# Verify that the Windows analyzer wrapper isolates and removes plugin clients.

. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
$testRoot = Join-Path $RepoRoot ('.buildlog\analyze-wrapper-test-' + [guid]::NewGuid().ToString('N'))
$savedPath = $env:PATH
$savedCapture = $env:ANALYZE_TEST_CAPTURE
$savedExit = $env:ANALYZE_TEST_EXIT

try {
  New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
  $capture = Join-Path $testRoot 'temp-paths.txt'
  $fakeFlutter = Join-Path $testRoot 'flutter.cmd'
  @'
@echo off
if not "%1"=="analyze" exit /b 91
if not "%2"=="--no-pub" exit /b 92
echo %TEMP%>>"%ANALYZE_TEST_CAPTURE%"
exit /b %ANALYZE_TEST_EXIT%
'@ | Set-Content -LiteralPath $fakeFlutter -Encoding ascii

  $env:PATH = "$testRoot;$savedPath"
  $env:ANALYZE_TEST_CAPTURE = $capture
  $env:ANALYZE_TEST_EXIT = '0'
  $wrapper = Join-Path $RepoRoot 'scripts\dev\analyze.ps1'

  for ($run = 0; $run -lt 2; $run++) {
    & pwsh -NoProfile -File $wrapper
    if ($LASTEXITCODE -ne 0) { throw "Analysis run failed: $LASTEXITCODE" }
  }

  $paths = @(Get-Content -LiteralPath $capture)
  if ($paths.Count -ne 2 -or $paths[0] -eq $paths[1]) {
    throw 'Analysis runs did not use distinct temporary directories.'
  }
  foreach ($path in $paths) {
    if (-not $path.StartsWith((Join-Path $RepoRoot '.buildlog\analyze-temp') + '\', [StringComparison]::OrdinalIgnoreCase)) {
      throw "Temporary directory escaped the repository: $path"
    }
    if (Test-Path -LiteralPath $path) { throw "Temporary directory was not removed: $path" }
  }

  $env:ANALYZE_TEST_EXIT = '7'
  & pwsh -NoProfile -File $wrapper
  if ($LASTEXITCODE -ne 7) { throw "Analyzer failure was not propagated: $LASTEXITCODE" }
  Write-Host 'PASS  isolated analyzer temporary directories and exit code'
} finally {
  $env:PATH = $savedPath
  $env:ANALYZE_TEST_CAPTURE = $savedCapture
  $env:ANALYZE_TEST_EXIT = $savedExit
  if (Test-Path -LiteralPath $testRoot) {
    $buildlog = (Resolve-Path -LiteralPath (Join-Path $RepoRoot '.buildlog')).Path.TrimEnd('\') + '\'
    $resolvedTestRoot = (Resolve-Path -LiteralPath $testRoot).Path
    if ($resolvedTestRoot.StartsWith($buildlog, [StringComparison]::OrdinalIgnoreCase)) {
      Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
  }
  Exit-RepoRoot
}
