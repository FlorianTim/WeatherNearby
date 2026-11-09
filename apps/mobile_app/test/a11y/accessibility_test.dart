import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/permissions/permission_gateway.dart';
import 'package:mobile_app/features/privacy/presentation/privacy_page.dart';
import 'package:mobile_app/features/settings/presentation/settings_page.dart';

import '../support/test_app.dart';

/// Executable form of `docs/architecture/contracts/07-accessibility.md`.
///
/// Prose alone erodes: nobody notices when a new option row drops below the
/// touch-target minimum, and text scaling breaks silently on a device nobody
/// tests on. These checks run on every PR instead.
///
/// Two subjects, because together they cover the template's whole
/// interaction vocabulary: the settings hub has the option groups and the
/// navigation rows, the privacy page has the destructive actions and their
/// dialogs. A derived app points the same checks at its own main screens.
void main() {
  Widget settingsPage({
    Locale? locale,
    ThemeMode themeMode = ThemeMode.system,
  }) => SettingsPage(
    currentLocale: locale,
    onLocaleChanged: (_) {},
    currentThemeMode: themeMode,
    onThemeModeChanged: (_) {},
    onOpenManual: () {},
    onOpenFaq: () {},
    onShowIntro: () {},
    onOpenPrivacy: () {},
    onOpenPro: () {},
    onOpenAbout: () {},
    onOpenDiagnostics: () {},
  );

  Widget privacyPage() => PrivacyPage(
    onOpenUrl: (_) {},
    onContactPrivacy: () {},
    onDeleteAllData: () async {},
    onResetSettings: () async {},
    permissions: const [
      PermissionOverviewEntry(
        icon: Icons.notifications_outlined,
        label: 'Benachrichtigungen',
        state: PermissionState.granted,
      ),
    ],
  );

  group('touch targets (rule 1)', () {
    testWidgets('every settings row is at least 48 dp tall', (tester) async {
      // Whole-tree target/semantics inspection; phone 2x checks are separate.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithL10n(settingsPage()));
      await tester.pumpAndSettle();

      final tiles = find.byType(ListTile);
      expect(tiles, findsWidgets);

      for (var i = 0; i < tiles.evaluate().length; i++) {
        final size = tester.getSize(tiles.at(i));
        expect(
          size.height,
          greaterThanOrEqualTo(48.0),
          reason:
              'ListTile #$i is ${size.height} dp tall, below the 48 dp '
              'minimum touch target',
        );
      }
    });

    testWidgets('every privacy row is at least 48 dp tall', (tester) async {
      // Whole-tree target/semantics inspection; phone 2x checks are separate.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithL10n(privacyPage()));
      await tester.pumpAndSettle();

      final tiles = find.byType(ListTile);
      expect(tiles, findsWidgets);

      for (var i = 0; i < tiles.evaluate().length; i++) {
        expect(
          tester.getSize(tiles.at(i)).height,
          greaterThanOrEqualTo(48.0),
          reason: 'privacy ListTile #$i is below the 48 dp minimum',
        );
      }
    });
  });

  group('text scaling (rule 5)', () {
    testWidgets('the hub renders at 2.0x without overflow', (tester) async {
      // Overflow throws in a test build, so an unhandled exception here IS
      // the assertion. A phone-sized surface on purpose: a tall test viewport
      // would hide exactly the overflow this guards against.
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithL10n(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: settingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the privacy page renders at 2.0x without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithL10n(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: privacyPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('every hub row stays reachable at 2.0x by scrolling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithL10n(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: settingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The hub is one scrollable, so nothing can be pushed out of reach —
      // unlike the pre-3.2.1 layout, where a fixed footer competed with the
      // options for vertical space.
      await tester.scrollUntilVisible(
        find.text('Über die App und Hilfe'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Über die App und Hilfe'), findsOneWidget);
    });
  });

  group('not by colour alone (rule 9)', () {
    testWidgets('the selected option carries an icon, not just a tint', (
      tester,
    ) async {
      // Whole-tree target/semantics inspection; phone 2x checks are separate.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithL10n(
          settingsPage(locale: const Locale('en'), themeMode: ThemeMode.dark),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly two selections: one language, one theme mode. A colour-blind
      // user has to be able to see which — hence the filled radio icon.
      expect(find.byIcon(Icons.radio_button_checked), findsNWidgets(2));
      expect(find.byIcon(Icons.radio_button_off), findsWidgets);
    });

    testWidgets('destructive rows carry an icon, not just the error colour', (
      tester,
    ) async {
      // Whole-tree target/semantics inspection; phone 2x checks are separate.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithL10n(privacyPage()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(
        find.byIcon(Icons.settings_backup_restore_outlined),
        findsOneWidget,
      );
    });
  });

  group('semantics (rules 2 and 6)', () {
    testWidgets('every option is reachable by its label', (tester) async {
      // Whole-tree target/semantics inspection; phone 2x checks are separate.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrapWithL10n(settingsPage()));
      await tester.pumpAndSettle();

      // Option rows announce exactly their label — no more. The language
      // code next to "Deutsch" is excluded from semantics, otherwise the
      // screen reader would say "Deutsch DE".
      for (final label in [
        'Systemsprache',
        'Deutsch',
        'English',
        'Systemeinstellung',
        'Hell',
        'Dunkel',
      ]) {
        expect(
          find.bySemanticsLabel(label),
          findsWidgets,
          reason: '"$label" has no semantics label a screen reader can find',
        );
      }

      handle.dispose();
    });

    testWidgets('the destructive actions state their scope, not just a name', (
      tester,
    ) async {
      // Whole-tree target/semantics inspection; phone 2x checks are separate.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrapWithL10n(privacyPage()));
      await tester.pumpAndSettle();

      // ListTile merges title and subtitle into ONE node, and here that is
      // wanted: "Delete app data" alone would overstate what happens, and
      // the two actions would be indistinguishable to a screen reader
      // (rule 3 and rule 6).
      expect(
        find.bySemanticsLabel(RegExp(r'Sprache und Erscheinungsbild')),
        findsWidgets,
        reason: 'the delete action must announce its scope, not just its name',
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Inhalte bleiben erhalten')),
        findsWidgets,
        reason: 'the reset action must announce that content survives',
      );

      handle.dispose();
    });
  });

  group('alternatives to gestures (rule 10)', () {
    testWidgets('no interaction depends on a swipe', (tester) async {
      // Whole-tree target/semantics inspection; phone 2x checks are separate.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithL10n(settingsPage()));
      await tester.pumpAndSettle();

      // Dismissible has no keyboard or screen-reader equivalent. If a screen
      // ever needs one, it must also offer a button or menu entry — this test
      // is the reminder to add that alternative alongside.
      expect(find.byType(Dismissible), findsNothing);
    });
  });
}
