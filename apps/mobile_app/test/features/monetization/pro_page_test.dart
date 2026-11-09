import 'dart:async';

import 'package:feature_flags/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';
import 'package:mobile_app/core/utils/clock.dart';
import 'package:mobile_app/features/monetization/application/monetization_providers.dart';
import 'package:mobile_app/features/monetization/data/purchase_gateway.dart';
import 'package:mobile_app/features/monetization/presentation/pro_page.dart';

import '../../support/fixed_clock.dart';
import '../../support/test_app.dart';

Future<InMemoryKeyValueStore> _pump(
  WidgetTester tester, {
  PurchaseGateway? gateway,
  Map<String, String> stored = const {},
  bool settle = true,
}) async {
  final store = InMemoryKeyValueStore(stored);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(
          FixedClock(DateTime.utc(2026, 8, 26, 12)),
        ),
        purchaseGatewayProvider.overrideWithValue(
          gateway ?? FakePurchaseGateway(),
        ),
      ],
      child: wrapWithL10n(const ProPage()),
    ),
  );
  if (settle) await tester.pumpAndSettle();

  return store;
}

/// A gateway whose answer never arrives, so the pending state can be
/// observed. A fake that resolves immediately cannot: its microtask
/// completes before the next frame is drawn.
class _PendingGateway implements PurchaseGateway {
  final _never = Completer<bool>();

  @override
  Future<bool> isStoreAvailable() => _never.future;

  @override
  Future<Entitlement> restorePurchases() async => Entitlement.free;
}

void main() {
  group('entitlement status', () {
    testWidgets('reads as the free version by default', (tester) async {
      await _pump(tester);

      expect(find.text('Kostenlose Version'), findsOneWidget);
      expect(
        find.text('Alle Funktionen sind derzeit kostenlos.'),
        findsOneWidget,
      );
    });

    testWidgets('reads as the Pro version with a cached entitlement', (
      tester,
    ) async {
      await _pump(tester, stored: {'billing.entitlement': 'pro-lifetime'});

      expect(find.text('Pro-Version'), findsOneWidget);
    });
  });

  group('store state', () {
    testWidgets('shows the pending state while the answer is fetched', (
      tester,
    ) async {
      await _pump(tester, gateway: _PendingGateway(), settle: false);
      await tester.pump();

      // Without this state, a slow platform call is indistinguishable from
      // an unavailable store.
      expect(find.text('Store wird geprüft ...'), findsOneWidget);
    });

    testWidgets('shows unavailable when the gateway says so', (tester) async {
      await _pump(tester, gateway: FakePurchaseGateway());

      expect(find.text('Store nicht verfügbar'), findsOneWidget);
    });

    testWidgets('shows available when the gateway says so', (tester) async {
      await _pump(tester, gateway: FakePurchaseGateway(storeAvailable: true));

      expect(find.text('Store verfügbar'), findsOneWidget);
    });

    testWidgets('a throwing gateway reads as unavailable', (tester) async {
      await _pump(tester, gateway: FakePurchaseGateway(throws: true));

      expect(find.text('Store nicht verfügbar'), findsOneWidget);
    });
  });

  group('restore', () {
    testWidgets('reports when there is nothing to restore', (tester) async {
      final store = await _pump(tester, gateway: FakePurchaseGateway());

      await tester.tap(find.text('Käufe wiederherstellen'));
      await tester.pumpAndSettle();

      expect(find.text('Keine Käufe gefunden.'), findsOneWidget);
      expect(store.getString('billing.entitlement'), isNull);
    });

    testWidgets('applies and caches a restored entitlement', (tester) async {
      final store = await _pump(
        tester,
        gateway: FakePurchaseGateway(restored: Entitlement.proLifetime),
      );

      await tester.tap(find.text('Käufe wiederherstellen'));
      await tester.pumpAndSettle();

      expect(find.text('Pro wurde wiederhergestellt.'), findsOneWidget);
      expect(store.getString('billing.entitlement'), 'pro-lifetime');
      expect(store.getString('billing.checkedAt'), isNotNull);
      expect(find.text('Pro-Version'), findsOneWidget);
    });

    testWidgets('a failing store call leaves the cache alone', (tester) async {
      final store = await _pump(
        tester,
        gateway: FakePurchaseGateway(throws: true),
      );

      await tester.tap(find.text('Käufe wiederherstellen'));
      await tester.pumpAndSettle();

      expect(
        find.text('Der Store ist derzeit nicht erreichbar.'),
        findsOneWidget,
      );
      expect(store.getString('billing.entitlement'), isNull);
    });
  });

  testWidgets('sells nothing: no price, no product list, no buy action', (
    tester,
  ) async {
    await _pump(tester, gateway: FakePurchaseGateway(storeAvailable: true));

    // Every one of these is a store-review surface that must not exist
    // before it works (ADR-0015).
    expect(find.textContaining('€'), findsNothing);
    expect(find.textContaining(RegExp(r'\d+[.,]\d\d')), findsNothing);
    expect(find.text('Kaufen'), findsNothing);
    expect(find.text('Upgrade'), findsNothing);

    // Exactly one button, and it restores rather than sells.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Käufe wiederherstellen'), findsOneWidget);
  });
}
