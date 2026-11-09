import 'package:feature_flags/feature_flags.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../storage/key_value_store.dart';
import 'setting_def.dart';

/// Every persisted setting of this app, in one place.
///
/// Add a setting here, not next to the widget that reads it. [all] is what
/// makes the set enumerable — a diagnostics screen or an export feature can
/// walk it instead of hardcoding a second list that silently falls behind.
abstract final class AppSettings {
  /// Selected app language; `null` means **follow the system**.
  ///
  /// The empty string is the stored form of "follow the system", so the
  /// difference between "never chosen" and "explicitly chose system" is not
  /// lost — both read back as `null`, but only the latter has an entry.
  static const SettingDef<Locale?> locale = SettingDef<Locale?>(
    key: 'app.locale',
    defaultValue: null,
    decode: _decodeLocale,
    encode: _encodeLocale,
  );

  /// Light/dark preference; [ThemeMode.system] follows the device.
  static const SettingDef<ThemeMode> themeMode = SettingDef<ThemeMode>(
    key: 'app.themeMode',
    defaultValue: ThemeMode.system,
    decode: _decodeThemeMode,
    encode: _encodeThemeMode,
  );

  /// Whether the first-start intro has been finished or skipped.
  ///
  /// The default is `false`, and every unreadable value degrades to it — see
  /// [_decodeBool]. That is the safe direction: showing an introduction once
  /// too often is recoverable, hiding it from a first-time user is not.
  static const SettingDef<bool> onboardingCompleted = SettingDef<bool>(
    key: 'app.onboardingCompleted',
    defaultValue: false,
    decode: _decodeBool,
    encode: _encodeBool,
  );

  /// Locally cached entitlement (spec 0007).
  ///
  /// A **cache**, never proof of payment: the platform store is the source
  /// of truth once purchases exist. Unknown values degrade to
  /// [Entitlement.free] — the store can re-grant a lost entitlement on the
  /// next restore, while a wrongly granted one cannot be taken back without
  /// an angry user.
  static const SettingDef<Entitlement> entitlement = SettingDef<Entitlement>(
    key: 'billing.entitlement',
    defaultValue: Entitlement.free,
    decode: _decodeEntitlement,
    encode: _encodeEntitlement,
  );

  /// When the entitlement was last verified against the store, in UTC.
  ///
  /// `null` means "never" — which is the truth for the whole template, since
  /// no store adapter ships with it (ADR-0015). Stored in UTC because a local
  /// timestamp changes meaning when the device travels.
  static const SettingDef<DateTime?> entitlementCheckedAt =
      SettingDef<DateTime?>(
        key: 'billing.checkedAt',
        defaultValue: null,
        decode: _decodeUtcTimestamp,
        encode: _encodeUtcTimestamp,
      );

  /// All settings this app defines. Keep in sync when adding one — a test
  /// asserts that every key is unique.
  static const List<SettingDescriptor> all = <SettingDescriptor>[
    locale,
    themeMode,
    onboardingCompleted,
    entitlement,
    entitlementCheckedAt,
  ];
}

/// Removes every registered setting, so the next read yields the defaults.
///
/// Defined over [AppSettings.all] rather than over a hand-written list: a
/// setting added later is reset automatically, which is the whole point of
/// making the register enumerable.
///
/// Deliberately **not** the same action as `wipeAllData()`. That one clears
/// content and keeps settings; this one clears settings and keeps content.
/// Two blast radii, two actions, two confirmations (spec 0005, SET-036/037).
Future<void> resetAllSettings(KeyValueStore store) async {
  for (final setting in AppSettings.all) {
    await store.remove(setting.key);
  }
}

/// Stored form of "follow the system locale".
const String kSystemLocaleValue = '';

Locale? _decodeLocale(String raw) {
  if (raw == kSystemLocaleValue) return null;

  // A language that the app no longer ships (dropped in a later version)
  // must fall back to the system locale, not to a hardcoded one.
  final isSupported = AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == raw,
  );
  return isSupported ? Locale(raw) : null;
}

String _encodeLocale(Locale? value) =>
    value?.languageCode ?? kSystemLocaleValue;

/// Persists the enum **name**, never its index: reordering `ThemeMode` must
/// not change what a stored value means.
ThemeMode? _decodeThemeMode(String raw) {
  for (final mode in ThemeMode.values) {
    if (mode.name == raw) return mode;
  }
  return null;
}

String _encodeThemeMode(ThemeMode value) => value.name;

/// Stored as the literal words, never as `1`/`0`: a numeric flag is the kind
/// of value another platform's storage layer helpfully converts.
bool? _decodeBool(String raw) => switch (raw) {
  'true' => true,
  'false' => false,
  _ => null,
};

String _encodeBool(bool value) => value ? 'true' : 'false';

/// Delegates to the domain rather than re-implementing the mapping.
///
/// A second copy here would drift: it did, and it silently dropped the
/// legacy `pro_lifetime` form that [Entitlement.fromStored] still accepts —
/// decoding a paying user's entitlement to free. One decoder, one place.
///
/// `fromStored` already degrades unknown values to [Entitlement.free], which
/// is this setting's default, so it never needs to return `null`.
Entitlement? _decodeEntitlement(String raw) => Entitlement.fromStored(raw);

String _encodeEntitlement(Entitlement value) => value.storedValue;

/// ISO-8601 in UTC. An unparseable value degrades to "never verified"
/// rather than to a wrong moment.
DateTime? _decodeUtcTimestamp(String raw) => DateTime.tryParse(raw)?.toUtc();

/// `null` is stored as the empty string, so "explicitly cleared" and "never
/// written" both read back as `null` without needing a second key.
String _encodeUtcTimestamp(DateTime? value) =>
    value?.toUtc().toIso8601String() ?? '';
