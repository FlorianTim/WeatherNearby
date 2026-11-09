import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpView(
  WidgetTester tester, {
  required String source,
  String contentType = kMarkdownContentType,
  void Function(Uri uri)? onLinkTap,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            child: AppMarkdownView(
              source: source,
              contentType: contentType,
              onLinkTap: onLinkTap,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('content type decides the rendering', () {
    test('recognises Markdown regardless of parameters or case', () {
      expect(AppMarkdownView.rendersAsMarkdown('text/markdown'), isTrue);
      expect(
        AppMarkdownView.rendersAsMarkdown('text/markdown; charset=utf-8'),
        isTrue,
      );
      expect(AppMarkdownView.rendersAsMarkdown('TEXT/MARKDOWN'), isTrue);
      expect(AppMarkdownView.rendersAsMarkdown('  text/markdown  '), isTrue);
    });

    test('treats everything else as not-Markdown', () {
      expect(AppMarkdownView.rendersAsMarkdown('text/plain'), isFalse);
      expect(AppMarkdownView.rendersAsMarkdown('text/html'), isFalse);
      expect(AppMarkdownView.rendersAsMarkdown('application/json'), isFalse);
      expect(AppMarkdownView.rendersAsMarkdown(''), isFalse);
    });

    // The rule from the interop contract: never guess that plain text is
    // Markdown. Guessing corrupts the body on the way to the screen and makes
    // a later re-export declare something the content is not.
    testWidgets('renders a text/plain body literally', (tester) async {
      await pumpView(
        tester,
        source: '**not bold** and # not a heading',
        contentType: 'text/plain',
      );

      expect(
        find.text('**not bold** and # not a heading'),
        findsOneWidget,
        reason: 'the markers must still be visible',
      );
    });

    testWidgets('renders an unknown content type literally', (tester) async {
      await pumpView(tester, source: '**not bold**', contentType: 'text/html');

      expect(find.text('**not bold**'), findsOneWidget);
    });
  });

  group('Markdown rendering', () {
    testWidgets('renders headings, emphasis and lists without error', (
      tester,
    ) async {
      await pumpView(
        tester,
        source:
            '# Überschrift\n\n'
            'Bitte **dunkle Schokolade** und *Sahne* verwenden.\n\n'
            '~~Kein Zucker~~\n\n'
            '- 12 Kerzen\n'
            '- Streichhölzer\n',
      );

      // The raw markers must NOT be visible: this body is Markdown.
      expect(find.textContaining('**'), findsNothing);
      expect(find.textContaining('- 12 Kerzen'), findsNothing);
      expect(find.byType(AppMarkdownView), findsOneWidget);
    });

    testWidgets('renders an empty body without throwing', (tester) async {
      await pumpView(tester, source: '');
      expect(find.byType(AppMarkdownView), findsOneWidget);
    });
  });

  group('links are inert until explicitly wired', () {
    testWidgets('a tap reaches onLinkTap as a parsed Uri', (tester) async {
      final tapped = <Uri>[];
      await pumpView(
        tester,
        source: '[Rezept](https://example.invalid/rezept)',
        onLinkTap: tapped.add,
      );

      await tester.tap(find.textContaining('Rezept'));
      await tester.pump();

      expect(tapped, [Uri.parse('https://example.invalid/rezept')]);
    });

    testWidgets('a null callback makes links untappable', (tester) async {
      await pumpView(
        tester,
        source: '[Rezept](https://example.invalid/rezept)',
      );

      // Nothing to assert beyond "this does not throw and nothing is
      // launched": with no callback the widget wires no tap handler at all.
      await tester.tap(find.textContaining('Rezept'), warnIfMissed: false);
      await tester.pump();

      expect(find.byType(AppMarkdownView), findsOneWidget);
    });

    // The renderer hands over the target; it does not decide whether the
    // scheme may be opened. That decision belongs to the app's allowlisted
    // launcher seam, and this test documents the division.
    testWidgets('hands over a non-web scheme unchanged, without opening it', (
      tester,
    ) async {
      final tapped = <Uri>[];
      await pumpView(
        tester,
        source: '[Datei](file:///etc/passwd)',
        onLinkTap: tapped.add,
      );

      await tester.tap(find.textContaining('Datei'));
      await tester.pump();

      expect(tapped, [Uri.parse('file:///etc/passwd')]);
    });
  });

  testWidgets('renders without overflow at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpView(
      tester,
      source:
          '# Eine ziemlich lange Überschrift für ein schmales Display\n\n'
          'Ein Absatz mit **fettem Text**, der bei doppelter '
          'Schriftgröße umbrechen muss statt überzulaufen.\n\n'
          '- Ein Listeneintrag, der ebenfalls umbricht\n',
      textScaler: const TextScaler.linear(2.0),
    );

    // Overflow throws in a test build, so reaching this line is the assertion.
    expect(find.byType(AppMarkdownView), findsOneWidget);
  });
}
