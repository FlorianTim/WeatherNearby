# 91. Anhang

## A. Verzeichnisstruktur

```
/
├── apps/mobile_app/       Flutter-App (Feature-first)
├── packages/              Wiederverwendbare Dart-/Flutter-Pakete
│   ├── app_core/          Konfiguration und Flavors
│   ├── design_system/     UI-Komponenten und Theme
│   ├── shared_models/     Geteilte Datenmodelle
│   ├── api_client/        API-Abstraktionen
│   └── feature_flags/     Feature-Flag-Verwaltung
├── services/api/          Dart-Backend (Shelf/Router)
├── docs/                  Langlebige Dokumentation
│   ├── architecture/      arc42, ADRs, Diagramme
│   ├── product/           Vision, Roadmap, Glossar
│   ├── api/               OpenAPI-Spezifikation
│   └── operations/        Runbooks, Signing, Releases
├── design/                Versionierte Design-Artefakte
├── drafts/                Nicht-normative Entwürfe
├── scripts/               Build- und Validierungsskripte
├── infra/                 Infrastruktur-Konfiguration
└── tools/                 Hilfswerkzeuge
```

## B. Diagramm-Quellen

Diagrammquellen liegen unter `docs/architecture/diagrams/src/`:

| Format | Ordner | Build-Ergebnis |
|--------|--------|---------------|
| draw.io | `src/drawio/` | `generated/diagrams/*.svg` |
| PlantUML | `src/plantuml/` | `generated/diagrams/*.svg` |
| Mermaid | `src/mermaid/` | `generated/diagrams/*.svg` |

## C. Build- und Render-Hinweise

### PDF-Generierung

```bash
./scripts/automation/docs/build_docs_pdf.sh
```

Verwendet `pandoc/extra:latest` Docker-Image. Konfiguration: `docs/architecture/pandoc/`.

### Diagramm-Generierung

```bash
./scripts/automation/docs/render_diagrams.sh
```

### Glossar-Generierung

```bash
./scripts/automation/docs/generate_glossary.sh
```

Quelle: `docs/architecture/glossary.csv` → Ziel: `docs/architecture/arc42/12-glossary.md`
