<#
.SYNOPSIS
  Generate 12-glossary.md from glossary.csv
.DESCRIPTION
  Reads docs/architecture/glossary.csv and produces docs/architecture/arc42/12-glossary.md
#>
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$Csv = Join-Path $RepoRoot "docs\architecture\glossary.csv"
$Out = Join-Path $RepoRoot "docs\architecture\arc42\12-glossary.md"

if (-not (Test-Path $Csv)) {
  Write-Error "ERROR: $Csv not found"
  exit 1
}

$header = @"
# 12. Glossar

> **Hinweis:** Diese Datei wird automatisch aus ``docs/architecture/glossary.csv`` generiert.
> Bearbeite die CSV-Datei, nicht dieses Markdown.

| Begriff | Definition | Kontext | Quelle | Aliase |
|---------|-----------|---------|--------|--------|
"@

$rows = Import-Csv -Path $Csv | Where-Object { $_.status -eq "accepted" -or $_.status -eq "" } | ForEach-Object {
  "| $($_.term) | $($_.definition) | $($_.context) | $($_.source) | $($_.aliases) |"
}

$date = Get-Date -Format "yyyy-MM-dd"
$footer = @"

---

*Generiert am $date aus ``docs/architecture/glossary.csv``.*
"@

$content = $header + "`n" + ($rows -join "`n") + "`n" + $footer
Set-Content -Path $Out -Value $content -Encoding UTF8

Write-Host "Generated: $Out"
