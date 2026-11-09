# Remove every backend component (backend/, services/api/, CI workflows,
# compose services, workspace tasks) in one operation.
#
# Usage:
#   .\scripts\remove_backend.ps1 [-DryRun]

param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    Write-Error "dart is required (comes with the Flutter SDK)."
  }

  $toolArgs = @()
  if ($DryRun) { $toolArgs += "--dry-run" }

  dart tools/remove_backend.dart @toolArgs
  exit $LASTEXITCODE
}
finally {
  Exit-RepoRoot
}
