# Example: Export Data — Define Export Format

This example shows how a Copilot task issue should look.

---

## Feature

`docs/product/specs/0002-export-data/`

## Story

`docs/delivery/stories/0002-export-data/story-001-define-export-format.md`

## Goal

Define the first versioned export format for app data.

## Context

The export feature spec describes that users should be able to export app data.
This story covers only the format definition — no UI, no import.

## Scope

- Define export DTOs or data structure
- Add version field
- Document serialization (in data-contract.md of the spec)
- Add tests for empty and example data

## Out of Scope

- UI
- Android Share Sheet
- Import
- Encryption
- Cloud Sync

## Relevant files

- `packages/shared_models/lib/src/` (data models)
- `docs/product/specs/0002-export-data/data-contract.md`
- `packages/shared_models/test/`

## Acceptance criteria

- [ ] Export format contains a `version` field
- [ ] Format is documented in `data-contract.md`
- [ ] Tests cover empty data (export with 0 entries)
- [ ] Tests cover non-empty data (export with example data)
- [ ] No new dependencies without justification
- [ ] Existing repository structure preserved

## Tests required

- Unit tests in `packages/shared_models/test/`
- `dart test` must pass
- `dart analyze` must pass

## Test commands

```bash
cd packages/shared_models && dart test
cd packages/shared_models && dart analyze
```

## Forbidden changes

- No UI changes
- No changes to apps/mobile_app/
- No new top-level folders
- No changes to CI workflows

## Expected PR summary

> Add versioned export data model with serialization tests.
> Covers empty and non-empty export scenarios.
> Format documented in feature spec data-contract.md.
