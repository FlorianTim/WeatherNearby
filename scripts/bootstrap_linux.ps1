# Bootstrap script for Linux platform
# Generates the linux/ directory with custom bundle ID.
#
# Safe by design: flutter create runs in a temp directory and only the
# platform folder is copied into apps/mobile_app (never `create . --overwrite`).

param()

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

Invoke-PlatformBootstrap -RepoRoot $RepoRoot `
  -Org $config['ORG'] `
  -ProjectName $config['PROJECT_NAME'] `
  -Platforms "linux"

Write-Host "Linux platform generated successfully!"
