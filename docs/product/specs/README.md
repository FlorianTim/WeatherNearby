# Feature Specs

This directory contains feature specifications for larger features.

## Workflow

1. A feature candidate is identified in `docs/product/feature-candidates.md`.
2. On promotion, a dedicated folder is created: `docs/product/specs/<NNNN-feature-name>/`.
3. The spec is the authoritative source of truth for the feature.
4. Implementation does NOT happen directly from the spec — it happens from stories.

## ID scheme

Feature IDs follow the pattern: `0001-feature-name`, `0002-feature-name`, etc.

## Template

Templates for new specs are under `_template/`.

## Spec maturity (when is a spec ready for planning?)

- [ ] Goals clear
- [ ] Non-goals clear
- [ ] Acceptance criteria present
- [ ] Test requirements present
- [ ] Open questions documented
- [ ] Architecture impact reviewed or explicitly excluded
- [ ] Rough release plan present

## Relationship to existing structure

These specs complement existing documentation under `docs/product/` (vision.md, roadmap.md).
They do not replace it.
