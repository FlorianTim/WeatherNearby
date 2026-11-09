import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show SingleActivator;
import 'package:flutter/services.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/menu/app_menu.dart';
import '../router/routes.dart';

/// The screens a menu entry can jump to, in menu order. `Alt+1` … `Alt+4`
/// (`Ctrl+Alt+1` … on a Mac, where Option+digit types a symbol).
const _gotoTargets = <(String, String)>[
  ('todos', AppRoutes.todos),
  ('settings', AppRoutes.settings),
  ('privacy', AppRoutes.privacy),
  ('about', AppRoutes.about),
];

const _digits = <LogicalKeyboardKey>[
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
];

/// Id of the entry that ends the desktop application.
const quitMenuId = 'app:quit';

/// Prefix of the entries that open a screen: `goto:settings`.
const gotoMenuPrefix = 'goto:';

/// The route a `goto:` id names, or `null` for any other id.
String? gotoRouteOf(String id) {
  if (!id.startsWith(gotoMenuPrefix)) return null;
  final name = id.substring(gotoMenuPrefix.length);
  for (final (target, route) in _gotoTargets) {
    if (target == name) return route;
  }
  return null;
}

/// The route a `help:` id opens, or `null` for any other id.
String? helpRouteOf(String id) => switch (id) {
  'help:manual' => AppRoutes.manual,
  'help:faq' => AppRoutes.faq,
  _ => null,
};

/// The screens a menu entry may *not* leave: the splash is still starting the
/// app, the error page and the intro are decisions the user has to take
/// first.
const _guardedRoutes = {
  AppRoutes.splash,
  AppRoutes.startupError,
  AppRoutes.intro,
};

/// Whether the screen at [location] can be left through the menu.
bool menuNavigationAllowed(String location) =>
    !_guardedRoutes.contains(Uri.parse(location).path);

/// Whether this platform is a desktop with an application window.
bool get isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// The menu of the app.
///
/// [location] is the current route: while it is guarded, the entries that
/// navigate are disabled. [desktop] adds File → Quit, which only exists where
/// an application window has to be closed by the application (not on the web,
/// not on a phone). [mac] spells the keys with Command and Control+Option.
List<AppMenuGroup> buildAppMenus(
  AppLocalizations l10n, {
  required String location,
  required bool desktop,
  required bool mac,
}) {
  final canNavigate = menuNavigationAllowed(location);
  final labels = {
    'todos': l10n.todosTitle,
    'settings': l10n.settingsTitle,
    'privacy': l10n.privacyTitle,
    'about': l10n.aboutTitle,
  };

  return [
    if (desktop)
      AppMenuGroup(
        id: 'file',
        label: l10n.menuFile,
        items: [
          AppMenuItem(
            id: quitMenuId,
            label: l10n.menuQuit,
            shortcut: SingleActivator(
              LogicalKeyboardKey.keyQ,
              control: !mac,
              meta: mac,
            ),
          ),
        ],
      ),
    AppMenuGroup(
      id: 'goto',
      label: l10n.menuGoTo,
      items: [
        for (var i = 0; i < _gotoTargets.length; i++)
          AppMenuItem(
            id: '$gotoMenuPrefix${_gotoTargets[i].$1}',
            label: labels[_gotoTargets[i].$1]!,
            enabled: canNavigate,
            shortcut: SingleActivator(_digits[i], alt: true, control: mac),
          ),
      ],
    ),
    AppMenuGroup(
      id: 'help',
      label: l10n.menuHelp,
      items: [
        AppMenuItem(
          id: 'help:manual',
          label: l10n.helpManualTitle,
          enabled: canNavigate,
          shortcut: const SingleActivator(LogicalKeyboardKey.f1),
        ),
        AppMenuItem(
          id: 'help:faq',
          label: l10n.helpFaqTitle,
          enabled: canNavigate,
        ),
      ],
    ),
  ];
}
