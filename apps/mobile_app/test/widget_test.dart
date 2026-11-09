import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/app/app.dart';

import 'support/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('app starts without crashing', (tester) async {
    final harness = TestAppHarness();
    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(App), findsOneWidget);
  });
}
