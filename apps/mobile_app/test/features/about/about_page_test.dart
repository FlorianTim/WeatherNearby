import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/app_identity.dart';
import 'package:mobile_app/core/errors/last_error_buffer.dart';
import 'package:mobile_app/core/platform/platform_seams.dart';
import 'package:mobile_app/features/about/presentation/about_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../support/test_app.dart';

/// Pumps the about page with a launcher seam that records instead of
/// launching, and a resolved package info so the version footer renders.
///
/// The viewport is made tall on purpose: the page is a lazy [ListView] and
/// the contact section sits below the fold on a default-sized surface, so
/// `tap()` would not find those rows at all.
Future<void> _pumpAboutPage(
  WidgetTester tester, {
  required List<Uri> launched,
  bool launchSucceeds = true,
  LastErrorBuffer? errorBuffer,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        urlLauncherProvider.overrideWithValue((
          uri, {
          UrlPolicy policy = UrlPolicy.webOnly,
        }) async {
          if (!policy.allows(uri)) return LaunchOutcome.schemeNotAllowed;
          launched.add(uri);
          return launchSucceeds ? LaunchOutcome.launched : LaunchOutcome.failed;
        }),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'MyApp',
            packageName: 'de.lumbre.code.myapp',
            version: '1.2.3',
            buildNumber: '42',
          ),
        ),
        if (errorBuffer != null)
          lastErrorBufferProvider.overrideWithValue(errorBuffer),
      ],
      child: wrapWithL10n(const AboutPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens a web link through the launcher seam', (tester) async {
    final launched = <Uri>[];
    await _pumpAboutPage(tester, launched: launched);

    await tester.tap(find.text('Datenschutzerklärung'));
    await tester.pumpAndSettle();

    expect(launched, [
      Uri.parse('https://lumbrecode.de/apps/todo-app/privacy/'),
    ]);
  });

  testWidgets('every web link of the app is reachable from the page', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpAboutPage(tester, launched: launched);

    for (final label in [
      'Website',
      'Häufige Fragen',
      'Support',
      'Was ist neu',
      'Datenschutzerklärung',
      'Daten löschen',
      'Lizenzen im Web',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(launched.toSet(), AppIdentity.links.all.values.toSet());
  });

  testWidgets('opens the bundled offline license page', (tester) async {
    final launched = <Uri>[];
    await _pumpAboutPage(tester, launched: launched);

    await tester.tap(find.text('Open-Source-Lizenzen'));
    await tester.pumpAndSettle();

    // Flutter's own page, generated from LicenseRegistry — it must open
    // in-app and must NOT go through the launcher seam, because it has to
    // work offline.
    expect(find.byType(LicensePage), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('bug report mail is tagged with the app slug and carries '
      'diagnostics', (tester) async {
    final launched = <Uri>[];
    final buffer = LastErrorBuffer()
      ..add(AppError(error: StateError('boom'), source: 'zone'));

    await _pumpAboutPage(tester, launched: launched, errorBuffer: buffer);

    await tester.tap(find.text('Fehler melden'));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    final uri = launched.single;
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'bugs@lumbrecode.de');

    final query = Uri.decodeComponent(uri.query);
    expect(query, contains('subject=[app:todo-app] Bug report'));
    expect(query, contains('MyApp 1.2.3+42'));
    expect(query, contains('Bad state: boom'));
  });

  testWidgets('plain contact mail has a subject but no diagnostics body', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpAboutPage(tester, launched: launched);

    await tester.tap(find.text('Feedback senden'));
    await tester.pumpAndSettle();

    final query = Uri.decodeComponent(launched.single.query);
    expect(launched.single.path, 'feedback@lumbrecode.de');
    expect(query, contains('subject=[app:todo-app] Feedback'));
    expect(query, isNot(contains('Diagnostic data')));
  });

  testWidgets('shows a message when no app can handle the link', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpAboutPage(tester, launched: launched, launchSucceeds: false);

    await tester.tap(find.text('Website'));
    await tester.pumpAndSettle();

    expect(find.text('Konnte nicht geöffnet werden'), findsOneWidget);
  });

  testWidgets('shows the resolved app version', (tester) async {
    await _pumpAboutPage(tester, launched: []);

    expect(find.text('Version 1.2.3+42'), findsOneWidget);
  });
}
