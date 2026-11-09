# Install git hooks for this repository.
# Usage:  .\scripts\install-hooks.ps1
#
#   pre-commit -> scripts/pre-commit.sh  (fast, format-only, path-aware)
#   pre-push   -> scripts/pre-push.sh    (full analyze + test, parallel)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  function Install-Hook($name, $target) {
    $hook = ".git/hooks/$name"
    $content = "#!/usr/bin/env bash`n# Installed by scripts/install-hooks.ps1`nexec ./scripts/$target `"`$@`"`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText((Resolve-Path ".").Path + "/$hook", $content, $utf8NoBom)
    Write-Host "$([char]0x2713) Git $name hook installed."
  }

  Install-Hook "pre-commit" "pre-commit.sh"
  Install-Hook "pre-push" "pre-push.sh"
}
finally {
  Exit-RepoRoot
}
