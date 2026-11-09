import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/settings/app_settings.dart';
import 'package:mobile_app/core/storage/key_value_store.dart';
import 'package:mobile_app/features/settings/presentation/settings_diagnostics_page.dart';

import '../../support/test_app.dart';

Future<void> _pump(WidgetTester tester, KeyValueStore store) async {
  // Read-only registry inspection, not a phone interaction viewport.
  tester.view.physicalSize = const Size(1080, 3000);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(wrapWithL10n(SettingsDiagnosticsPage(store: store)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists one row per registered setting', (tester) async {
    await _pump(tester, InMemoryKeyValueStore());

    for (final setting in AppSettings.all) {
      expect(
        find.text(setting.key),
        findsOneWidget,
        reason: '${setting.key} is registered but not listed',
      );
    }
  });

  testWidgets('a setting that was never written shows as unset', (
    tester,
  ) async {
    await _pump(tester, InMemoryKeyValueStore());

    expect(find.textContaining('nicht gesetzt'), findsWidgets);
  });

  testWidgets('a stored value is shown raw, next to its default', (
    tester,
  ) async {
    await _pump(tester, InMemoryKeyValueStore({'app.themeMode': 'dark'}));

    // Raw, not prettified: the point is to see what storage actually holds.
    expect(find.textContaining('dark'), findsWidgets);
    expect(find.textContaining('Standard: system'), findsWidgets);
  });

  testWidgets('offers no way to change a value', (tester) async {
    await _pump(tester, InMemoryKeyValueStore());

    // Read-only by requirement (SET-052): a value written here would bypass
    // the notifier that owns it, and the UI would then disagree with storage
    // until the next restart.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });
}
