import 'package:app_core/app_core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/l10n/generated/app_localizations.dart';
import 'app_identity.dart';
import 'menu/app_menu_scope.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key, this.overrides = const []});

  /// Riverpod overrides for the root [ProviderScope].
  ///
  /// `bootstrap()` injects production implementations (persistent key-value
  /// store, ...); the test harness injects fakes.
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(overrides: overrides, child: const _AppContent());
  }
}

class _AppContent extends ConsumerWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppIdentity.titleFor(AppFlavor.current),
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: themeMode,
      // NOTE: `locale` is null while the user follows the system language.
      // That is what makes Flutter resolve the device locale against
      // `supportedLocales` — passing a non-null default here would pin every
      // user to one language. See `LocaleNotifier`.
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // The menu bar (macOS: the system's, Windows/Linux/web: a Flutter bar;
      // none on a phone) wraps every screen. It rebuilds with the route, so
      // the entries that leave a screen can be disabled on the splash.
      builder: (context, child) =>
          AppMenuScope(router: router, child: child ?? const SizedBox.shrink()),
    );
  }
}
