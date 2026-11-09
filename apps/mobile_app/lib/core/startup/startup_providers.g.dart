// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everything that has to happen before the app shows its first screen.
///
/// **Extend this list per app**, one entry per piece of startup work, and
/// state its [StartupPolicy] deliberately:
///
///  - `blocking` only when the app genuinely cannot continue without it,
///  - `guarded` for caches the first screen would otherwise load lazily,
///  - `fireAndForget` for work nothing on screen depends on.
///
/// Blocking tasks run in this order, so a later one may rely on an earlier
/// one having succeeded.

@ProviderFor(startupTasks)
const startupTasksProvider = StartupTasksProvider._();

/// Everything that has to happen before the app shows its first screen.
///
/// **Extend this list per app**, one entry per piece of startup work, and
/// state its [StartupPolicy] deliberately:
///
///  - `blocking` only when the app genuinely cannot continue without it,
///  - `guarded` for caches the first screen would otherwise load lazily,
///  - `fireAndForget` for work nothing on screen depends on.
///
/// Blocking tasks run in this order, so a later one may rely on an earlier
/// one having succeeded.

final class StartupTasksProvider
    extends
        $FunctionalProvider<
          List<StartupTask>,
          List<StartupTask>,
          List<StartupTask>
        >
    with $Provider<List<StartupTask>> {
  /// Everything that has to happen before the app shows its first screen.
  ///
  /// **Extend this list per app**, one entry per piece of startup work, and
  /// state its [StartupPolicy] deliberately:
  ///
  ///  - `blocking` only when the app genuinely cannot continue without it,
  ///  - `guarded` for caches the first screen would otherwise load lazily,
  ///  - `fireAndForget` for work nothing on screen depends on.
  ///
  /// Blocking tasks run in this order, so a later one may rely on an earlier
  /// one having succeeded.
  const StartupTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupTasksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupTasksHash();

  @$internal
  @override
  $ProviderElement<List<StartupTask>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<StartupTask> create(Ref ref) {
    return startupTasks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<StartupTask> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<StartupTask>>(value),
    );
  }
}

String _$startupTasksHash() => r'8a368094b02dcb901746e1e0d2a676ff2b1264ad';

@ProviderFor(startupCoordinator)
const startupCoordinatorProvider = StartupCoordinatorProvider._();

final class StartupCoordinatorProvider
    extends
        $FunctionalProvider<
          StartupCoordinator,
          StartupCoordinator,
          StartupCoordinator
        >
    with $Provider<StartupCoordinator> {
  const StartupCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupCoordinatorHash();

  @$internal
  @override
  $ProviderElement<StartupCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StartupCoordinator create(Ref ref) {
    return startupCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartupCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartupCoordinator>(value),
    );
  }
}

String _$startupCoordinatorHash() =>
    r'e43425c0b6ee30249b4a67505c8070598b3ad756';

/// Outcome of the last startup run; `null` until startup has finished.
///
/// Kept in a provider rather than a local variable because the splash writes
/// it and both the router and the recovery screen read it.

@ProviderFor(StartupOutcome)
const startupOutcomeProvider = StartupOutcomeProvider._();

/// Outcome of the last startup run; `null` until startup has finished.
///
/// Kept in a provider rather than a local variable because the splash writes
/// it and both the router and the recovery screen read it.
final class StartupOutcomeProvider
    extends $NotifierProvider<StartupOutcome, StartupResult?> {
  /// Outcome of the last startup run; `null` until startup has finished.
  ///
  /// Kept in a provider rather than a local variable because the splash writes
  /// it and both the router and the recovery screen read it.
  const StartupOutcomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupOutcomeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupOutcomeHash();

  @$internal
  @override
  StartupOutcome create() => StartupOutcome();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartupResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartupResult?>(value),
    );
  }
}

String _$startupOutcomeHash() => r'80f5edbadaf007282a2416840db3a97e367b1c2e';

/// Outcome of the last startup run; `null` until startup has finished.
///
/// Kept in a provider rather than a local variable because the splash writes
/// it and both the router and the recovery screen read it.

abstract class _$StartupOutcome extends $Notifier<StartupResult?> {
  StartupResult? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<StartupResult?, StartupResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StartupResult?, StartupResult?>,
              StartupResult?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
