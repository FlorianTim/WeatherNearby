import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/menu/app_menu.dart';
import 'package:mobile_app/core/menu/app_menu_host.dart';

const _menus = [
  AppMenuGroup(
    id: 'goto',
    label: 'Go to',
    items: [
      AppMenuItem(
        id: 'goto:settings',
        label: 'Settings',
        shortcut: SingleActivator(LogicalKeyboardKey.digit2, alt: true),
      ),
      AppMenuItem(id: 'goto:about', label: 'About', dividerBefore: true),
    ],
  ),
  AppMenuGroup(
    id: 'help',
    label: 'Help',
    items: [AppMenuItem(id: 'help:manual', label: 'Manual', enabled: false)],
  ),
];

Widget _host(
  AppMenuStyle style,
  List<String> received, {
  List<AppMenuGroup> menus = _menus,
}) {
  return MaterialApp(
    home: AppMenuHost(
      style: style,
      menus: menus,
      semanticLabel: 'Application menu',
      onCommand: received.add,
      child: const Focus(autofocus: true, child: Text('page')),
    ),
  );
}

void main() {
  group('AppMenuHost, bar style (Windows, Linux, web)', () {
    testWidgets('draws a menu bar above the page', (tester) async {
      await tester.pumpWidget(_host(AppMenuStyle.bar, []));

      expect(find.byType(MenuBar), findsOneWidget);
      expect(find.text('Go to'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('a chosen entry reports its id and closes the menu', (
      tester,
    ) async {
      final received = <String>[];
      await tester.pumpWidget(_host(AppMenuStyle.bar, received));

      await tester.tap(find.text('Go to'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(received, ['goto:about']);
      expect(find.text('About'), findsNothing);
    });

    testWidgets('a disabled entry does not report', (tester) async {
      final received = <String>[];
      await tester.pumpWidget(_host(AppMenuStyle.bar, received));

      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manual'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(received, isEmpty);
    });

    testWidgets('F10 opens the first menu', (tester) async {
      await tester.pumpWidget(_host(AppMenuStyle.bar, []));
      expect(find.text('Settings'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets("an entry's key runs it from anywhere", (tester) async {
      final received = <String>[];
      await tester.pumpWidget(_host(AppMenuStyle.bar, received));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(received, ['goto:settings']);
    });

    testWidgets('follows a new child and new labels', (tester) async {
      final received = <String>[];
      await tester.pumpWidget(_host(AppMenuStyle.bar, received));

      await tester.pumpWidget(
        _host(
          AppMenuStyle.bar,
          received,
          menus: const [AppMenuGroup(id: 'x', label: 'Other', items: [])],
        ),
      );

      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Go to'), findsNothing);
    });
  });

  group('AppMenuHost, none style (phone, tablet)', () {
    testWidgets('draws no bar but the keys still work', (tester) async {
      final received = <String>[];
      await tester.pumpWidget(_host(AppMenuStyle.none, received));

      expect(find.byType(MenuBar), findsNothing);
      expect(find.text('page'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(received, ['goto:settings']);
    });

    testWidgets('a disabled entry ignores its key', (tester) async {
      final received = <String>[];
      await tester.pumpWidget(
        _host(
          AppMenuStyle.none,
          received,
          menus: const [
            AppMenuGroup(
              id: 'g',
              label: 'G',
              items: [
                AppMenuItem(
                  id: 'goto:settings',
                  label: 'Settings',
                  enabled: false,
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.digit2,
                    alt: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(received, isEmpty);
    });
  });

  group('AppMenuStyle.detect', () {
    for (final (platform, style) in [
      (TargetPlatform.macOS, AppMenuStyle.native),
      (TargetPlatform.windows, AppMenuStyle.bar),
      (TargetPlatform.linux, AppMenuStyle.bar),
      (TargetPlatform.android, AppMenuStyle.none),
      (TargetPlatform.iOS, AppMenuStyle.none),
    ]) {
      test('$platform draws $style', () {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        expect(AppMenuStyle.detect(), style);
      });
    }
  });
}
