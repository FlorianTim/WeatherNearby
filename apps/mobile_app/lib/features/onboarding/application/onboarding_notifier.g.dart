// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the first-start intro has been finished or skipped.
///
/// Read **synchronously**: `bootstrap()` has already installed the
/// persistent key-value store by the time the splash finishes, so the
/// routing decision at the end of the splash needs no `await` and no
/// intermediate loading screen (spec 0006, ONB-004).
///
/// The definition lives in [AppSettings.onboardingCompleted] — key, default
/// and encoding are declared once, there.

@ProviderFor(OnboardingCompleted)
const onboardingCompletedProvider = OnboardingCompletedProvider._();

/// Whether the first-start intro has been finished or skipped.
///
/// Read **synchronously**: `bootstrap()` has already installed the
/// persistent key-value store by the time the splash finishes, so the
/// routing decision at the end of the splash needs no `await` and no
/// intermediate loading screen (spec 0006, ONB-004).
///
/// The definition lives in [AppSettings.onboardingCompleted] — key, default
/// and encoding are declared once, there.
final class OnboardingCompletedProvider
    extends $NotifierProvider<OnboardingCompleted, bool> {
  /// Whether the first-start intro has been finished or skipped.
  ///
  /// Read **synchronously**: `bootstrap()` has already installed the
  /// persistent key-value store by the time the splash finishes, so the
  /// routing decision at the end of the splash needs no `await` and no
  /// intermediate loading screen (spec 0006, ONB-004).
  ///
  /// The definition lives in [AppSettings.onboardingCompleted] — key, default
  /// and encoding are declared once, there.
  const OnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompletedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  OnboardingCompleted create() => OnboardingCompleted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingCompletedHash() =>
    r'e6ad6500979cec2bda58222a33832e9dc1a540a4';

/// Whether the first-start intro has been finished or skipped.
///
/// Read **synchronously**: `bootstrap()` has already installed the
/// persistent key-value store by the time the splash finishes, so the
/// routing decision at the end of the splash needs no `await` and no
/// intermediate loading screen (spec 0006, ONB-004).
///
/// The definition lives in [AppSettings.onboardingCompleted] — key, default
/// and encoding are declared once, there.

abstract class _$OnboardingCompleted extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
