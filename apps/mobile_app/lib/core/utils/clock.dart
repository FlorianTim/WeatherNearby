import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// Source of the current time.
///
/// Domain and application code must read "now" through this seam instead of
/// calling `DateTime.now()` directly. Time is a platform dependency like any
/// other: a test that cannot fix the clock either becomes flaky (midnight,
/// month ends, leap days, DST) or grows sleeps.
///
/// Same convention as the plugin seams in `core/platform/platform_seams.dart`:
/// an interface plus a keepAlive provider; tests override it with
/// `FixedClock` from `test/support/fixed_clock.dart`.
abstract interface class Clock {
  DateTime now();
}

/// Production implementation.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// The clock every feature should read.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();
