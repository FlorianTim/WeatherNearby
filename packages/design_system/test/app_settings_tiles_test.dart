import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: ListView(children: [child])),
);

void main() {
  group('AppSettingsSection', () {
    testWidgets('renders its heading and its rows', (tester) async {
      await tester.pumpWidget(
        _host(
          AppSettingsSection(
            title: 'Hilfe',
            children: [
              AppSettingsTile(
                icon: Icons.menu_book_outlined,
                title: 'Anleitung',
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Hilfe'), findsOneWidget);
      expect(find.text('Anleitung'), findsOneWidget);
    });

    testWidgets('renders nothing at all when it has no rows', (tester) async {
      await tester.pumpWidget(
        _host(const AppSettingsSection(title: 'Entwicklung', children: [])),
      );

      // The heading is the point: an empty section must not leave one
      // hanging over blank space.
      expect(find.text('Entwicklung'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('AppSettingsTile', () {
    testWidgets('shows the chevron only when asked', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              AppSettingsTile(
                icon: Icons.info_outline,
                title: 'Öffnet eine Seite',
                showChevron: true,
                onTap: () {},
              ),
              AppSettingsTile(
                icon: Icons.replay,
                title: 'Handelt sofort',
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders its subtitle', (tester) async {
      await tester.pumpWidget(
        _host(
          AppSettingsTile(
            icon: Icons.delete_outline,
            title: 'App-Daten löschen',
            subtitle: 'Einstellungen bleiben erhalten.',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Einstellungen bleiben erhalten.'), findsOneWidget);
    });

    testWidgets('a destructive row uses the error colour and keeps its icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppSettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'App-Daten löschen',
            destructive: true,
            onTap: () {},
          ),
        ),
      );

      final context = tester.element(find.byType(AppSettingsTile));
      final errorColor = Theme.of(context).colorScheme.error;

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.delete_forever_outlined),
      );
      expect(icon.color, errorColor);

      // The icon is the part that survives greyscale and colour blindness;
      // the colour is an addition, never the only signal.
      expect(find.byIcon(Icons.delete_forever_outlined), findsOneWidget);
    });

    testWidgets('tapping reports the action', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        _host(
          AppSettingsTile(
            icon: Icons.info_outline,
            title: 'Über die App',
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Über die App'));

      expect(taps, 1);
    });

    testWidgets('is at least 48 dp tall', (tester) async {
      await tester.pumpWidget(
        _host(
          AppSettingsTile(
            icon: Icons.info_outline,
            title: 'Über die App',
            onTap: () {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(ListTile)).height,
        greaterThanOrEqualTo(48.0),
      );
    });

    testWidgets('does not overflow at double text scale', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _host(
            AppSettingsSection(
              title: 'Daten und Datenschutz',
              children: [
                AppSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Datenschutz und Daten',
                  subtitle: 'Was gespeichert wird, und wie man es löscht',
                  showChevron: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
