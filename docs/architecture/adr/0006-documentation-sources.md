# ADR 0006: Dokumentationsquellen und generierte Dateien

## Status

Angenommen

## Kontext

Das Projekt verwendet mehrere Dokumentationsformate und Generierungspipelines. Es muss
klar sein, welche Dateien Quellen und welche generiert sind.

## Entscheidung

### Quell-/Zielpaare

| Quelle | Generiert | Methode |
|--------|-----------|---------|
| `docs/architecture/glossary.csv` | `docs/architecture/arc42/12-glossary.md` | `scripts/automation/docs/generate_glossary.sh` |
| `docs/architecture/diagrams/src/` | `docs/architecture/generated/diagrams/` | `scripts/automation/docs/render_diagrams.sh` |
| `docs/architecture/arc42/*.md` + `adr/*.md` | `docs/architecture/generated/architecture.pdf` | `scripts/automation/docs/build_docs_pdf.sh` |

### Regeln

- Generierte Dateien liegen unter `docs/architecture/generated/`
- Generierte Dateien werden nicht als Quelle bearbeitet
- Generierte Dateien können in `.gitignore` stehen oder committet werden (projektabhängig)
- Die Quell-Dateien sind die einzige autoritative Bearbeitungsgrundlage

## Konsequenzen

### Positiv

- klare Trennung von Quell- und Build-Artefakten
- reproduzierbare Dokumentations-Builds
- kein Risiko, generierte Dateien versehentlich zu bearbeiten

### Negativ

- erfordert Build-Schritt für aktuelle generierte Dateien
