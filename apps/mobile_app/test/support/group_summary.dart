// Ported from flutter-libraries packages/task_interchange/test/support/summary.dart
// (tag interchange-v0.1.0). The library keeps it in its private test support, so
// a receiving app has to copy it to run CT-16 (guide 12.2). Recorded in
// docs/template-feedback/2026-10-08-ct16-summary-projection-not-exported.md.
// Replace this file with an import the day the library exports it.
import 'dart:convert';

import 'package:task_interchange/task_interchange.dart';

/// The expected import result of a `Group` fixture, derived from what the
/// profile **decoded** — the receiver's side of guide section 12.2 and
/// contract test CT-16.
///
/// The committed `expected/<fixture>.summary.json` files are the same thing
/// as data. `lumbrecode-engineering` derives them from the raw JSON; this
/// derives them from the decoded models and the resolved tree, so a decoder
/// that loses a property, flips a relation or mis-reads a date shows up as a
/// summary that differs.
Map<String, Object?> summarizeGroup(TaskDecoded decoded, String fixture) {
  final group = (decoded.document as JsGroupDocument).group;
  final tasks = group.entries;
  final parentOf = decoded.tree.parentIndexOf;
  final kids = <int, List<int>>{};
  for (final MapEntry(key: child, value: parent) in parentOf.entries) {
    (kids[parent] ??= []).add(child);
  }

  Map<String, Object?> node(int i) =>
      _node(tasks[i], [for (final c in kids[i] ?? const <int>[]) node(c)]);

  final roots = [
    for (var i = 0; i < tasks.length; i++)
      if (!parentOf.containsKey(i)) node(i),
  ];
  return {
    'summaryVersion': 1,
    'fixture': fixture,
    'kind': 'group',
    'title': group.title,
    'tasks': _sorted(roots),
  };
}

Map<String, Object?> _node(JsTask task, List<Map<String, Object?>> children) {
  final progress = task.progress ?? 'needs-action';
  final percent = task.percentComplete ?? (progress == 'completed' ? 100 : 0);
  final body = task.description;
  return {
    'title': task.title,
    'description': body,
    'descriptionContentType': body == null
        ? null
        : (task.descriptionContentType ?? 'text/plain'),
    'start': _local(task, task.start),
    'due': _local(task, task.due),
    'timeZone': task.timeZone,
    'progress': progress,
    'percentComplete': percent,
    'priority': _band(task.priority),
    'keywords': task.keywords.toList()..sort(),
    'links': [
      for (final link in task.links.values)
        {
          'href': link.href,
          'rel': link.rel,
          'title': link.title,
          'contentType': link.contentType,
          'size': link.size,
        },
    ]..sort((a, b) => (a['href']! as String).compareTo(b['href']! as String)),
    'children': _sorted(children),
  };
}

/// `YYYY-MM-DD` for the date-only form, else the local date-time.
String? _local(JsTask task, JsLocalDateTime? value) {
  if (value == null) return null;
  if (task.showWithoutTime) {
    if (!value.isMidnight) {
      throw StateError(
        'showWithoutTime with a time is not covered by summary format 1',
      );
    }
    return value.format().substring(0, 10);
  }
  return value.format();
}

/// Guide 2.7: 0 undefined, 1-4 high, 5 normal, 6-9 low.
String _band(int priority) => switch (priority) {
  0 => 'none',
  <= 4 => 'high',
  5 => 'normal',
  _ => 'low',
};

/// Siblings are ordered by title, then by their JSON text.
List<Map<String, Object?>> _sorted(List<Map<String, Object?>> nodes) =>
    nodes..sort((a, b) {
      final byTitle = (a['title']! as String).compareTo(b['title']! as String);
      return byTitle != 0 ? byTitle : _canonical(a).compareTo(_canonical(b));
    });

String _canonical(Object? value) => jsonEncode(_keysSorted(value));

Object? _keysSorted(Object? value) => switch (value) {
  Map() => {
    for (final k in (value.keys.cast<String>().toList()..sort()))
      k: _keysSorted(value[k]),
  },
  List() => [for (final v in value) _keysSorted(v)],
  _ => value,
};
