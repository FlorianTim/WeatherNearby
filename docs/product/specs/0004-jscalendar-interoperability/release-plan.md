# Release plan: JSCalendar interoperability

> **Package location (ADR-0017, 2026-10-08).** The codec is no longer
> `packages/task_interchange` in this repository. It is `task_interchange` in
> `flutter-libraries` (family `interchange`), consumed as a tag-pinned git
> dependency of `apps/mobile_app`. Statements below that say
> `packages/task_interchange` mean that package. Fixtures are read from
> `.lumbrecode/schemas/`, not vendored.

## Target release

Template **3.1.0**. Roadmap lane: `now`.

## Phases

Delivered by slices 1, 8, 9 and 12 of
`docs/delivery/implementation-plans/0001-todo-reference-app.md`.

| Phase | Slice | Delivers | Schema |
|---|---|---|---|
| 1 | **1 — consume `flutter-libraries`** | `task_interchange` as a tag-pinned dependency (ADR-0017), CI access and the contract test over the baseline fixtures. The models, codec, validation, warnings and recurrence parser/expander are built in `flutter-libraries`. **No UI, no database.** | — |
| 2 | **8 — import** | Platform channel, bootstrap manifest patcher, byte cap, envelope and batch unwrapping, import review route, one-transaction write, the report | — |
| 3 | **9 — export / share** | Document building for task / selection / list, the unskippable preview, the `ShareDocument` seam, cache cleanup, the receiver query | — |
| 4 | **12 — contract tests** | CT-1..CT-16 wired as a suite, the fuzz corpus, the checksum test, the end-to-end assertion | — |

**Slice 1 having no UI and no database is the point.** It is the piece that
must be exactly right, and it can be reviewed against the golden fixtures
alone, under plain `dart test`, without a Flutter toolchain.

**Slice 12 is a consolidation slice, not the first time the tests appear.**
CT-2, CT-3, CT-4, CT-9, CT-10, CT-13 and CT-14 are written *in slice 1*
alongside the code they test — a codec merged without them is not reviewable.
Slice 12 adds CT-1 in CI, CT-8, CT-11, CT-12, the fuzz corpus, the provenance
checksum and the end-to-end assertion, and makes the whole set one named
suite.

## Dependencies

**Blocking, upstream:**

- **Slice 1 blocks slices 8, 9 and 12.** Everything else needs the codec.
- **Spec 0001, slice 2 (data layer)** — the persistence target and the
  invariants the importer must respect (INT-115). Slice 8 cannot start
  without it.
- **Spec 0002, slice 3 (navigation shell)** — the review is a route
  (INT-309), so `AppRoutes` must exist.
- **Slice 0 (shared foundations)** — the `ShareDocument` seam is extended from
  the template's existing `ShareText` there, and the scheme-allowlisted URL
  seam is what makes imported links safe to render.
- **Spec 0003, slice 7 (recurrence)** — only for `recurrenceOverrides`
  (INT-215). Slice 1 owns the *parser*; the override table arrives in schema
  v4. Import can land before it and report `DroppedOverrides` in the interim,
  but the ordering in the plan avoids that.

**Slice 1 is independent of everything else**, including the database. It can
be built in parallel with spec 0001's slice 2.

**External:**

- The `lumbrecode-engineering` repository must be reachable **once**, to
  vendor the 45 fixtures and the two schemas with a recorded commit hash.
  After that, the build is standalone — CI must not depend on a sibling
  checkout.
- `path_provider` (decided) and possibly `mime` (Q-4g, leaning no). Both
  runtime-only; resolve against the KI-001 tree before adoption.
- A real Android device for the eight manual verification steps. The Kotlin
  channel is not covered by `flutter test`.

**This spec blocks:** nothing else in 3.1.0.

## Rollout notes

- **No feature flag.** The share action appears with slice 9; the app becomes
  a share target when a build carrying slice 8's manifest patch is installed.
- **The manifest patch changes the installed app's system surface.** After
  slice 8, the app appears in the share sheet for
  `application/jscalendar+json`. A reviewer must check the **generated**
  manifest after a bootstrap run — there is no committed `android/` to read
  (ADR-0013).
- **Both bootstrap paths must be updated together.** `apply_android_branding.sh`
  and `Apply-AndroidBranding.ps1`. A patch that exists only in bash works on
  the author's machine and silently does nothing on Windows.
- **Web is unaffected.** There is no share intent on web; the export path
  degrades through the seam.
- **The demo is untouched** throughout.

## Migration notes

- **No `schemaVersion` bump is owned by this spec.** Every column it uses is
  declared in spec 0001 (v2) or spec 0003 (v4).
- **`unknown_json` exists from v2**, before there is an importer to fill it.
  Deliberate: adding it later would be a migration, and a column that is
  always `NULL` costs nothing.
- **`sequence` exists from v2** for the same reason.
- **The fixture vendoring is a one-time content addition**, not a migration.
  `PROVENANCE.md` records the source commit; the checksum test makes a later
  divergence fail CI (INT-603).
- **Forward compatibility is a design property, not a promise**: a property a
  future contract version defines is simply an unknown property to this app —
  kept verbatim, ignored for behaviour, written back (INT-104). No migration
  is required when the contract moves, only new behaviour if the app wants to
  act on the new field.

## Validation

A phase is done when all of the following hold:

1. Every `Must` requirement in the phase's sections has a passing test at the
   level named in `acceptance-criteria.md`.
2. All 45 vendored fixtures are present, `PROVENANCE.md` records repository,
   commit and date, and the checksum test passes (AC-64).
3. CT-1 runs **in CI** — every accepted fixture validates against the schema.
4. Every `9x-invalid-` fixture is rejected with a typed, readable error
   (AC-11).
5. The fuzz suite runs with **zero** unhandled exceptions (AC-65).
6. Import totality is proved on a real in-memory database: a rejected document
   leaves zero rows (AC-25), and a `uid` seen twice creates two lists (AC-24).
7. `task_interchange` passes under plain `dart test` in `flutter-libraries` with
   no Flutter import anywhere in `lib/` (AC-01); the template resolves it by tag.
8. The generated `AndroidManifest.xml` after a bootstrap contains exactly the
   two narrow filters, no `*/*`, no `text/plain`, no
   `READ_EXTERNAL_STORAGE` — from **both** the bash and the PowerShell path
   (AC-35), and the patcher is idempotent (AC-36).
9. No app-local field appears in any exported document (AC-55).
10. `scripts/dev/quality_gate.sh` is green; `melos run codegen` produces no
    diff.
11. The eight manual verification steps have been walked on a named device and
    recorded in the PR — **including anything that could not be run**.
12. The demo still builds, still routes and its tests still pass.

## Risks

| Risk | Mitigation |
|---|---|
| The manifest patch exists only in bash and silently does nothing on Windows | Validation item 8 requires both paths; the check reads the generated manifest, not the script |
| Vendored fixtures drift from the contract repository | `PROVENANCE.md` + checksum test (AC-64); the "change both repos in one change" rule; Q-4e proposes a re-copy script so the discipline has a mechanical path |
| The `upsert` ambiguity is resolved differently by the next implementation | INT-141..143 states this app's position with its reasoning, and Q-4d raises it with the contract owner so it becomes a contract rule |
| A local date-time is round-tripped through an instant somewhere | `JsLocalDateTime` offers no `DateTime` constructor (AC-02) — the wrong thing does not compile, rather than being discouraged |
| Determinism breaks through map iteration order | CT-14 runs over every fixture, ten times each |
| An intent imports twice after rotation or process restore | AC-37 covers rotation, back and restore; the consumed marker is part of slice 8's design, not an afterthought |
| A 500-entry Group is slow through per-row repository calls | Measure before optimizing (Q-4k); any bulk path must run the same validation |
| CI depends on a sibling checkout | Fixtures are vendored precisely so it does not; validation item 7 runs the package standalone |
| The Kotlin side has no automated coverage | Stated openly in ADR-0013; eight manual test-plan entries, and everything downstream of the channel is pure Dart and fully tested |
