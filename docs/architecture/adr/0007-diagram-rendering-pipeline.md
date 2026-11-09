# ADR 0007: Diagramm-Rendering-Pipeline

## Status

Angenommen

## Kontext

Architekturdiagramme sollen versionierbar, reproduzierbar und CI-tauglich sein.
Verschiedene Diagrammformate werden benötigt.

## Entscheidung

### Unterstützte Formate

| Format | Quellordner | Docker-Image | Dateiendung |
|--------|-------------|-------------|-------------|
| draw.io | `diagrams/src/drawio/` | `rlespinasse/drawio-export:latest` | `.drawio` |
| PlantUML | `diagrams/src/plantuml/` | `plantuml/plantuml` | `.puml` |
| Mermaid | `diagrams/src/mermaid/` | `minlag/mermaid-cli:latest` | `.mmd` |

### Ausgabe

Alle generierten SVGs landen in `docs/architecture/generated/diagrams/`.

### Referenzierung

In arc42-Kapiteln:
```markdown
![Kontextdiagramm](../generated/diagrams/context.svg)
```

## Konsequenzen

### Positiv

- Diagramme versioniert als Text
- reproduzierbare SVG-Generierung per CI
- mehrere Diagrammformate unterstützt

### Negativ

- Docker erforderlich für Rendering
- Mermaid erfordert Headless-Browser im Container
