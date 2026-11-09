<#
.SYNOPSIS
  Remove Docker resources created by the local generation services.
.EXAMPLE
  .\scripts\docker-cleanup.ps1          # stop containers, remove volumes
  .\scripts\docker-cleanup.ps1 -Prune   # also remove pulled images
#>
param(
    [switch]$Prune
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  Write-Host "Stopping containers and removing volumes..."
  docker compose down --remove-orphans -v

  if ($Prune) {
      Write-Host "Removing generation images..."
      $images = @(
          "python:3.12-slim"
          "pandoc/extra:latest"
          "rlespinasse/drawio-export:latest"
          "plantuml/plantuml:latest"
          "minlag/mermaid-cli:latest"
          "ghcr.io/cirruslabs/flutter:stable"
      )
      foreach ($img in $images) {
          $exists = docker image inspect $img 2>$null
          if ($LASTEXITCODE -eq 0) {
              docker rmi $img
              Write-Host "  Removed $img"
          }
      }
  }

  Write-Host "Docker cleanup complete."
}
finally {
  Exit-RepoRoot
}
