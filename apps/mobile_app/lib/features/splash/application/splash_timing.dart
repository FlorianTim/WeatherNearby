import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_timing.g.dart';

/// Durations of the two splash phases.
class SplashTiming {
  const SplashTiming({required this.company, required this.appMinimum});

  /// How long the company (LumbreCode) phase is shown.
  final Duration company;

  /// Minimum duration of the app phase before navigation may happen.
  final Duration appMinimum;
}

/// Production splash timing: 3 s company phase + 3 s app phase minimum —
/// long enough for the localized logo reveal animations to play through.
///
/// Tests override this with 1 s / 1 s via the test harness
/// (`test/support/test_app.dart`) so `pump(3 s)` reaches the shell.
@Riverpod(keepAlive: true)
SplashTiming splashTiming(Ref ref) => const SplashTiming(
  company: Duration(seconds: 3),
  appMinimum: Duration(seconds: 3),
);
