/// Company-level branding constants for LumbreCode template apps.
///
/// These values are template-wide and must NOT be replaced when a new app
/// is initialized from this template. App-specific branding (display name,
/// splash title, icons) is derived from the app specification instead.
abstract final class AppBranding {
  /// Company name shown on the company splash phase.
  static const String companyName = 'LumbreCode';

  /// Company domain (documentation, imprint, support links).
  static const String companyDomain = 'LumbreCode.de';

  /// Base URL under which every LumbreCode app publishes its public pages.
  ///
  /// Per-app URLs are derived from this plus the app's web slug — see
  /// `AppLinks` in `app_links.dart`. No trailing slash.
  static const String appsBaseUrl = 'https://lumbrecode.de/apps';

  /// Base package prefix for all LumbreCode apps.
  ///
  /// Full application ids follow the schema `de.lumbre.code.<app_slug>`,
  /// where `<app_slug>` comes from the app specification (OpenSpec).
  static const String basePackage = 'de.lumbre.code';
}
