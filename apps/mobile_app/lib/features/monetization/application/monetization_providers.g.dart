// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monetization_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The store gateway. Override with a real adapter when an app sells
/// something (ADR-0015), or with [FakePurchaseGateway] in tests.

@ProviderFor(purchaseGateway)
const purchaseGatewayProvider = PurchaseGatewayProvider._();

/// The store gateway. Override with a real adapter when an app sells
/// something (ADR-0015), or with [FakePurchaseGateway] in tests.

final class PurchaseGatewayProvider
    extends
        $FunctionalProvider<PurchaseGateway, PurchaseGateway, PurchaseGateway>
    with $Provider<PurchaseGateway> {
  /// The store gateway. Override with a real adapter when an app sells
  /// something (ADR-0015), or with [FakePurchaseGateway] in tests.
  const PurchaseGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseGatewayHash();

  @$internal
  @override
  $ProviderElement<PurchaseGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurchaseGateway create(Ref ref) {
    return purchaseGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchaseGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchaseGateway>(value),
    );
  }
}

String _$purchaseGatewayHash() => r'61a7161e9b3054d12d4e164d929f4a5bb9877072';

/// The gate catalogue this build ships.
///
/// Empty by requirement (IAP-022): the template gates nothing, so no
/// reference-app feature teaches derived apps that it is paid. Override in a
/// test to prove the mechanism.

@ProviderFor(featureGates)
const featureGatesProvider = FeatureGatesProvider._();

/// The gate catalogue this build ships.
///
/// Empty by requirement (IAP-022): the template gates nothing, so no
/// reference-app feature teaches derived apps that it is paid. Override in a
/// test to prove the mechanism.

final class FeatureGatesProvider
    extends $FunctionalProvider<FeatureGates, FeatureGates, FeatureGates>
    with $Provider<FeatureGates> {
  /// The gate catalogue this build ships.
  ///
  /// Empty by requirement (IAP-022): the template gates nothing, so no
  /// reference-app feature teaches derived apps that it is paid. Override in a
  /// test to prove the mechanism.
  const FeatureGatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureGatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureGatesHash();

  @$internal
  @override
  $ProviderElement<FeatureGates> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeatureGates create(Ref ref) {
    return featureGates(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureGates value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureGates>(value),
    );
  }
}

String _$featureGatesHash() => r'0a029635c5d03d20762f317ccb61c681ebbeef77';

/// The locally cached entitlement.
///
/// A **cache**, never proof of payment. The store is the source of truth
/// once purchases exist; until then this is `free` for everyone, and the
/// cache exists so the contract is already final when the first purchase
/// lands.

@ProviderFor(CachedEntitlement)
const cachedEntitlementProvider = CachedEntitlementProvider._();

/// The locally cached entitlement.
///
/// A **cache**, never proof of payment. The store is the source of truth
/// once purchases exist; until then this is `free` for everyone, and the
/// cache exists so the contract is already final when the first purchase
/// lands.
final class CachedEntitlementProvider
    extends $NotifierProvider<CachedEntitlement, Entitlement> {
  /// The locally cached entitlement.
  ///
  /// A **cache**, never proof of payment. The store is the source of truth
  /// once purchases exist; until then this is `free` for everyone, and the
  /// cache exists so the contract is already final when the first purchase
  /// lands.
  const CachedEntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cachedEntitlementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cachedEntitlementHash();

  @$internal
  @override
  CachedEntitlement create() => CachedEntitlement();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Entitlement value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Entitlement>(value),
    );
  }
}

String _$cachedEntitlementHash() => r'f6785d1b9816d8f315eb5bf2f50b008d4b565e0d';

/// The locally cached entitlement.
///
/// A **cache**, never proof of payment. The store is the source of truth
/// once purchases exist; until then this is `free` for everyone, and the
/// cache exists so the contract is already final when the first purchase
/// lands.

abstract class _$CachedEntitlement extends $Notifier<Entitlement> {
  Entitlement build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Entitlement, Entitlement>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Entitlement, Entitlement>,
              Entitlement,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Whether [featureKey] is unlocked for the cached entitlement.
///
/// **The one question app code asks.** Nothing outside this file branches on
/// the entitlement enum, so a change in how entitlements are decided touches
/// one place instead of every call site (IAP-020).
///
/// Unknown keys are unlocked (IAP-021): a typo must never lock a user out of
/// a core feature.

@ProviderFor(featureUnlocked)
const featureUnlockedProvider = FeatureUnlockedFamily._();

/// Whether [featureKey] is unlocked for the cached entitlement.
///
/// **The one question app code asks.** Nothing outside this file branches on
/// the entitlement enum, so a change in how entitlements are decided touches
/// one place instead of every call site (IAP-020).
///
/// Unknown keys are unlocked (IAP-021): a typo must never lock a user out of
/// a core feature.

final class FeatureUnlockedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether [featureKey] is unlocked for the cached entitlement.
  ///
  /// **The one question app code asks.** Nothing outside this file branches on
  /// the entitlement enum, so a change in how entitlements are decided touches
  /// one place instead of every call site (IAP-020).
  ///
  /// Unknown keys are unlocked (IAP-021): a typo must never lock a user out of
  /// a core feature.
  const FeatureUnlockedProvider._({
    required FeatureUnlockedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'featureUnlockedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$featureUnlockedHash();

  @override
  String toString() {
    return r'featureUnlockedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return featureUnlocked(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureUnlockedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$featureUnlockedHash() => r'02fa7418b4b86f2d59c4bdba481d5ea758839f57';

/// Whether [featureKey] is unlocked for the cached entitlement.
///
/// **The one question app code asks.** Nothing outside this file branches on
/// the entitlement enum, so a change in how entitlements are decided touches
/// one place instead of every call site (IAP-020).
///
/// Unknown keys are unlocked (IAP-021): a typo must never lock a user out of
/// a core feature.

final class FeatureUnlockedFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  const FeatureUnlockedFamily._()
    : super(
        retry: null,
        name: r'featureUnlockedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [featureKey] is unlocked for the cached entitlement.
  ///
  /// **The one question app code asks.** Nothing outside this file branches on
  /// the entitlement enum, so a change in how entitlements are decided touches
  /// one place instead of every call site (IAP-020).
  ///
  /// Unknown keys are unlocked (IAP-021): a typo must never lock a user out of
  /// a core feature.

  FeatureUnlockedProvider call(String featureKey) =>
      FeatureUnlockedProvider._(argument: featureKey, from: this);

  @override
  String toString() => r'featureUnlockedProvider';
}

/// Store availability, queried on demand from the Pro page.
///
/// A throwing gateway — a missing platform channel, absent store services —
/// degrades to "unavailable" rather than to an error screen (IAP-006).

@ProviderFor(storeAvailable)
const storeAvailableProvider = StoreAvailableProvider._();

/// Store availability, queried on demand from the Pro page.
///
/// A throwing gateway — a missing platform channel, absent store services —
/// degrades to "unavailable" rather than to an error screen (IAP-006).

final class StoreAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Store availability, queried on demand from the Pro page.
  ///
  /// A throwing gateway — a missing platform channel, absent store services —
  /// degrades to "unavailable" rather than to an error screen (IAP-006).
  const StoreAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storeAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storeAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return storeAvailable(ref);
  }
}

String _$storeAvailableHash() => r'e19fe9f3ccef67fa558da371c7c787033590ea8e';
