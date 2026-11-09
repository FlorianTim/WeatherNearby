import 'package:app_core/app_core.dart';

/// Identity of this concrete app.
///
/// Everything here is **app-specific** and is replaced when a new app is
/// derived from the template — unlike `AppBranding` in `app_core`, which
/// holds the company-level constants that stay the same for every app.
abstract final class AppIdentity {
  /// Human-readable app name.
  ///
  /// Used for `MaterialApp.title` (Android task switcher, browser tab) and as
  /// the application name on the licence page. Deliberately a constant and
  /// **not** an l10n key: the task-switcher title is read before any locale is
  /// resolved, and a product name is usually not translated. Keep in sync with
  /// `android:label` and `project.env`.
  static const String displayName = 'Flutter App Template';

  /// The name shown in the task switcher for a flavor: the plain name for the
  /// release and for debug builds, else the name with the flavor
  /// (`Flutter App Template (Snapshot)`) so builds installed side by side
  /// can be told apart.
  static String titleFor(AppFlavor flavor) => flavor.storageSuffix.isEmpty
      ? displayName
      : '$displayName (${_label(flavor)})';

  static String _label(AppFlavor flavor) =>
      flavor.name[0].toUpperCase() + flavor.name.substring(1);

  /// Web slug in kebab-case.
  ///
  /// Must match `WEB_SLUG` in `project.env`. Drives both the public page
  /// URLs (`https://lumbrecode.de/apps/<slug>/...`) and the `[app:<slug>]`
  /// subject prefix on support mails.
  static const String webSlug = 'todo-app';

  /// External web links and support mailboxes for this app.
  static const AppLinks links = AppLinks(slug: webSlug);
}
