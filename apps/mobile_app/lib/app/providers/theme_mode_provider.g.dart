// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Light/dark preference — [ThemeMode.system] by default.
///
/// Sibling of [LocaleNotifier] and deliberately shaped the same way: both
/// answer "does the app follow the device, or did the user override it?".
/// Following the system is the default; an explicit choice is persisted.
///
/// The definition lives in [AppSettings.themeMode] — key, default and
/// encoding are declared once, there.

@ProviderFor(ThemeModeNotifier)
const themeModeProvider = ThemeModeNotifierProvider._();

/// Light/dark preference — [ThemeMode.system] by default.
///
/// Sibling of [LocaleNotifier] and deliberately shaped the same way: both
/// answer "does the app follow the device, or did the user override it?".
/// Following the system is the default; an explicit choice is persisted.
///
/// The definition lives in [AppSettings.themeMode] — key, default and
/// encoding are declared once, there.
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeMode> {
  /// Light/dark preference — [ThemeMode.system] by default.
  ///
  /// Sibling of [LocaleNotifier] and deliberately shaped the same way: both
  /// answer "does the app follow the device, or did the user override it?".
  /// Following the system is the default; an explicit choice is persisted.
  ///
  /// The definition lives in [AppSettings.themeMode] — key, default and
  /// encoding are declared once, there.
  const ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'eb0a1f0624d3a0c85a3aca08e97a76e0fb7fedd9';

/// Light/dark preference — [ThemeMode.system] by default.
///
/// Sibling of [LocaleNotifier] and deliberately shaped the same way: both
/// answer "does the app follow the device, or did the user override it?".
/// Following the system is the default; an explicit choice is persisted.
///
/// The definition lives in [AppSettings.themeMode] — key, default and
/// encoding are declared once, there.

abstract class _$ThemeModeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
