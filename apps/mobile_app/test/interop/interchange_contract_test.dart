import 'dart:convert';
import 'dart:io';

import 'package:task_interchange/task_interchange.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration proof for the `task_interchange` dependency (ADR-0017).
///
/// The code under test lives in `flutter-libraries`, pinned by tag. The
/// fixtures are the baseline's golden fixtures under `.lumbrecode/schemas/`,
/// read by **directory**: a fixture added by a baseline sync is exercised
/// without touching this file, and an invalid fixture this file has no
/// documented outcome for fails loudly instead of being skipped.
///
/// The library's own suite asserts exact fixture counts for the baseline it was
/// released against;
/// this one deliberately does not, because the template adopts the baseline
/// on its own schedule (feedback entry on the baseline lag).
final Directory _root = Directory('../../.lumbrecode/schemas');

List<File> _fixtures(String schema) {
  final dir = Directory('${_root.path}/$schema/v1/examples');
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _name(File f) => f.uri.pathSegments.last;
bool _invalid(File f) => _name(f).startsWith('9');

/// The documented outcome of the `9x-invalid-` task fixtures (the fixtures'
/// README and the library's tolerance table): four cannot be imported at all,
/// three are malformed emissions a receiver reads tolerantly.
const Map<String, RejectionReason?> _taskInvalidOutcome = {
  '90-invalid-missing-type.json': RejectionReason.missingType,
  '93-invalid-empty-title.json': RejectionReason.invalidRequired,
  '95-invalid-group-without-entries.json': RejectionReason.invalidEntries,
  '96-invalid-uid-not-uuid.json': RejectionReason.invalidRequired,
  // Tolerated: decoded, and the loss is reported (or kept verbatim for 92).
  '91-invalid-due-with-offset.json': null,
  '92-invalid-progress-value.json': null,
  '94-invalid-percent-out-of-range.json': null,
  // Tolerated: the `false` keyword value is dropped and reported
  // (`invalidProperty`); the rest of the file is read.
  '97-invalid-keyword-value-false.json': null,
};

void main() {
  final taskFixtures = _fixtures('jscalendar-task');
  final accepted = taskFixtures.where((f) => !_invalid(f)).toList();
  final invalid = taskFixtures.where(_invalid).toList();

  test('fixtures are found (cwd must be apps/mobile_app)', () {
    expect(accepted, isNotEmpty);
    expect(invalid, isNotEmpty);
  });

  group('accepted task fixtures', () {
    for (final file in accepted) {
      final name = _name(file);
      final source = file.readAsStringSync();

      test('$name conforms and decodes without surprises', () {
        expect(JsCalendarConformance.check(jsonDecode(source)), isEmpty);
        final result = TaskInterchange.decodeString(source);
        expect(result, isA<TaskDecoded>());
        final warnings = (result as TaskDecoded).warnings;
        // A one-task document cannot contain its own parent (INT-111).
        final dangling = name == '11-task-subtask.json';
        expect(
          warnings.map((w) => w.toString()),
          dangling ? hasLength(1) : isEmpty,
          reason: warnings.join('\n'),
        );
      });

      test('$name: encode(decode(x)) equals x semantically', () {
        final decoded = TaskInterchange.decodeString(source) as TaskDecoded;
        final encoded = TaskInterchange.encode(decoded.document);
        expect(jsonDecode(encoded), jsonDecode(source));
      });

      test('$name: encoding is deterministic', () {
        final doc =
            (TaskInterchange.decodeString(source) as TaskDecoded).document;
        expect(
          TaskInterchange.encodeBytes(doc),
          TaskInterchange.encodeBytes(doc),
        );
      });
    }
  });

  group('invalid task fixtures', () {
    for (final file in invalid) {
      final name = _name(file);
      final source = file.readAsStringSync();

      test('$name violates the schema with a named rule', () {
        final violations = JsCalendarConformance.check(jsonDecode(source));
        expect(violations, isNotEmpty);
        for (final v in violations) {
          expect(v.rule, matches(RegExp(r'^[a-zA-Z]+$')));
        }
      });

      test('$name has a documented decode outcome', () {
        expect(
          _taskInvalidOutcome,
          contains(name),
          reason:
              'New invalid fixture: document its outcome in '
              '_taskInvalidOutcome (and in the library tolerance table).',
        );
        final expected = _taskInvalidOutcome[name];
        final result = TaskInterchange.decodeString(source);
        if (expected != null) {
          expect(result, isA<TaskRejected>());
          final rejection = (result as TaskRejected).rejection;
          expect(rejection.reason, expected);
          expect(rejection.message, isNotEmpty);
        } else {
          expect(result, isA<TaskDecoded>());
        }
      });
    }
  });

  // Expected summaries (CT-16) are compared in packing_list_contract_test.dart,
  // which finds every accepted Group fixture by directory.

  test('an unknown property survives decode and encode', () {
    final base =
        jsonDecode(accepted.first.readAsStringSync()) as Map<String, Object?>;
    final withUnknown = {
      ...base,
      'x-future-thing': {
        'a': [1, 2, 3],
        'b': 'kept',
      },
    };
    final decoded = TaskInterchange.decodeJson(withUnknown) as TaskDecoded;
    final out =
        jsonDecode(TaskInterchange.encode(decoded.document))
            as Map<String, Object?>;
    expect(out['x-future-thing'], withUnknown['x-future-thing']);
  });

  group('exchange fixtures (envelope is not part of the library yet)', () {
    final exchange = _fixtures('lumbrecode-exchange');
    final accepted = exchange.where((f) => !_invalid(f)).toList();

    test('fixtures are found', () => expect(accepted, isNotEmpty));

    for (final file in accepted) {
      final name = _name(file);
      final envelope = jsonDecode(file.readAsStringSync());
      if (envelope is! Map<String, Object?>) continue;
      final type = envelope['datacontenttype'];
      final isTask =
          type == 'application/jscalendar+json;type=task' ||
          type == 'application/jscalendar+json;type=group';
      if (!isTask) continue;

      test('$name: the unwrapped data decodes like a plain document', () {
        final result = TaskInterchange.decodeJson(envelope['data']);
        expect(result, isA<TaskDecoded>());
        final doc = (result as TaskDecoded).document;
        expect(jsonDecode(TaskInterchange.encode(doc)), envelope['data']);
      });
    }

    test('malformed JSON is rejected, not thrown', () {
      final f = exchange.firstWhere((f) => _name(f).startsWith('90-'));
      final result = TaskInterchange.decodeString(f.readAsStringSync());
      expect(result, isA<TaskRejected>());
      expect(
        (result as TaskRejected).rejection.reason,
        RejectionReason.malformedJson,
      );
    });
  });
}
