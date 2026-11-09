<#
.SYNOPSIS
  Shared helpers for every script under scripts/.
.DESCRIPTION
  Dot-source it as the FIRST statement of a script:

      . "$PSScriptRoot\..\lib\Common.ps1"
      $RepoRoot = Enter-RepoRoot
      try { ... } finally { Exit-RepoRoot }

  Enter-RepoRoot pushes the repository root onto the location stack, so every
  relative path inside a script is root-relative regardless of where the user
  invoked it from. Exit-RepoRoot restores the caller's directory - important
  because .ps1 scripts run inside the caller's session, where a stray
  Set-Location would leak.

  Provides: logging (Write-Step/Ok/Warn/Fail), Test-Cmd, Confirm-Action,
  Get-AppDir, Get-ProjectEnv, Get-ApplicationId, Invoke-Melos, Get-AdbPath,
  Get-AdbDevice, Use-AndroidBuildWorkarounds.
#>

# ── location ───────────────────────────────────────────────────────────────────

# scripts/lib/Common.ps1 -> repo root is two levels up. Works without git too
# (exported template copies, archives, containers).
function Get-RepoRoot {
  (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

# A NAMED location stack keeps this isolated from any Push-Location the caller
# is using, and the flag makes Exit-RepoRoot idempotent - Write-Fail restores
# the location before exiting, and the script's own finally block runs too.
$script:RepoRootPushed = $false

function Enter-RepoRoot {
  $root = Get-RepoRoot
  Push-Location $root -StackName 'RepoRoot'
  $script:RepoRootPushed = $true
  return $root
}

function Exit-RepoRoot {
  Restore-AndroidBuildEnv
  if (-not $script:RepoRootPushed) { return }
  $script:RepoRootPushed = $false
  Pop-Location -StackName 'RepoRoot' -ErrorAction SilentlyContinue
}

# ── logging ────────────────────────────────────────────────────────────────────

function Write-Step { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Blue }
function Write-Ok   { param([string]$Message) Write-Host "  OK $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "warn $Message" -ForegroundColor Yellow }
function Write-Info { param([string]$Message) Write-Host "     $Message" -ForegroundColor DarkGray }
function Write-Fail {
  param([string]$Message)
  Write-Host "ERROR $Message" -ForegroundColor Red
  Exit-RepoRoot
  exit 1
}

# ── tooling ────────────────────────────────────────────────────────────────────

function Test-Cmd {
  param([string]$Name)
  [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Confirm-Action {
  param([string]$Question, [switch]$AssumeYes)
  if ($AssumeYes -or $env:ASSUME_YES -eq '1') { return $true }
  # Read-Host against redirected input returns empty, which would read as a
  # silent "no" - say so instead, matching confirm() in common.sh.
  if ([Console]::IsInputRedirected) {
    Write-Warn "non-interactive session, assuming 'no' for: $Question (use -Yes to proceed)"
    return $false
  }
  $reply = Read-Host "$Question [y/N]"
  return $reply -match '^[Yy]'
}

# ── project layout / identity ──────────────────────────────────────────────────

# The Flutter app directory. Constant by convention; kept as a function so
# call sites stay readable and a future move is a one-line change.
function Get-AppDir {
  Join-Path (Get-RepoRoot) "apps\mobile_app"
}

function Get-ProjectEnv {
  . (Join-Path $PSScriptRoot "Read-ProjectEnv.ps1")
  $config = Read-ProjectEnv -EnvFilePath (Join-Path (Get-RepoRoot) "project.env")
  if (-not $config) { Write-Fail "could not read project.env" }
  return $config
}

function Get-ApplicationId {
  $config = Get-ProjectEnv
  return "$($config['ORG']).$($config['PROJECT_NAME'])"
}

# Fails early when the Dart SDK on PATH is older than the workspace requires.
# Without this, pub reports a bare "version solving failed", which sends the
# reader looking at the dependencies instead of at their shell - the usual
# cause is a terminal whose PATH still points at a previous SDK install.
function Assert-DartSdk {
  if (-not (Test-Cmd dart)) {
    Write-Fail "dart not found on PATH. Install the Flutter SDK (it ships dart)."
  }

  $versionPattern = '[0-9]+\.[0-9]+\.[0-9]+'
  $sdkLine = Select-String -Path (Join-Path (Get-RepoRoot) "pubspec.yaml") `
    -Pattern '^\s*sdk:' | Select-Object -First 1
  $required = if ($sdkLine -match $versionPattern) { $Matches[0] } else { $null }
  $current = if ((& dart --version 2>&1 | Out-String) -match $versionPattern) { $Matches[0] } else { $null }

  # Unparseable on either side: say nothing and let pub speak.
  if (-not $required -or -not $current) { return }

  if ([version]$current -lt [version]$required) {
    Write-Warn "Dart $current is older than the $required this workspace requires."
    Write-Info "dart:    $((Get-Command dart).Source)"
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    Write-Info "flutter: $(if ($flutter) { $flutter.Source } else { 'not on PATH' })"
    Write-Fail "Open a fresh terminal (an old one keeps the PATH it started with), or upgrade the SDK: .\scripts\deps\flutter_upgrade.ps1"
  }
}

function Invoke-Melos {
  param([Parameter(ValueFromRemainingArguments)] [string[]]$MelosArgs)
  if (Test-Cmd melos) { & melos @MelosArgs } else { & dart run melos @MelosArgs }
}

# ── android ────────────────────────────────────────────────────────────────────

# Two host-specific Gradle startup problems seen on Windows, both fixed
# process-locally so the caller's shell stays untouched (Exit-RepoRoot
# restores the previous values):
#
# 1. JDK 16+ backs every NIO Selector (and therefore the Gradle client/daemon
#    connection) with an AF_UNIX socket file in java.io.tmpdir. Endpoint
#    security that refuses socket files under %LOCALAPPDATA% makes every
#    Gradle start die with "Unable to establish loopback connection".
#    Relocating that one directory is harmless elsewhere.
# 2. A GRADLE_USER_HOME reached through directory junctions (Scoop's
#    `apps\gradle-bin\current\.gradle`) breaks Kotlin DSL script compilation
#    with "Unresolved reference" errors, because the script classpath is
#    resolved against the canonical distribution path. Resolving the
#    junctions before Gradle starts is enough.
$script:SavedEnv = @{}

function Save-EnvOnce {
  param([string]$Name)
  if (-not $script:SavedEnv.ContainsKey($Name)) {
    $script:SavedEnv[$Name] = [Environment]::GetEnvironmentVariable($Name)
  }
}

# Follows every junction/symlink in a path (any segment), returns the real path.
function Resolve-LinkPath {
  param([string]$Path)
  $resolved = $Path
  for ($i = 0; $i -lt 8; $i++) {
    $item = Get-Item -LiteralPath $resolved -Force -ErrorAction SilentlyContinue
    if (-not $item) { return $Path }
    $target = $null
    $node = $item
    while ($node -and -not $target) {
      if ($node.LinkType) { $target = $node.ResolveLinkTarget($true).FullName }
      else { $node = $node.Parent }
    }
    if (-not $target) { return $item.FullName }
    $resolved = if ($node.FullName -eq $item.FullName) { $target }
                else { Join-Path $target $item.FullName.Substring($node.FullName.Length + 1) }
  }
  return $resolved
}

function Use-AndroidBuildWorkarounds {
  if (-not $IsWindows -and $env:OS -ne 'Windows_NT') { return }
  if ($env:JAVA_TOOL_OPTIONS -notmatch 'jdk\.net\.unixdomain\.tmpdir') {
    $dir = Join-Path $env:USERPROFILE ".java-ipc"
    New-Item -ItemType Directory -Force $dir | Out-Null
    Save-EnvOnce JAVA_TOOL_OPTIONS
    $flag = "-Djdk.net.unixdomain.tmpdir=$dir"
    $env:JAVA_TOOL_OPTIONS = if ($env:JAVA_TOOL_OPTIONS) { "$env:JAVA_TOOL_OPTIONS $flag" } else { $flag }
  }
  if ($env:GRADLE_USER_HOME) {
    $real = Resolve-LinkPath $env:GRADLE_USER_HOME
    if ($real -ne $env:GRADLE_USER_HOME) {
      Write-Info "GRADLE_USER_HOME resolved to $real (junction-free) for this build"
      Save-EnvOnce GRADLE_USER_HOME
      $env:GRADLE_USER_HOME = $real
      # A daemon started by a bare `flutter build` still holds the junction
      # path and would be reused with the same broken script classpath.
      # Only when this project's wrapper distribution is already cached -
      # `gradlew --stop` would otherwise download it first.
      $wrapper = Join-Path (Get-AppDir) "android\gradlew.bat"
      $props = Join-Path (Get-AppDir) "android\gradle\wrapper\gradle-wrapper.properties"
      if ((Test-Path $wrapper) -and (Test-Path $props) -and (Test-Path (Join-Path $real "daemon"))) {
        $url = (Get-Content $props | Where-Object { $_ -like 'distributionUrl=*' }) -replace '^distributionUrl=', ''
        $dist = [IO.Path]::GetFileNameWithoutExtension(($url -split '/')[-1])
        if ($dist -and (Test-Path (Join-Path $real "wrapper\dists\$dist"))) {
          & $wrapper --stop --quiet 2>&1 | Out-Null
        }
      }
    }
  }
}

function Restore-AndroidBuildEnv {
  foreach ($name in @($script:SavedEnv.Keys)) {
    [Environment]::SetEnvironmentVariable($name, $script:SavedEnv[$name])
  }
  $script:SavedEnv = @{}
}

# Returns the path to adb, searching PATH and the usual SDK locations.
function Get-AdbPath {
  $onPath = Get-Command adb -ErrorAction SilentlyContinue
  if ($onPath) { return $onPath.Source }
  $candidates = @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, "$env:LOCALAPPDATA\Android\Sdk") |
    Where-Object { $_ } |
    ForEach-Object { Join-Path $_ "platform-tools\adb.exe" }
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }
  return $null
}

# Returns the target device serial: $env:ANDROID_SERIAL if set, the only
# attached device, or fails with a hint when several are attached.
function Get-AdbDevice {
  $adb = Get-AdbPath
  if (-not $adb) { Write-Fail "adb not found. Install Android platform-tools or set ANDROID_SDK_ROOT." }
  if ($env:ANDROID_SERIAL) { return $env:ANDROID_SERIAL }

  $serials = @(& $adb devices |
    Select-Object -Skip 1 |
    Where-Object { $_ -match '^\S+\s+device$' } |
    ForEach-Object { ($_ -split '\s+')[0] })

  if ($serials.Count -eq 0) {
    Write-Fail "no Android device attached. Start an emulator (scripts\dev\emulator.ps1 start) or connect a device."
  }
  if ($serials.Count -gt 1) {
    Write-Warn "several devices attached: $($serials -join ', ')"
    Write-Fail "pick one with `$env:ANDROID_SERIAL=<serial> or -Device <serial>."
  }
  return $serials[0]
}
