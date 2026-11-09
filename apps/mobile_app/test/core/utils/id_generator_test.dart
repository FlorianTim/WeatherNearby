import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/utils/id_generator.dart';

void main() {
  test('produces 32 lowercase hex characters', () {
    final id = generateId();

    expect(id, hasLength(32));
    expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('produces distinct ids', () {
    // 128 bit of secure randomness: a collision inside 10k draws would mean
    // the generator is not random, not that we were unlucky.
    final ids = {for (var i = 0; i < 10000; i++) generateId()};

    expect(ids, hasLength(10000));
  });
}
