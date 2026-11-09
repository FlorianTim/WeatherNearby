import 'package:feature_flags/feature_flags.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureFlags', () {
    test('unknown keys are off', () {
      expect(const FeatureFlags.empty().isEnabled('anything'), isFalse);
    });

    test('returns the configured value', () {
      const flags = FeatureFlags({'a': true, 'b': false});
      expect(flags.isEnabled('a'), isTrue);
      expect(flags.isEnabled('b'), isFalse);
      expect(flags.knownKeys, containsAll(<String>['a', 'b']));
    });
  });

  group('Entitlement', () {
    test('free is not pro, paid levels are', () {
      expect(Entitlement.free.isPro, isFalse);
      expect(Entitlement.proLifetime.isPro, isTrue);
      expect(Entitlement.proSubscription.isPro, isTrue);
    });

    test('everyone satisfies a free requirement', () {
      for (final entitlement in Entitlement.values) {
        expect(entitlement.satisfies(Entitlement.free), isTrue);
      }
    });

    test('any paid entitlement satisfies any paid requirement', () {
      expect(
        Entitlement.proSubscription.satisfies(Entitlement.proLifetime),
        isTrue,
      );
      expect(Entitlement.free.satisfies(Entitlement.proLifetime), isFalse);
    });

    test('stored values round-trip and unknown values degrade to free', () {
      for (final entitlement in Entitlement.values) {
        expect(Entitlement.fromStored(entitlement.storedValue), entitlement);
      }
      expect(Entitlement.fromStored(null), Entitlement.free);
      expect(
        Entitlement.fromStored('pro_from_a_future_version'),
        Entitlement.free,
      );
    });

    test('stored values are stable strings, never enum indices', () {
      // Pinned against literals on purpose: this vocabulary is shared with
      // every other LumbreCode stack (schemas/entitlement/v1), so a rename
      // here would silently break an entitlement written by a sibling app.
      expect(Entitlement.free.storedValue, 'free');
      expect(Entitlement.proLifetime.storedValue, 'pro-lifetime');
      expect(Entitlement.proSubscription.storedValue, 'pro-subscription');
    });

    test('the pre-3.2.2 snake_case forms still decode', () {
      // Dropping them would decode a paying user's entitlement to free -
      // the one direction this cache must never fail in.
      expect(Entitlement.fromStored('pro_lifetime'), Entitlement.proLifetime);
      expect(
        Entitlement.fromStored('pro_subscription'),
        Entitlement.proSubscription,
      );
    });
  });

  group('FeatureGates', () {
    const gates = FeatureGates({'backup.export': Entitlement.proLifetime});

    test('gated feature stays locked for free users', () {
      expect(gates.isUnlocked('backup.export', Entitlement.free), isFalse);
    });

    test('gated feature unlocks for a paid entitlement', () {
      expect(
        gates.isUnlocked('backup.export', Entitlement.proLifetime),
        isTrue,
      );
      expect(
        gates.isUnlocked('backup.export', Entitlement.proSubscription),
        isTrue,
      );
    });

    test('fail-open: an unknown key is always unlocked', () {
      // The important guarantee: a typo in a feature key must never lock a
      // user out of a core feature.
      expect(gates.isUnlocked('typo.in.key', Entitlement.free), isTrue);
      expect(
        const FeatureGates.none().isUnlocked('anything', Entitlement.free),
        isTrue,
      );
    });

    test('the shipped catalog gates nothing by default', () {
      expect(FeatureGates.shipped.gatedKeys, isEmpty);
    });
  });
}
