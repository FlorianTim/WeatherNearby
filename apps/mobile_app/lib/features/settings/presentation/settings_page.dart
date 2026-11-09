import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// The settings hub.
///
/// A **destination**, not a startup step. Until 3.2.1 this page sat between
/// the splash and the app and carried a "Continue" button, which made it a
/// wizard — and a wizard is not somewhere you come back to (spec 0005,
/// SET-001/002).
///
/// Two kinds of rows, on purpose:
///
///  - **Inline options** for the things a user changes often — language and
///    appearance. A language switch is two taps here and five behind a
///    sub-page, and it is the most-used setting in a bilingual app.
///  - **Navigation rows** for everything else, so the hub stays scannable as
///    an app grows (SET-003/004).
///
/// Deliberately provider-free: the page receives values and callbacks, so it
/// can be pumped in a widget test without a `ProviderScope`. The wiring lives
/// in `lib/app/router/app_router.dart`.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.onOpenManual,
    required this.onOpenFaq,
    required this.onShowIntro,
    required this.onOpenPrivacy,
    required this.onOpenPro,
    required this.onOpenAbout,
    this.onReportLastError,
    this.onOpenDiagnostics,
  });

  /// `null` means "follow the system language".
  final Locale? currentLocale;

  /// Called with `null` when the user picks the system language again.
  final ValueChanged<Locale?> onLocaleChanged;

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  final VoidCallback onOpenManual;
  final VoidCallback onOpenFaq;

  /// Reopens the first-start intro immediately (spec 0006, ONB-005).
  final VoidCallback onShowIntro;

  /// Opens the page that owns the destructive actions (spec 0005, SET-035).
  final VoidCallback onOpenPrivacy;

  final VoidCallback onOpenPro;
  final VoidCallback onOpenAbout;

  /// `null` while no uncaught error is buffered — the row then does not
  /// exist, rather than existing and doing nothing (SET-041).
  final VoidCallback? onReportLastError;

  /// `null` in release builds. The whole development section disappears with
  /// it, heading included (SET-051).
  final VoidCallback? onOpenDiagnostics;

  /// Language names stay in their own language — a German speaker looks for
  /// "Deutsch", not for "German".
  static const _languageLabels = {'de': 'Deutsch', 'en': 'English'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _SectionHeader(l10n.settingsLanguageSection),
          AppOptionTile(
            label: l10n.settingsSystemLanguage,
            isSelected: currentLocale == null,
            onTap: () => onLocaleChanged(null),
          ),
          ...AppLocalizations.supportedLocales.map(
            (locale) => AppOptionTile(
              label:
                  _languageLabels[locale.languageCode] ?? locale.languageCode,
              trailing: locale.languageCode.toUpperCase(),
              isSelected: locale.languageCode == currentLocale?.languageCode,
              onTap: () => onLocaleChanged(locale),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(l10n.settingsThemeSection),
          ...ThemeMode.values.map(
            (mode) => AppOptionTile(
              label: _themeLabel(l10n, mode),
              isSelected: mode == currentThemeMode,
              onTap: () => onThemeModeChanged(mode),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          AppSettingsSection(
            title: l10n.settingsSectionHelp,
            children: [
              AppSettingsTile(
                icon: Icons.menu_book_outlined,
                title: l10n.settingsManual,
                showChevron: true,
                onTap: onOpenManual,
              ),
              AppSettingsTile(
                icon: Icons.help_outline,
                title: l10n.settingsFaq,
                showChevron: true,
                onTap: onOpenFaq,
              ),
              AppSettingsTile(
                icon: Icons.slideshow_outlined,
                title: l10n.settingsShowIntro,
                showChevron: true,
                onTap: onShowIntro,
              ),
            ],
          ),

          AppSettingsSection(
            title: l10n.settingsSectionDataPrivacy,
            children: [
              AppSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.settingsPrivacyEntry,
                subtitle: l10n.settingsPrivacyEntryHint,
                showChevron: true,
                onTap: onOpenPrivacy,
              ),
            ],
          ),

          AppSettingsSection(
            title: l10n.settingsSectionPro,
            children: [
              AppSettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: l10n.settingsProEntry,
                // Without this subtitle a premium icon reads as "there is
                // something you have not paid for" — which is false, and
                // sends users hunting for a paywall that does not exist.
                subtitle: l10n.proAllFree,
                showChevron: true,
                onTap: onOpenPro,
              ),
            ],
          ),

          AppSettingsSection(
            title: l10n.settingsSectionSupport,
            children: [
              AppSettingsTile(
                icon: Icons.info_outline,
                title: l10n.settingsAboutEntry,
                showChevron: true,
                onTap: onOpenAbout,
              ),
              if (onReportLastError != null)
                AppSettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: l10n.settingsReportError,
                  subtitle: l10n.settingsReportErrorHint,
                  onTap: onReportLastError!,
                ),
            ],
          ),

          // Absent, not hidden: `kReleaseMode` is a compile-time constant, so
          // a release build does not contain these widgets at all (SET-051).
          if (!kReleaseMode)
            AppSettingsSection(
              title: l10n.settingsSectionDevelopment,
              children: [
                if (onOpenDiagnostics != null)
                  AppSettingsTile(
                    icon: Icons.tune_outlined,
                    title: l10n.settingsDiagnostics,
                    subtitle: l10n.settingsDiagnosticsHint,
                    showChevron: true,
                    onTap: onOpenDiagnostics!,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _themeLabel(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.settingsSystemTheme,
        ThemeMode.light => l10n.settingsThemeLight,
        ThemeMode.dark => l10n.settingsThemeDark,
      };
}

/// Heading above a group of inline options.
///
/// The navigation groups bring their own heading through
/// [AppSettingsSection]; the option groups are plain lists of cards, so they
/// need this.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
