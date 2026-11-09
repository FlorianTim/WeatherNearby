import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fails when [package] is imported anywhere outside [allowedDirectory].
///
/// Use this for every dependency that must stay behind an app-owned adapter —
/// in practice: pre-1.0 packages, packages with high API drift, and anything
/// whose types would otherwise diffuse through the codebase. See rule 8 of
/// `docs/architecture/contracts/06-library-evaluation.md`.
///
/// Why a test and not just a rule: the architecture rule alone erodes. One
/// "quick" import outside the adapter is invisible in review, and by the time
/// the package needs replacing it is referenced in thirty files. With this
/// test, a package swap touches the adapter and nothing else.
///
/// ```dart
/// // test/features/calendar/calendar_encapsulation_test.dart
/// void main() {
///   expectPackageEncapsulated(
///     package: 'kalender',
///     allowedDirectory: 'lib/features/calendar/presentation/kalender',
///   );
/// }
/// ```
///
/// [allowedDirectory] is relative to the package root (where `pubspec.yaml`
/// lives), using forward slashes. [searchRoot] defaults to `lib`.
void expectPackageEncapsulated({
  required String package,
  required String allowedDirectory,
  String searchRoot = 'lib',
}) {
  test('package:$package is imported only by its adapter', () {
    final offenders = findPackageImportsOutside(
      package: package,
      allowedDirectory: allowedDirectory,
      searchRoot: searchRoot,
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'These files reach past the adapter for package:$package. Move the '
          'code into $allowedDirectory/ and expose it through the adapter\'s '
          'own types instead:\n  ${offenders.join('\n  ')}',
    );
  });
}

/// The raw check behind [expectPackageEncapsulated], for custom assertions.
///
/// Returns the offending file paths (forward slashes, relative to the package
/// root), or an empty list when the encapsulation holds.
List<String> findPackageImportsOutside({
  required String package,
  required String allowedDirectory,
  String searchRoot = 'lib',
}) {
  final needle = 'package:$package/';
  final allowed = _normalize(allowedDirectory);
  final offenders = <String>[];

  for (final entity in Directory(searchRoot).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    // Windows and POSIX separators must compare the same way.
    final path = _normalize(entity.path);
    if (path.startsWith('$allowed/') || path == allowed) continue;
    if (!entity.readAsStringSync().contains(needle)) continue;

    offenders.add(path);
  }

  offenders.sort();
  return offenders;
}

String _normalize(String path) =>
    path.replaceAll(r'\', '/').replaceAll(RegExp(r'^\./'), '');
