import 'package:time_machine2/time_machine2.dart';

/// Calendar-correct date validation built on `time_machine2`.
///
/// Prefer this over hand-written month-length switches: it gets leap years
/// (Feb 29 only in leap years) and yearless dates (birthdays, anniversaries)
/// right without special cases.
///
/// ⚠️ `time_machine2` 0.14 does NOT expose `ArgumentOutOfRangeException`;
/// its preconditions throw [RangeError]. The helpers below therefore catch
/// [RangeError] plus a generic fallback and turn invalid input into `false` /
/// `null` instead of leaking exceptions.
abstract final class DateValidation {
  /// Whether [year]/[month]/[day] form a valid Gregorian date.
  ///
  /// Feb 29 is valid only in leap years.
  static bool isValidDate(int year, int month, int day) {
    try {
      LocalDate(year, month, day);
      return true;
    } on RangeError {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Whether [month]/[day] form a valid **yearless** date (e.g. a birthday).
  ///
  /// Feb 29 is accepted here because it is a valid annual date; use
  /// [annualDateOccursIn] to check whether it materializes in a given year.
  static bool isValidAnnualDate(int month, int day) {
    try {
      AnnualDate(month, day);
      return true;
    } on RangeError {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Whether the yearless [month]/[day] occurs in [year] without truncation.
  ///
  /// Returns `false` for Feb 29 in a non-leap year (and for invalid input).
  static bool annualDateOccursIn(int month, int day, int year) {
    try {
      return AnnualDate(month, day).isValidYear(year);
    } on RangeError {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Parses [year]/[month]/[day] into a [LocalDate], or `null` if invalid.
  static LocalDate? tryLocalDate(int year, int month, int day) {
    try {
      return LocalDate(year, month, day);
    } on RangeError {
      return null;
    } catch (_) {
      return null;
    }
  }
}
