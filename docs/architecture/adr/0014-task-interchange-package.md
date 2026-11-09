# ADR-0014: `packages/task_interchange` — a hand-written JSCalendar codec as template surface

## Status

superseded in part by ADR-0017 (decision 2 and 6; the rest stands, now realised in `flutter-libraries`)

## Date

2026-08-25

## Decision owners

- Product Owner (F. Kroschewski)
- Template architecture

## Related feature / spec

- `docs/product/specs/0004-jscalendar-interoperability/`
- Contract: `lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md` 2, 4, 5, 7, 15
- Slice 1 of `docs/delivery/implementation-plans/0001-todo-reference-app.md`
- `docs/architecture/contracts/06-library-evaluation.md`

## Related issues / PRs

- none yet

## Context

The task interchange format is fixed: RFC 8984 JSCalendar `Task` and `Group`,
profiled by `lumbrecode-engineering`, schema-validated, with 24 golden
fixtures for the payload and 21 for the CloudEvents envelope, and a second
implementation (WasThereSomething 1.5) already writing it.

Four questions are open on this side.

1. **Library or hand-written?** The interop guide 7.1 records an audit: there
   is no Dart JSCalendar library. Re-checked 2026-08-25 — still none.

2. **Where does the code live?** The codec is generic. It knows nothing about
   lists, views, notifications or navigation. Putting it in
   `features/interop/` would bury template surface inside one feature of one
   app.

3. **How do the golden fixtures get here?** The interop guide 15.3 says they
   "arrive automatically at `.lumbrecode/schemas/` through the baseline sync".
   **They do not.** There is no `.lumbrecode/` directory in this repository
   and no baseline sync wired into it. Verified. And the contract tests are
   defined *by* those fixtures, so this cannot be deferred.

4. **How does a `uid` get generated?** JSCalendar requires an RFC 4122 v4
   UUID in canonical lowercase. The template's `core/utils/id_generator.dart`
   produces a 32-character hex string that is **not** a UUID, and its doc
   comment cites library-evaluation rule 9 ("no large dependency for a
   trivial problem", with UUID generation as the named counter-example) as the
   reason the `uuid` package was not taken. The planning draft asks for the
   `uuid` package and mis-attributes the existing helper to a WasThereSomething
   dependency lock.

## Decision

1. **The codec is hand-written.** No JSCalendar library exists for Dart, and
   the supported subset is small and fully specified in the guide's section 2.
   Writing it is a day's work; auditing a hypothetical library against a
   contract this precise would cost more.

2. **It lives in a new package, `packages/task_interchange`**, and it is
   **template surface**, not app code. Any LumbreCode app may want to read or
   write the task format.

   ```text
   packages/task_interchange/
     lib/task_interchange.dart          public API
     lib/src/model/                     Task Group Relation Link
                                        RecurrenceRule NDay PatchObject
                                        LocalDateTime UtcInstant
     lib/src/codec/                     decode encode validate
     lib/src/warning/                   the ImportWarning hierarchy
     lib/src/media_type.dart            the registered media-type constants
     test/fixtures/jscalendar-task/v1/  vendored golden fixtures
     test/fixtures/lumbrecode-exchange/v1/
   ```

3. **It is pure Dart.** No Flutter, no Drift, no `dart:io`, no platform
   channel. It is added to the workspace under `noDependsOn: "flutter"`, so
   `melos run test:dart` runs it with plain `dart test` — fast, and runnable
   without a Flutter toolchain. A test asserts the package has no Flutter
   import, in the spirit of the template's package-encapsulation test.

4. **Freezed + `json_serializable` are used for the models, but the codec is
   hand-written on top.** `json_serializable` is a compile-time generator, so
   the library-evaluation contract does not require a wrapper for it — and
   the template already mandates generator workflows. But `toJson`/`fromJson`
   alone cannot honour the contract: key order (`@type` first, `uid` second,
   then alphabetical), "never emit `null`", "omit empty collections",
   `showWithoutTime` pairing, offset-free `LocalDateTime`, and unknown-property
   preservation are all encoder policy. So the generated map is an
   intermediate; `JsCalendarCodec` owns the final shape.

5. **`LocalDateTime` is its own value type, and it is not a `DateTime`.**

   ```dart
   final class JsLocalDateTime {   // year month day hour minute second
     // no offset, no zone, no instant. Never constructed from a DateTime.
   }
   ```

   This is the single easiest thing in the contract to get wrong (guide 2.4),
   and a distinct type makes the wrong thing unrepresentable rather than
   merely discouraged. `created`/`updated`/`progressUpdated` use a separate
   `JsUtcInstant` with second precision and no fractional seconds.

6. **Golden fixtures are vendored, with provenance.** Until a baseline sync
   exists, `packages/task_interchange/test/fixtures/` holds a copy of
   `lumbrecode-engineering/schemas/jscalendar-task/v1/examples/` and
   `.../lumbrecode-exchange/v1/examples/`, plus both JSON Schemas, plus a
   `PROVENANCE.md` recording the source repository, the commit hash and the
   date. A test asserts the fixture count and a checksum manifest, so a
   silent divergence fails CI rather than quietly weakening the contract.

   The rule from the guide stands unchanged: **if a fixture changes, it
   changes in both repositories in the same change.** Vendoring makes that a
   discipline; the checksum test makes it a detectable discipline.

7. **`uid` generation gets a `Uuid4` helper in `packages/app_core`, and the
   `uuid` package is not added.** Sixteen bytes from `Random.secure()`, the
   version nibble set to 4, the variant bits set to `10`, formatted canonical
   lowercase. Roughly fifteen lines with a property test asserting the
   canonical form, version, variant and distinctness over 100 000 draws.

   `generateId()` stays as it is for **local row ids**, which are never
   exported and have no format contract. The two are deliberately separate:
   a row id is a database detail, a `uid` is an identity that survives leaving
   the app. Library-evaluation rule 9 is satisfied and RFC 4122 is met.

8. **`rrule` is not added.** The contract supports a named subset (`frequency`
   with four values, `interval`, `byDay` with `nthOfPeriod`, `byMonthDay`). A
   full RFC 5545 engine would let this app emit rules WasThereSomething cannot
   read, which is a compatibility bug wearing a feature's clothes. The subset
   parser and the recurrence *expander* live in this package, hand-written,
   with a property test.

9. **Distribution to a second app is deliberately left open** (Q-05). The
   package is built as if it will be shared — pure Dart, no app knowledge, its
   own tests, a stable public API — so that copy, git dependency or private
   pub host all remain available. Choosing between them needs a second
   consumer, and there is not one yet. The same question applies to the
   Markdown editor in `packages/design_system`; one answer should cover both.

## Alternatives considered

| Alternative | Pro | Contra |
|---|---|---|
| **Codec inside `features/interop/`** | No new package; everything for the feature in one place | Buries template surface in one feature of one app. A second LumbreCode app would copy it, and the two copies would drift. The whole point of the 3.1.0 exercise is that general things land in `packages/`. |
| **Put it in `packages/shared_models`** | Package already exists | `shared_models` is for cross-app *app* models (`AppUser` today). The interchange package is a standard's implementation with its own validation, warnings and fixtures. Mixing them means the codec's fixtures and pure-Dart constraint leak into a package with a different job. |
| **Use `json_serializable` output directly as the wire format** | Less code | Cannot express key order, null omission, empty-collection omission, `showWithoutTime` pairing or unknown-property preservation. CT-3, CT-10 and CT-14 would fail. |
| **Model `start`/`due` as `DateTime`** | Familiar; less code | `DateTime` carries an instant. The contract's `LocalDateTime` does not. Every conversion through an instant moves the day across DST and time zones — the guide's explicit "never do this". A distinct type is the cheapest possible enforcement. |
| **Add the `uuid` package** | Battle-tested; RFC 4122 by construction | A package for fifteen lines, against a rule this template wrote down with UUID generation as its named example, in a tree with a documented analyzer ceiling (KI-001). The helper is trivially testable. |
| **Reference fixtures from the sibling repo by path** | Single source of truth; no vendoring | CI would depend on a second repository being checked out next to this one. It is not, and the template must build standalone. |
| **Add `rrule`** | Full RFC 5545 | Lets the app emit rules the other side cannot read. A wider parser is a narrower contract. |

## Consequences

### Positive

- The contract implementation is reviewable on its own, against fixtures
  alone, with no UI and no database — which is why slice 1 has no UI.
- `melos run test:dart` gives a fast, Flutter-free feedback loop on the part
  that must be exactly right.
- Any future LumbreCode app inherits the format for free.
- The distinct `JsLocalDateTime` and `JsUtcInstant` types make the two most
  common contract bugs compile errors rather than runtime surprises.
- No new runtime dependency at all for the codec itself.

### Negative

- Hand-written means hand-maintained. When the contract moves to v2, this
  code moves with it, and nobody else will do it. The fixture checksum test
  is the tripwire.
- Vendored fixtures are a copy, and copies drift. Provenance file plus
  checksum test plus the "change both repos in one change" rule are the
  mitigation; none of them is a guarantee.
- A new package in the workspace is a small permanent cost: another
  `pubspec.yaml`, another entry in the melos workspace, another CI target.
- `packages/task_interchange` is generic surface with exactly one consumer
  today. If the second app never arrives, it is a package that could have
  been a folder. Accepted: the reference-app decision (ADR-0011) is precisely
  a bet that this kind of surface pays off.

## Test and validation impact

This package owns CT-1 to CT-10, CT-13, CT-14 and CT-15 from the interop
guide 12; CT-11 and CT-12 belong to the app's data layer because they are
about transactions and rows.

| Test | Level |
|---|---|
| CT-1 every accepted fixture validates against the JSON Schema | CI |
| CT-2 every `9x-invalid-` fixture is rejected with a typed, readable error | unit |
| CT-3 `encode(decode(fixture))` is semantically equal to the fixture | unit |
| CT-4 `decode(encode(model))` equals the original model | unit |
| CT-5 recurrence round trip, property-based | property |
| CT-6 date round trip: none / start / due / both, with and without a time | property |
| CT-7 tree safety: 10 000 random parent assignments never produce a cycle | property |
| CT-9 Markdown body byte-identical after a round trip | unit |
| CT-10 an unknown property survives decode then encode | unit |
| CT-13 every loss produces a counted warning, never silence | unit |
| CT-14 determinism: same input, byte-identical output | unit |
| CT-15 no app-local field appears in any document | unit |
| Fuzz: truncated, oversized, randomly mutated input never throws | unit |
| Fixture provenance checksum matches `PROVENANCE.md` | unit |
| No Flutter import anywhere in `lib/` | unit |

## Follow-up tasks

- Record the fixture source commit in `PROVENANCE.md` when slice 1 vendors
  them.
- Raise the distribution question (Q-05) with the owner of
  `lumbrecode-engineering` once a second consumer exists; one answer should
  cover both this package and the shared Markdown editor.
- Ask the contract owner to state explicitly how a receiver without a matching
  model should treat `de.lumbrecode.exchange.jscalendar.upsert.v1` (spec 0004
  Q-04). This app's position is INT-141: accept it, execute it as an import,
  warn.
- Re-run the "is there a Dart JSCalendar library yet" check at the next
  contract version bump.

## References

- `lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md` 2, 4, 5, 7.1, 12, 15
- `lumbrecode-engineering/schemas/jscalendar-task/v1/`
- `lumbrecode-engineering/schemas/lumbrecode-exchange/v1/`
- `docs/architecture/contracts/06-library-evaluation.md` rules 9 and 10
- `docs/known-issues.md` KI-001, KI-009
- `docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md` 4.2, 4.4
- RFC 8984, RFC 7493, RFC 7763, RFC 4122 4.4, RFC 5545
