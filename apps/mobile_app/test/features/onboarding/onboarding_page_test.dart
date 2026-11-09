import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/onboarding/presentation/onboarding_page.dart';

import '../../support/test_app.dart';

/// The pager is provider-free, so it can be pumped without a ProviderScope.
Future<void> _pump(
  WidgetTester tester, {
  Locale? currentLocale,
  ThemeMode themeMode = ThemeMode.system,
  ValueChanged<Locale?>? onLocaleChanged,
  ValueChanged<ThemeMode>? onThemeModeChanged,
  VoidCallback? onFinished,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    wrapWithL10n(
      OnboardingPage(
        currentLocale: currentLocale,
        onLocaleChanged: onLocaleChanged ?? (_) {},
        currentThemeMode: themeMode,
        onThemeModeChanged: onThemeModeChanged ?? (_) {},
        onFinished: onFinished ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _advance(WidgetTester tester, int pages) async {
  for (var i = 0; i < pages; i++) {
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('flow', () {
    testWidgets('starts on the welcome page', (tester) async {
      await _pump(tester);

      expect(find.text('Willkommen'), findsOneWidget);
      expect(find.text('Weiter'), findsOneWidget);
    });

    testWidgets('the primary action advances one page at a time', (
      tester,
    ) async {
      await _pump(tester);

      await _advance(tester, 1);
      expect(find.text('Was die App kann'), findsOneWidget);

      await _advance(tester, 1);
      expect(find.text('Deine Daten'), findsOneWidget);
    });

    testWidgets('the last page relabels the primary action', (tester) async {
      await _pump(tester);
      await _advance(tester, 4);

      // The label, not the dots, is what says "this is the end": a screen
      // reader never announces the indicator at all.
      expect(find.text('Fertig'), findsOneWidget);
      expect(find.text('Los geht’s'), findsOneWidget);
      expect(find.text('Weiter'), findsNothing);
    });

    testWidgets('swiping moves the page and the button stays in sync', (
      tester,
    ) async {
      await _pump(tester);

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-600, 0));
        await tester.pumpAndSettle();
      }

      expect(find.text('Los geht’s'), findsOneWidget);
    });
  });

  group('leaving', () {
    testWidgets('skip on the first page finishes immediately', (tester) async {
      var finished = 0;
      await _pump(tester, onFinished: () => finished++);

      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();

      expect(finished, 1);
    });

    testWidgets('skip is available on every page', (tester) async {
      await _pump(tester);

      for (var page = 0; page < 5; page++) {
        expect(
          find.text('Überspringen'),
          findsOneWidget,
          reason: 'skip is missing on page $page',
        );
        if (page < 4) await _advance(tester, 1);
      }
    });

    testWidgets('the last page finishes', (tester) async {
      var finished = 0;
      await _pump(tester, onFinished: () => finished++);
      await _advance(tester, 4);

      await tester.tap(find.text('Los geht’s'));
      await tester.pumpAndSettle();

      expect(finished, 1);
    });
  });

  group('the language and appearance page', () {
    testWidgets('offers both settings with the system option first', (
      tester,
    ) async {
      await _pump(tester);
      await _advance(tester, 3);

      expect(find.text('Sprache und Darstellung'), findsOneWidget);
      expect(find.text('Systemsprache'), findsOneWidget);
      expect(find.text('Systemeinstellung'), findsOneWidget);
    });

    testWidgets('picking a language reports it immediately', (tester) async {
      Locale? reported;
      await _pump(tester, onLocaleChanged: (locale) => reported = locale);
      await _advance(tester, 3);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(reported, const Locale('en'));
    });

    testWidgets('picking a theme mode reports it immediately', (tester) async {
      ThemeMode? reported;
      await _pump(tester, onThemeModeChanged: (mode) => reported = mode);
      await _advance(tester, 3);

      await tester.ensureVisible(find.text('Dunkel'));
      await tester.pumpAndSettle();
      expect(find.text('Dunkel').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Dunkel'));
      await tester.pumpAndSettle();

      expect(reported, ThemeMode.dark);
    });
  });

  group('accessibility', () {
    testWidgets('skip and the primary action are at least 48 dp tall', (
      tester,
    ) async {
      await _pump(tester);

      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48.0),
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48.0),
      );
    });

    testWidgets('renders at 2.0x without overflow, on every page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithL10n(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: OnboardingPage(
              currentLocale: null,
              onLocaleChanged: (_) {},
              currentThemeMode: ThemeMode.system,
              onThemeModeChanged: (_) {},
              onFinished: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var page = 0; page < 4; page++) {
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'page ${page + 1} overflows at 2.0x text scale',
        );
      }
    });
  });
}
