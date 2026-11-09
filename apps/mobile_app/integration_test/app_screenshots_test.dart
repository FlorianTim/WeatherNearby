import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/features/privacy/presentation/privacy_page.dart';
import 'package:mobile_app/features/settings/presentation/settings_page.dart';
import 'package:mobile_app/main.dart' as app;

/// Screenshot-capturing integration test for the app's main flow.
///
/// This file is the carrier of the screenshot infrastructure. When a new app
/// is derived from the template, keep the infrastructure (profile-based view
/// sizing, `_shot` helper, file name) and swap only the flow steps and
/// assertions for the new app.
///
/// The drive target path is defined in ONE place:
/// `scripts/automation/integration-test/run_web_tests.sh` (`TEST_TARGET`).
///
/// Screen profiles come from `docs/public-site/screenshot-profiles.json` —
/// a shared LumbreCode contract, so the web template's Playwright capture
/// renders at the same sizes and writes into the same layout. The runner
/// reads that file and passes the values in; this test carries no copy of
/// them, because two lists of sizes drift.

/// Applies the correct rendering surface size for the current screen profile.
///
/// physicalSize is explicitly set so the Flutter rendering surface matches the
/// target device dimensions regardless of the actual browser window size.
/// devicePixelRatio is fixed at 1.0 for consistent 1:1 pixel screenshots.
void _applyViewSize(WidgetTester tester) {
  // Supplied by run_web_tests.sh from the shared profile file. The fallback
  // is only for `flutter test integration_test/` without a driver, where no
  // screenshot is taken anyway.
  const width = int.fromEnvironment('SCREEN_WIDTH', defaultValue: 390);
  const height = int.fromEnvironment('SCREEN_HEIGHT', defaultValue: 844);

  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = 1;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.physicalSize = Size(width.toDouble(), height.toDouble());
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

/// Takes a screenshot when a driver is attached; is a no-op otherwise so the
/// same test also passes under plain `flutter test integration_test/`.
Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
  String title,
  String description,
) async {
  const driverAttached = bool.fromEnvironment('SCREENSHOT_DRIVER');
  try {
    debugPrint('Screenshot flow: requesting $name');
    await binding
        .takeScreenshot(name, {'title': title, 'description': description})
        .timeout(const Duration(seconds: 30));
    debugPrint('Screenshot flow: completed $name');
  } catch (error) {
    // Plain flutter test has no screenshot driver. A driver run must fail
    // visibly instead of silently omitting an image or waiting for hours.
    if (driverAttached) rethrow;
    debugPrint('Screenshot flow: skipped $name without driver ($error)');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App screenshots', () {
    // The shot ids must match docs/public-site/screenshots.yaml — the
    // renderer fails when a guide references one this flow never produces.
    //
    // Finders are icons and widget types, not text: a fresh install follows
    // the system language, so the locale inside the container is not ours to
    // predict, and a text finder would make the capture fail in whichever
    // language CI happens to run.
    testWidgets('shell flow: intro -> settings -> privacy', (tester) async {
      _applyViewSize(tester);

      await app.main();
      await tester.pump();

      // Both splash phases (production timing: 3 s + 3 s).
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();

      // A fresh install has no completion flag, so the intro comes first.
      expect(find.byType(PageView), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await _shot(
        binding,
        '01-intro',
        'App intro',
        'The first-start intro on the step that explains where the data '
            'lives.',
      );

      // Skip is on every page and leaves the intro the way a user would.
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      await _shot(
        binding,
        '02-settings',
        'Settings',
        'The settings hub: language and appearance inline, everything else '
            'as a row that opens its own page.',
      );

      debugPrint('Screenshot flow: locating privacy settings row');
      final settingsScroll = find.descendant(
        of: find.byType(SettingsPage),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byIcon(Icons.privacy_tip_outlined),
        240,
        scrollable: settingsScroll,
      );
      await tester.pumpAndSettle();
      debugPrint('Screenshot flow: opening privacy page');
      await tester.tap(find.byIcon(Icons.privacy_tip_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPage), findsOneWidget);
      await _shot(
        binding,
        '03-privacy',
        'Privacy and data',
        'What the app stores, the published documents, and the danger zone '
            'with its two separately confirmed actions.',
      );
    });
  });
}
