import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/app.dart';
import 'package:mobile_app/core/platform/platform_seams.dart';
import 'package:mobile_app/core/startup/startup_providers.dart';
import 'package:mobile_app/core/startup/startup_task.dart';
import 'package:mobile_app/features/splash/presentation/startup_error_page.dart';

import '../../support/test_app.dart';

/// Builds the page with a recorded fatal outcome.
Future<ProviderContainer> _pumpErrorPage(
  WidgetTester tester, {
  required List<Uri> launched,
  VoidCallback? onRetry,
  StartupFailure? failure,
}) async {
  final container = ProviderContainer(
    overrides: [
      urlLauncherProvider.overrideWithValue((
        uri, {
        UrlPolicy policy = UrlPolicy.webOnly,
      }) async {
        if (!policy.allows(uri)) return LaunchOutcome.schemeNotAllowed;
        launched.add(uri);
        return LaunchOutcome.launched;
      }),
    ],
  );
  addTearDown(container.dispose);

  container
      .read(startupOutcomeProvider.notifier)
      .record(
        StartupResult(
          fatal:
              failure ??
              const StartupFailure(taskName: 'database', error: 'boom'),
        ),
      );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: wrapWithL10n(StartupErrorPage(onRetry: onRetry ?? () {})),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  testWidgets('explains the situation and names the failed step', (
    tester,
  ) async {
    await _pumpErrorPage(tester, launched: []);

    expect(find.text('Die App konnte nicht starten'), findsOneWidget);
    expect(find.text('Fehlgeschlagener Schritt: database'), findsOneWidget);
  });

  testWidgets('shows no exception message and no stack trace', (tester) async {
    await _pumpErrorPage(
      tester,
      launched: [],
      failure: StartupFailure(
        taskName: 'database',
        error: StateError('disk image is malformed'),
        stackTrace: StackTrace.current,
      ),
    );

    // Rule: technical detail belongs in the report mail the user chooses to
    // send, never on screen.
    expect(find.textContaining('disk image is malformed'), findsNothing);
    expect(find.textContaining('#0'), findsNothing);
  });

  testWidgets('retry triggers the callback', (tester) async {
    var retried = false;
    await _pumpErrorPage(tester, launched: [], onRetry: () => retried = true);

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();

    expect(retried, isTrue);
  });

  testWidgets('reporting opens a tagged bug mail through the seam', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpErrorPage(tester, launched: launched);

    await tester.tap(find.text('Fehler melden'));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    final uri = launched.single;
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'bugs@lumbrecode.de');

    final query = Uri.decodeComponent(uri.query);
    expect(query, contains('[app:todo-app] Startup failure: database'));
  });

  testWidgets(
    'a fatal startup failure routes to the recovery screen instead of the app',
    (tester) async {
      final harness = TestAppHarness();

      await tester.pumpWidget(
        App(
          overrides: [
            ...harness.overrides,
            // Inject the failure through the task list, so no provider is
            // overridden twice.
            startupTasksProvider.overrideWithValue([
              StartupTask(
                name: 'database',
                policy: StartupPolicy.blocking,
                run: () async => throw StateError('cannot open database'),
              ),
            ]),
          ],
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(StartupErrorPage), findsOneWidget);
      expect(find.text('Die App konnte nicht starten'), findsOneWidget);
    },
  );

  testWidgets('a degraded (guarded) failure still reaches the app', (
    tester,
  ) async {
    final harness = TestAppHarness();

    await tester.pumpWidget(
      App(
        overrides: [
          ...harness.overrides,
          startupTasksProvider.overrideWithValue([
            StartupTask(
              name: 'cache',
              policy: StartupPolicy.guarded,
              run: () async => throw StateError('preload failed'),
            ),
          ]),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Guarded work is allowed to fail: the data loads lazily instead.
    expect(find.byType(StartupErrorPage), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
