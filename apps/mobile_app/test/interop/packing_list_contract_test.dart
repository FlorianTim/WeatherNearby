import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_interchange/task_interchange.dart';

import '../support/group_summary.dart';

/// CT-16 (interop guide 12.2) and the packing-list conventions of guide 2.9,
/// proven against the **decoder** the app will import through.
///
/// "Import" here is `TaskInterchange.decodeString` plus the resolved tree: the
/// persistence half (lists, tasks, one transaction) arrives with slice 8 of
/// `docs/delivery/implementation-plans/0001-todo-reference-app.md`. The
/// obligations that need it are listed at the bottom as skipped tests, so they
/// stay visible instead of being forgotten.
///
/// Fixtures are found by **directory**, never by a hand-picked list: a `5x`
/// fixture (and its `expected/` summary) added by a baseline sync is exercised
/// without touching this file.
final Directory _examples = Directory(
  '../../.lumbrecode/schemas/jscalendar-task/v1/examples',
);

String _name(File f) => f.uri.pathSegments.last;

List<File> _groupFixtures() =>
    _examples
        .listSync()
        .whereType<File>()
        .where((f) => _name(f).startsWith('5') && _name(f).endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

File _summaryOf(File fixture) => File(
  '${_examples.path}/expected/'
  '${_name(fixture).replaceAll('.json', '.summary.json')}',
);

File _fixture(String name) => File('${_examples.path}/$name');

TaskDecoded _decode(File f) =>
    TaskInterchange.decodeString(f.readAsStringSync()) as TaskDecoded;

JsGroup _group(TaskDecoded d) => (d.document as JsGroupDocument).group;

Map<String, Object?> _asMap(File f) =>
    jsonDecode(f.readAsStringSync()) as Map<String, Object?>;

Map<String, Object?> _entry(Map<String, Object?> template, int i) => {
  ...template,
  'uid': '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
  'title': 'Item $i',
}..remove('relatedTo');

void main() {
  final groups = _groupFixtures();
  final packing = groups
      .where((f) => _name(f).contains('packing-list'))
      .toList();

  test(
    'Group fixtures and packing lists are found (cwd = apps/mobile_app)',
    () {
      expect(groups, isNotEmpty);
      expect(packing, isNotEmpty);
    },
  );

  test('every accepted Group fixture has a summary, and no other exists', () {
    final summaries = Directory(
      '${_examples.path}/expected',
    ).listSync().whereType<File>().map(_name).toSet();
    expect(summaries, groups.map((f) => _name(_summaryOf(f))).toSet());
  });

  group('CT-16: every accepted Group fixture imports to its summary', () {
    for (final file in groups) {
      test(_name(file), () {
        expect(
          summarizeGroup(_decode(file), _name(file)),
          jsonDecode(_summaryOf(file).readAsStringSync()),
        );
      });

      test('${_name(file)}: decodes without warnings', () {
        expect(_decode(file).warnings, isEmpty);
      });
    }
  });

  group('packing-list conventions (guide 2.9)', () {
    final byCategory = _fixture('52-group-packing-list-by-category.json');

    test('sections become parents, items their children', () {
      final d = _decode(byCategory);
      final tasks = _group(d).entries;
      final parentOf = d.tree.parentIndexOf;
      expect(
        {for (final i in parentOf.values.toSet()) tasks[i].title},
        {'Kleidung', 'Technik'},
      );
      for (final MapEntry(key: child, value: parent) in parentOf.entries) {
        // two levels only: a section never has a section above it
        expect(parentOf.containsKey(parent), isFalse);
        expect(tasks[child].title, isNot(anyOf('Kleidung', 'Technik')));
      }
    });

    test(
      'in-process keeps its percentage; completed and open stay as sent',
      () {
        final tasks = _group(_decode(byCategory)).entries;
        final tshirt = tasks.firstWhere((t) => t.title == 'T-Shirt ×3');
        expect(tshirt.progress, 'in-process');
        expect(tshirt.percentComplete, 66);
        final socks = tasks.firstWhere((t) => t.title == 'Socken 3 Paar');
        expect(socks.progress, 'completed');
        final jacket = tasks.firstWhere((t) => t.title == 'Regenjacke');
        expect(jacket.progress ?? 'needs-action', 'needs-action');
      },
    );

    test('titles are kept exactly, quantity and unit included', () {
      final titles = [
        for (final f in packing)
          ..._group(_decode(f)).entries.map((t) => t.title),
      ];
      expect(
        titles,
        containsAll(['T-Shirt ×3', 'Socken 3 Paar', 'Waschmittel 1,5 l']),
      );
      // the wire form survives a decode/encode round trip unchanged
      for (final f in packing) {
        final out =
            jsonDecode(TaskInterchange.encode(_decode(f).document))
                as Map<String, Object?>;
        expect(out, _asMap(f), reason: _name(f));
      }
    });

    test('to-buy, last-minute and category keywords are stored', () {
      final keywords = {
        for (final f in packing)
          for (final t in _group(_decode(f)).entries) ...t.keywords,
      };
      expect(keywords, containsAll(['to-buy', 'last-minute', 'clothing']));
    });

    test('a last-minute due stays date-only', () {
      final dated = [
        for (final f in packing)
          ..._group(_decode(f)).entries.where((t) => t.due != null),
      ];
      expect(
        dated,
        isNotEmpty,
        reason: 'a fixture should carry a date-only due',
      );
      for (final t in dated) {
        expect(t.keywords, contains('last-minute'));
        expect(t.showWithoutTime, isTrue);
        expect(t.due!.isMidnight, isTrue);
      }
    });

    test('prodId never changes the import', () {
      const other = '-//Somebody Else//Other App 9//EN';
      for (final f in packing) {
        final json = _asMap(f)..['prodId'] = other;
        for (final t
            in (json['entries']! as List).cast<Map<String, Object?>>()) {
          t['prodId'] = other;
        }
        expect(
          summarizeGroup(
            TaskInterchange.decodeJson(json) as TaskDecoded,
            _name(f),
          ),
          jsonDecode(_summaryOf(f).readAsStringSync()),
          reason: _name(f),
        );
      }
    });

    test('files of one trip are independent lists, never merged', () {
      final a = _group(_decode(byCategory));
      final b = _group(
        _decode(_fixture('53-group-packing-list-single-set.json')),
      );
      expect(b.title, startsWith(a.title!), reason: 'shared trip prefix');
      expect(a.uid, isNot(b.uid));
      final uidsA = a.entries.map((t) => t.uid).toSet();
      expect(b.entries.map((t) => t.uid).toSet().intersection(uidsA), isEmpty);
    });
  });

  group('whole-file rejection', () {
    final source = _fixture('53-group-packing-list-single-set.json');
    Map<String, Object?> template() =>
        (_asMap(source)['entries']! as List).first as Map<String, Object?>;

    test('501 entries are rejected as a whole', () {
      final json = _asMap(source)
        ..['entries'] = [for (var i = 0; i < 501; i++) _entry(template(), i)];
      final r = TaskInterchange.decodeJson(json);
      expect(r, isA<TaskRejected>());
      expect(
        (r as TaskRejected).rejection.reason,
        RejectionReason.invalidEntries,
      );
    });

    test('500 entries are accepted (the boundary)', () {
      final json = _asMap(source)
        ..['entries'] = [for (var i = 0; i < 500; i++) _entry(template(), i)];
      expect(TaskInterchange.decodeJson(json), isA<TaskDecoded>());
    });

    test('malformed JSON is rejected, not thrown', () {
      final r = TaskInterchange.decodeString('{"@type": "Group", ');
      expect(r, isA<TaskRejected>());
      expect(
        (r as TaskRejected).rejection.reason,
        RejectionReason.malformedJson,
      );
    });

    test('one unusable item rejects the whole file', () {
      final json = _asMap(source);
      ((json['entries']! as List).last as Map<String, Object?>)['title'] = '';
      expect(TaskInterchange.decodeJson(json), isA<TaskRejected>());
    });
  });

  group('obligations that need the import slice', () {
    const why =
        'needs persistence (slice 2) and the import path (slice 8); see '
        'docs/delivery/implementation-plans/0001-todo-reference-app.md';

    test(
      'two files with the same trip prefix produce two separate lists',
      () {},
      skip: why,
    );
    test(
      'importing the same file twice creates two lists (guide 10.3)',
      () {},
      skip: why,
    );
    test('a rejected file writes nothing', () {}, skip: why);
    test(
      'the section / sub-task shape survives the database round trip',
      () {},
      skip: why,
    );
  });
}
