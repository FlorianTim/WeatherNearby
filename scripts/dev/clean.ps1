<#
.SYNOPSIS
  Clean local build output and caches. Runs from anywhere - the shared helper
  switches to the repository root first.
.DESCRIPTION
  Targets (default: build):
    build       build/, .dart_tool/, coverage/ in every package  (safe, cheap)
    deep        build + native caches: android\.gradle, ios\Pods, .symlinks,
                desktop build dirs, .flutter-plugins*             (safe, slow to rebuild)
    generated   delete generated Dart sources (*.g.dart, *.freezed.dart,
                l10n\generated) and re-run codegen                (needs Flutter)
    docker      stop compose services and drop volumes (scripts\docker-cleanup.ps1)
    all         build + deep + docker
.EXAMPLE
  .\scripts\dev\clean.ps1                       # everyday cleanup
  .\scripts\dev\clean.ps1 deep -Restore         # full reset before a fresh build
  .\scripts\dev\clean.ps1 generated             # rebuild all generated sources
  .\scripts\dev\clean.ps1 all -DryRun
#>
param(
  [ValidateSet("build", "deep", "generated", "docker", "all")]
  [string[]]$Target = @("build"),
  [switch]$DryRun,
  [switch]$Restore,
  [switch]$Yes
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

$script:Removed = 0

# Package roots we ever clean inside. Deliberately explicit: a blind recursive
# search for "build" would also hit node_modules and Flutter's own SDK cache.
function Get-PackageRoots {
  $roots = [System.Collections.Generic.List[string]]::new()
  $roots.Add($RepoRoot)
  foreach ($group in @("apps", "packages", "services")) {
    $dir = Join-Path $RepoRoot $group
    if (Test-Path $dir) {
      Get-ChildItem $dir -Directory | ForEach-Object { $roots.Add($_.FullName) }
    }
  }
  return $roots
}

function Remove-Target {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $rel = $Path.Replace("$RepoRoot\", "")
  if ($DryRun) {
    Write-Info "would remove $rel"
  } else {
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    Write-Info "removed $rel"
  }
  $script:Removed++
}

function Clear-BuildOutput {
  Write-Step "Removing build output and Dart tool caches"
  foreach ($root in Get-PackageRoots) {
    Remove-Target (Join-Path $root "build")
    Remove-Target (Join-Path $root ".dart_tool")
    Remove-Target (Join-Path $root "coverage")
  }
}

function Clear-NativeCaches {
  Clear-BuildOutput
  Write-Step "Removing native build caches"
  $app = Get-AppDir
  foreach ($rel in @(
      "android\.gradle", "android\build", "android\app\build",
      "ios\Pods", "ios\.symlinks", "macos\Pods", "macos\.symlinks",
      "windows\build", "linux\build",
      ".flutter-plugins", ".flutter-plugins-dependencies")) {
    Remove-Target (Join-Path $app $rel)
  }
}

function Clear-GeneratedSources {
  Write-Step "Removing generated Dart sources"
  Write-Warn "Generated sources are committed - this only makes sense together with codegen."
  # Nothing is deleted on a dry run, so do not make it interactive.
  if (-not $DryRun -and
      -not (Confirm-Action "Delete all *.g.dart / *.freezed.dart / l10n output and regenerate?" -AssumeYes:$Yes)) {
    Write-Fail "aborted."
  }

  foreach ($root in Get-PackageRoots) {
    $lib = Join-Path $root "lib"
    if (-not (Test-Path $lib)) { continue }
    Get-ChildItem $lib -Recurse -File -Include "*.g.dart", "*.freezed.dart" |
      ForEach-Object { Remove-Target $_.FullName }
  }
  Remove-Target (Join-Path (Get-AppDir) "lib\core\l10n\generated")

  if ($DryRun) { Write-Info "would run: melos run codegen"; return }
  Write-Step "Regenerating (melos run codegen)"
  Invoke-Melos run codegen
  if ($LASTEXITCODE -ne 0) { Write-Fail "codegen failed - the deleted sources are still missing." }
}

function Clear-DockerResources {
  Write-Step "Cleaning Docker resources"
  if (-not (Test-Cmd docker)) { Write-Warn "docker not on PATH - skipping"; return }
  if ($DryRun) { Write-Info "would run: scripts\docker-cleanup.ps1"; return }
  & "$RepoRoot\scripts\docker-cleanup.ps1"
}

try {
  foreach ($t in $Target) {
    switch ($t) {
      "build" { Clear-BuildOutput }
      "deep" { Clear-NativeCaches }
      "generated" { Clear-GeneratedSources }
      "docker" { Clear-DockerResources }
      "all" { Clear-NativeCaches; Clear-DockerResources }
    }
  }

  if ($Restore -and -not $DryRun) {
    Write-Step "Restoring workspace (melos bs)"
    Invoke-Melos bs
  }

  Write-Host ""
  if ($DryRun) {
    Write-Ok "dry run finished - $($script:Removed) path(s) would be removed."
  } else {
    Write-Ok "clean finished - $($script:Removed) path(s) removed."
    if (-not $Restore) { Write-Info "Run 'melos bs' (or .\scripts\dev\clean.ps1 -Restore) before building again." }
  }
}
finally {
  Exit-RepoRoot
}
