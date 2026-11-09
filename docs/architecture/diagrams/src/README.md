# Diagram Sources

This directory contains the source files for architecture diagrams.

## Structure

```
src/
├── drawio/       draw.io / diagrams.net files (.drawio)
├── plantuml/     PlantUML files (.puml)
└── mermaid/      Mermaid files (.mmd)
```

## Rendering

Run `./scripts/automation/docs/render_diagrams.sh` to generate SVGs from all sources.

Generated output goes to `docs/architecture/generated/diagrams/`.

## Adding new diagrams

1. Place the source file in the appropriate subfolder.
2. Run the render script or wait for CI to generate the SVGs.
3. Reference the generated SVG in arc42 chapters:
   ```markdown
   ![Context diagram](../generated/diagrams/context.svg)
   ```
