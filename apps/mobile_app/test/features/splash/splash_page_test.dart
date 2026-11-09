import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_app/features/splash/presentation/splash_page.dart';

import '../../support/test_app.dart';

Finder findLottieAsset(String assetName) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is LottieBuilder &&
        (widget.lottie as AssetLottie).assetName == assetName,
  );
}

void main() {
  testWidgets('shows company phase, then app phase', (tester) async {
    // Semantics labels are only built while a handle is held.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(wrapWithL10n(SplashPage(onFinished: () {})));
    await tester.pump(const Duration(milliseconds: 500));

    // The names are part of the animation files, so they exist as semantics
    // labels rather than as text on screen.
    expect(find.bySemanticsLabel('LumbreCode'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    // The cross-fade only starts ticking on the next frame, and a fading-in
    // child contributes no semantics while it is still transparent.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.bySemanticsLabel('Flutter App Template'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('draws the animation fullscreen and no title of its own', (
    tester,
  ) async {
    await tester.pumpWidget(wrapWithL10n(SplashPage(onFinished: () {})));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.getSize(find.byType(LottieBuilder)),
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    // A visible title would duplicate the one inside the animation.
    expect(find.text('LumbreCode'), findsNothing);
  });

  testWidgets('finishes after minimum duration when init is fast', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      wrapWithL10n(
        SplashPage(
          onFinished: () => finished = true,
          initialization: () async {},
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1900));
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 200));
    expect(finished, isTrue);
  });

  testWidgets('company phase plays the German animation for locale de', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithL10n(SplashPage(onFinished: () {}), locale: const Locale('de')),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      findLottieAsset(
        'assets/animations/lumbrecode_logo_reveal_3s_de_sequential.json',
      ),
      findsOneWidget,
    );
  });

  testWidgets('company phase plays the English animation for locale en', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithL10n(SplashPage(onFinished: () {}), locale: const Locale('en')),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      findLottieAsset(
        'assets/animations/lumbrecode_logo_reveal_3s_en_sequential.json',
      ),
      findsOneWidget,
    );
  });

  testWidgets('waits for slow initialization before finishing', (tester) async {
    var finished = false;
    final initDone = Completer<void>();

    await tester.pumpWidget(
      wrapWithL10n(
        SplashPage(
          onFinished: () => finished = true,
          initialization: () => initDone.future,
        ),
      ),
    );

    // Minimum splash duration (2s) has elapsed, but init is still running.
    await tester.pump(const Duration(seconds: 3));
    expect(finished, isFalse);

    initDone.complete();
    await tester.pump();
    expect(finished, isTrue);
  });
}
