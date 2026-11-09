import '../storage/key_value_store.dart';

/// The non-generic face of a [SettingDef].
///
/// Exists so a registry can list settings of different value types without
/// running into Dart's covariance rules — enumerating keys is safe, calling
/// `encode` through an upcast `SettingDef<Object?>` would not be.
abstract interface class SettingDescriptor {
  /// Storage key. Prefix with the area (`app.`, `sync.`, …) so the key space
  /// stays readable when a diagnostics export lists it.
  String get key;

  /// The default, in its **stored** form.
  ///
  /// Part of the non-generic face because that is what a diagnostics view
  /// needs: "what would this key read as if nothing were stored?" answered
  /// without knowing the value type. Producing it inside [SettingDef] keeps
  /// `encode` away from an upcast caller.
  String get encodedDefault;
}

/// One persisted app setting: key, default, and how it is encoded.
///
/// Why a declarative definition instead of a hand-written notifier per
/// setting:
///
///  - **One place per setting.** Key, default and encoding cannot drift
///    apart across a read site and a write site.
///  - **Enumerable.** [SettingDescriptor] makes "which settings exist?"
///    answerable — needed for diagnostics and for an export/backup feature.
///    Hand-written notifiers can only be found by grepping.
///  - **A migration hook has somewhere to live.** When a stored format
///    changes, [decode] is the single place that has to understand the old
///    one.
///
/// [decode] **must not throw**. A value written by a newer app version, or a
/// corrupted one, has to degrade to [defaultValue] — a settings entry must
/// never be able to prevent the app from starting. Return `null` from
/// [decode] to say "unusable, take the default".
class SettingDef<T> implements SettingDescriptor {
  const SettingDef({
    required this.key,
    required this.defaultValue,
    required this.decode,
    required this.encode,
  });

  @override
  final String key;

  /// Used when nothing is stored, and whenever [decode] rejects the value.
  final T defaultValue;

  /// Parses a stored value. Returns `null` when it cannot be used.
  final T? Function(String raw) decode;

  /// Serialises a value. Must be stable across app versions — never persist
  /// an enum index or anything else that changes when code is reordered.
  final String Function(T value) encode;

  /// Reads the current value, falling back to [defaultValue].
  T read(KeyValueStore store) {
    final raw = store.getString(key);
    if (raw == null) return defaultValue;
    return decode(raw) ?? defaultValue;
  }

  /// Persists [value].
  Future<void> write(KeyValueStore store, T value) =>
      store.setString(key, encode(value));

  @override
  String get encodedDefault => encode(defaultValue);

  /// Removes the stored value, so the next read yields [defaultValue].
  Future<void> reset(KeyValueStore store) => store.remove(key);
}
