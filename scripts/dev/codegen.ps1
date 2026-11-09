# Run ALL code generation (build_runner + gen-l10n) via melos. Thin wrapper
# around `melos run codegen` so agents have one obvious command and never
# forget the l10n step.
#
# Usage: .\scripts\dev\codegen.ps1

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  Invoke-Melos run codegen
  exit $LASTEXITCODE
}
finally {
  Exit-RepoRoot
}
