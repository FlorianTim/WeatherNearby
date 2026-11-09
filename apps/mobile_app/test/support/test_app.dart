import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/app.dart';
import 'package:mobile_app/core/database/app_database.dart';
import 'package:mobile_app/core/database/database_provider.dart';
import 'package:mobile_app/core/l10n/generated/app_localizations.dart';
import 'package:mobile_app/core/platform/platform_seams.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';
import 'package:mobile_app/core/utils/clock.dart';
import 'package:mobile_app/features/splash/application/splash_timing.dart';

import 'fixed_clock.dart';

/// Test harness that wires the whole app with safe fakes.
///
/// Default overrides:
///  - in-memory Drift database (no file system, closed automatically)
///  - in-memory key-value store (no shared_preferences channel)
///  - plugin seams as recording fakes (no share/url/clipboard channels)
///  - a fixed clock, so nothing depends on the wall-clock time
///  - short splash timing (1 s + 1 s), so `pump(3 s)` reaches the shell
///  - a seeded app language, so nothing depends on the host machine's locale
///  - the intro marked as completed, so a test lands on the app rather than
///    in the first-start intro (pass `onboardingCompleted: false` to test it)
///
/// Usage:
///   final harness = TestAppHarness();
///   await tester.pumpWidget(harness.buildApp());
///   await tester.pump(const Duration(seconds: 3));
///   await tester.pumpAndSettle();
///
/// Gotchas (learned the hard way — keep these in mind):
///  - `await someDriftStream.first` directly in a `testWidgets` body
///    deadlocks under FakeAsync. Do DB setup/asserts inside
///    `tester.runAsync(() async { ... })`.
///  - Lazy ListViews don't build offscreen children. Use UiTestProfile.phone
///    and scrollUntilVisible for interaction tests. Tall surfaces are only
///    for explicitly labelled whole-content inspections, not phone usability.
class TestAppHarness {
  TestAppHarness({
    SplashTiming? splashTiming,
    String? localeCode = 'de',
    DateTime? now,
    bool onboardingCompleted = true,
    this.extraOverrides = const [],
  }) : splashTiming =
           splashTiming ??
           const SplashTiming(
             company: Duration(seconds: 1),
             appMinimum: Duration(seconds: 1),
           ),
       clock = FixedClock(now ?? DateTime(2026, 1, 15, 10, 30)),
       keyValueStore = InMemoryKeyValueStore({
         'app.locale': ?localeCode,
         // Completed by default on purpose. The alternative — every existing
         // test learning to dismiss an intro — would make the intro a
         // fixture of the whole suite instead of the subject of a few tests.
         if (onboardingCompleted) 'app.onboardingCompleted': 'true',
       });

  /// Overrides appended after the defaults, so a test can replace one of
  /// them (a failing startup task, a fake gateway) without rebuilding the
  /// whole list.
  final List<Override> extraOverrides;

  final SplashTiming splashTiming;

  /// Fixed "now" for every provider that reads `clockProvider`.
  final FixedClock clock;

  /// Seeded with the app language, because in production the default is
  /// "follow the system" — which in a test would resolve to whatever locale
  /// the machine running CI happens to have. Pass `localeCode: null` to test
  /// the system-default path deliberately.
  final InMemoryKeyValueStore keyValueStore;

  final AppDatabase database = AppDatabase(NativeDatabase.memory());

  /// Values recorded by the fake plugin seams.
  final List<String> sharedTexts = [];
  final List<SharePayload> sharedDocuments = [];
  final List<Uri> launchedUrls = [];
  final List<String> clipboardTexts = [];

  /// The scheme allowlist is enforced in the fake too, so a widget test
  /// cannot accidentally "prove" that a refused scheme opens.
  final List<Uri> refusedUrls = [];

  List<Override> get overrides => [
    keyValueStoreProvider.overrideWithValue(keyValueStore),
    appDatabaseProvider.overrideWith((ref) {
      ref.onDispose(database.close);
      return database;
    }),
    clockProvider.overrideWithValue(clock),
    splashTimingProvider.overrideWithValue(splashTiming),
    shareTextProvider.overrideWithValue((text) async => sharedTexts.add(text)),
    shareDocumentProvider.overrideWithValue(
      (payload) async => sharedDocuments.add(payload),
    ),
    urlLauncherProvider.overrideWithValue((
      uri, {
      UrlPolicy policy = UrlPolicy.webOnly,
    }) async {
      if (!policy.allows(uri)) {
        refusedUrls.add(uri);
        return LaunchOutcome.schemeNotAllowed;
      }
      launchedUrls.add(uri);
      return LaunchOutcome.launched;
    }),
    copyToClipboardProvider.overrideWithValue(
      (text) async => clipboardTexts.add(text),
    ),
    ...extraOverrides,
  ];

  /// The full app with all harness overrides applied.
  Widget buildApp() => App(overrides: overrides);
}

/// Wraps a single widget in a localized [MaterialApp] shell.
///
/// The default locale is **de** because the ARB template is `app_de.arb` —
/// without an explicit locale, widget tests would resolve to `en` and the
/// very first test of a new app fails on German strings.
Widget wrapWithL10n(Widget child, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

/// Pumps the harness app past the splash sequence into the first screen.
Future<void> pumpPastSplash(WidgetTester tester, TestAppHarness harness) async {
  await tester.pumpWidget(harness.buildApp());
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}
