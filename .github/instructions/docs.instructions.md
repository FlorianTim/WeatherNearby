---
name: Documentation conventions
description: Rules for architecture, product, and operational docs
applyTo: "docs/**/*.md,docs/**/*.yaml,design/**/*.md,drafts/**/*.md"
---
# Documentation conventions

- Keep architecture and operational docs concise but explicit.
- Use German for product and architecture notes unless the file already uses English.
- Record architecture decisions as ADRs in `docs/architecture/adr/`.
- ADR filenames: `NNNN-slug.md` (e.g. `0003-semver-conventional-commits.md`).
- Keep drafts in `drafts/`; do not move draft content into `docs/` until it is stable.
- Prefer Markdown tables only when they genuinely improve readability.
- `12-glossary.md` is generated from `glossary.csv` — edit the CSV, not the Markdown.
- Files under `docs/architecture/generated/` are build outputs — do not edit directly.
- Diagram sources live in `docs/architecture/diagrams/src/`.

## Idea and spec workflow

- Raw ideas live in `docs/ideas/simple/ideas.md`. They are input, not implementation orders.
- Do not implement code from raw ideas.
- Feature specs live in `docs/product/specs/<NNNN-feature-name>/`.
- Specs are the authoritative source for feature scope, requirements, and acceptance criteria.
- arc42 is architecture documentation, not a backlog.
- Update arc42 only for architecture-relevant changes.
- Open questions belong in `open-questions.md` within the spec folder.
- Assumptions must be explicitly documented.
- Acceptance criteria should be testable and verifiable.
- Changes to documentation should be traceable (linked to spec, story, or ADR).
