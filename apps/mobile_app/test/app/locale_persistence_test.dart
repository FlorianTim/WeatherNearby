import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/providers/locale_provider.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';

void main() {
  ProviderContainer containerWith(KeyValueStore store) {
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('follows the system locale when nothing is stored', () {
    final container = containerWith(InMemoryKeyValueStore());

    // null is the whole point: only a null `MaterialApp.locale` lets Flutter
    // resolve the device language against supportedLocales.
    expect(container.read(localeProvider), isNull);
  });

  test('setLocale persists and a fresh container restores it', () async {
    final store = InMemoryKeyValueStore();

    final first = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    first.read(localeProvider.notifier).setLocale(const Locale('en'));
    await Future<void>.delayed(Duration.zero);
    first.dispose();

    // Simulates an app restart: new container, same (persisted) store.
    expect(containerWith(store).read(localeProvider), const Locale('en'));
  });

  test(
    'setLocale(null) returns to the system locale and persists that',
    () async {
      final store = InMemoryKeyValueStore({'app.locale': 'en'});

      final first = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );
      first.read(localeProvider.notifier).setLocale(null);
      await Future<void>.delayed(Duration.zero);
      expect(first.read(localeProvider), isNull);
      first.dispose();

      expect(containerWith(store).read(localeProvider), isNull);
    },
  );

  test('an unsupported stored locale falls back to the system locale', () {
    // e.g. a language dropped from the app in a later version.
    final store = InMemoryKeyValueStore({'app.locale': 'fr'});

    expect(containerWith(store).read(localeProvider), isNull);
  });
}
