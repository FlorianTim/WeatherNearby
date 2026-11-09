<#
.SYNOPSIS
  Upgrade all pub dependencies across the monorepo.
.DESCRIPTION
  Runs `flutter pub upgrade --major-versions` / `dart pub upgrade --major-versions`
  in every project directory and widens version constraints in pubspec.yaml
  where necessary.
.EXAMPLE
  .\scripts\upgrade_deps.ps1
#>

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Get-RepoRoot

function Upgrade-Flutter([string]$Dir) {
    Write-Host ""
    Write-Host "--- flutter pub upgrade --major-versions: $Dir ---"
    Push-Location $Dir
    try { flutter pub upgrade --major-versions }
    finally { Pop-Location }
}

function Upgrade-Dart([string]$Dir) {
    Write-Host ""
    Write-Host "--- dart pub upgrade --major-versions: $Dir ---"
    Push-Location $Dir
    try { dart pub upgrade --major-versions }
    finally { Pop-Location }
}

# Mobile app
Upgrade-Flutter (Join-Path $RepoRoot "apps\mobile_app")

# Packages — use flutter or dart depending on whether the package uses the Flutter SDK
Get-ChildItem (Join-Path $RepoRoot "packages") -Directory | ForEach-Object {
    $pubspec = Join-Path $_.FullName "pubspec.yaml"
    if (Test-Path $pubspec) {
        $content = Get-Content $pubspec -Raw
        if ($content -match "sdk:\s*flutter") {
            Upgrade-Flutter $_.FullName
        }
        else {
            Upgrade-Dart $_.FullName
        }
    }
}

# Backend API
if (Test-Path (Join-Path $RepoRoot "services\api")) {
  Upgrade-Dart (Join-Path $RepoRoot "services\api")
}

Write-Host ""
Write-Host "All dependencies upgraded. Review pubspec.yaml changes before committing."
Write-Host "Run 'flutter pub outdated' in each directory to check remaining constraints."
