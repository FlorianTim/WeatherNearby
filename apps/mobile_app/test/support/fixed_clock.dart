import 'package:mobile_app/core/utils/clock.dart';

/// Deterministic [Clock] for tests: always returns the injected instant.
///
/// Override `clockProvider` with this instead of letting code call
/// `DateTime.now()`. Anything time-dependent that reads the real clock is
/// flaky by construction — it changes behaviour at midnight, at month ends,
/// on 29 February and across DST switches.
class FixedClock implements Clock {
  const FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// A mutable clock for tests that need time to advance deliberately.
class MutableClock implements Clock {
  MutableClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration duration) => _now = _now.add(duration);

  void setTo(DateTime instant) => _now = instant;
}
