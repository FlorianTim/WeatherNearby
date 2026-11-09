import 'package:feature_flags/feature_flags.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/utils/clock.dart';
import '../data/purchase_gateway.dart';

part 'monetization_providers.g.dart';

/// The store gateway. Override with a real adapter when an app sells
/// something (ADR-0015), or with [FakePurchaseGateway] in tests.
@Riverpod(keepAlive: true)
PurchaseGateway purchaseGateway(Ref ref) => const UnavailablePurchaseGateway();

/// The gate catalogue this build ships.
///
/// Empty by requirement (IAP-022): the template gates nothing, so no
/// reference-app feature teaches derived apps that it is paid. Override in a
/// test to prove the mechanism.
@Riverpod(keepAlive: true)
FeatureGates featureGates(Ref ref) => FeatureGates.shipped;

/// The locally cached entitlement.
///
/// A **cache**, never proof of payment. The store is the source of truth
/// once purchases exist; until then this is `free` for everyone, and the
/// cache exists so the contract is already final when the first purchase
/// lands.
@Riverpod(keepAlive: true)
class CachedEntitlement extends _$CachedEntitlement {
  @override
  Entitlement build() =>
      AppSettings.entitlement.read(ref.watch(keyValueStoreProvider));

  /// Persists a store-verified entitlement together with the moment it was
  /// verified (IAP-014). The two keys are written as one operation because a
  /// timestamp without its entitlement — or the reverse — describes a state
  /// that never existed.
  Future<void> setVerified(Entitlement entitlement) async {
    final store = ref.read(keyValueStoreProvider);
    await AppSettings.entitlement.write(store, entitlement);
    await AppSettings.entitlementCheckedAt.write(
      store,
      ref.read(clockProvider).now().toUtc(),
    );
    state = entitlement;
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
@riverpod
bool featureUnlocked(Ref ref, String featureKey) {
  return ref
      .watch(featureGatesProvider)
      .isUnlocked(featureKey, ref.watch(cachedEntitlementProvider));
}

/// Store availability, queried on demand from the Pro page.
///
/// A throwing gateway — a missing platform channel, absent store services —
/// degrades to "unavailable" rather than to an error screen (IAP-006).
@riverpod
Future<bool> storeAvailable(Ref ref) async {
  try {
    return await ref.watch(purchaseGatewayProvider).isStoreAvailable();
  } catch (_) {
    return false;
  }
}
