# Story: `Uuid4` in `packages/app_core`

## Metadata

- **Status:** ready
- **Feature:** none — template surface. Plan:
  `docs/delivery/implementation-plans/0000-shared-foundations.md`, component 2
- **Target release:** 3.1.0 (`now`)
- **Decision:** ADR-0014

## Goal

Provide RFC 4122 version 4 UUID generation as template surface, without adding
the `uuid` package.

## Context

JSCalendar requires `uid` to be an RFC 4122 v4 UUID in canonical lowercase
(interop guide §2.1). The template's existing
`core/utils/id_generator.dart` produces a 32-character hex string that is
**not** a UUID — no dashes, no version nibble, no variant bits.

The planning draft asked for the `uuid` package and mis-attributed the
existing helper to a WasThereSomething dependency lock. In fact
`generateId()`'s own doc comment cites **library-evaluation rule 9** — "no
large dependency for a trivial problem", whose named counter-example is
verbatim UUID generation — as the reason the package was not taken (audit
§4.4).

So: keep the rule, meet the standard, write fifteen lines.

## Scope

- `packages/app_core/lib/src/uuid4.dart` — `Uuid4.generate()` and
  `Uuid4.isCanonical(String)`.
- Export from `packages/app_core/lib/app_core.dart`.
- Tests under `packages/app_core/test/`.

## Out of scope

- Changing or removing `core/utils/id_generator.dart`. It keeps generating
  **local row ids**, which have no format contract and are never exported.
  The two are deliberately separate.
- Using `Uuid4` anywhere. Spec 0001's slice 2 wires it to
  `tasks.jscalendar_uid`.
- UUID v1, v5, v7 or parsing/normalizing a foreign UUID.

## Relevant files

- `apps/mobile_app/lib/core/utils/id_generator.dart` — the sibling that stays
- `packages/app_core/lib/app_core.dart` — the export barrel
- `docs/architecture/contracts/06-library-evaluation.md` rule 9
- `docs/architecture/adr/0014-task-interchange-package.md` decision 7

## Acceptance criteria

- [ ] `Uuid4.generate()` returns a 36-character string matching
      `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`.
- [ ] The version nibble is `4` and the variant bits are `10` (first variant
      character in `89ab`), asserted directly on the bytes, not only via the
      regex.
- [ ] Randomness comes from `Random.secure()`.
- [ ] 100 000 generated values are all distinct.
- [ ] Output is lowercase; no call site needs to normalize it.
- [ ] `Uuid4.isCanonical` accepts valid v4 values and rejects: uppercase, a
      missing dash, a wrong version nibble, a wrong variant nibble, a
      too-short and a too-long string.
- [ ] No `pubspec.yaml` in the workspace declares the `uuid` package.
- [ ] `packages/app_core` gains no new dependency.

## Test requirements

- `packages/app_core/test/uuid4_test.dart`:
  - property test over 100 000 draws — form, version, variant, distinctness
  - `isCanonical` accept and reject cases
  - a test asserting no `uuid` dependency in `pubspec.yaml`
- Commands: `melos run test:dart` (this package is pure Dart),
  `dart analyze`, `scripts/dev/quality_gate.sh`.

## Documentation requirements

- A doc comment stating why this exists rather than the `uuid` package, and
  the division of labour with `generateId()`: **row id versus identity**.
  Someone will otherwise "clean this up" by adding the package.

## Implementation notes

- Sixteen bytes from `Random.secure()`; set `bytes[6] = (bytes[6] & 0x0f) | 0x40`
  and `bytes[8] = (bytes[8] & 0x3f) | 0x80`; format `8-4-4-4-12` lowercase.
- `packages/app_core` is pure Dart (`noDependsOn: "flutter"` in the melos
  filters), so its tests run under `dart test`. Keep it that way.
- Do not import `dart:io` or anything Flutter.

## Review checklist

- [ ] Scope maintained — `generateId()` untouched, no call sites changed
- [ ] Acceptance criteria fulfilled
- [ ] Tests present and passing
- [ ] No new dependency
- [ ] Existing structure preserved; `features/todos/` untouched
