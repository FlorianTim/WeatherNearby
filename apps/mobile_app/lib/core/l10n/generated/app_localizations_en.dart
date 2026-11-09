// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get splashTitle => 'Flutter App Template';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Choose language';

  @override
  String get settingsSystemLanguage => 'System language';

  @override
  String get settingsThemeSection => 'Appearance';

  @override
  String get settingsSystemTheme => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsDeleteData => 'Delete app data';

  @override
  String get settingsDeleteDataHint =>
      'Clears all content. Language and appearance are kept.';

  @override
  String get settingsDeleteDataConfirmTitle => 'Delete app data?';

  @override
  String get settingsDeleteDataConfirmBody =>
      'All locally stored content will be deleted permanently. This cannot be undone.';

  @override
  String get settingsDeleteDataDone => 'App data deleted';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get permissionAllow => 'Allow';

  @override
  String get permissionNotNow => 'Not now';

  @override
  String get permissionOpenSettings => 'Open settings';

  @override
  String get startupErrorTitle => 'The app could not start';

  @override
  String get startupErrorBody =>
      'Something went wrong during startup that could not be fixed automatically. Try again — if the problem persists, a bug report helps.';

  @override
  String startupErrorTask(String task) {
    return 'Failed step: $task';
  }

  @override
  String get startupErrorRetry => 'Try again';

  @override
  String get startupErrorReport => 'Report the problem';

  @override
  String get greetMe => 'Greet me!';

  @override
  String get greeting => 'Hello! Welcome to the example app.';

  @override
  String get currentTime => 'Current time';

  @override
  String get todosTitle => 'Tasks';

  @override
  String get todoCreateTitle => 'New task';

  @override
  String get todoTitleLabel => 'Title';

  @override
  String get todoDescriptionLabel => 'Description (optional)';

  @override
  String get todoStatusPending => 'Pending';

  @override
  String get todoStatusInProgress => 'In progress';

  @override
  String get todoStatusCompleted => 'Completed';

  @override
  String get todoEmpty => 'No tasks yet';

  @override
  String get todoDelete => 'Delete';

  @override
  String get todoCreate => 'Create';

  @override
  String get todoRequired => 'Required';

  @override
  String get todoErrorLoading => 'Error loading tasks';

  @override
  String get todoRetry => 'Try again';

  @override
  String get aboutTitle => 'About & help';

  @override
  String get aboutOpen => 'Open about & help';

  @override
  String get aboutSectionHelp => 'Help & information';

  @override
  String get aboutSectionLegal => 'Legal';

  @override
  String get aboutSectionContact => 'Contact';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutFaq => 'FAQ';

  @override
  String get aboutSupport => 'Support';

  @override
  String get aboutChangelog => 'What\'s new';

  @override
  String get aboutPrivacy => 'Privacy policy';

  @override
  String get aboutDataDeletion => 'Delete my data';

  @override
  String get aboutLicensesOffline => 'Open source licenses';

  @override
  String get aboutLicensesOfflineHint =>
      'Every package in this build, available offline';

  @override
  String get aboutLicensesOnline => 'Licenses on the web';

  @override
  String get aboutMailSupport => 'Get help';

  @override
  String get aboutMailFeedback => 'Send feedback';

  @override
  String get aboutMailBug => 'Report a bug';

  @override
  String get aboutMailBugHint =>
      'Includes app version, device and the last error';

  @override
  String get aboutMailPrivacy => 'Ask a privacy question';

  @override
  String get aboutMailSecurity => 'Report a security issue';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutOpenFailed => 'Could not be opened';

  @override
  String get linkSchemeNotSupported => 'This link cannot be opened';

  @override
  String get settingsOpen => 'Settings';

  @override
  String get settingsSectionHelp => 'Help';

  @override
  String get settingsSectionDataPrivacy => 'Data and privacy';

  @override
  String get settingsSectionPro => 'Pro';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionDevelopment => 'Development';

  @override
  String get settingsManual => 'User manual';

  @override
  String get settingsFaq => 'Frequently asked questions';

  @override
  String get settingsShowIntro => 'Show the app intro again';

  @override
  String get settingsPrivacyEntry => 'Privacy and data';

  @override
  String get settingsPrivacyEntryHint => 'What is stored, and how to delete it';

  @override
  String get settingsProEntry => 'Pro status';

  @override
  String get settingsAboutEntry => 'About and help';

  @override
  String get settingsReportError => 'Report the last error';

  @override
  String get settingsReportErrorHint =>
      'Opens a mail with the technical details';

  @override
  String get settingsDiagnostics => 'Settings diagnostics';

  @override
  String get settingsDiagnosticsHint => 'Visible in debug builds only';

  @override
  String get settingsResetSettings => 'Reset settings';

  @override
  String get settingsResetSettingsHint =>
      'Language and appearance back to the system default. Content is kept.';

  @override
  String get settingsResetSettingsConfirmTitle => 'Reset settings?';

  @override
  String get settingsResetSettingsConfirmBody =>
      'Every setting returns to its default. Your content is kept.';

  @override
  String get settingsResetSettingsDone => 'Settings reset';

  @override
  String get commonReset => 'Reset';

  @override
  String get diagnosticsTitle => 'Settings diagnostics';

  @override
  String get diagnosticsIntro =>
      'Every registered setting with its raw stored value. Read-only.';

  @override
  String get diagnosticsUnset => 'not set';

  @override
  String get helpManualTitle => 'User manual';

  @override
  String get helpFaqTitle => 'Frequently asked questions';

  @override
  String get helpLoadError => 'The document could not be loaded.';

  @override
  String get privacyTitle => 'Privacy and data';

  @override
  String get privacyLocalTitle => 'Your data stays on this device';

  @override
  String get privacyLocalBody =>
      'The app stores its content in a database on this device. There is no account, no server and no background transfer. What you delete here is gone.';

  @override
  String get privacyPermissionsSection => 'Permissions';

  @override
  String get privacyPermissionGranted => 'Granted';

  @override
  String get privacyPermissionDenied => 'Denied';

  @override
  String get privacyPermissionPermanentlyDenied => 'Permanently denied';

  @override
  String get privacyPermissionNotRequested => 'Not requested';

  @override
  String get privacyDocumentsSection => 'Published documents';

  @override
  String get privacyContact => 'Send a privacy enquiry';

  @override
  String get privacyDangerSection => 'Danger zone';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Get started';

  @override
  String get introWelcomeTitle => 'Welcome';

  @override
  String get introWelcomeBody =>
      'This app was built from the LumbreCode Flutter template. The next pages show briefly what it does.';

  @override
  String get introFeaturesTitle => 'What the app does';

  @override
  String get introFeaturesBody =>
      'Create, find and edit content — offline, without an account, on this device.';

  @override
  String get introPrivacyTitle => 'Your data';

  @override
  String get introPrivacyBody =>
      'Everything stays stored locally. Nothing is uploaded, and you can delete all of it at any time.';

  @override
  String get introSettingsTitle => 'Language and appearance';

  @override
  String get introSettingsBody =>
      'Both can be changed at any time in the settings.';

  @override
  String get introReadyTitle => 'All set';

  @override
  String get introReadyBody =>
      'The manual, the privacy page and every setting are behind the gear icon.';

  @override
  String get proTitle => 'Pro';

  @override
  String get proStatusFree => 'Free version';

  @override
  String get proStatusPro => 'Pro version';

  @override
  String get proAllFree => 'All features are currently free.';

  @override
  String get proStoreChecking => 'Checking the store ...';

  @override
  String get proStoreAvailable => 'Store available';

  @override
  String get proStoreUnavailable => 'Store unavailable';

  @override
  String get proRestore => 'Restore purchases';

  @override
  String get proRestoreNone => 'No purchases found.';

  @override
  String get proRestoreRestored => 'Pro was restored.';

  @override
  String get proRestoreFailed => 'The store cannot be reached right now.';

  @override
  String get proNote =>
      'This page shows the entitlement status. Purchases are not enabled in this version yet.';

  @override
  String diagnosticsDefault(String value) {
    return 'Default: $value';
  }

  @override
  String get menuLabel => 'Application menu';

  @override
  String get menuFile => 'File';

  @override
  String get menuGoTo => 'Go to';

  @override
  String get menuHelp => 'Help';

  @override
  String get menuQuit => 'Quit';

  @override
  String get channelDev => 'Development';

  @override
  String get channelSnapshot => 'Snapshot – for trying things out';

  @override
  String get channelStaging => 'Staging';

  @override
  String get channelPrerelease => 'Pre-release – a test version before release';

  @override
  String aboutChannel(String name) {
    return 'Channel: $name';
  }
}
