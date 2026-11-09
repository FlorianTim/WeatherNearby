// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(LocaleNotifier)
const localeProvider = LocaleNotifierProvider._();

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
final class LocaleNotifierProvider
    extends $NotifierProvider<LocaleNotifier, Locale?> {
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
  const LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale?>(value),
    );
  }
}

String _$localeNotifierHash() => r'11cc268be0a675b625d501fb510bd332030995dc';

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

abstract class _$LocaleNotifier extends $Notifier<Locale?> {
  Locale? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Locale?, Locale?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale?, Locale?>,
              Locale?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
