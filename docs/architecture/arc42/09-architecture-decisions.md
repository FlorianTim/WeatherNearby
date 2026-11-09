# 09. Architekturentscheidungen

Detaillierte Architecture Decision Records (ADRs) liegen unter `docs/architecture/adr/`.

## Übersicht

| ADR | Titel | Status |
|-----|-------|--------|
| 0001 | Monorepo als Standard | Angenommen |
| 0002 | Feature-first-Struktur in Flutter | Angenommen |
| 0003 | Semantic Versioning und Conventional Commits | Angenommen |
| 0004 | Design-Artefakte mit Manifest-Versionierung | Angenommen |
| 0005 | Drafts als nicht-normative Quelle | Angenommen |
| 0006 | Dokumentationsquellen und generierte Dateien | Angenommen |
| 0007 | Diagramm-Rendering-Pipeline | Angenommen |

## Zusammenfassung der Schlüsselentscheidungen

- **Monorepo** statt Multi-Repo – gemeinsamer Kontext für App, Backend, Docs, Design
- **Feature-first** in der Flutter-App – fachliche statt technische Gliederung
- **Semantic Versioning** mit Conventional Commits – klare, automatisierbare Versionierung
- **Design-Manifest-Versionierung** – maschinenlesbare aktuelle Versionen
- **Drafts nicht-normativ** – keine explorativen Inhalte in Entscheidungen
- **Quell-/Ziel-Trennung** – generierte Docs klar von Quellen getrennt
- **Diagramm-Pipeline** – draw.io, PlantUML, Mermaid als reproduzierbare SVG-Builds
