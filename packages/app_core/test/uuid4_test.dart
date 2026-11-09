import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:test/test.dart';

void main() {
  group('Uuid4.generate', () {
    test('produces 100 000 distinct, canonical, correctly tagged values', () {
      const count = 100000;
      final seen = <String>{};

      for (var i = 0; i < count; i++) {
        final uuid = Uuid4.generate();

        expect(uuid.length, 36, reason: uuid);
        expect(Uuid4.isCanonical(uuid), isTrue, reason: uuid);

        // Assert the tagging on the characters themselves, not only via the
        // regex — a regex typo would otherwise validate its own mistake.
        expect(uuid[14], '4', reason: 'version nibble: $uuid');
        expect(
          '89ab'.contains(uuid[19]),
          isTrue,
          reason: 'variant nibble: $uuid',
        );

        seen.add(uuid);
      }

      expect(seen.length, count, reason: 'generated a duplicate');
    });

    test('is lowercase, so no call site has to normalize', () {
      for (var i = 0; i < 1000; i++) {
        final uuid = Uuid4.generate();
        expect(uuid, uuid.toLowerCase());
      }
    });

    test('places the dashes canonically', () {
      final uuid = Uuid4.generate();
      expect(uuid[8], '-');
      expect(uuid[13], '-');
      expect(uuid[18], '-');
      expect(uuid[23], '-');
      expect(uuid.split('-').map((p) => p.length).toList(), [8, 4, 4, 4, 12]);
    });
  });

  group('Uuid4.isCanonical', () {
    test('accepts a generated value', () {
      expect(Uuid4.isCanonical(Uuid4.generate()), isTrue);
      // From the interop contract's golden fixtures.
      expect(Uuid4.isCanonical('018f7d8c-7f5b-4be7-91a8-08cdb8216a11'), isTrue);
    });

    test('rejects a non-canonical or non-v4 value', () {
      const cases = {
        'uppercase': '018F7D8C-7F5B-4BE7-91A8-08CDB8216A11',
        'missing a dash': '018f7d8c7f5b-4be7-91a8-08cdb8216a11',
        'wrong version nibble': '018f7d8c-7f5b-1be7-91a8-08cdb8216a11',
        'wrong variant nibble': '018f7d8c-7f5b-4be7-71a8-08cdb8216a11',
        'too short': '018f7d8c-7f5b-4be7-91a8-08cdb8216a1',
        'too long': '018f7d8c-7f5b-4be7-91a8-08cdb8216a111',
        'braced': '{018f7d8c-7f5b-4be7-91a8-08cdb8216a11}',
        'non-hex character': '018f7d8c-7f5b-4be7-91a8-08cdb8216g11',
        'empty': '',
        // What generateId() produces — the whole reason both exist.
        'a bare 32-char hex id': '018f7d8c7f5b4be791a808cdb8216a11',
      };

      cases.forEach((name, value) {
        expect(Uuid4.isCanonical(value), isFalse, reason: name);
      });
    });
  });

  group('dependency discipline', () {
    test('no package in the workspace declares the uuid package', () {
      // Library-evaluation rule 9. If this fails, someone "cleaned up" the
      // fifteen lines above by adding a dependency — read the doc comment on
      // Uuid4 before deciding that is an improvement.
      final root = Directory.current.path.replaceAll('\\', '/');
      final workspaceRoot = root.substring(0, root.indexOf('/packages/'));

      final pubspecs = Directory(workspaceRoot)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) {
            final path = f.path.replaceAll('\\', '/');
            return path.endsWith('/pubspec.yaml') &&
                !path.contains('/build/') &&
                !path.contains('/.dart_tool/');
          });

      expect(pubspecs, isNotEmpty, reason: 'found no pubspec.yaml to check');

      for (final pubspec in pubspecs) {
        final declared = pubspec.readAsLinesSync().where(
          (line) => RegExp(r'^\s{2}uuid:').hasMatch(line),
        );

        expect(declared, isEmpty, reason: 'uuid declared in ${pubspec.path}');
      }
    });
  });
}
