<#
.SYNOPSIS
  Run the Flutter app on Android (requires the Flutter SDK on PATH).
.DESCRIPTION
  Device and emulator plumbing lives in scripts\dev\adb.ps1 and
  scripts\dev\emulator.ps1 - this script is the two-step convenience path.
.EXAMPLE
  .\scripts\run_android.ps1 device      # hot reload on a connected device
  .\scripts\run_android.ps1 emulator    # boot an AVD, then run
  .\scripts\run_android.ps1 emulator Pixel_10
#>
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet("device", "emulator")]
  [string]$Target,

  [Parameter(Position = 1)]
  [string]$Name
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

# Interactive device picker over `adb devices`; returns the chosen serial.
# adb is the source of truth here - `flutter devices` needs JSON parsing and
# reports emulators as ready before their package manager is up.
function Select-Device {
  param([string]$Adb)
  $serials = @(& $Adb devices | Select-Object -Skip 1 |
    Where-Object { $_ -match '^\S+\s+device$' } |
    ForEach-Object { ($_ -split '\s+')[0] })

  if ($serials.Count -eq 0) { return $null }

  $labels = foreach ($s in $serials) {
    $model = (& $Adb -s $s shell getprop ro.product.model 2>$null | Out-String).Trim()
    "$model ($s)"
  }

  if ($serials.Count -eq 1) {
    Write-Info "Using $($labels[0])"
    return $serials[0]
  }

  Write-Host "Multiple devices found. Select one:"
  for ($i = 0; $i -lt $serials.Count; $i++) {
    Write-Host "  [$($i + 1)] $($labels[$i])"
  }
  $choice = [int](Read-Host "Enter number") - 1
  if ($choice -lt 0 -or $choice -ge $serials.Count) { Write-Fail "invalid selection." }
  return $serials[$choice]
}

try {
  if (-not (Test-Cmd flutter)) { Write-Fail "flutter not found. Install the Flutter SDK and put it on PATH." }
  Assert-DartSdk
  $adb = Get-AdbPath
  if (-not $adb) { Write-Fail "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT." }

  switch ($Target) {

    "device" {
      if ($Name) {
        $deviceId = $Name
      } else {
        Write-Step "Scanning for connected Android devices"
        Write-Info "(USB debugging must be enabled and the computer authorised.)"
        $deviceId = Select-Device -Adb $adb
        if (-not $deviceId) {
          Write-Fail "no Android device found. Connect one, or use: .\scripts\run_android.ps1 emulator"
        }
      }
    }

    "emulator" {
      # emulator.ps1 boots the AVD and waits until the package manager answers,
      # which is what makes the first install succeed instead of racing the boot.
      if ($Name) {
        & "$RepoRoot\scripts\dev\emulator.ps1" start $Name
      } else {
        & "$RepoRoot\scripts\dev\emulator.ps1" start
      }
      if ($LASTEXITCODE -ne 0) { Write-Fail "the emulator did not start." }
      $deviceId = Get-AdbDevice
    }
  }

  Write-Step "Starting the app on $deviceId (hot reload enabled)"
  Use-AndroidBuildWorkarounds
  Set-Location (Get-AppDir)
  # Exit code 0 = clean quit, non-zero = disconnected; both are acceptable.
  $ErrorActionPreference = "Continue"
  & flutter run -d $deviceId
}
finally {
  Exit-RepoRoot
}
