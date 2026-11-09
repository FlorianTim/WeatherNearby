/// A wall-clock time of day, as minutes since midnight (0..1439).
///
/// **A [MinuteOfDay] is not a duration and not a moment.** "10:00" is a
/// position on a clock face; it becomes an instant only when combined with a
/// calendar day and a time zone, and only for display or scheduling.
///
/// Why minutes and not a [Duration] or a [DateTime]
/// ([database contract](../../../../../../docs/architecture/contracts/02-database.md),
/// rule 6): storing a wall-clock time as a `DateTime` forces a date and a
/// zone onto a value that has neither, and a `Duration` invites arithmetic
/// that runs past midnight without saying so.
///
/// A task with no time stores `NULL`, never a sentinel like `0` — midnight is
/// a real time of day, and "no time" is not.
/// Like [EpochDay], this deliberately does not implement
/// `Comparable<MinuteOfDay>`: an extension type may only implement a
/// supertype of its representation, and `int` is `Comparable<num>`. Sort with
/// `times.sort(MinuteOfDay.compare)`.
extension type const MinuteOfDay._(int value) {
  /// Minutes since midnight, 0..1439.
  ///
  /// Throws [RangeError] outside that range. 1440 is not "midnight tomorrow";
  /// it is a different day, and this type cannot express one.
  factory MinuteOfDay(int minutes) {
    RangeError.checkValueInInterval(minutes, 0, 1439, 'minutes');
    return MinuteOfDay._(minutes);
  }

  /// Builds from clock components, or throws if they are out of range.
  factory MinuteOfDay.fromHm(int hour, int minute) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    return MinuteOfDay._(hour * 60 + minute);
  }

  /// Returns `null` instead of throwing when [minutes] is out of range.
  ///
  /// For values read from storage or from an untrusted document, where a bad
  /// value must degrade rather than crash.
  static MinuteOfDay? tryFrom(int? minutes) {
    if (minutes == null || minutes < 0 || minutes > 1439) return null;
    return MinuteOfDay._(minutes);
  }

  int get hour => value ~/ 60;
  int get minute => value % 60;

  bool operator <(MinuteOfDay other) => value < other.value;
  bool operator <=(MinuteOfDay other) => value <= other.value;
  bool operator >(MinuteOfDay other) => value > other.value;
  bool operator >=(MinuteOfDay other) => value >= other.value;

  int compareTo(MinuteOfDay other) => value.compareTo(other.value);

  /// Comparator for sorting: `times.sort(MinuteOfDay.compare)`.
  static int compare(MinuteOfDay a, MinuteOfDay b) =>
      a.value.compareTo(b.value);
}
