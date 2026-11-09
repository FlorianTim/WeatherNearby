# Story: Release 3.2.1

## Metadata

- **Status:** ready
- **Feature:** specs 0005, 0006, 0007
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`, slice 7
- **Target release:** 3.2.1 (`now`)
- **Depends on:** stories 001–006

## Goal

Ship the app shell as template version 3.2.1, with the documentation that
makes it usable by a derived app.

## Scope

- `VERSION` and `apps/mobile_app/pubspec.yaml` set to `3.2.1` (validate.sh
  checks that they match).
- `CHANGELOG.md` — the release entry, including the behaviour change to the
  startup flow.
- `README.md` — the settings surface, the startup flow, and what a derived
  app replaces.
- `AGENTS.md` — the reference-app state note updated.
- `docs/product/roadmap.md` and `feature-candidates.md`.
- `docs/architecture/contracts/` — the lines the new surfaces satisfy.
- ADR-0015 recorded in the ADR table.

## Out of scope

- Tagging or publishing a release.
- Any code change beyond what stories 001–006 delivered.

## Acceptance criteria

- [ ] `VERSION` and the app pubspec agree on `3.2.1`.
- [ ] The changelog names the three breaking-ish changes for derived apps:
      the startup destination, the removed `onContinue`, and the extracted
      `AppOptionTile`.
- [ ] The version jump from 3.0.0 is explained — 3.1.0's reference-app work
      is still in progress on its own branch.
- [ ] README documents the new routes and the help-asset convention.
- [ ] The ADR table in `AGENTS.md` lists 0015.
- [ ] `scripts/dev/quality_gate.sh` is green.

## Test requirements

- Full suite: `flutter test` in the app and `dart test` in the packages.
- `melos run analyze` clean, `format:check` clean.
- Codegen idempotent: `melos run codegen` produces no diff.

## Documentation requirements

Everything in scope above.

## Implementation notes

The version jumps 3.0.0 → 3.2.1 deliberately. 3.1.0 is reserved for the
to-do reference app (plan 0001), which is still mid-flight; taking 3.1.x for
the app shell would make the two lines of work look sequential when they are
not.

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present
- [ ] No unauthorized scope expansion
- [ ] Existing structure preserved
