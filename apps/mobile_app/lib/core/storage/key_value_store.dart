import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'key_value_store.g.dart';

/// Minimal key-value store seam for small app settings (locale, flags, ...).
///
/// Reference pattern: providers read through this interface instead of a
/// concrete plugin, so widget tests never touch platform channels. The
/// default provider value is an [InMemoryKeyValueStore]; `bootstrap()`
/// overrides it with the persistent [SharedPreferencesKeyValueStore].
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// Non-persistent store — default in tests and before bootstrap overrides.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial])
    : _values = {...?initial};

  final Map<String, String> _values;

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

/// Persistent store backed by shared_preferences (with in-memory cache so
/// reads stay synchronous).
class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedPreferencesKeyValueStore> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return SharedPreferencesKeyValueStore._(prefs);
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Keeps another store's keys under a prefix.
///
/// A snapshot or a pre-release build installed next to the release shares one
/// preferences file with it on desktop, where the file is named after the
/// product. Prefixing the keys keeps their settings apart; the release and
/// debug builds use an empty prefix and read the keys exactly as before.
class PrefixedKeyValueStore implements KeyValueStore {
  const PrefixedKeyValueStore(this._inner, this.prefix);

  final KeyValueStore _inner;
  final String prefix;

  @override
  String? getString(String key) => _inner.getString('$prefix$key');

  @override
  Future<void> setString(String key, String value) =>
      _inner.setString('$prefix$key', value);

  @override
  Future<void> remove(String key) => _inner.remove('$prefix$key');
}

/// Overridden in `bootstrap()` with the persistent implementation.
@Riverpod(keepAlive: true)
KeyValueStore keyValueStore(Ref ref) => InMemoryKeyValueStore();
