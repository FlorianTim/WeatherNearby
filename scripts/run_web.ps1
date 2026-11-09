<#
.SYNOPSIS
  Run the Flutter web app locally (requires Flutter SDK on PATH).
.EXAMPLE
  .\scripts\run_web.ps1 chrome    # hot-reload dev build in Chrome
  .\scripts\run_web.ps1 firefox   # dev server on :8080, open in Firefox
  .\scripts\run_web.ps1 headless  # dev server on :8080, no browser window
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet("chrome", "firefox", "headless")]
    [string]$Mode
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot
Assert-DartSdk
Set-Location (Get-AppDir)

$Port = 8080

function Open-Browser {
    param([string]$Url, [string]$Browser)
    $browserPath = Get-Command $Browser -ErrorAction SilentlyContinue
    if ($browserPath) {
        Start-Process $Browser $Url
    }
    else {
        # Fall back to the Windows default browser
        Start-Process $Url
    }
}

try {
    switch ($Mode) {
        "chrome" {
            Write-Host "Starting app in Chrome (hot reload enabled)..."
            flutter run -d chrome
        }

        "firefox" {
            Write-Host "Starting Flutter dev server on http://localhost:$Port ..."
            $job = Start-Job -ScriptBlock {
                param($dir, $port)
                Set-Location $dir
                flutter run -d web-server --web-port=$port
            } -ArgumentList (Get-Location).Path, $Port

            # Give the dev server a moment to compile and bind
            Start-Sleep -Seconds 4

            Write-Host "Opening Firefox at http://localhost:$Port"
            Open-Browser "http://localhost:$Port" "firefox"

            Write-Host "   Flutter dev server running. Press Ctrl-C to stop."
            Receive-Job $job -Wait
        }

        "headless" {
            Write-Host "Starting Flutter web-server on http://localhost:$Port (no browser window)."
            Write-Host "   Example headless test with Chromium:"
            Write-Host "     chromium --headless --screenshot http://localhost:$Port"
            Write-Host "   Press Ctrl-C to stop."
            flutter run -d web-server --web-port=$Port
        }
    }
} finally {
    Exit-RepoRoot
}
