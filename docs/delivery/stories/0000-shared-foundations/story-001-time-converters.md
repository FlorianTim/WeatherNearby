# Story: Epoch-day and minute-of-day converters

## Metadata

- **Status:** ready
- **Feature:** none — template surface. Plan:
  `docs/delivery/implementation-plans/0000-shared-foundations.md`, component 1
- **Target release:** 3.1.0 (`now`)
- **Related issue:** —
- **Related PR:** —

## Goal

Give the template calendar-day and time-of-day storage types with Drift type
converters, so dates are stored as epoch-day integers rather than midnight
`DateTime` values.

## Context

`docs/architecture/contracts/02-database.md` rule 6 requires calendar days as
epoch-day integers and wall-clock times stored separately from instants. The
contract's own status table marks it **partial**: "`EpochDayConverter` /
`AllDayInterval` werden erst mit der ersten datumslastigen App vorgelegt."

The To-do reference app is that app. Spec 0001 (TLD-303, TLD-305, TLD-1006)
depends on these types, and spec 0003 computes notification moments from them.

They are template surface: any app with dates needs them.

## Scope

- `apps/mobile_app/lib/core/domain/time/epoch_day.dart` — an `EpochDay`
  value type over an `int`, converting to and from `time_machine2`'s
  `LocalDate`.
- `apps/mobile_app/lib/core/domain/time/minute_of_day.dart` — a
  `MinuteOfDay` value type over an `int`, 0..1439, with hour/minute
  accessors and a formatting-free API.
- `apps/mobile_app/lib/core/domain/time/converters.dart` —
  `EpochDayConverter` and `MinuteOfDayConverter`, both
  `TypeConverter<X, int>`.
- Tests under `apps/mobile_app/test/core/domain/time/`.

## Out of scope

- Any table using them. Spec 0001's slice 2 owns that.
- `AllDayInterval` — the half-open interval helper. It is named in the
  database contract but nothing in 3.1.0 forces it yet; adding it
  speculatively is how `core/` acquires unused surface.
- Formatting for display. That is `intl` in the presentation layer.
- Updating the contract's status table — story 007.

## Relevant files

- `apps/mobile_app/lib/core/database/app_database.dart` — where converters
  must be imported for codegen (KI-004)
- `packages/app_core/lib/src/date_validation.dart` — existing calendar-correct
  validation on `time_machine2` 0.14; reuse it, do not duplicate it
- `docs/architecture/contracts/02-database.md` rule 6
- `docs/known-issues.md` KI-004, KI-008

## Acceptance criteria

- [ ] `EpochDay` converts to and from `LocalDate` losslessly for every day in
      1900..2200.
- [ ] `EpochDay.fromLocalDate` is calendar-correct: it goes through
      `time_machine2`, not through a `DateTime` arithmetic shortcut.
- [ ] `MinuteOfDay` rejects values outside 0..1439 at construction.
- [ ] `MinuteOfDay` exposes `hour` and `minute` and performs no formatting.
- [ ] Both converters are declared on the **storage** type
      (`integer().map(...)`), and a doc comment states why (KI-004).
- [ ] A Drift round trip through a temporary in-memory table stores and reads
      both types unchanged.
- [ ] A date around each `Europe/Berlin` DST transition round-trips to the
      same calendar day — no shift.
- [ ] No public API of either type accepts or returns a `DateTime`.

## Test requirements

- `test/core/domain/time/epoch_day_test.dart` — round trip over the full
  range; the two DST dates; the no-`DateTime`-in-the-API assertion.
- `test/core/domain/time/minute_of_day_test.dart` — boundary values 0, 1439,
  and rejection of −1 and 1440.
- `test/core/domain/time/converters_test.dart` — a Drift round trip using
  `NativeDatabase.memory()`.
- Commands: `flutter test`, `flutter analyze`,
  `scripts/dev/quality_gate.sh`.

## Documentation requirements

- Doc comments on both types stating what they are **not**: `EpochDay` is not
  a moment; `MinuteOfDay` is not a duration.
- A doc comment on each converter naming the KI-004 trap it avoids.

## Implementation notes

- `time_machine2` 0.14 is already a dependency of `packages/app_core` and
  reaches the app transitively. Do **not** add it to the app's pubspec — the
  draft's claim that it needs adding is wrong (audit §4.7).
- `time_machine2` 0.14 throws `RangeError` rather than
  `ArgumentOutOfRangeException`; `DateValidation` already handles that and is
  the pattern to follow.
- Extension types (`extension type const EpochDay(int value)`) keep the
  runtime representation an `int` while making the type distinct. Dart 3.12 is
  the pinned SDK, so they are available.
- The converter must be imported into the **database library file**
  (`app_database.dart`), not only into the file that declares the column, or
  codegen fails with `Couldn't find constructor 'XConverter'` — KI-004.

## Review checklist

- [ ] Scope maintained — no table uses these yet
- [ ] Acceptance criteria fulfilled
- [ ] Tests present and passing
- [ ] No unauthorized scope expansion (no `AllDayInterval`)
- [ ] Existing structure preserved; `features/todos/` untouched
- [ ] No generated file edited by hand
