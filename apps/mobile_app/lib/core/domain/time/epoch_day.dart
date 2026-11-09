import 'package:time_machine2/time_machine2.dart';

/// A calendar day, stored as days since the Unix epoch (1970-01-01).
///
/// **An [EpochDay] is not a moment.** It has no time, no offset and no time
/// zone. "14 March 2027" is the same day in Berlin and in Auckland; the
/// instant that day begins is not, and this type deliberately cannot express
/// it.
///
/// Why not a midnight [DateTime]
/// ([database contract](../../../../../../docs/architecture/contracts/02-database.md),
/// rule 6):
///
///  - A midnight `DateTime` carries a zone. Round-tripping one through UTC
///    moves the day across a DST boundary or a zone change — a bug that
///    surfaces twice a year and never in a test written in January.
///  - Drift persists `DateTime` at second precision
///    ([KI-008](../../../../../../docs/known-issues.md#ki-008)), so a
///    "date" column would silently carry 86 399 values it must never hold.
///  - An integer sorts, compares and indexes exactly as the domain means it.
///
/// The representation is an `int`, so storage and comparison cost nothing:
/// this is an extension type, erased at runtime.
///
/// It deliberately does **not** implement `Comparable<EpochDay>` — an
/// extension type may only implement a supertype of its representation, and
/// `int` is `Comparable<num>`. Sort with [compareTo] as an explicit
/// comparator: `days.sort(EpochDay.compare)`.
extension type const EpochDay(int value) {
  /// The day [date] falls on.
  factory EpochDay.fromLocalDate(LocalDate date) => EpochDay(date.epochDay);

  /// Builds from calendar components, or throws if they are not a real date.
  ///
  /// Calendar correctness (leap years, month lengths) comes from
  /// `time_machine2` via [LocalDate], never from a hand-written month-length
  /// switch. Use `DateValidation.isValidDate` from `package:app_core` first
  /// when the input is untrusted.
  factory EpochDay.fromYmd(int year, int month, int day) =>
      EpochDay(LocalDate(year, month, day).epochDay);

  /// The calendar date this day represents.
  LocalDate toLocalDate() => LocalDate.fromEpochDay(value);

  int get year => toLocalDate().year;
  int get month => toLocalDate().monthOfYear;
  int get day => toLocalDate().dayOfMonth;

  /// [days] later (or earlier, when negative).
  EpochDay plusDays(int days) => EpochDay(value + days);

  /// How many days [other] lies before this one.
  int daysSince(EpochDay other) => value - other.value;

  bool operator <(EpochDay other) => value < other.value;
  bool operator <=(EpochDay other) => value <= other.value;
  bool operator >(EpochDay other) => value > other.value;
  bool operator >=(EpochDay other) => value >= other.value;

  int compareTo(EpochDay other) => value.compareTo(other.value);

  /// Comparator for sorting: `days.sort(EpochDay.compare)`.
  static int compare(EpochDay a, EpochDay b) => a.value.compareTo(b.value);
}
