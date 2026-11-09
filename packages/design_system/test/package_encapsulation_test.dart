import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture rules that erode unless something checks them.
///
/// Both rules below are written down elsewhere — in the library-evaluation
/// contract and in the shared-foundations plan — and prose alone does not
/// survive the first deadline. These tests are the enforcement.
///
/// They inspect **import and export directives**, not raw text: a doc comment
/// explaining why a package is *not* used must not fail the test that checks
/// it is not used.
void main() {
  /// Repository root, found by walking up from this package.
  Directory workspaceRoot() {
    final here = Directory.current.path.replaceAll('\\', '/');
    final marker = here.indexOf('/packages/');
    return Directory(marker == -1 ? here : here.substring(0, marker));
  }

  Iterable<File> dartSourcesUnder(Directory root) {
    if (!root.existsSync()) return const [];
    return root.listSync(recursive: true).whereType<File>().where((f) {
      final path = f.path.replaceAll('\\', '/');
      return path.endsWith('.dart') &&
          path.contains('/lib/') &&
          !path.contains('/build/') &&
          !path.contains('/.dart_tool/');
    });
  }

  /// The URIs a file imports or exports.
  Iterable<String> directiveUris(File file) sync* {
    final pattern = RegExp(
      '''^\\s*(?:import|export)\\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    for (final match in pattern.allMatches(file.readAsStringSync())) {
      yield match.group(1)!;
    }
  }

  test('flutter_markdown_plus is imported by exactly one file', () {
    // A UI package with API drift must sit behind an adapter, so a swap
    // touches one file rather than every screen that shows a body.
    final importers = <String>[];

    for (final file in dartSourcesUnder(workspaceRoot())) {
      final usesIt = directiveUris(
        file,
      ).any((uri) => uri.startsWith('package:flutter_markdown_plus/'));
      if (usesIt) importers.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      importers,
      hasLength(1),
      reason: 'expected only the AppMarkdownView adapter, found: $importers',
    );
    expect(
      importers.single,
      endsWith('/lib/src/widgets/app_markdown_view.dart'),
    );
  });

  test('design_system does not depend on any app', () {
    // The package takes localized strings as parameters. The moment it
    // imports one app's AppLocalizations, it stops being reusable by the
    // next app — and that is the whole reason it exists.
    final offenders = <String>[];

    final packageLib = Directory(
      '${workspaceRoot().path}/packages/design_system/lib',
    );

    for (final file in dartSourcesUnder(packageLib)) {
      final coupled = directiveUris(file).any(
        (uri) =>
            uri.startsWith('package:mobile_app/') ||
            uri.contains('app_localizations'),
      );
      if (coupled) offenders.add(file.path.replaceAll('\\', '/'));
    }

    expect(offenders, isEmpty, reason: 'app coupling found in: $offenders');
  });
}
