import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical layout sizes; DPR changes capture resolution, not layout width.
enum UiTestProfile {
  phone(Size(390, 844)),
  compactPhone(Size(360, 800)),
  largeText(Size(390, 844), textScale: 2),
  tablet(Size(1024, 768)),
  desktop(Size(1440, 900));

  const UiTestProfile(this.size, {this.textScale = 1});

  final Size size;
  final double textScale;

  void apply(WidgetTester tester, {double pixelRatio = 1}) {
    tester.view.devicePixelRatio = pixelRatio;
    tester.view.physicalSize = size * pixelRatio;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
}

/// Scrolls a single page to a target before checking and tapping its hit area.
Future<void> tapAfterScroll(WidgetTester tester, Finder target) async {
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
