<#
.SYNOPSIS
  Produce app screenshots - either by hand from a running device/emulator, or
  automatically from the screenshot integration test.
.DESCRIPTION
  The full walkthrough (store sizes, which route to pick, how to add a new
  screenshot step) is in docs\operations\screenshots.md.

  Commands:
    capture <name>      grab the current screen from the attached device into
                        design\screenshots\<profile>\<name>.png
                        -ProfileName <p> subfolder, default: the device model
                        -Delay <sec>   wait before grabbing
    auto                run the screenshot integration test (all profiles from
                        scripts\automation\integration-test\profiles.json) and
                        collect the results into design\screenshots\
    list                show what has been captured so far
    clean               delete everything under design\screenshots\
.EXAMPLE
  .\scripts\dev\screenshots.ps1 capture 01-greeting -Delay 3
  .\scripts\dev\screenshots.ps1 auto
#>
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet("capture", "auto", "list", "clean")]
  [string]$Command,

  [Parameter(Position = 1)]
  [string]$Name,

  [string]$ProfileName,
  [int]$Delay = 0,
  [switch]$Yes
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  $shotDir = Join-Path $RepoRoot "design\screenshots"
  $testResults = Join-Path (Get-AppDir) "test_results\screenshots"

  switch ($Command) {

    "capture" {
      if (-not $Name) { Write-Fail "usage: screenshots.ps1 capture <name>" }
      $adb = Get-AdbPath
      if (-not $adb) { Write-Fail "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT." }
      $serial = Get-AdbDevice

      if (-not $ProfileName) {
        # Device model as a slug, so shots from different form factors stay apart.
        $model = (& $adb -s $serial shell getprop ro.product.model 2>$null | Out-String).Trim()
        $ProfileName = ($model.ToLower() -replace '\s+', '_' -replace '[^a-z0-9_-]', '')
        if (-not $ProfileName) { $ProfileName = "device" }
      }

      if ($Delay -gt 0) {
        Write-Step "Capturing in ${Delay}s - bring the right screen up now"
        Start-Sleep -Seconds $Delay
      }

      $out = Join-Path $shotDir $ProfileName "$Name.png"
      New-Item -ItemType Directory -Force (Split-Path $out -Parent) | Out-Null
      # exec-out keeps the PNG binary intact; the pipeline must stay byte-exact.
      & $adb -s $serial exec-out screencap -p | Set-Content -LiteralPath $out -AsByteStream
      $size = (& $adb -s $serial shell wm size 2>$null | Out-String).Trim()
      Write-Ok "$($out.Replace("$RepoRoot\", '')) ($size)"
    }

    "auto" {
      Write-Step "Running the screenshot integration test"
      Write-Info "This drives the app through integration_test\app_screenshots_test.dart"
      Write-Info "for every profile in scripts\automation\integration-test\profiles.json."
      if (Test-Cmd docker) {
        & "$RepoRoot\scripts\build.ps1" integration-web
      } else {
        Write-Fail "docker not found. Install Docker Desktop, or run the web tests directly: bash scripts/automation/integration-test/run_web_tests.sh"
      }

      if (-not (Test-Path $testResults)) { Write-Fail "no screenshots produced in $testResults" }
      Write-Step "Collecting into design\screenshots"
      New-Item -ItemType Directory -Force $shotDir | Out-Null
      Copy-Item "$testResults\*" $shotDir -Recurse -Force
      $count = @(Get-ChildItem $shotDir -Recurse -Filter *.png).Count
      Write-Ok "collected $count screenshot(s)"
    }

    "list" {
      Write-Step "design\screenshots"
      $files = @(Get-ChildItem $shotDir -Recurse -Filter *.png -ErrorAction SilentlyContinue)
      if ($files.Count -eq 0) {
        Write-Info "none yet - see docs\operations\screenshots.md"
        break
      }
      foreach ($f in $files | Sort-Object FullName) {
        Write-Host "  $($f.FullName.Replace("$shotDir\", ''))"
      }
    }

    "clean" {
      if (-not (Confirm-Action "Delete every screenshot under design\screenshots\?" -AssumeYes:$Yes)) {
        Write-Fail "aborted."
      }
      if (Test-Path $shotDir) {
        # .gitkeep is what keeps the directory in git - never sweep it away.
        Get-ChildItem $shotDir -Force |
          Where-Object { $_.Name -ne '.gitkeep' } |
          Remove-Item -Recurse -Force
      }
      Write-Ok "screenshots removed"
    }
  }
}
finally {
  Exit-RepoRoot
}
