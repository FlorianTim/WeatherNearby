abstract final class AppRoutes {
  static const splash = '/';

  /// Recovery screen shown when a blocking startup task failed.
  static const startupError = '/startup-error';

  /// First-start intro. Also reachable from settings at any time.
  static const intro = '/intro';

  static const settings = '/settings';

  /// Debug-only view over the settings register. The route is not registered
  /// in a release build (spec 0005, SET-051).
  static const settingsDiagnostics = '/settings/diagnostics';

  static const manual = '/help/manual';
  static const faq = '/help/faq';
  static const privacy = '/privacy';
  static const pro = '/pro';

  static const greeting = '/greeting';
  static const about = '/about';
  static const todos = '/todos';
  static const todoDetail = '/todos/:id';
}
