import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/settings/app_settings.dart';
import '../../core/storage/key_value_store.dart';

part 'theme_mode_provider.g.dart';

/// Light/dark preference — [ThemeMode.system] by default.
///
/// Sibling of [LocaleNotifier] and deliberately shaped the same way: both
/// answer "does the app follow the device, or did the user override it?".
/// Following the system is the default; an explicit choice is persisted.
///
/// The definition lives in [AppSettings.themeMode] — key, default and
/// encoding are declared once, there.
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() =>
      AppSettings.themeMode.read(ref.watch(keyValueStoreProvider));

  /// Selects [mode]; [ThemeMode.system] hands control back to the device.
  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(
      AppSettings.themeMode.write(ref.read(keyValueStoreProvider), mode),
    );
  }
}
