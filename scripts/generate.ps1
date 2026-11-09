<#
.SYNOPSIS
  Run documentation generation tasks locally via Docker.
.DESCRIPTION
  Uses docker compose services defined in docker-compose.yml.
.EXAMPLE
  .\scripts\generate.ps1              # all tasks
  .\scripts\generate.ps1 glossary     # glossary only
  .\scripts\generate.ps1 pdf          # PDF only
  .\scripts\generate.ps1 diagrams     # diagrams only
#>
param(
    [ValidateSet("all", "glossary", "pdf", "diagrams")]
    [string]$Task = "all"
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib\Common.ps1"
$RepoRoot = Enter-RepoRoot

try {
  function Run-Glossary { docker compose run --rm glossary }
  function Run-Pdf { docker compose run --rm pdf }
  function Run-Diagrams {
      docker compose run --rm diagrams-drawio
      docker compose run --rm diagrams-plantuml
    & sh scripts/automation/docs/render_mermaid_inner.sh
  }

  switch ($Task) {
      "glossary" { Run-Glossary }
      "pdf" { Run-Pdf }
      "diagrams" { Run-Diagrams }
      "all" {
          Run-Glossary
          Run-Pdf
          Run-Diagrams
          Write-Host ""
          Write-Host "All generation tasks finished."
      }
  }
}
finally {
  Exit-RepoRoot
}
