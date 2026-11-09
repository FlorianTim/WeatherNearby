# Run Flutter analysis with an isolated temporary plugin client.
# Usage: .\scripts\dev\analyze.ps1

. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
$priorTemp = $env:TEMP
$priorTmp = $env:TMP
$analysisExit = 1
$runDir = $null
$tempBase = Join-Path $RepoRoot '.buildlog\analyze-temp'

try {
  New-Item -ItemType Directory -Force -Path $tempBase | Out-Null
  $runDir = Join-Path $tempBase ([guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $runDir | Out-Null
  $env:TEMP = $runDir
  $env:TMP = $runDir
  Set-Location (Get-AppDir)
  flutter analyze --no-pub
  $analysisExit = $LASTEXITCODE
} finally {
  $env:TEMP = $priorTemp
  $env:TMP = $priorTmp
  if ($runDir -and (Test-Path -LiteralPath $runDir)) {
    $basePath = (Resolve-Path -LiteralPath $tempBase).Path.TrimEnd('\') + '\'
    $runPath = (Resolve-Path -LiteralPath $runDir).Path
    if ($runPath.StartsWith($basePath, [StringComparison]::OrdinalIgnoreCase)) {
      for ($attempt = 0; $attempt -lt 3; $attempt++) {
        Remove-Item -LiteralPath $runPath -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path -LiteralPath $runPath)) { break }
        Start-Sleep -Milliseconds 200
      }
    }
  }
  Exit-RepoRoot
}

exit $analysisExit
