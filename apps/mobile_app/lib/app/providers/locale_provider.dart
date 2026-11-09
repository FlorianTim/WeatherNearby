import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/settings/app_settings.dart';
import '../../core/storage/key_value_store.dart';

part 'locale_provider.g.dart';

/// Currently selected app locale — `null` means **follow the system**.
///
/// Reference pattern for exposing a [SettingDef] as a provider: the
/// definition (key, default, encoding) lives in [AppSettings], the notifier
/// only wires it to Riverpod. Do not re-declare the key here.
///
/// The `null` default is load-bearing: `MaterialApp.locale` must stay `null`
/// while the user follows the system language, because only then does Flutter
/// resolve the device locale against `supportedLocales`, with the ARB
/// template as the last-resort fallback. Returning a fixed `Locale('de')`
/// would silently pin every user to one language.
///
/// Widget tests must not depend on the host machine's locale — the test
/// harness seeds the store with a fixed language
/// (`test/support/test_app.dart`).
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale? build() => AppSettings.locale.read(ref.watch(keyValueStoreProvider));

  /// Selects [locale]; pass `null` to follow the system locale again.
  void setLocale(Locale? locale) {
    state = locale;
    unawaited(
      AppSettings.locale.write(ref.read(keyValueStoreProvider), locale),
    );
  }
}
