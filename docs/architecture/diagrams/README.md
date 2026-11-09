# Diagrams

Architecture diagrams are maintained as versionable source files and rendered to SVG.

## Source files

Place diagram sources under `src/`:

| Format | Folder | Extension |
|--------|--------|-----------|
| draw.io | `src/drawio/` | `.drawio` |
| PlantUML | `src/plantuml/` | `.puml` |
| Mermaid | `src/mermaid/` | `.mmd` |

## Rendering

```bash
./scripts/automation/docs/render_diagrams.sh
```

Output: `docs/architecture/generated/diagrams/*.svg`

## Recommended diagram types

- System context (Kontextdiagramm)
- Building block view (Bausteinsicht)
- Runtime view (Laufzeitsicht)
- Deployment view (Verteilungssicht)
