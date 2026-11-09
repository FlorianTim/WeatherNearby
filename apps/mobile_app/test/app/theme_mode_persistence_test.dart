import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/providers/theme_mode_provider.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';

void main() {
  ProviderContainer containerWith(KeyValueStore store) {
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('follows the system setting when nothing is stored', () {
    expect(
      containerWith(InMemoryKeyValueStore()).read(themeModeProvider),
      ThemeMode.system,
    );
  });

  test('setThemeMode persists and a fresh container restores it', () async {
    final store = InMemoryKeyValueStore();

    final first = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    first.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    first.dispose();

    expect(containerWith(store).read(themeModeProvider), ThemeMode.dark);
  });

  test('the stored value is the enum name, not its index', () async {
    // Persisting the index would silently change meaning if ThemeMode ever
    // reordered — the stored value must be self-describing.
    final store = InMemoryKeyValueStore();
    final container = containerWith(store);

    container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
    await Future<void>.delayed(Duration.zero);

    expect(store.getString('app.themeMode'), 'light');
  });

  test('an unknown stored value degrades to the system setting', () {
    // e.g. a mode written by a newer app version.
    final store = InMemoryKeyValueStore({'app.themeMode': 'midnight'});

    expect(containerWith(store).read(themeModeProvider), ThemeMode.system);
  });
}
