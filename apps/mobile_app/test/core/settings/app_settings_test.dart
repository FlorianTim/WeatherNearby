import 'package:feature_flags/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/settings/app_settings.dart';
import 'package:mobile_app/core/settings/setting_def.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';

void main() {
  group('registry', () {
    test('every setting key is unique', () {
      final keys = AppSettings.all.map((s) => s.key).toList();

      expect(keys.toSet(), hasLength(keys.length));
    });

    test('keys are namespaced', () {
      // Keeps the key space readable once a diagnostics export lists it.
      for (final setting in AppSettings.all) {
        expect(setting.key, contains('.'), reason: setting.key);
      }
    });

    test('every setting can name its default in stored form', () {
      // What the diagnostics page renders. It has to work for every entry,
      // whatever the value type, without an upcast `encode` call.
      for (final setting in AppSettings.all) {
        expect(setting.encodedDefault, isNotNull, reason: setting.key);
      }
    });
  });

  group('resetAllSettings', () {
    test('removes every registered key', () async {
      final store = InMemoryKeyValueStore({
        for (final setting in AppSettings.all) setting.key: 'whatever',
      });

      await resetAllSettings(store);

      for (final setting in AppSettings.all) {
        expect(
          store.getString(setting.key),
          isNull,
          reason: '${setting.key} survived the reset',
        );
      }
    });

    test('leaves keys that are not settings alone', () async {
      // Content lives elsewhere, but a stray key proves the reset is scoped
      // to the register rather than clearing the store.
      final store = InMemoryKeyValueStore({
        'app.locale': 'en',
        'not.a.setting': 'keep me',
      });

      await resetAllSettings(store);

      expect(store.getString('not.a.setting'), 'keep me');
    });

    test('a reset setting reads as its default again', () async {
      final store = InMemoryKeyValueStore({
        'app.themeMode': 'dark',
        'app.onboardingCompleted': 'true',
      });

      await resetAllSettings(store);

      expect(AppSettings.themeMode.read(store), ThemeMode.system);
      expect(AppSettings.onboardingCompleted.read(store), isFalse);
    });
  });

  group('SettingDef', () {
    const answer = SettingDef<int>(
      key: 'test.answer',
      defaultValue: 42,
      decode: int.tryParse,
      encode: _encodeInt,
    );

    test('reads the default when nothing is stored', () {
      expect(answer.read(InMemoryKeyValueStore()), 42);
    });

    test('round-trips a value', () async {
      final store = InMemoryKeyValueStore();

      await answer.write(store, 7);

      expect(answer.read(store), 7);
    });

    test('an undecodable value degrades to the default, it does not throw', () {
      // A settings entry must never be able to stop the app from starting.
      final store = InMemoryKeyValueStore({'test.answer': 'not-a-number'});

      expect(answer.read(store), 42);
    });

    test('reset removes the entry', () async {
      final store = InMemoryKeyValueStore({'test.answer': '7'});

      await answer.reset(store);

      expect(store.getString('test.answer'), isNull);
      expect(answer.read(store), 42);
    });
  });

  group('locale setting', () {
    test('defaults to the system locale', () {
      expect(AppSettings.locale.read(InMemoryKeyValueStore()), isNull);
    });

    test('an unsupported language falls back to the system locale', () {
      final store = InMemoryKeyValueStore({'app.locale': 'fr'});

      expect(AppSettings.locale.read(store), isNull);
    });

    test('the system choice is stored as an empty value', () async {
      final store = InMemoryKeyValueStore();

      await AppSettings.locale.write(store, null);

      expect(store.getString('app.locale'), '');
      expect(AppSettings.locale.read(store), isNull);
    });

    test('a supported language round-trips', () async {
      final store = InMemoryKeyValueStore();

      await AppSettings.locale.write(store, const Locale('en'));

      expect(store.getString('app.locale'), 'en');
      expect(AppSettings.locale.read(store), const Locale('en'));
    });
  });

  group('themeMode setting', () {
    test('defaults to the system setting', () {
      expect(
        AppSettings.themeMode.read(InMemoryKeyValueStore()),
        ThemeMode.system,
      );
    });

    test('stores the enum name, never its index', () async {
      final store = InMemoryKeyValueStore();

      await AppSettings.themeMode.write(store, ThemeMode.dark);

      // An index would silently change meaning if ThemeMode were reordered.
      expect(store.getString('app.themeMode'), 'dark');
    });

    test('an unknown value degrades to the system setting', () {
      // e.g. a mode written by a newer app version.
      final store = InMemoryKeyValueStore({'app.themeMode': 'midnight'});

      expect(AppSettings.themeMode.read(store), ThemeMode.system);
    });

    test('every mode round-trips', () async {
      for (final mode in ThemeMode.values) {
        final store = InMemoryKeyValueStore();
        await AppSettings.themeMode.write(store, mode);
        expect(AppSettings.themeMode.read(store), mode);
      }
    });
  });

  group('onboardingCompleted setting', () {
    test('defaults to false, so a first-time user sees the intro', () {
      expect(
        AppSettings.onboardingCompleted.read(InMemoryKeyValueStore()),
        isFalse,
      );
    });

    test('round-trips both values as literal words', () async {
      final store = InMemoryKeyValueStore();

      await AppSettings.onboardingCompleted.write(store, true);
      expect(store.getString('app.onboardingCompleted'), 'true');
      expect(AppSettings.onboardingCompleted.read(store), isTrue);

      await AppSettings.onboardingCompleted.write(store, false);
      expect(store.getString('app.onboardingCompleted'), 'false');
      expect(AppSettings.onboardingCompleted.read(store), isFalse);
    });

    test('anything unreadable degrades to showing the intro', () {
      // The safe direction: showing an introduction once too often is
      // recoverable, hiding it from a first-time user is not.
      for (final raw in ['1', 'yes', 'TRUE', '']) {
        final store = InMemoryKeyValueStore({'app.onboardingCompleted': raw});
        expect(
          AppSettings.onboardingCompleted.read(store),
          isFalse,
          reason: '"RAW" should degrade to false'.replaceAll('RAW', raw),
        );
      }
    });
  });

  group('entitlement setting', () {
    test('defaults to free', () {
      expect(
        AppSettings.entitlement.read(InMemoryKeyValueStore()),
        Entitlement.free,
      );
    });

    test('stores the stable string of every value, never the index', () async {
      // Pinned against a literal table on purpose: reordering the enum must
      // not silently promote a free user to Pro, or the reverse.
      const expected = {
        Entitlement.free: 'free',
        Entitlement.proLifetime: 'pro-lifetime',
        Entitlement.proSubscription: 'pro-subscription',
      };

      expect(expected.keys, containsAll(Entitlement.values));

      for (final entry in expected.entries) {
        final store = InMemoryKeyValueStore();
        await AppSettings.entitlement.write(store, entry.key);
        expect(store.getString('billing.entitlement'), entry.value);
        expect(AppSettings.entitlement.read(store), entry.key);
      }
    });

    test(
      'the values written before the vocabulary was shared still decode',
      () {
        // Template 3.2.1 stored snake_case. Losing the mapping would decode a
        // paying user's entitlement to free — the one direction this cache
        // must never fail in.
        final store = InMemoryKeyValueStore({
          'billing.entitlement': 'pro_lifetime',
        });
        expect(AppSettings.entitlement.read(store), Entitlement.proLifetime);

        final other = InMemoryKeyValueStore({
          'billing.entitlement': 'pro_subscription',
        });
        expect(
          AppSettings.entitlement.read(other),
          Entitlement.proSubscription,
        );
      },
    );

    test('an unknown value degrades to free', () {
      for (final raw in ['', 'nonsense', 'PRO_LIFETIME', '1']) {
        final store = InMemoryKeyValueStore({'billing.entitlement': raw});
        expect(
          AppSettings.entitlement.read(store),
          Entitlement.free,
          reason: '"RAW" should degrade to free'.replaceAll('RAW', raw),
        );
      }
    });
  });

  group('entitlementCheckedAt setting', () {
    test('is null until a verification is written', () {
      expect(
        AppSettings.entitlementCheckedAt.read(InMemoryKeyValueStore()),
        isNull,
      );
    });

    test('round-trips as UTC', () async {
      final store = InMemoryKeyValueStore();
      final local = DateTime(2026, 8, 26, 14, 30);

      await AppSettings.entitlementCheckedAt.write(store, local);

      // A local timestamp changes meaning when the device travels.
      final read = AppSettings.entitlementCheckedAt.read(store)!;
      expect(read.isUtc, isTrue);
      expect(read, local.toUtc());
    });

    test('an unparseable value degrades to never-verified', () {
      final store = InMemoryKeyValueStore({'billing.checkedAt': 'yesterday'});

      expect(AppSettings.entitlementCheckedAt.read(store), isNull);
    });
  });
}

String _encodeInt(int value) => '$value';
