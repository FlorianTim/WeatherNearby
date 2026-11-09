import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: ListView(children: [child])),
);

void main() {
  group('AppOptionTile', () {
    testWidgets('selected state shows the checked radio icon', (tester) async {
      await tester.pumpWidget(
        _host(AppOptionTile(label: 'Deutsch', isSelected: true, onTap: () {})),
      );

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_off), findsNothing);
    });

    testWidgets('unselected state shows the empty radio icon', (tester) async {
      await tester.pumpWidget(
        _host(AppOptionTile(label: 'Deutsch', isSelected: false, onTap: () {})),
      );

      expect(find.byIcon(Icons.radio_button_off), findsOneWidget);
    });

    testWidgets('selection is not carried by the icon alone', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              AppOptionTile(label: 'A', isSelected: true, onTap: _noop),
              AppOptionTile(label: 'B', isSelected: false, onTap: _noop),
            ],
          ),
        ),
      );

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards, hasLength(2));
      // Different container colours, so the state survives a screenshot in
      // greyscale as well as a screen reader.
      expect(cards.first.color, isNot(cards.last.color));
    });

    testWidgets('the trailing shorthand is excluded from semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          AppOptionTile(
            label: 'Deutsch',
            trailing: 'DE',
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      // Rendered for the eye ...
      expect(find.text('DE'), findsOneWidget);
      // ... but never announced next to the label it abbreviates.
      expect(find.bySemanticsLabel('Deutsch DE'), findsNothing);
      expect(find.bySemanticsLabel('Deutsch'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('tapping reports the selection', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        _host(
          AppOptionTile(
            label: 'Deutsch',
            isSelected: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Deutsch'));

      expect(taps, 1);
    });

    testWidgets('is at least 48 dp tall', (tester) async {
      await tester.pumpWidget(
        _host(AppOptionTile(label: 'Deutsch', isSelected: false, onTap: () {})),
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
            AppOptionTile(
              label: 'Systemsprache verwenden',
              trailing: 'DE',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

void _noop() {}
