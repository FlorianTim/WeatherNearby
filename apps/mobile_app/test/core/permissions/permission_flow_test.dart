import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/permissions/permission_flow.dart';
import 'package:mobile_app/core/permissions/permission_gateway.dart';
import 'package:mobile_app/core/permissions/permission_rationale_sheet.dart';

import '../../support/fake_permission_gateway.dart';
import '../../support/test_app.dart';

const _copy = PermissionCopy(
  title: 'Zugriff auf den Kalender',
  rationale:
      'Damit Termine im Kalender erscheinen. Ohne die Freigabe bleiben '
      'sie nur in der App sichtbar.',
  icon: Icons.calendar_month,
  blockedHint:
      'Der Zugriff ist dauerhaft abgelehnt. In den '
      'Systemeinstellungen lässt er sich wieder erlauben.',
);

/// Pumps a screen whose only button runs the permission flow, and returns the
/// outcome once it completed.
Future<PermissionState?> _runFlow(
  WidgetTester tester,
  FakePermissionGateway gateway, {
  bool tapPrimaryButton = true,
}) async {
  PermissionState? outcome;

  await tester.pumpWidget(
    wrapWithL10n(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                outcome = await ensurePermission(
                  context: context,
                  gateway: gateway,
                  copy: _copy,
                );
              },
              child: const Text('start'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('start'));
  await tester.pumpAndSettle();

  if (find.text('Erlauben').evaluate().isNotEmpty ||
      find.text('Einstellungen öffnen').evaluate().isNotEmpty) {
    final label = find.text('Erlauben').evaluate().isNotEmpty
        ? 'Erlauben'
        : 'Einstellungen öffnen';
    await tester.tap(find.text(tapPrimaryButton ? label : 'Nicht jetzt'));
    await tester.pumpAndSettle();
  }

  return outcome;
}

void main() {
  testWidgets('an already granted permission asks nothing', (tester) async {
    final gateway = FakePermissionGateway(state: PermissionState.granted);

    final outcome = await _runFlow(tester, gateway);

    expect(outcome, PermissionState.granted);
    expect(gateway.calls, ['status']);
    expect(find.text('Erlauben'), findsNothing);
  });

  testWidgets('the rationale comes before the system dialog', (tester) async {
    final gateway = FakePermissionGateway();

    final outcome = await _runFlow(tester, gateway);

    // The order is the whole point: status, then the user's decision on the
    // in-app sheet, then — and only then — the system dialog.
    expect(gateway.calls, ['status', 'request']);
    expect(outcome, PermissionState.granted);
  });

  testWidgets('the rationale explains the consequence of declining', (
    tester,
  ) async {
    final gateway = FakePermissionGateway();

    await tester.pumpWidget(
      wrapWithL10n(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => ensurePermission(
                  context: context,
                  gateway: gateway,
                  copy: _copy,
                ),
                child: const Text('start'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(find.text(_copy.title), findsOneWidget);
    expect(find.textContaining('bleiben sie nur in der App'), findsOneWidget);
  });

  testWidgets('declining the rationale never reaches the system dialog', (
    tester,
  ) async {
    final gateway = FakePermissionGateway();

    final outcome = await _runFlow(tester, gateway, tapPrimaryButton: false);

    expect(gateway.requestCount, 0);
    expect(outcome, PermissionState.notRequested);
  });

  testWidgets('a denied answer is returned, not thrown', (tester) async {
    final gateway = FakePermissionGateway(grantOnRequest: false);

    final outcome = await _runFlow(tester, gateway);

    // Denial is an outcome the caller handles, not an error: the app stays
    // usable and names what is limited.
    expect(outcome, PermissionState.denied);
  });

  group('permanently denied', () {
    testWidgets('never shows a system dialog that cannot appear', (
      tester,
    ) async {
      final gateway = FakePermissionGateway(
        state: PermissionState.permanentlyDenied,
      );

      await _runFlow(tester, gateway);

      expect(gateway.requestCount, 0);
    });

    testWidgets('offers the settings route instead of "Allow"', (tester) async {
      final gateway = FakePermissionGateway(
        state: PermissionState.permanentlyDenied,
      );

      await _runFlow(tester, gateway);

      expect(gateway.openedAppSettings, isTrue);
    });

    testWidgets('re-reads the state after the settings trip', (tester) async {
      final gateway = FakePermissionGateway(
        state: PermissionState.permanentlyDenied,
      );

      final outcome = await _runFlow(tester, gateway);

      // The system stays the source of truth: the flow asks again rather
      // than assuming the user did or did not change anything.
      expect(gateway.calls.where((c) => c == 'status').length, 2);
      expect(outcome, PermissionState.permanentlyDenied);
    });

    testWidgets('picks up a permission granted in the system settings', (
      tester,
    ) async {
      final gateway = FakePermissionGateway(
        state: PermissionState.permanentlyDenied,
      );
      await tester.pumpWidget(
        wrapWithL10n(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await ensurePermission(
                      context: context,
                      gateway: gateway,
                      copy: _copy,
                    );
                  },
                  child: const Text('start'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      gateway.state = PermissionState.granted;
      await tester.tap(find.text('Einstellungen öffnen'));
      await tester.pumpAndSettle();

      expect(gateway.state, PermissionState.granted);
    });
  });

  group('PermissionState', () {
    test('only notRequested and denied can still be requested', () {
      expect(PermissionState.notRequested.canRequest, isTrue);
      expect(PermissionState.denied.canRequest, isTrue);
      expect(PermissionState.granted.canRequest, isFalse);
      expect(PermissionState.permanentlyDenied.canRequest, isFalse);
    });
  });
}
