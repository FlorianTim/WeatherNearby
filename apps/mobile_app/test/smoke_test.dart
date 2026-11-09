import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('app renders company splash phase first', (tester) async {
    // The splash draws no title: the name is inside the Lottie file and
    // reaches the tree only as a semantics label.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(TestAppHarness().buildApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('LumbreCode'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('splash transitions to app phase', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(TestAppHarness().buildApp());
    // Phase switch fires at 1s (harness timing); the AnimatedSwitcher fade
    // starts with the next drawn frame, so pump past the switch, then let
    // the 300ms fade finish and give it one extra frame to remove the
    // outgoing phase.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.bySemanticsLabel('Flutter App Template'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('splash transitions into the app after timeout', (tester) async {
    final harness = TestAppHarness();
    await pumpPastSplash(tester, harness);

    // Since 3.2.1 the settings page is a destination, not a startup step:
    // a returning user lands on the app itself.
    expect(find.text('Aufgaben'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('the settings hub is reachable from the app', (tester) async {
    final harness = TestAppHarness();
    await pumpPastSplash(tester, harness);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('can switch the app language from the hub', (tester) async {
    final harness = TestAppHarness();
    await pumpPastSplash(tester, harness);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Choose language'), findsOneWidget);
  });

  testWidgets('the main screen is the to-do list and opens the create sheet', (
    tester,
  ) async {
    final harness = TestAppHarness();
    await pumpPastSplash(tester, harness);

    expect(find.text('Keine Aufgaben vorhanden'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Neue Aufgabe'), findsOneWidget);
  });
}
