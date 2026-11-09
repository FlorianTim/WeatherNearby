import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests pump deliberately rather than calling `pumpAndSettle`.
///
/// A live snackbar has a running timer, so `pumpAndSettle` either waits out
/// the whole window or hides the very behaviour under test — and a test that
/// leaves the timer pending fails flutter_test's own invariant
/// (`docs/known-issues.md`, KI-005).
void main() {
  /// Pumps a screen with a button that shows the snackbar.
  Future<void> pumpHost(
    WidgetTester tester, {
    required String message,
    required Future<void> Function() onUndo,
    Duration duration = const Duration(seconds: 5),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showUndoSnackBar(
                  context,
                  message: message,
                  undoLabel: 'Rückgängig',
                  onUndo: onUndo,
                  duration: duration,
                ),
                child: const Text('act'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the message and the action', (tester) async {
    await pumpHost(tester, message: 'Gelöscht', onUndo: () async {});

    await tester.tap(find.text('act'));
    await tester.pump();

    expect(find.text('Gelöscht'), findsOneWidget);
    expect(find.text('Rückgängig'), findsOneWidget);

    // Let the timer run out so none is left pending.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('dismisses itself after the duration', (tester) async {
    await pumpHost(
      tester,
      message: 'Gelöscht',
      onUndo: () async {},
      duration: const Duration(seconds: 2),
    );

    await tester.tap(find.text('act'));
    // The dismiss timer only starts once the entrance animation has finished,
    // so settle first — otherwise pumping past the duration proves nothing.
    await tester.pumpAndSettle();
    expect(find.text('Gelöscht'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Gelöscht'), findsNothing);
  });

  testWidgets('runs onUndo exactly once on a single tap', (tester) async {
    var undoCount = 0;
    await pumpHost(
      tester,
      message: 'Gelöscht',
      onUndo: () async => undoCount++,
    );

    await tester.tap(find.text('act'));
    // Settle first: the snackbar animates in, and tapping mid-animation aims
    // at where the action is not yet.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rückgängig'));
    await tester.pump();

    expect(undoCount, 1);
    await tester.pumpAndSettle();
  });

  // SnackBarAction can fire again before the snackbar finishes closing. An
  // undo that runs twice restores a task and then restores it again — or, in
  // a delete-undo pair, resurrects a row twice.
  testWidgets('runs onUndo exactly once on a rapid double tap', (tester) async {
    var undoCount = 0;
    await pumpHost(
      tester,
      message: 'Gelöscht',
      onUndo: () async => undoCount++,
    );

    await tester.tap(find.text('act'));
    await tester.pumpAndSettle();

    final action = find.text('Rückgängig');
    await tester.tap(action, warnIfMissed: false);
    await tester.tap(action, warnIfMissed: false);
    await tester.pump();

    expect(undoCount, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('does not run onUndo when it simply times out', (tester) async {
    var undoCount = 0;
    await pumpHost(
      tester,
      message: 'Gelöscht',
      onUndo: () async => undoCount++,
      duration: const Duration(seconds: 1),
    );

    await tester.tap(find.text('act'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(undoCount, 0);
    expect(find.text('Gelöscht'), findsNothing);
  });

  // Without hideCurrentSnackBar, the second snackbar queues behind the first:
  // the user acts twice and sees an undo for the older action.
  testWidgets('a second call replaces the first without firing its callback', (
    tester,
  ) async {
    var firstUndo = 0;
    var secondUndo = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => showUndoSnackBar(
                      context,
                      message: 'Erste',
                      undoLabel: 'Rückgängig',
                      onUndo: () async => firstUndo++,
                    ),
                    child: const Text('first'),
                  ),
                  ElevatedButton(
                    onPressed: () => showUndoSnackBar(
                      context,
                      message: 'Zweite',
                      undoLabel: 'Rückgängig',
                      onUndo: () async => secondUndo++,
                    ),
                    child: const Text('second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('first'));
    await tester.pump();
    await tester.tap(find.text('second'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Erste'), findsNothing);
    expect(find.text('Zweite'), findsOneWidget);

    await tester.tap(find.text('Rückgängig'));
    await tester.pump();

    expect(firstUndo, 0, reason: 'the replaced snackbar must not fire');
    expect(secondUndo, 1);
    await tester.pumpAndSettle();
  });

  // Regression guard for a Flutter default this helper deliberately
  // overrides: SnackBar computes `persist = persist ?? action != null`, so an
  // undo snackbar would never dismiss itself. Without an explicit value, a
  // Flutter upgrade changes undo behaviour in every app at once.
  testWidgets('persist is set explicitly, not inherited from the framework', (
    tester,
  ) async {
    late SnackBar captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showUndoSnackBar(
                context,
                message: 'Gelöscht',
                undoLabel: 'Rückgängig',
                onUndo: () async {},
              ),
              child: const Text('act'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('act'));
    await tester.pump();

    captured = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      captured.persist,
      isFalse,
      reason:
          'the timed window is the specified behaviour; the trash is the '
          'safety net, not the snackbar',
    );
    expect(captured.action, isNotNull);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('persist: true keeps the snackbar until the user acts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showUndoSnackBar(
                context,
                message: 'Gelöscht',
                undoLabel: 'Rückgängig',
                onUndo: () async {},
                duration: const Duration(seconds: 1),
                persist: true,
              ),
              child: const Text('act'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('act'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Gelöscht'), findsOneWidget);

    // Leave nothing pending.
    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
  });

  testWidgets('the action is reachable and large enough', (tester) async {
    await pumpHost(tester, message: 'Gelöscht', onUndo: () async {});

    await tester.tap(find.text('act'));
    await tester.pumpAndSettle();

    // Accessibility contract rule 2: reachable by its label.
    expect(find.bySemanticsLabel('Rückgängig'), findsOneWidget);

    // Rule 1: at least 48 dp in the tap direction. Material's SnackBarAction
    // is a TextButton, whose minimum height comes from the theme.
    final size = tester.getSize(find.byType(TextButton).first);
    expect(size.height, greaterThanOrEqualTo(48.0));

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('renders without overflow at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showUndoSnackBar(
                    context,
                    message:
                        'Aufgabe gelöscht und in den Papierkorb '
                        'verschoben',
                    undoLabel: 'Rückgängig',
                    onUndo: () async {},
                  ),
                  child: const Text('act'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('act'));
    await tester.pumpAndSettle();

    // Overflow throws in a test build, so reaching this line is the assertion.
    expect(find.text('Rückgängig'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });
}
