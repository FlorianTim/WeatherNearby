# Requirements

## Purpose

This document describes overarching product requirements, quality requirements, and constraints.
Detailed feature requirements live in `docs/product/specs/<feature>/requirements.md`.

## Global product requirements

- TODO: Add general functional requirements here.

## Quality requirements

- Stability and crash-freedom take priority.
- Offline capability where technically feasible.
- Performant UI interactions (no perceivable delays).
- Accessibility at a minimum baseline level (sufficient contrast, screen reader labels).

## Constraints

- Flutter as the primary mobile technology.
- Monorepo structure (see ADR-0001).
- Feature-first architecture (see ADR-0002).
- SemVer + Conventional Commits (see ADR-0003).

## Test and validation expectations

- Every functional change should be tested.
- Widget tests for UI logic.
- Unit tests for business logic.
- Integration tests for critical user flows.
- `flutter analyze` must pass without errors.

## References

- Feature-specific requirements: `docs/product/specs/<NNNN-feature>/requirements.md`
- Architecture quality requirements: `docs/architecture/arc42/10-quality-requirements.md`
