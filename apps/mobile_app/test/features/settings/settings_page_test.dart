import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/settings/presentation/settings_page.dart';

import '../../support/test_app.dart';
import '../../support/ui_test_profile.dart';

/// Records which navigation row was tapped, so the hub's wiring can be
/// asserted without a router.
class _Taps {
  final List<String> opened = [];

  void record(String what) => opened.add(what);
}

/// The page is provider-free, so it can be pumped without a ProviderScope.
Future<void> _pump(
  WidgetTester tester, {
  Locale? currentLocale,
  ThemeMode themeMode = ThemeMode.system,
  ValueChanged<Locale?>? onLocaleChanged,
  ValueChanged<ThemeMode>? onThemeModeChanged,
  _Taps? taps,
  bool withBufferedError = false,
  bool withDiagnostics = true,
  bool inspectAllContent = false,
}) async {
  UiTestProfile.phone.apply(tester);
  if (inspectAllContent) {
    // Whole-content ordering inspection, not a phone interaction check.
    tester.view.physicalSize = const Size(1080, 4200);
  }

  final record = taps ?? _Taps();

  await tester.pumpWidget(
    wrapWithL10n(
      SettingsPage(
        currentLocale: currentLocale,
        onLocaleChanged: onLocaleChanged ?? (_) {},
        currentThemeMode: themeMode,
        onThemeModeChanged: onThemeModeChanged ?? (_) {},
        onOpenManual: () => record.record('manual'),
        onOpenFaq: () => record.record('faq'),
        onShowIntro: () => record.record('intro'),
        onOpenPrivacy: () => record.record('privacy'),
        onOpenPro: () => record.record('pro'),
        onOpenAbout: () => record.record('about'),
        onReportLastError: withBufferedError
            ? () => record.record('report')
            : null,
        onOpenDiagnostics: withDiagnostics
            ? () => record.record('diagnostics')
            : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('inline options', () {
    testWidgets('offers the system option first for both settings', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Systemsprache'), findsOneWidget);
      expect(find.text('Systemeinstellung'), findsOneWidget);
    });

    testWidgets('picking the system language reports null', (tester) async {
      Locale? reported;
      var called = false;
      await _pump(
        tester,
        currentLocale: const Locale('en'),
        onLocaleChanged: (locale) {
          reported = locale;
          called = true;
        },
      );

      await tapAfterScroll(tester, find.text('Systemsprache'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(reported, isNull);
    });

    testWidgets('picking a language reports that locale', (tester) async {
      Locale? reported;
      await _pump(tester, onLocaleChanged: (locale) => reported = locale);

      await tapAfterScroll(tester, find.text('English'));
      await tester.pumpAndSettle();

      expect(reported, const Locale('en'));
    });

    testWidgets('picking a theme mode reports it', (tester) async {
      ThemeMode? reported;
      await _pump(tester, onThemeModeChanged: (mode) => reported = mode);

      await tapAfterScroll(tester, find.text('Dunkel'));
      await tester.pumpAndSettle();

      expect(reported, ThemeMode.dark);
    });
  });

  group('the hub is a destination, not a wizard step', () {
    testWidgets('has no continue action', (tester) async {
      await _pump(tester);

      // The button that made this page a startup step until 3.2.1.
      expect(find.text('Weiter'), findsNothing);
    });

    testWidgets('the destructive action is not on the hub', (tester) async {
      await _pump(tester);

      // It lives on the privacy page, together with the explanation that
      // leads a user to it (spec 0005, Q1).
      expect(find.text('App-Daten löschen'), findsNothing);
      await tester.scrollUntilVisible(find.text('Datenschutz und Daten'), 250);
      expect(find.text('Datenschutz und Daten'), findsWidgets);
    });
  });

  group('sections', () {
    testWidgets('renders every heading in the specified order', (tester) async {
      await _pump(tester, inspectAllContent: true);

      const expected = [
        'Sprache wählen',
        'Erscheinungsbild',
        'Hilfe',
        'Daten und Datenschutz',
        'Pro',
        'Unterstützung',
        'Entwicklung',
      ];

      var previousY = double.negativeInfinity;
      for (final heading in expected) {
        final finder = find.text(heading);
        expect(finder, findsWidgets, reason: 'missing heading: $heading');
        final y = tester.getTopLeft(finder.first).dy;
        expect(y, greaterThan(previousY), reason: '$heading is out of order');
        previousY = y;
      }
    });

    testWidgets('the development section disappears with its only row', (
      tester,
    ) async {
      // What a release build looks like: no diagnostics callback, so the
      // section has no rows — and an empty section renders nothing at all,
      // heading included.
      await _pump(tester, withDiagnostics: false);

      expect(find.text('Entwicklung'), findsNothing);
      expect(find.text('Einstellungen-Diagnose'), findsNothing);
    });
  });

  group('navigation rows', () {
    testWidgets('each row reports its destination', (tester) async {
      final taps = _Taps();
      await _pump(tester, taps: taps, withBufferedError: true);

      for (final label in [
        'Anleitung',
        'Häufige Fragen',
        'App-Einleitung erneut anzeigen',
        'Datenschutz und Daten',
        'Pro-Status',
        'Über die App und Hilfe',
        'Einstellungen-Diagnose',
      ]) {
        await tapAfterScroll(tester, find.text(label));
        await tester.pumpAndSettle();
      }

      expect(taps.opened, [
        'manual',
        'faq',
        'intro',
        'privacy',
        'pro',
        'about',
        'diagnostics',
      ]);
    });

    testWidgets('the Pro row says that nothing is locked', (tester) async {
      await _pump(tester);

      await tester.scrollUntilVisible(
        find.text('Alle Funktionen sind derzeit kostenlos.'),
        250,
      );
      // Without this, a premium icon reads as a paywall that does not exist.
      expect(
        find.text('Alle Funktionen sind derzeit kostenlos.'),
        findsOneWidget,
      );
    });
  });

  group('report the last error', () {
    testWidgets('is absent while no error is buffered', (tester) async {
      await _pump(tester);

      expect(find.text('Letzten Fehler melden'), findsNothing);
    });

    testWidgets('appears once an error was recorded', (tester) async {
      final taps = _Taps();
      await _pump(tester, taps: taps, withBufferedError: true);

      await tapAfterScroll(tester, find.text('Letzten Fehler melden'));
      await tester.pumpAndSettle();

      expect(taps.opened, ['report']);
    });
  });
}
