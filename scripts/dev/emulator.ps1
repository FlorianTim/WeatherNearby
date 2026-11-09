<#
.SYNOPSIS
  Create, start and stop Android emulators without opening Android Studio.
.DESCRIPTION
  Commands:
    list                       installed AVDs and their state
    create [name]              create an AVD (default name: template-api<API>)
                               -Api <level>      API level, default 35
                               -DeviceProfile <p> hardware profile, default pixel_7
                               -ListProfiles     list hardware profiles and exit
    start [name]               boot an AVD and wait until it is really usable
                               -Wipe             factory reset before boot
                               -Cold             cold boot, ignore the snapshot
                               -Headless         no emulator window (CI)
    wait                       wait for the attached device to finish booting
    stop [name|all]            shut the emulator down cleanly
    delete <name>              remove an AVD and its data

  Requires the Android SDK. "create" additionally needs the SDK Command-line
  Tools (Android Studio > SDK Manager > SDK Tools > Android SDK Command-line
  Tools) - the script says so if they are missing.
.EXAMPLE
  .\scripts\dev\emulator.ps1 create -Api 35 -DeviceProfile pixel_7
  .\scripts\dev\emulator.ps1 start template-api35 -Wipe
  .\scripts\dev\emulator.ps1 stop all
#>
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet("list", "create", "start", "wait", "stop", "delete")]
  [string]$Command,

  [Parameter(Position = 1)]
  [string]$Name,

  [int]$Api = 35,
  [string]$DeviceProfile = "pixel_7",
  [switch]$ListProfiles,
  [switch]$Wipe,
  [switch]$Cold,
  [switch]$Headless,
  [switch]$Yes
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

# ── SDK tool lookup ────────────────────────────────────────────────────────────

function Get-AndroidSdkRoot {
  foreach ($c in @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, "$env:LOCALAPPDATA\Android\Sdk")) {
    if ($c -and (Test-Path $c)) { return $c }
  }
  $adb = Get-AdbPath
  if ($adb) { return (Split-Path (Split-Path $adb -Parent) -Parent) }
  return $null
}

# cmdline-tools live under a version directory ("latest", "16.0", ...), so the
# lookup globs instead of hardcoding one layout.
function Get-SdkTool {
  param([string]$ToolName, [string[]]$RelativeDirs)
  $sdk = Get-AndroidSdkRoot
  if (-not $sdk) { return $null }
  foreach ($rel in $RelativeDirs) {
    foreach ($dir in @(Get-Item (Join-Path $sdk $rel) -ErrorAction SilentlyContinue)) {
      foreach ($ext in @(".exe", ".bat", ".cmd", "")) {
        $candidate = Join-Path $dir.FullName "$ToolName$ext"
        if (Test-Path $candidate -PathType Leaf) { return $candidate }
      }
    }
  }
  return $null
}

function Get-EmulatorBin { Get-SdkTool "emulator" @("emulator", "tools") }
function Get-AvdManagerBin { Get-SdkTool "avdmanager" @("cmdline-tools\*\bin", "tools\bin") }
function Get-SdkManagerBin { Get-SdkTool "sdkmanager" @("cmdline-tools\*\bin", "tools\bin") }

function Assert-CmdlineTools {
  if (-not (Get-AvdManagerBin)) {
    Write-Fail "avdmanager not found. Install it via Android Studio > SDK Manager > SDK Tools > Android SDK Command-line Tools (latest), then re-run."
  }
}

try {
  $emulator = Get-EmulatorBin
  if (-not $emulator) { Write-Fail "emulator binary not found. Install the Android SDK or set ANDROID_SDK_ROOT." }
  $adb = Get-AdbPath
  if (-not $adb) { Write-Fail "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT." }

  function Get-Avds {
    @(& $emulator -list-avds 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  }

  function Get-RunningEmulators {
    @(& $adb devices | Select-Object -Skip 1 |
      Where-Object { $_ -match '^emulator-\S+\s+device$' } |
      ForEach-Object { ($_ -split '\s+')[0] })
  }

  function Get-AvdNameOf {
    param([string]$Serial)
    (& $adb -s $Serial emu avd name 2>$null | Select-Object -First 1).Trim()
  }

  # Blocks until the device finished booting AND the package manager answers -
  # an emulator shows up in `flutter devices` long before installs actually work.
  function Wait-Boot {
    param([string]$Serial, [int]$TimeoutSec = 180)
    Write-Step "Waiting for $Serial to finish booting (up to ${TimeoutSec}s)"
    & $adb -s $Serial wait-for-device
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
      $booted = (& $adb -s $Serial shell getprop sys.boot_completed 2>$null | Out-String).Trim()
      if ($booted -eq "1") {
        $pm = (& $adb -s $Serial shell pm path android 2>$null | Out-String).Trim()
        if ($pm) {
          # Dismiss the lock screen so the app is visible right away.
          & $adb -s $Serial shell input keyevent 82 2>$null | Out-Null
          Write-Ok "$Serial is ready"
          return
        }
      }
      Start-Sleep -Seconds 3
    }
    Write-Fail "$Serial did not become ready within ${TimeoutSec}s."
  }

  switch ($Command) {

    "list" {
      Write-Step "Installed AVDs"
      $running = Get-RunningEmulators
      $avds = Get-Avds
      if ($avds.Count -eq 0) {
        Write-Info "none - create one with: .\scripts\dev\emulator.ps1 create"
      }
      foreach ($avd in $avds) {
        $state = "stopped"
        foreach ($serial in $running) {
          if ((Get-AvdNameOf $serial) -eq $avd) { $state = "running ($serial)" }
        }
        Write-Host ("  {0,-32} {1}" -f $avd, $state)
      }
    }

    "create" {
      Assert-CmdlineTools
      $avdmanager = Get-AvdManagerBin
      if ($ListProfiles) { & $avdmanager list device; break }

      if (-not $Name) { $Name = "template-api$Api" }
      $image = "system-images;android-$Api;google_apis;x86_64"

      if (Get-Avds | Where-Object { $_ -eq $Name }) {
        Write-Fail "AVD '$Name' already exists. Delete it first: .\scripts\dev\emulator.ps1 delete $Name"
      }

      $sdkmanager = Get-SdkManagerBin
      if ($sdkmanager) {
        Write-Step "Ensuring system image $image is installed"
        # Licences are accepted interactively on a fresh SDK; the piped "y"
        # keeps a repeat run from blocking on the already-accepted prompt.
        "y" | & $sdkmanager --install $image
        if ($LASTEXITCODE -ne 0) { Write-Fail "could not install $image" }
      } else {
        Write-Warn "sdkmanager not found - assuming $image is already installed."
      }

      Write-Step "Creating AVD '$Name' ($DeviceProfile, API $Api)"
      "no" | & $avdmanager create avd --name $Name --package $image --device $DeviceProfile --force
      if ($LASTEXITCODE -ne 0) { Write-Fail "avdmanager could not create '$Name'." }
      Write-Ok "AVD '$Name' created - start it with: .\scripts\dev\emulator.ps1 start $Name"
    }

    "start" {
      $avds = Get-Avds
      if (-not $Name) {
        if ($avds.Count -eq 0) { Write-Fail "no AVD available. Create one: .\scripts\dev\emulator.ps1 create" }
        $Name = $avds[0]
        Write-Info "no name given, using '$Name'"
      }
      if (-not ($avds -contains $Name)) {
        Write-Fail "unknown AVD '$Name'. See: .\scripts\dev\emulator.ps1 list"
      }

      $before = Get-RunningEmulators

      $flags = [System.Collections.Generic.List[string]]::new()
      $flags.Add("-avd"); $flags.Add($Name)
      if ($Wipe) { $flags.Add("-wipe-data") }
      if ($Cold) { $flags.Add("-no-snapshot-load") }
      if ($Headless) { $flags.AddRange([string[]]@("-no-window", "-no-audio", "-gpu", "swiftshader_indirect")) }

      # Skip the leading "-avd <name>" - the name is already in the message.
      Write-Step "Booting '$Name' $(($flags | Select-Object -Skip 2) -join ' ')"
      # The emulator outlives this script (like Android Studio's runner), but
      # its output is kept: a failed launch dies within a second and the reason
      # is only in there - "PANIC: Cannot find AVD system path", a missing
      # system image, a busy port.
      $emuLog = [System.IO.Path]::GetTempFileName()
      $proc = Start-Process -FilePath $emulator -ArgumentList $flags `
        -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $emuLog -RedirectStandardError "$emuLog.err"

      function Show-EmulatorLog {
        foreach ($f in @($emuLog, "$emuLog.err")) {
          if (Test-Path $f) {
            Get-Content $f -Tail 15 | ForEach-Object { Write-Host "    $_" }
          }
        }
      }
      function Remove-EmulatorLog {
        Remove-Item $emuLog, "$emuLog.err" -ErrorAction SilentlyContinue
      }

      Write-Step "Waiting for the emulator to register with adb"
      $serial = $null
      $deadline = (Get-Date).AddSeconds(120)
      while ((Get-Date) -lt $deadline) {
        $new = @(Get-RunningEmulators | Where-Object { $before -notcontains $_ })
        if ($new.Count -gt 0) { $serial = $new[0]; break }
        # Fail fast instead of waiting out the timeout on a launch that is over.
        if ($proc.HasExited) {
          Write-Warn "the emulator process exited immediately. Its output:"
          Show-EmulatorLog
          Remove-EmulatorLog
          Write-Fail "'$Name' could not start. A missing system image is the usual cause - open Android Studio > Device Manager and check the AVD, or recreate it: .\scripts\dev\emulator.ps1 create"
        }
        Start-Sleep -Seconds 2
      }
      if (-not $serial) {
        Show-EmulatorLog
        Remove-EmulatorLog
        Write-Fail "emulator did not show up in 'adb devices' within 120s."
      }
      Remove-EmulatorLog

      Wait-Boot -Serial $serial
      Write-Info "run the app on it with: .\scripts\dev\adb.ps1 run -Device $serial"
    }

    "wait" {
      Wait-Boot -Serial (Get-AdbDevice)
    }

    "stop" {
      $target = if ($Name) { $Name } else { "all" }
      $stopped = 0
      foreach ($serial in Get-RunningEmulators) {
        $avd = Get-AvdNameOf $serial
        if ($target -eq "all" -or $target -eq $avd -or $target -eq $serial) {
          & $adb -s $serial emu kill 2>$null | Out-Null
          Write-Ok "stopped $avd ($serial)"
          $stopped++
        }
      }
      if ($stopped -eq 0) { Write-Info "no matching emulator was running" }
    }

    "delete" {
      Assert-CmdlineTools
      if (-not $Name) { Write-Fail "usage: emulator.ps1 delete <name>" }
      if (-not (Confirm-Action "Delete AVD '$Name' including all its data?" -AssumeYes:$Yes)) {
        Write-Fail "aborted."
      }
      & (Get-AvdManagerBin) delete avd --name $Name
      Write-Ok "AVD '$Name' deleted"
    }
  }
}
finally {
  Exit-RepoRoot
}
