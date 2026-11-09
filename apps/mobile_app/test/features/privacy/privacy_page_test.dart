import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/app_identity.dart';
import 'package:mobile_app/core/permissions/permission_gateway.dart';
import 'package:mobile_app/features/privacy/presentation/privacy_page.dart';

import '../../support/test_app.dart';
import '../../support/ui_test_profile.dart';

Future<void> _pump(
  WidgetTester tester, {
  List<PermissionOverviewEntry> permissions = const [],
  List<Uri>? opened,
  VoidCallback? onContactPrivacy,
  Future<void> Function()? onDeleteAllData,
  Future<void> Function()? onResetSettings,
  bool inspectAllContent = false,
}) async {
  UiTestProfile.phone.apply(tester);
  if (inspectAllContent) {
    // Whole-content inspection, not an interaction viewport.
    tester.view.physicalSize = const Size(1080, 4200);
  }

  await tester.pumpWidget(
    wrapWithL10n(
      PrivacyPage(
        permissions: permissions,
        onOpenUrl: (uri) => opened?.add(uri),
        onContactPrivacy: onContactPrivacy ?? () {},
        onDeleteAllData: onDeleteAllData ?? () async {},
        onResetSettings: onResetSettings ?? () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('states where the data lives', (tester) async {
    await _pump(tester, inspectAllContent: true);

    expect(find.text('Deine Daten bleiben auf diesem Gerät'), findsOneWidget);
    expect(find.textContaining('kein Konto, keinen Server'), findsOneWidget);
  });

  group('permission overview', () {
    testWidgets('is absent when the app declares no permission', (
      tester,
    ) async {
      await _pump(tester, inspectAllContent: true);

      // Not rendered empty: an empty section leaves a heading hanging over
      // nothing, which reads as a bug.
      expect(find.text('Berechtigungen'), findsNothing);
    });

    testWidgets('renders each declared permission with its state', (
      tester,
    ) async {
      await _pump(
        tester,
        permissions: const [
          PermissionOverviewEntry(
            icon: Icons.notifications_outlined,
            label: 'Benachrichtigungen',
            state: PermissionState.granted,
          ),
          PermissionOverviewEntry(
            icon: Icons.contacts_outlined,
            label: 'Kontakte',
            state: PermissionState.permanentlyDenied,
          ),
        ],
      );

      expect(find.text('Berechtigungen'), findsOneWidget);
      expect(find.text('Benachrichtigungen'), findsOneWidget);
      expect(find.text('Erteilt'), findsOneWidget);
      // The state that has no way back through a dialog gets its own word;
      // collapsing it into "Abgelehnt" would hide the system-settings route.
      expect(find.text('Dauerhaft abgelehnt'), findsOneWidget);
    });
  });

  group('published documents', () {
    testWidgets('open the URLs derived from the app identity', (tester) async {
      final opened = <Uri>[];
      await _pump(tester, opened: opened);

      await tapAfterScroll(tester, find.text('Datenschutzerklärung'));
      await tester.pumpAndSettle();
      await tapAfterScroll(tester, find.text('Daten löschen'));
      await tester.pumpAndSettle();

      expect(opened, [
        AppIdentity.links.privacyPolicy,
        AppIdentity.links.dataDeletion,
      ]);
    });

    testWidgets('the privacy contact row reports a tap', (tester) async {
      var contacted = false;
      await _pump(tester, onContactPrivacy: () => contacted = true);

      await tapAfterScroll(tester, find.text('Datenschutz-Anfrage senden'));
      await tester.pumpAndSettle();

      expect(contacted, isTrue);
    });
  });

  group('the two destructive actions', () {
    testWidgets('each states its own scope before it is tapped', (
      tester,
    ) async {
      await _pump(tester, inspectAllContent: true);

      // A user has to be able to tell them apart *before* tapping — the
      // dialog is too late.
      expect(
        find.text(
          'Löscht alle Inhalte. Sprache und Erscheinungsbild bleiben erhalten.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Sprache und Erscheinungsbild zurück auf Systemeinstellung. '
          'Inhalte bleiben erhalten.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('delete asks first and names the consequence', (tester) async {
      var deleted = false;
      await _pump(tester, onDeleteAllData: () async => deleted = true);

      await tapAfterScroll(tester, find.text('App-Daten löschen'));
      await tester.pumpAndSettle();

      expect(find.text('App-Daten löschen?'), findsOneWidget);
      expect(find.textContaining('endgültig gelöscht'), findsOneWidget);
      expect(deleted, isFalse);
    });

    testWidgets('cancelling delete changes nothing', (tester) async {
      var deleted = false;
      await _pump(tester, onDeleteAllData: () async => deleted = true);

      await tapAfterScroll(tester, find.text('App-Daten löschen'));
      await tester.pumpAndSettle();
      await tapAfterScroll(tester, find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
    });

    testWidgets('confirming delete runs it and reports back', (tester) async {
      var deleted = false;
      await _pump(tester, onDeleteAllData: () async => deleted = true);

      await tapAfterScroll(tester, find.text('App-Daten löschen'));
      await tester.pumpAndSettle();
      await tapAfterScroll(tester, find.text('Löschen'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
      expect(find.text('App-Daten gelöscht'), findsOneWidget);
    });

    testWidgets('reset has its own dialog, not the delete one', (tester) async {
      await _pump(tester);

      await tapAfterScroll(tester, find.text('Einstellungen zurücksetzen'));
      await tester.pumpAndSettle();

      expect(find.text('Einstellungen zurücksetzen?'), findsOneWidget);
      expect(find.text('App-Daten löschen?'), findsNothing);
      expect(find.text('Zurücksetzen'), findsOneWidget);
    });

    testWidgets('confirming reset runs it and reports back', (tester) async {
      var reset = false;
      await _pump(tester, onResetSettings: () async => reset = true);

      await tapAfterScroll(tester, find.text('Einstellungen zurücksetzen'));
      await tester.pumpAndSettle();
      await tapAfterScroll(tester, find.text('Zurücksetzen'));
      await tester.pumpAndSettle();

      expect(reset, isTrue);
      expect(find.text('Einstellungen zurückgesetzt'), findsOneWidget);
    });

    testWidgets('one action never triggers the other', (tester) async {
      var deleted = false;
      var reset = false;
      await _pump(
        tester,
        onDeleteAllData: () async => deleted = true,
        onResetSettings: () async => reset = true,
      );

      await tapAfterScroll(tester, find.text('Einstellungen zurücksetzen'));
      await tester.pumpAndSettle();
      await tapAfterScroll(tester, find.text('Zurücksetzen'));
      await tester.pumpAndSettle();

      expect(reset, isTrue);
      expect(deleted, isFalse);
    });
  });
}
