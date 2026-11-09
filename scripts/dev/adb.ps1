<#
.SYNOPSIS
  Talk to a connected Android device or emulator without remembering adb
  syntax. The application id comes from project.env, the device is picked
  automatically when only one is attached.
.DESCRIPTION
  Commands:
    devices                 list attached devices with model and API level
    install [-Release]      build the APK and install it on the device
    run [-Release]          flutter run on the resolved device (hot reload)
    logcat [-All|<tag>]     app-only logcat (default: this app's Flutter output)
    screenshot [file]       save a PNG (default: design\screenshots\<ts>.png)
    record [file]           screen recording, stop with Ctrl-C
    deeplink <uri>          open a deep link / custom scheme in the app
    permissions             show the app's runtime permission state
    grant <perm>            grant a runtime permission (e.g. POST_NOTIFICATIONS)
    revoke <perm>           revoke a runtime permission - the fastest way to
                            re-test the permission rationale flow
    clear                   wipe app data (fresh-install state, keeps the APK)
    uninstall               remove the app
    info                    application id, installed version, data dir
    shell [args...]         raw adb shell passthrough on the resolved device
.EXAMPLE
  .\scripts\dev\adb.ps1 install -Release
  .\scripts\dev\adb.ps1 logcat
  .\scripts\dev\adb.ps1 revoke POST_NOTIFICATIONS; .\scripts\dev\adb.ps1 clear
#>
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet("devices", "install", "run", "logcat", "screenshot", "record",
    "deeplink", "permissions", "grant", "revoke", "clear", "uninstall", "info", "shell")]
  [string]$Command,

  [Parameter(Position = 1, ValueFromRemainingArguments)]
  [string[]]$Extra = @(),

  [string]$Device,
  [switch]$Release,
  [switch]$All
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  $adb = Get-AdbPath
  if (-not $adb) { Write-Fail "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT." }

  if ($Device) { $env:ANDROID_SERIAL = $Device }

  if ($Command -ne "devices") {
    $serial = Get-AdbDevice
    $appId = Get-ApplicationId
  }

  # adb on the resolved device.
  function d { & $adb -s $serial @args }

  $shotDir = Join-Path $RepoRoot "design\screenshots"
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"

  switch ($Command) {

    "devices" {
      Write-Step "Attached devices"
      $serials = @(& $adb devices | Select-Object -Skip 1 |
        Where-Object { $_ -match '^\S+\s+device$' } |
        ForEach-Object { ($_ -split '\s+')[0] })
      if ($serials.Count -eq 0) {
        Write-Info "none - start one with .\scripts\dev\emulator.ps1 start"
      }
      foreach ($s in $serials) {
        $model = (& $adb -s $s shell getprop ro.product.model 2>$null).Trim()
        $api = (& $adb -s $s shell getprop ro.build.version.sdk 2>$null).Trim()
        $rel = (& $adb -s $s shell getprop ro.build.version.release 2>$null).Trim()
        Write-Host ("  {0,-24} {1} (Android {2}, API {3})" -f $s, $model, $rel, $api)
      }
    }

    "install" {
      Assert-DartSdk
      $mode = if ($Release) { "release" } else { "debug" }
      Write-Step "Building $mode APK"
      Push-Location (Get-AppDir)
      try { & flutter build apk "--$mode" } finally { Pop-Location }
      if ($LASTEXITCODE -ne 0) { Write-Fail "flutter build apk failed." }
      $apk = Join-Path (Get-AppDir) "build\app\outputs\flutter-apk\app-$mode.apk"
      if (-not (Test-Path $apk)) { Write-Fail "APK not found at $apk" }
      Write-Step "Installing on $serial"
      d install -r $apk
      Write-Ok "$appId installed"
    }

    "run" {
      Assert-DartSdk
      Write-Step "flutter run on $serial"
      Push-Location (Get-AppDir)
      try {
        if ($Release) { & flutter run -d $serial --release } else { & flutter run -d $serial }
      } finally { Pop-Location }
    }

    "logcat" {
      d logcat -c
      if ($All) {
        Write-Step "logcat (everything)"
        d logcat
      } elseif ($Extra.Count -gt 0) {
        Write-Step "logcat tag: $($Extra[0])"
        d logcat "$($Extra[0]):V" "*:S"
      } else {
        Write-Step "logcat for $appId (flutter + app tags, Ctrl-C to stop)"
        # Flutter writes to the "flutter" tag; app crashes land in
        # AndroidRuntime; everything else is silenced.
        d logcat "flutter:V" "FlutterJNI:V" "AndroidRuntime:E" "${appId}:V" "*:S"
      }
    }

    "screenshot" {
      $out = if ($Extra.Count -gt 0) { $Extra[0] } else { Join-Path $shotDir "$stamp.png" }
      New-Item -ItemType Directory -Force (Split-Path $out -Parent) | Out-Null
      # exec-out keeps the PNG binary intact; the pipeline must stay byte-exact.
      & $adb -s $serial exec-out screencap -p | Set-Content -LiteralPath $out -AsByteStream
      Write-Ok "saved $($out.Replace("$RepoRoot\", ''))"
    }

    "record" {
      $out = if ($Extra.Count -gt 0) { $Extra[0] } else { Join-Path $shotDir "$stamp.mp4" }
      New-Item -ItemType Directory -Force (Split-Path $out -Parent) | Out-Null
      $remote = "/sdcard/_rec_$PID.mp4"
      Write-Step "Recording - press Ctrl-C to stop"
      # screenrecord stops on Ctrl-C and flushes the file on the device; the
      # finally block is what still gets it off the device afterwards.
      try {
        d shell screenrecord $remote
      }
      finally {
        Start-Sleep -Seconds 1
        d pull $remote $out | Out-Null
        d shell rm -f $remote
        Write-Ok "saved $($out.Replace("$RepoRoot\", ''))"
      }
    }

    "deeplink" {
      if ($Extra.Count -lt 1) { Write-Fail "usage: adb.ps1 deeplink <uri>" }
      Write-Step "Opening $($Extra[0]) in $appId"
      d shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d $Extra[0] $appId
    }

    "permissions" {
      Write-Step "Runtime permissions of $appId"
      $dump = d shell dumpsys package $appId
      $inSection = $false
      foreach ($line in $dump) {
        if ($line -match 'runtime permissions:') { $inSection = $true; continue }
        if ($inSection) {
          if ($line -match '^\s*android\.permission') { Write-Host "  $($line.Trim())" }
          elseif ($line.Trim() -eq '') { break }
        }
      }
    }

    { $_ -in "grant", "revoke" } {
      if ($Extra.Count -lt 1) { Write-Fail "usage: adb.ps1 $Command <PERMISSION>" }
      $perm = $Extra[0]
      if ($perm -notlike "android.permission.*") { $perm = "android.permission.$perm" }
      d shell pm $Command $appId $perm
      Write-Ok "$Command $perm"
    }

    "clear" {
      d shell pm clear $appId
      Write-Ok "app data of $appId wiped"
    }

    "uninstall" {
      d uninstall $appId
      Write-Ok "$appId removed"
    }

    "info" {
      Write-Step "$appId on $serial"
      $version = (d shell dumpsys package $appId | Select-String "versionName" | Select-Object -First 1)
      if (-not $version) {
        Write-Info "not installed - run: .\scripts\dev\adb.ps1 install"
      } else {
        Write-Info "$($version.ToString().Trim())"
        Write-Info "data dir: /data/data/$appId"
      }
    }

    "shell" {
      d shell @Extra
    }
  }
}
finally {
  Exit-RepoRoot
}
