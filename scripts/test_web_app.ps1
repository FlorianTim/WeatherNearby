# Start Flutter web app local development server.
#
# Usage:
#   .\scripts\test_web_app.ps1

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
Assert-DartSdk
Set-Location (Get-AppDir)

try {
  Write-Host "Starting Flutter web app on http://localhost:8080"
  Write-Host "Open your browser to manually test and take screenshots"
  Write-Host "Press Ctrl+C to stop the server"
  Write-Host ""

  # Start web server on port 8080
  flutter run -d web-server --web-port=8080
} finally {
  Exit-RepoRoot
}
