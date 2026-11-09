# ADR-0017: The template depends on `flutter-libraries` instead of owning `task_interchange`

## Status

accepted. Supersedes ADR-0014 in part (see "What stays of ADR-0014").

## Date

2026-10-08

## Decision owners

- Product Owner (F. Kroschewski)
- Template architecture

## Related feature / spec

- `docs/product/specs/0004-jscalendar-interoperability/`
- Slice 1 of `docs/delivery/implementation-plans/0001-todo-reference-app.md`
- `flutter-libraries`: `docs/adr/0001-*` (repository and package cut),
  `docs/consuming.md`

## Related issues / PRs

- ADR-0014 (`packages/task_interchange` as template surface), ADR-0011
- Packzeit ADR-0014 / ADR-0016 (origin of the extraction)

## Context

ADR-0014 planned the JSCalendar codec as `packages/task_interchange` in this
repository, copied into every derived app. That slice was never built here.
The same code now exists in the private repository `flutter-libraries` as
three packages of the family `interchange` (`ijson`, `jscalendar`,
`task_interchange`), released as one tag per family.

Code under `packages/` is copied into every derived app and drifts from the
copy in every other app. A fix to the codec would have to be re-applied by
hand N times. A tag bump does not.

## Decision

1. **The template does not contain the codec.** `apps/mobile_app` depends on
   `task_interchange` through **one** `git:` block pinned to a release tag
   (`interchange-v0.1.0`). `jscalendar` and `ijson` come along by relative
   path at the same commit. Never a branch.
2. **The dependency is kept by the initializer.** It is a dependency, not
   template surface to replace and not an example-app part to delete: a
   derived app inherits it and updates it by bumping the tag.
3. **The golden fixtures stay in `.lumbrecode/schemas/`** (baseline sync). They
   are not copied anywhere. The template's contract test
   (`apps/mobile_app/test/interop/interchange_contract_test.dart`) iterates
   them by directory and proves the dependency from the consumer's side.
4. **CI reads the private repository** through the optional `git-read-token`
   secret of the shared `flutter-quality.yml`, fed from the repository secret
   `FLUTTER_LIBRARIES_TOKEN` (read-only Contents on `flutter-libraries`).
5. **Local work across both repositories** uses an untracked
   `pubspec_overrides.yaml` (`docs/operations/local-library-development.md`).

## What stays of ADR-0014

- Decision 1 (hand-written codec, no JSCalendar library for Dart): stands; the
  codec is now written and owned in `flutter-libraries`.
- Decisions 3 to 5 (pure Dart, Freezed models over a hand-written codec,
  `JsLocalDateTime` as its own type): stand, enforced there by
  `package_boundary_test.dart` and the codec tests.
- Decision 2 (a package in this repository, template surface) and decision 6
  (fixtures vendored with provenance) are **superseded**.

## Alternatives considered

| Alternative | Pro | Contra |
|---|---|---|
| Build `packages/task_interchange` here (ADR-0014) | Self-contained template | A second copy that drifts from `flutter-libraries` and from every derived app |
| Copy the packages in with a sync script | No private-repo access in CI | Same drift, plus a sync mechanism to maintain |
| Git dependency on a branch | No tagging step | Unreproducible builds; a push to the branch changes every consumer |
| Publish to pub.dev | Plain version constraint | Public; `task_interchange` encodes an internal contract |

## Consequences

### Positive

- One implementation; a fix reaches an app as a tag bump.
- The template is the first consumer, so the consumption path (tag, token,
  workspace) is proven before a productive app depends on it.

### Negative

- Every checkout and every CI job needs read access to a private repository.
  Workflows that run `pub get` outside the shared workflow need the same
  token step (`docs/operations/local-library-development.md`).
- The pinned tag must exist before CI can be green.
- The template's baseline (`.lumbrecode/`) must be at least as new as the
  library's fixtures for the library's own count assertions to apply; the
  template's contract test therefore asserts no counts.

## Test and validation impact

`apps/mobile_app/test/interop/interchange_contract_test.dart` is the
integration proof. The library's own suite (CT-1..CT-16, fuzz corpus) runs in
`flutter-libraries`; it is not re-run here.

## Follow-up tasks

- Plan 0001: slice 1 is "consume `flutter-libraries`" (done by this ADR's
  change); slices 8, 9 and 12 use the dependency.
- Return `ci-mobile.yml` to the moving `@v1` once that tag carries the
  `git-read-token` input.

## References

- `flutter-libraries/docs/consuming.md`
- `lumbrecode-engineering/docs/GITHUB_ACTIONS_ACCESS.md`
