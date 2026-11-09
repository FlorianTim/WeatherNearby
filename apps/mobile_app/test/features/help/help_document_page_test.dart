import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/platform/platform_seams.dart';
import 'package:mobile_app/features/help/presentation/help_document_page.dart';

import '../../support/test_app.dart';

/// Serves exactly the assets it was given, and fails for everything else —
/// which is how the missing-asset path gets tested without deleting a file.
class _StubBundle extends CachingAssetBundle {
  _StubBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('asset not bundled in this test: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

void main() {
  group('asset resolution', () {
    test('uses the language variant when one exists', () {
      expect(
        HelpDocumentPage.assetPathFor(HelpDocument.manual, 'de'),
        'assets/help/manual_de.md',
      );
      expect(
        HelpDocumentPage.assetPathFor(HelpDocument.faq, 'en'),
        'assets/help/faq_en.md',
      );
    });

    test('falls back to English for a language with no variant', () {
      // Failing here would mean a French device sees an error instead of a
      // manual — the fallback is the difference between "not translated yet"
      // and "broken".
      expect(
        HelpDocumentPage.assetPathFor(HelpDocument.manual, 'fr'),
        'assets/help/manual_en.md',
      );
    });
  });

  group('rendering', () {
    Future<void> pump(
      WidgetTester tester, {
      required Map<String, String> assets,
      HelpDocument document = HelpDocument.manual,
      Locale locale = const Locale('de'),
      List<Uri>? launched,
      List<Uri>? refused,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            urlLauncherProvider.overrideWithValue((
              uri, {
              UrlPolicy policy = UrlPolicy.webOnly,
            }) async {
              if (!policy.allows(uri)) {
                refused?.add(uri);
                return LaunchOutcome.schemeNotAllowed;
              }
              launched?.add(uri);
              return LaunchOutcome.launched;
            }),
          ],
          child: DefaultAssetBundle(
            bundle: _StubBundle(assets),
            child: wrapWithL10n(
              HelpDocumentPage(document: document),
              locale: locale,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders the document for the active language', (tester) async {
      await pump(
        tester,
        assets: {
          'assets/help/manual_de.md': '# Anleitung\n\nEin Absatz.',
          'assets/help/manual_en.md': '# Manual\n\nA paragraph.',
        },
      );

      expect(find.textContaining('Ein Absatz.'), findsOneWidget);
      expect(find.textContaining('A paragraph.'), findsNothing);
    });

    testWidgets('follows the rendered locale, not a stored setting', (
      tester,
    ) async {
      await pump(
        tester,
        locale: const Locale('en'),
        assets: {
          'assets/help/manual_de.md': '# Anleitung\n\nEin Absatz.',
          'assets/help/manual_en.md': '# Manual\n\nA paragraph.',
        },
      );

      // A manual in a different language than the surrounding UI is a bug
      // that is hard to notice and embarrassing to ship.
      expect(find.textContaining('A paragraph.'), findsOneWidget);
    });

    testWidgets('a missing asset shows the load error, not an exception', (
      tester,
    ) async {
      await pump(tester, assets: const {});

      expect(
        find.text('Das Dokument konnte nicht geladen werden.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an https link goes through the launcher seam', (tester) async {
      final launched = <Uri>[];
      await pump(
        tester,
        launched: launched,
        assets: {
          // The whole paragraph is the link, so a tap at its centre lands on
          // the gesture recognizer rather than on surrounding prose.
          'assets/help/manual_de.md':
              '[LumbreCode](https://lumbrecode.de/apps)',
        },
      );

      await tester.tap(find.textContaining('LumbreCode'));
      await tester.pumpAndSettle();

      expect(launched, [Uri.parse('https://lumbrecode.de/apps')]);
    });

    testWidgets('a refused scheme is reported instead of opened', (
      tester,
    ) async {
      final launched = <Uri>[];
      final refused = <Uri>[];
      await pump(
        tester,
        launched: launched,
        refused: refused,
        assets: {'assets/help/manual_de.md': '[Gefahr](javascript:alert(1))'},
      );

      await tester.tap(find.textContaining('Gefahr'));
      await tester.pumpAndSettle();

      // A help text is prose, and prose gets edited. Only http/https may
      // escape it — this is where anything else stops.
      expect(launched, isEmpty);
      expect(refused, hasLength(1));
      expect(
        find.text('Dieser Link kann nicht geöffnet werden'),
        findsOneWidget,
      );
    });
  });

  group('the bundled assets', () {
    testWidgets('every document exists in every supported language', (
      tester,
    ) async {
      // Guards the convention itself: a derived app replaces the content,
      // but a missing variant would only show up on a user's device.
      for (final document in HelpDocument.values) {
        for (final language in ['de', 'en']) {
          final path = HelpDocumentPage.assetPathFor(document, language);
          final source = await rootBundle.loadString(path);
          expect(
            source.trim(),
            isNotEmpty,
            reason: '$path is bundled but empty',
          );
        }
      }
    });
  });
}
