import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// The first-start intro.
///
/// Five pages: what the app is, what it does, where the data lives, the
/// language and appearance choice, and a closing page. Short on purpose — a
/// template that asks a new user to read documentation before seeing the app
/// has already lost them.
///
/// **It requests no permission.** Not "does not yet": permissions are asked
/// for by the feature that needs them, at the moment it needs them
/// (`docs/architecture/contracts/04-permissions.md`). An intro that asks for
/// four permissions up front is the pattern that contract exists to prevent.
///
/// Deliberately provider-free, like the settings page: values and callbacks
/// in, so a widget test needs no `ProviderScope`.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.onFinished,
  });

  /// `null` means "follow the system language".
  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleChanged;

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// Called after the completion flag was recorded — on finish **and** on
  /// skip, which are the same thing to everything downstream.
  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pageCount = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage >= _pageCount - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: Text(l10n.introSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _IntroPage(
                    icon: Icons.waving_hand_outlined,
                    title: l10n.introWelcomeTitle,
                    body: l10n.introWelcomeBody,
                  ),
                  _IntroPage(
                    icon: Icons.checklist_outlined,
                    title: l10n.introFeaturesTitle,
                    body: l10n.introFeaturesBody,
                  ),
                  _IntroPage(
                    icon: Icons.lock_outline,
                    title: l10n.introPrivacyTitle,
                    body: l10n.introPrivacyBody,
                  ),
                  _IntroSettingsPage(
                    currentLocale: widget.currentLocale,
                    onLocaleChanged: widget.onLocaleChanged,
                    currentThemeMode: widget.currentThemeMode,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                  _IntroPage(
                    icon: Icons.rocket_launch_outlined,
                    title: l10n.introReadyTitle,
                    body: l10n.introReadyBody,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  _PageIndicator(
                    pageCount: _pageCount,
                    currentPage: _currentPage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      // The label, not the dots, is what says "this is the
                      // end": a row of dots is too small to carry that, and
                      // a screen reader never announces it at all.
                      child: Text(
                        isLastPage ? l10n.introStart : l10n.introNext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One informational page: icon, title, body.
class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Scrolls rather than overflowing: at a large text scale a fixed layout
    // would clip the body on a phone (ONB-014).
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Decorative: the title says the same thing in words.
          ExcludeSemantics(
            child: Icon(icon, size: 80, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// The language and appearance page.
///
/// Uses the same [AppOptionTile] rows as the settings hub, and a tap takes
/// effect immediately — the intro switches language and theme under the
/// user's finger. That demonstration is the point; a preview would be weaker
/// and cost more code.
class _IntroSettingsPage extends StatelessWidget {
  const _IntroSettingsPage({
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleChanged;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static const _languageLabels = {'de': 'Deutsch', 'en': 'English'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.lg),
        ExcludeSemantics(
          child: Icon(
            Icons.language,
            size: 64,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.introSettingsTitle,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.introSettingsBody, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),

        AppOptionTile(
          label: l10n.settingsSystemLanguage,
          isSelected: currentLocale == null,
          onTap: () => onLocaleChanged(null),
        ),
        ...AppLocalizations.supportedLocales.map(
          (locale) => AppOptionTile(
            label: _languageLabels[locale.languageCode] ?? locale.languageCode,
            trailing: locale.languageCode.toUpperCase(),
            isSelected: locale.languageCode == currentLocale?.languageCode,
            onTap: () => onLocaleChanged(locale),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...ThemeMode.values.map(
          (mode) => AppOptionTile(
            label: switch (mode) {
              ThemeMode.system => l10n.settingsSystemTheme,
              ThemeMode.light => l10n.settingsThemeLight,
              ThemeMode.dark => l10n.settingsThemeDark,
            },
            isSelected: mode == currentThemeMode,
            onTap: () => onThemeModeChanged(mode),
          ),
        ),
      ],
    );
  }
}

/// Row of dots showing how far the intro has got.
///
/// Excluded from semantics: a row of dots read out as "dot dot dot" is
/// noise. Progress is announced by the primary button's label instead
/// (ONB-041).
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.pageCount, required this.currentPage});

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var page = 0; page < pageCount; page++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Container(
                width: page == currentPage ? 10 : 8,
                height: page == currentPage ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page == currentPage
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
