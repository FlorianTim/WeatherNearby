import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/app/app.dart';

/// Smoke-level integration test that validates the main user flow.
///
/// Run with: flutter test integration_test/
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('full flow: splash -> settings -> greeting', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    // 1. Company splash phase is displayed first
    expect(find.text('LumbreCode'), findsOneWidget);

    // 2. Wait for splash to finish (production timing: 3 s + 3 s)
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    // 3. Settings page: choose language
    expect(find.text('Deutsch'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // 4. Navigate to greeting
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 5. Tap greet button
    expect(find.text('Greet me!'), findsOneWidget);
    await tester.tap(find.text('Greet me!'));
    await tester.pumpAndSettle();

    // 6. Verify greeting is shown
    expect(find.text('Hello! Welcome to the example app.'), findsOneWidget);
    expect(find.text('Current time:'), findsOneWidget);
  });
}
