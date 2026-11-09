import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// Background of the splash surface.
///
/// Must stay identical to `splash_background` in
/// `scripts/bootstrap/android-res/values/splash_colors.xml` — rule 2 of the
/// startup contract: system splash, launch window and the first Flutter
/// `Scaffold` share one colour, so the handover shows no colour jump. It is
/// also what fills the letterbox around the animation, which is why it must
/// not depend on the theme.
///
/// Documented exception to rule 8 of the accessibility contract ("no
/// hardcoded colour outside the `ColorScheme`") — the splash is a brand
/// surface, not a themed one.
const Color _splashBackground = Color(0xFF070A10);

/// Foreground on [_splashBackground] — same exception, same reason.
const Color _splashForeground = Color(0xFFF5F3EF);

/// Two-phase splash screen shown on app launch.
///
/// Phase 1 (company): shows the LumbreCode company branding.
/// Phase 2 (app): shows the concrete app.
///
/// Both phases render their Lottie animation **fullscreen**. The company and
/// the app name are part of the animation files themselves, so this screen
/// deliberately draws no title of its own — a second, differently styled
/// title next to the one inside the animation is exactly the duplication
/// this avoids. The names still reach screen readers, through the
/// [Semantics] label of each phase.
///
/// While the splash sequence is visible, [initialization] runs in the
/// background (config, local settings, auth/session state, ...). Navigation
/// happens via [onFinished] once BOTH the minimum splash duration has elapsed
/// and [initialization] has completed.
///
/// The company phase plays the official LumbreCode logo reveal animation in
/// the active locale (German or English, resolved via
/// [Localizations.localeOf], i.e. the in-app language selection with system
/// language as fallback); the app phase uses a local placeholder asset that
/// is replaced per app (see `assets/animations/README.md`).
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.onFinished,
    this.initialization,
    this.companyPhaseDuration = const Duration(seconds: 1),
    this.appPhaseMinimumDuration = const Duration(seconds: 1),
  });

  /// Called when the splash sequence is complete.
  final VoidCallback onFinished;

  /// Optional startup work executed while the splash is visible.
  ///
  /// Keep this fast and side-effect free where possible. Typical tasks:
  /// load configuration, restore local settings, check session state.
  final Future<void> Function()? initialization;

  /// How long the company (LumbreCode) phase is shown.
  final Duration companyPhaseDuration;

  /// Minimum duration of the app phase before [onFinished] may fire.
  final Duration appPhaseMinimumDuration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

enum _SplashPhase { company, app }

class _SplashPageState extends State<SplashPage> {
  _SplashPhase _phase = _SplashPhase.company;
  Timer? _phaseTimer;
  Timer? _minimumSplashTimer;

  /// Completes when the minimum splash duration has elapsed.
  ///
  /// Backed by a cancelable [Timer] (instead of `Future.delayed`) so that
  /// disposing the splash early — e.g. in widget tests — leaves no pending
  /// timers behind.
  final Completer<void> _minimumSplashElapsed = Completer<void>();

  @override
  void initState() {
    super.initState();
    _phaseTimer = Timer(widget.companyPhaseDuration, _showAppPhase);
    _minimumSplashTimer = Timer(
      widget.companyPhaseDuration + widget.appPhaseMinimumDuration,
      _minimumSplashElapsed.complete,
    );
    unawaited(_runSequence());
  }

  void _showAppPhase() {
    if (!mounted) return;
    setState(() => _phase = _SplashPhase.app);
  }

  Future<void> _runSequence() async {
    final init = widget.initialization?.call() ?? Future<void>.value();
    await Future.wait<void>([_minimumSplashElapsed.future, init]);
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _minimumSplashTimer?.cancel();
    super.dispose();
  }

  /// Resolves the localized company logo reveal animation.
  ///
  /// German gets the DE variant; every other locale falls back to English.
  static String _companyAnimationAsset(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'de'
        ? 'assets/animations/lumbrecode_logo_reveal_3s_de_sequential.json'
        : 'assets/animations/lumbrecode_logo_reveal_3s_en_sequential.json';
  }

  @override
  Widget build(BuildContext context) {
    // The splash owns the whole screen, including the area behind the system
    // bars — light icons are the only ones readable on [_splashBackground].
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _splashBackground,
      ),
      child: Scaffold(
        backgroundColor: _splashBackground,
        // No SafeArea and no padding, on purpose: see the class docs.
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _phase == _SplashPhase.company
              ? _SplashContent(
                  key: const ValueKey('company-splash'),
                  animationAsset: _companyAnimationAsset(context),
                  fallbackIcon: 'assets/branding/lumbrecode_icon_512.png',
                  name: AppBranding.companyName,
                )
              : _SplashContent(
                  key: const ValueKey('app-splash'),
                  animationAsset:
                      'assets/animations/app_splash_placeholder.json',
                  fallbackIcon: 'assets/images/app_icon.png',
                  name: AppLocalizations.of(context).splashTitle,
                ),
        ),
      ),
    );
  }
}

/// One splash phase: its animation, fullscreen, plus a progress hint.
class _SplashContent extends StatelessWidget {
  const _SplashContent({
    super.key,
    required this.animationAsset,
    required this.fallbackIcon,
    required this.name,
  });

  final String animationAsset;

  /// Icon shown instead of the animation when [animationAsset] cannot be
  /// loaded.
  final String fallbackIcon;

  /// Company or app name. Drawn only by the fallback — in the normal case it
  /// is part of [animationAsset], and screen readers get it from the
  /// [Semantics] label below.
  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      container: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // `contain`, not `cover`: the names live inside the file, and cover
          // would crop them on every screen whose aspect ratio differs from
          // the asset's. The letterbox disappears into the animation's own
          // background layer, which carries the same near-black.
          Lottie.asset(
            animationAsset,
            repeat: false,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                _BrandFallback(assetName: fallbackIcon, name: name),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl * 2),
              child: SizedBox(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _splashForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static branding for a splash phase whose Lottie asset is missing.
///
/// The animation carries the name, so the fallback has to draw it as text —
/// otherwise a broken asset would leave an unbranded black screen.
///
/// The icon PNGs are opaque and carry the brand background, so they are
/// clipped to a rounded square and read the same in light and dark themes —
/// unlike a bare [Icon], which would have to be tinted per theme.
class _BrandFallback extends StatelessWidget {
  const _BrandFallback({required this.assetName, required this.name});

  final String assetName;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Image.asset(
              assetName,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _splashForeground,
            ),
          ),
        ],
      ),
    );
  }
}
