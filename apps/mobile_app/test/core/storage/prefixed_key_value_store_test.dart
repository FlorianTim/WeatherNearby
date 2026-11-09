import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';

/// A snapshot or pre-release build installed next to the release shares one
/// preferences file with it on desktop; the prefix keeps their settings apart.
void main() {
  test('stores under the prefix, reads back without it', () async {
    final inner = InMemoryKeyValueStore();
    final store = PrefixedKeyValueStore(inner, 'snapshot.');

    await store.setString('app.locale', 'en');

    expect(store.getString('app.locale'), 'en');
    expect(inner.getString('snapshot.app.locale'), 'en');
    expect(inner.getString('app.locale'), isNull);
  });

  test('does not see the keys of the unprefixed store', () async {
    final inner = InMemoryKeyValueStore({'app.locale': 'de'});
    final store = PrefixedKeyValueStore(inner, 'snapshot.');

    expect(store.getString('app.locale'), isNull);
  });

  test('removes only its own key', () async {
    final inner = InMemoryKeyValueStore({
      'app.locale': 'de',
      'snapshot.app.locale': 'en',
    });
    final store = PrefixedKeyValueStore(inner, 'snapshot.');

    await store.remove('app.locale');

    expect(inner.getString('snapshot.app.locale'), isNull);
    expect(inner.getString('app.locale'), 'de');
  });
}
