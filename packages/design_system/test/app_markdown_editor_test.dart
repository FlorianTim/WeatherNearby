import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Literal labels, so these tests are locale-independent — which is itself a
/// property of the design: the package takes its strings as parameters.
const labels = AppMarkdownEditorLabels(
  heading: 'Überschrift',
  bold: 'Fett',
  italic: 'Kursiv',
  strikethrough: 'Durchgestrichen',
  bulletList: 'Liste',
  clearFormatting: 'Formatierung entfernen',
  undo: 'Rückgängig',
  redo: 'Wiederholen',
  reset: 'Zurücksetzen',
  save: 'Speichern',
  copy: 'Kopieren',
  share: 'Teilen',
  close: 'Schließen',
  tooLong: 'Zu lang',
);

Future<void> pumpEditor(
  WidgetTester tester, {
  String initialText = '',
  Future<void> Function(String)? onSave,
  Future<void> Function(String)? onCopy,
  Future<void> Function(String)? onShare,
  VoidCallback? onClose,
  int? maxLength,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            child: AppMarkdownEditor(
              initialText: initialText,
              labels: labels,
              onSave: onSave,
              onCopy: onCopy,
              onShare: onShare,
              onClose: onClose,
              maxLength: maxLength,
            ),
          ),
        ),
      ),
    ),
  );
}

TextField editorField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

String editorText(WidgetTester tester) => editorField(tester).controller!.text;

void main() {
  group('toolbar wiring', () {
    testWidgets('bold wraps the selection in the field', (tester) async {
      await pumpEditor(tester, initialText: 'Milch kaufen');

      editorField(tester).controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Fett'));
      await tester.pump();

      expect(editorText(tester), '**Milch** kaufen');
    });

    testWidgets('the list button prefixes the current line', (tester) async {
      await pumpEditor(tester, initialText: 'Milch');
      await tester.tap(find.byTooltip('Liste'));
      await tester.pump();

      expect(editorText(tester), '- Milch');
    });

    testWidgets('clear formatting strips markers', (tester) async {
      await pumpEditor(tester, initialText: '# **Einkauf**');
      await tester.tap(find.byTooltip('Formatierung entfernen'));
      await tester.pump();

      expect(editorText(tester), 'Einkauf');
    });
  });

  group('undo / redo / reset state machine', () {
    testWidgets('all three start disabled', (tester) async {
      await pumpEditor(tester, initialText: 'Milch');

      for (final tooltip in ['Rückgängig', 'Wiederholen', 'Zurücksetzen']) {
        final button = tester.widget<IconButton>(
          find
              .ancestor(
                of: find.byTooltip(tooltip),
                matching: find.byType(IconButton),
              )
              .first,
        );
        expect(button.onPressed, isNull, reason: tooltip);
      }
    });

    testWidgets('undo steps back and redo steps forward', (tester) async {
      await pumpEditor(tester, initialText: 'Milch');

      await tester.tap(find.byTooltip('Liste'));
      await tester.pump();
      expect(editorText(tester), '- Milch');

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pump();
      expect(editorText(tester), 'Milch');

      await tester.tap(find.byTooltip('Wiederholen'));
      await tester.pump();
      expect(editorText(tester), '- Milch');
    });

    testWidgets('reset returns to the initially loaded text', (tester) async {
      await pumpEditor(tester, initialText: 'Milch');

      await tester.tap(find.byTooltip('Liste'));
      await tester.pump();
      await tester.tap(find.byTooltip('Fett'));
      await tester.pump();
      expect(editorText(tester), isNot('Milch'));

      await tester.tap(find.byTooltip('Zurücksetzen'));
      await tester.pump();
      expect(editorText(tester), 'Milch');
    });
  });

  group('actions are optional', () {
    testWidgets('a null callback hides its button', (tester) async {
      await pumpEditor(tester);

      expect(find.byTooltip('Speichern'), findsNothing);
      expect(find.byTooltip('Kopieren'), findsNothing);
      expect(find.byTooltip('Teilen'), findsNothing);
      expect(find.byTooltip('Schließen'), findsNothing);
    });

    testWidgets('a supplied callback shows its button', (tester) async {
      await pumpEditor(
        tester,
        onSave: (_) async {},
        onCopy: (_) async {},
        onShare: (_) async {},
        onClose: () {},
      );

      expect(find.byTooltip('Speichern'), findsOneWidget);
      expect(find.byTooltip('Kopieren'), findsOneWidget);
      expect(find.byTooltip('Teilen'), findsOneWidget);
      expect(find.byTooltip('Schließen'), findsOneWidget);
    });

    testWidgets('save hands over the Markdown SOURCE', (tester) async {
      String? saved;
      await pumpEditor(
        tester,
        initialText: '# Einkauf\n\n**Milch**',
        onSave: (text) async => saved = text,
      );

      await tester.tap(find.byTooltip('Speichern'));
      await tester.pump();

      expect(
        saved,
        '# Einkauf\n\n**Milch**',
        reason: 'storage keeps the source verbatim',
      );
    });

    // MDE-009: pasted text must not carry `**` or `#`.
    testWidgets('copy and share hand over PLAIN TEXT', (tester) async {
      String? copied;
      String? shared;

      await pumpEditor(
        tester,
        initialText: '# Einkauf\n\n**Milch** und *Eier*',
        onCopy: (text) async => copied = text,
        onShare: (text) async => shared = text,
      );

      await tester.tap(find.byTooltip('Kopieren'));
      await tester.pump();
      await tester.tap(find.byTooltip('Teilen'));
      await tester.pump();

      expect(copied, 'Einkauf\n\nMilch und Eier');
      expect(shared, 'Einkauf\n\nMilch und Eier');
    });
  });

  group('the length cap is reported, never silent', () {
    testWidgets('an over-long body shows a message and blocks save', (
      tester,
    ) async {
      var saveCount = 0;
      await pumpEditor(tester, maxLength: 10, onSave: (_) async => saveCount++);

      await tester.enterText(find.byType(TextField), 'x' * 11);
      await tester.pump();

      expect(find.text('Zu lang'), findsOneWidget);
      expect(editorText(tester).length, 11, reason: 'nothing was truncated');

      final save = tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byTooltip('Speichern'),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(save.onPressed, isNull);
      expect(saveCount, 0);
    });

    testWidgets('the message clears when the body fits again', (tester) async {
      await pumpEditor(tester, maxLength: 10, onSave: (_) async {});

      await tester.enterText(find.byType(TextField), 'x' * 11);
      await tester.pump();
      expect(find.text('Zu lang'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'x' * 5);
      await tester.pump();
      expect(find.text('Zu lang'), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('every icon-only button carries a label', (tester) async {
      await pumpEditor(
        tester,
        onSave: (_) async {},
        onCopy: (_) async {},
        onShare: (_) async {},
        onClose: () {},
      );

      const everyLabel = [
        'Überschrift',
        'Fett',
        'Kursiv',
        'Durchgestrichen',
        'Liste',
        'Formatierung entfernen',
        'Rückgängig',
        'Wiederholen',
        'Zurücksetzen',
        'Kopieren',
        'Teilen',
        'Speichern',
        'Schließen',
      ];

      for (final label in everyLabel) {
        expect(find.byTooltip(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('every button meets 48 dp', (tester) async {
      await pumpEditor(tester, onSave: (_) async {});

      for (final element in find.byType(IconButton).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(48.0));
        expect(size.height, greaterThanOrEqualTo(48.0));
      }
    });

    testWidgets('renders without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await pumpEditor(
        tester,
        initialText:
            'Ein Text, der bei doppelter Schriftgröße umbrechen '
            'muss statt überzulaufen.',
        onSave: (_) async {},
        onCopy: (_) async {},
        onShare: (_) async {},
        onClose: () {},
        textScaler: const TextScaler.linear(2.0),
      );

      // Overflow throws in a test build, so reaching this line is the
      // assertion. The toolbars wrap rather than shrinking their targets.
      expect(find.byType(AppMarkdownEditor), findsOneWidget);
    });
  });
}
