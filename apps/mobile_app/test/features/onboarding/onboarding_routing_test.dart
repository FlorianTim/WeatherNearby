import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/settings/app_settings.dart';
import 'package:mobile_app/core/startup/startup_providers.dart';
import 'package:mobile_app/core/startup/startup_task.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';
import 'package:mobile_app/features/onboarding/application/onboarding_notifier.dart';
import 'package:mobile_app/features/onboarding/presentation/onboarding_page.dart';

import '../../support/fake_permission_gateway.dart';
import '../../support/test_app.dart';

/// A store whose writes fail, as one does when the platform storage is
/// unavailable.
class _FailingStore implements KeyValueStore {
  _FailingStore(this._initial);

  final Map<String, String> _initial;

  @override
  String? getString(String key) => _initial[key];

  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('storage unavailable');

  @override
  Future<void> remove(String key) async =>
      throw StateError('storage unavailable');
}

/// Opens the settings hub and scrolls to the intro row.
///
/// The hub is one long scrollable on a phone-sized test surface, so the row
/// is below the fold — as it is on a real device.
Future<void> _openIntroFromSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.text('App-Einleitung erneut anzeigen'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('App-Einleitung erneut anzeigen'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('where the splash routes to', () {
    testWidgets('the intro, on a first start', (tester) async {
      final harness = TestAppHarness(onboardingCompleted: false);
      await pumpPastSplash(tester, harness);

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Willkommen'), findsOneWidget);
    });

    testWidgets('the app, once the intro has been completed', (tester) async {
      final harness = TestAppHarness();
      await pumpPastSplash(tester, harness);

      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.text('Aufgaben'), findsOneWidget);
    });

    testWidgets('the recovery screen wins over the intro', (tester) async {
      final harness = TestAppHarness(
        onboardingCompleted: false,
        extraOverrides: [
          startupTasksProvider.overrideWithValue([
            StartupTask(
              name: 'database',
              policy: StartupPolicy.blocking,
              run: () async => throw StateError('boom'),
            ),
          ]),
        ],
      );
      await pumpPastSplash(tester, harness);

      // A user who cannot start the app must not be shown an introduction
      // to it first.
      expect(find.text('Die App konnte nicht starten'), findsOneWidget);
      expect(find.byType(OnboardingPage), findsNothing);
    });
  });

  group('finishing the intro', () {
    testWidgets('persists the flag and continues into the app', (tester) async {
      final harness = TestAppHarness(onboardingCompleted: false);
      await pumpPastSplash(tester, harness);

      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();

      expect(find.text('Aufgaben'), findsOneWidget);
      expect(
        harness.keyValueStore.getString('app.onboardingCompleted'),
        'true',
      );
    });

    testWidgets('a failing store still lets the user out', (tester) async {
      final store = _FailingStore({'app.locale': 'de'});
      final container = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      var finished = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithL10n(
            Consumer(
              builder: (context, ref, _) => OnboardingPage(
                currentLocale: const Locale('de'),
                onLocaleChanged: (_) {},
                currentThemeMode: ThemeMode.system,
                onThemeModeChanged: (_) {},
                onFinished: () async {
                  await ref
                      .read(onboardingCompletedProvider.notifier)
                      .complete();
                  finished = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();

      // A storage failure must never trap someone inside a modal flow. The
      // worst acceptable outcome is seeing the intro again next start.
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
      expect(container.read(onboardingCompletedProvider), isTrue);
    });
  });

  group('reopening it from settings', () {
    testWidgets('shows the intro although the flag is set', (tester) async {
      final harness = TestAppHarness();
      await pumpPastSplash(tester, harness);

      await _openIntroFromSettings(tester);

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('finishing it returns to settings and changes nothing else', (
      tester,
    ) async {
      final harness = TestAppHarness();
      await pumpPastSplash(tester, harness);

      await _openIntroFromSettings(tester);
      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();

      expect(find.text('Einstellungen'), findsWidgets);
      expect(harness.keyValueStore.getString('app.locale'), 'de');
      expect(
        AppSettings.themeMode.read(harness.keyValueStore),
        ThemeMode.system,
      );
    });
  });

  testWidgets('the intro never asks for a permission', (tester) async {
    final gateway = FakePermissionGateway();

    final harness = TestAppHarness(onboardingCompleted: false);
    await pumpPastSplash(tester, harness);

    for (var page = 0; page < 4; page++) {
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Los geht’s'));
    await tester.pumpAndSettle();

    // Permissions are requested just-in-time by the feature that needs them
    // (`docs/architecture/contracts/04-permissions.md`). An intro that asks
    // up front is the pattern that contract exists to prevent.
    expect(gateway.calls, isEmpty);
  });
}
