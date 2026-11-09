import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/features/settings/presentation/settings_page.dart';

import '../support/test_app.dart';

/// The menu bar around the whole app: drawn on a desktop, absent on a phone,
/// and never in the way of the splash.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('desktop: Go to jumps to a screen, Quit is offered', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpPastSplash(tester, TestAppHarness());

      expect(find.byType(MenuBar), findsOneWidget);
      expect(find.text('Datei'), findsOneWidget);

      await tester.tap(find.text('Gehe zu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Einstellungen'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      // The bar stays while a screen is open.
      expect(find.byType(MenuBar), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop: Alt+2 jumps to the settings from anywhere', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpPastSplash(tester, TestAppHarness());

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop: the splash cannot be left through the menu', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(TestAppHarness().buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(find.byType(SettingsPage), findsNothing);
      // Let the startup finish so no timer is left behind.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('phone: no menu bar, the screens are reached as before', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pumpPastSplash(tester, TestAppHarness());

      expect(find.byType(MenuBar), findsNothing);
      expect(find.text('Gehe zu'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
