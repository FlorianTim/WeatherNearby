import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/database_provider.dart';
import '../../core/errors/feedback_mail.dart';
import '../../core/errors/last_error_buffer.dart';
import '../../core/platform/platform_seams.dart';
import '../../core/settings/app_settings.dart';
import '../../core/startup/startup_providers.dart';
import '../../core/storage/key_value_store.dart';
import '../../features/about/presentation/about_page.dart';
import '../../features/help/presentation/help_document_page.dart';
import '../../features/monetization/application/monetization_providers.dart';
import '../../features/monetization/presentation/pro_page.dart';
import '../../features/onboarding/application/onboarding_notifier.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/privacy/presentation/privacy_page.dart';
import '../../features/settings/presentation/settings_diagnostics_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/application/splash_timing.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/splash/presentation/startup_error_page.dart';
import '../../features/todos/application/todo_list_notifier.dart';
import '../../features/todos/presentation/todo_list_page.dart';
import '../app_identity.dart';
import '../developer_tools.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_mode_provider.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Subject of the privacy enquiry mail.
///
/// Deliberately not localized, like every other mail subject: the shared
/// LumbreCode mailboxes are sorted by the `[app:<slug>]` prefix plus this
/// subject, and a per-locale mix would break those filters.
const _privacySubject = 'Privacy enquiry';
const _bugSubject = 'Bug report';

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final timing = ref.watch(splashTimingProvider);
            return SplashPage(
              companyPhaseDuration: timing.company,
              appPhaseMinimumDuration: timing.appMinimum,
              // Startup work runs while the branded animation plays; the
              // coordinator decides what may fail and how (see
              // core/startup/). The outcome is recorded so the routing
              // decision below stays synchronous.
              initialization: () async {
                final result = await ref.read(startupCoordinatorProvider).run();
                ref.read(startupOutcomeProvider.notifier).record(result);
              },
              onFinished: () {
                final outcome = ref.read(startupOutcomeProvider);
                // Three destinations, in order of precedence: a fatal
                // startup failure wins over everything (ONB-003), then the
                // first-start intro, then the app itself. Both reads are
                // synchronous, so nothing is shown in between.
                final destination = switch (outcome?.isFatal ?? false) {
                  true => AppRoutes.startupError,
                  false when !ref.read(onboardingCompletedProvider) =>
                    AppRoutes.intro,
                  false => AppRoutes.todos,
                };
                GoRouter.of(context).go(destination);
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.startupError,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => StartupErrorPage(
            // Retry means "run the whole pipeline again": drop the previous
            // outcome and the resources the failed task owned, then go back
            // to the splash so the coordinator runs from the top.
            onRetry: () {
              ref.read(startupOutcomeProvider.notifier).reset();
              ref.invalidate(appDatabaseProvider);
              GoRouter.of(context).go(AppRoutes.splash);
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => OnboardingPage(
            currentLocale: ref.watch(localeProvider),
            onLocaleChanged: (locale) =>
                ref.read(localeProvider.notifier).setLocale(locale),
            currentThemeMode: ref.watch(themeModeProvider),
            onThemeModeChanged: (mode) =>
                ref.read(themeModeProvider.notifier).setThemeMode(mode),
            onFinished: () async {
              await ref.read(onboardingCompletedProvider.notifier).complete();
              if (!context.mounted) return;
              final router = GoRouter.of(context);
              // Reached from settings, the intro was pushed and belongs on
              // top of it; reached from the splash, it is the whole stack
              // and the app comes next.
              if (router.canPop()) {
                router.pop();
              } else {
                router.go(AppRoutes.todos);
              }
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final router = GoRouter.of(context);
            // Read, not watched: the buffer is filled by the zone handlers
            // and does not notify. A row that appears mid-session is not
            // worth a listenable here — the next visit shows it.
            final hasError = ref.read(lastErrorBufferProvider).last != null;

            return SettingsPage(
              currentLocale: ref.watch(localeProvider),
              onLocaleChanged: (locale) =>
                  ref.read(localeProvider.notifier).setLocale(locale),
              currentThemeMode: ref.watch(themeModeProvider),
              onThemeModeChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(mode),
              onOpenManual: () => router.push(AppRoutes.manual),
              onOpenFaq: () => router.push(AppRoutes.faq),
              onShowIntro: () => router.push(AppRoutes.intro),
              onOpenPrivacy: () => router.push(AppRoutes.privacy),
              onOpenPro: () => router.push(AppRoutes.pro),
              onOpenAbout: () => router.push(AppRoutes.about),
              onReportLastError: hasError
                  ? () => _reportLastError(context, ref)
                  : null,
              onOpenDiagnostics: developerToolsEnabled
                  ? () => router.push(AppRoutes.settingsDiagnostics)
                  : null,
            );
          },
        ),
      ),
      // Developer builds only: the route itself does not exist in a release
      // or pre-release build, so a deep link cannot reach the page either
      // (SET-051).
      if (developerToolsEnabled)
        GoRoute(
          path: AppRoutes.settingsDiagnostics,
          builder: (context, state) => Consumer(
            builder: (context, ref, _) => SettingsDiagnosticsPage(
              store: ref.watch(keyValueStoreProvider),
            ),
          ),
        ),
      GoRoute(
        path: AppRoutes.manual,
        builder: (context, state) =>
            const HelpDocumentPage(document: HelpDocument.manual),
      ),
      GoRoute(
        path: AppRoutes.faq,
        builder: (context, state) =>
            const HelpDocumentPage(document: HelpDocument.faq),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => PrivacyPage(
            // Every URI on this page is built by the app from
            // AppIdentity.links, so the app-authored policy applies.
            onOpenUrl: (uri) => ref.read(urlLauncherProvider)(
              uri,
              policy: UrlPolicy.appAuthored,
            ),
            onContactPrivacy: () => ref.read(urlLauncherProvider)(
              AppIdentity.links.mailto(
                SupportMailbox.privacy,
                subject: _privacySubject,
              ),
              policy: UrlPolicy.appAuthored,
            ),
            onDeleteAllData: () async {
              await ref.read(appDatabaseProvider).wipeAllData();
              // Providers hold the deleted rows; drop their caches so every
              // screen reflects the wipe instead of showing stale data.
              ref.invalidate(todoListProvider);
            },
            onResetSettings: () async {
              await resetAllSettings(ref.read(keyValueStoreProvider));
              // The store is now empty, but the notifiers still hold what
              // they read at build time — drop them so the UI returns to
              // the system defaults without a restart.
              ref.invalidate(localeProvider);
              ref.invalidate(themeModeProvider);
              ref.invalidate(onboardingCompletedProvider);
              ref.invalidate(cachedEntitlementProvider);
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.pro,
        builder: (context, state) => const ProPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.todos,
        builder: (context, state) => TodoListPage(
          onOpenSettings: () => GoRouter.of(context).push(AppRoutes.settings),
          onOpenAbout: () => GoRouter.of(context).push(AppRoutes.about),
        ),
      ),
    ],
  );
}

/// Opens a prefilled bug mail carrying the buffered error.
///
/// Diagnostics are best-effort: the plugins are async and may not have
/// resolved yet, so an unresolved value simply omits that block.
void _reportLastError(BuildContext context, WidgetRef ref) {
  final uri = FeedbackMailBuilder(links: AppIdentity.links).build(
    mailbox: SupportMailbox.bugs,
    subject: _bugSubject,
    packageInfo: ref.read(packageInfoProvider).value,
    deviceInfo: ref.read(deviceInfoProvider).value,
    lastError: ref.read(lastErrorBufferProvider).last,
  );
  ref.read(urlLauncherProvider)(uri, policy: UrlPolicy.appAuthored);
}
