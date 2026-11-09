import 'package:feature_flags/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/settings/app_settings.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';
import 'package:mobile_app/core/utils/clock.dart';
import 'package:mobile_app/features/monetization/application/monetization_providers.dart';
import 'package:mobile_app/features/monetization/data/purchase_gateway.dart';

import '../../support/fixed_clock.dart';

ProviderContainer _container({
  Map<String, String> stored = const {},
  PurchaseGateway? gateway,
  FeatureGates? gates,
  DateTime? now,
}) {
  final container = ProviderContainer(
    overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore(stored)),
      clockProvider.overrideWithValue(
        FixedClock(now ?? DateTime.utc(2026, 8, 26, 12)),
      ),
      if (gateway != null) purchaseGatewayProvider.overrideWithValue(gateway),
      if (gates != null) featureGatesProvider.overrideWithValue(gates),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the default gateway', () {
    test('reports no store and never throws', () async {
      const gateway = UnavailablePurchaseGateway();

      // Not a stub that throws: this is the correct implementation for a
      // device without store services, and for web.
      expect(await gateway.isStoreAvailable(), isFalse);
      expect(await gateway.restorePurchases(), Entitlement.free);
    });
  });

  group('store availability', () {
    test('is what the gateway reports', () async {
      final container = _container(
        gateway: FakePurchaseGateway(storeAvailable: true),
      );

      expect(await container.read(storeAvailableProvider.future), isTrue);
    });

    test('degrades to unavailable when the gateway throws', () async {
      final container = _container(gateway: FakePurchaseGateway(throws: true));

      // A missing platform channel is an expected answer, not an error
      // screen (IAP-006).
      expect(await container.read(storeAvailableProvider.future), isFalse);
    });

    test('is not queried until someone asks', () async {
      final gateway = FakePurchaseGateway();
      final container = _container(gateway: gateway);

      // Building the entitlement cache must not touch the store: a platform
      // call in the startup path is how a splash screen starts hanging on a
      // device without store services (IAP-005).
      container.read(cachedEntitlementProvider);
      expect(gateway.calls, isEmpty);

      await container.read(storeAvailableProvider.future);
      expect(gateway.calls, ['isStoreAvailable']);
    });
  });

  group('the entitlement cache', () {
    test('reads a stored entitlement', () {
      final container = _container(
        stored: {'billing.entitlement': 'pro-lifetime'},
      );

      expect(
        container.read(cachedEntitlementProvider),
        Entitlement.proLifetime,
      );
    });

    test('degrades to free for anything unreadable', () {
      for (final raw in ['', 'nonsense', 'PRO_LIFETIME', '1']) {
        final container = _container(stored: {'billing.entitlement': raw});

        // The safe direction for a cache of a paid state: the store can
        // re-grant a lost entitlement, an angry user cannot be un-granted.
        expect(
          container.read(cachedEntitlementProvider),
          Entitlement.free,
          reason: '"$raw" should decode to free',
        );
      }
    });

    test('is free when nothing was ever stored', () {
      expect(_container().read(cachedEntitlementProvider), Entitlement.free);
    });

    test('writing a verified entitlement writes both keys', () async {
      final store = InMemoryKeyValueStore();
      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 8, 26, 12)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(cachedEntitlementProvider.notifier)
          .setVerified(Entitlement.proSubscription);

      // A timestamp without its entitlement — or the reverse — describes a
      // state that never existed.
      expect(store.getString('billing.entitlement'), 'pro-subscription');
      expect(store.getString('billing.checkedAt'), '2026-08-26T12:00:00.000Z');
      expect(
        container.read(cachedEntitlementProvider),
        Entitlement.proSubscription,
      );
    });

    test('checkedAt stays null until a verification happens', () {
      final container = _container();

      expect(
        AppSettings.entitlementCheckedAt.read(
          container.read(keyValueStoreProvider),
        ),
        isNull,
      );
    });
  });

  group('feature gating', () {
    test('the shipped catalogue gates nothing', () {
      final container = _container();

      // The template must not teach a derived app that one of its features
      // is paid (IAP-022).
      expect(FeatureGates.shipped.gatedKeys, isEmpty);
      expect(container.read(featureUnlockedProvider('anything')), isTrue);
    });

    test('a gated key follows the cached entitlement', () {
      const gates = FeatureGates({'demo.feature': Entitlement.proLifetime});

      final free = _container(gates: gates);
      expect(free.read(featureUnlockedProvider('demo.feature')), isFalse);

      final pro = _container(
        gates: gates,
        stored: {'billing.entitlement': 'pro-lifetime'},
      );
      expect(pro.read(featureUnlockedProvider('demo.feature')), isTrue);
    });

    test('an unknown key stays unlocked even with a catalogue', () {
      final container = _container(
        gates: const FeatureGates({'demo.feature': Entitlement.proLifetime}),
      );

      // Fail-open: a typo in a feature key must never lock a user out of a
      // core feature (IAP-021).
      expect(container.read(featureUnlockedProvider('demo.typo')), isTrue);
    });
  });
}
