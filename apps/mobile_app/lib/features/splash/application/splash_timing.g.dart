// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_timing.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Production splash timing: 3 s company phase + 3 s app phase minimum —
/// long enough for the localized logo reveal animations to play through.
///
/// Tests override this with 1 s / 1 s via the test harness
/// (`test/support/test_app.dart`) so `pump(3 s)` reaches the shell.

@ProviderFor(splashTiming)
const splashTimingProvider = SplashTimingProvider._();

/// Production splash timing: 3 s company phase + 3 s app phase minimum —
/// long enough for the localized logo reveal animations to play through.
///
/// Tests override this with 1 s / 1 s via the test harness
/// (`test/support/test_app.dart`) so `pump(3 s)` reaches the shell.

final class SplashTimingProvider
    extends $FunctionalProvider<SplashTiming, SplashTiming, SplashTiming>
    with $Provider<SplashTiming> {
  /// Production splash timing: 3 s company phase + 3 s app phase minimum —
  /// long enough for the localized logo reveal animations to play through.
  ///
  /// Tests override this with 1 s / 1 s via the test harness
  /// (`test/support/test_app.dart`) so `pump(3 s)` reaches the shell.
  const SplashTimingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashTimingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashTimingHash();

  @$internal
  @override
  $ProviderElement<SplashTiming> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SplashTiming create(Ref ref) {
    return splashTiming(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SplashTiming value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SplashTiming>(value),
    );
  }
}

String _$splashTimingHash() => r'6b008038cfc40a13247c521f0aa960d19813ffb0';
