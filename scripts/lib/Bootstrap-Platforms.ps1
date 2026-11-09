# Shared PowerShell function to (re)generate Flutter platform folders SAFELY.
#
# IMPORTANT: never run `flutter create . --overwrite` inside apps/mobile_app —
# it overwrites pubspec.yaml (all dependencies gone), lib/main.dart,
# test/widget_test.dart, README.md, analysis_options.yaml and .gitignore.
#
# Instead, `flutter create` runs in a throw-away temp directory and ONLY the
# requested platform folders (android/, web/, linux/, ...) are copied into
# apps/mobile_app. All app files stay untouched.
#
# Usage:
#   . scripts/lib/Read-ProjectEnv.ps1
#   . scripts/lib/Bootstrap-Platforms.ps1
#   $config = Read-ProjectEnv -EnvFilePath $EnvFile
#   Invoke-PlatformBootstrap -RepoRoot $RepoRoot -Org $config['ORG'] `
#     -ProjectName $config['PROJECT_NAME'] -Platforms "android,web"

function Invoke-PlatformBootstrap {
  param(
    [Parameter(Mandatory)] [string]$RepoRoot,
    [Parameter(Mandatory)] [string]$Org,
    [Parameter(Mandatory)] [string]$ProjectName,
    [Parameter(Mandatory)] [string]$Platforms
  )

  $projectDir = Join-Path $RepoRoot "apps\mobile_app"

  if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter is not installed or not on PATH."
    return
  }

  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) `
    ("flutter_bootstrap_" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Path $tmp | Out-Null

  try {
    Write-Host "Generating platforms [$Platforms] for org=$Org project_name=$ProjectName"
    Push-Location $tmp
    try {
      flutter create --org $Org --project-name $ProjectName --platforms=$Platforms app
      if ($LASTEXITCODE -ne 0) { throw "flutter create failed (exit $LASTEXITCODE)." }
    } finally {
      Pop-Location
    }

    $hasAndroid = $false
    foreach ($p in ($Platforms -split ',')) {
      $p = $p.Trim()
      $dest = Join-Path $projectDir $p
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse (Join-Path $tmp "app\$p") $dest
      Write-Host "  refreshed $p/"
      if ($p -eq "android") { $hasAndroid = $true }
    }

    # The generated android/ carries Flutter's white launch screen and no
    # backup policy. Put the Android-only branding resources back in place -
    # everything Flutter can do itself stays with Flutter.
    if ($hasAndroid) {
      . (Join-Path $RepoRoot "scripts\lib\Apply-AndroidBranding.ps1")
      Invoke-AndroidBranding -RepoRoot $RepoRoot
    }
  } finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  }

  Push-Location $projectDir
  try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed (exit $LASTEXITCODE)." }
  } finally {
    Pop-Location
  }
}
