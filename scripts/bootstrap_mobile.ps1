# Convenience wrapper — generates Android and Web platforms (Windows-compatible).
# For iOS, use macOS and run bootstrap_ios.sh.
# Edit project.env in the repo root to change ORG / PROJECT_NAME.
#
# Safe by design: flutter create runs in a temp directory and only the
# platform folders are copied into apps/mobile_app (never `create . --overwrite`).

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $RepoRoot "project.env"

# Load shared helpers
. (Join-Path $ScriptDir "lib\Read-ProjectEnv.ps1")
. (Join-Path $ScriptDir "lib\Bootstrap-Platforms.ps1")

$config = Read-ProjectEnv -EnvFilePath $EnvFile
if (-not $config) {
  exit 1
}

Write-Host "(Note: iOS requires macOS - use bootstrap_ios.sh on a Mac)"
Invoke-PlatformBootstrap -RepoRoot $RepoRoot `
  -Org $config['ORG'] `
  -ProjectName $config['PROJECT_NAME'] `
  -Platforms "android,web"

Write-Host "Done. Android and Web folders are ready."
