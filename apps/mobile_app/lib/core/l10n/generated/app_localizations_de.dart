// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get splashTitle => 'Flutter App Template';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguageSection => 'Sprache wählen';

  @override
  String get settingsSystemLanguage => 'Systemsprache';

  @override
  String get settingsThemeSection => 'Erscheinungsbild';

  @override
  String get settingsSystemTheme => 'Systemeinstellung';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsDataSection => 'Daten';

  @override
  String get settingsDeleteData => 'App-Daten löschen';

  @override
  String get settingsDeleteDataHint =>
      'Löscht alle Inhalte. Sprache und Erscheinungsbild bleiben erhalten.';

  @override
  String get settingsDeleteDataConfirmTitle => 'App-Daten löschen?';

  @override
  String get settingsDeleteDataConfirmBody =>
      'Alle lokal gespeicherten Inhalte werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get settingsDeleteDataDone => 'App-Daten gelöscht';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get permissionAllow => 'Erlauben';

  @override
  String get permissionNotNow => 'Nicht jetzt';

  @override
  String get permissionOpenSettings => 'Einstellungen öffnen';

  @override
  String get startupErrorTitle => 'Die App konnte nicht starten';

  @override
  String get startupErrorBody =>
      'Beim Start ist ein Fehler aufgetreten, der sich nicht automatisch beheben ließ. Versuche es erneut — bleibt der Fehler bestehen, hilft ein Fehlerbericht.';

  @override
  String startupErrorTask(String task) {
    return 'Fehlgeschlagener Schritt: $task';
  }

  @override
  String get startupErrorRetry => 'Erneut versuchen';

  @override
  String get startupErrorReport => 'Fehler melden';

  @override
  String get greetMe => 'Begrüß mich!';

  @override
  String get greeting => 'Hallo! Willkommen zur Beispiel-App.';

  @override
  String get currentTime => 'Aktuelle Uhrzeit';

  @override
  String get todosTitle => 'Aufgaben';

  @override
  String get todoCreateTitle => 'Neue Aufgabe';

  @override
  String get todoTitleLabel => 'Titel';

  @override
  String get todoDescriptionLabel => 'Beschreibung (optional)';

  @override
  String get todoStatusPending => 'Offen';

  @override
  String get todoStatusInProgress => 'In Bearbeitung';

  @override
  String get todoStatusCompleted => 'Erledigt';

  @override
  String get todoEmpty => 'Keine Aufgaben vorhanden';

  @override
  String get todoDelete => 'Löschen';

  @override
  String get todoCreate => 'Erstellen';

  @override
  String get todoRequired => 'Pflichtfeld';

  @override
  String get todoErrorLoading => 'Fehler beim Laden';

  @override
  String get todoRetry => 'Erneut versuchen';

  @override
  String get aboutTitle => 'Über & Hilfe';

  @override
  String get aboutOpen => 'Über & Hilfe öffnen';

  @override
  String get aboutSectionHelp => 'Hilfe & Informationen';

  @override
  String get aboutSectionLegal => 'Rechtliches';

  @override
  String get aboutSectionContact => 'Kontakt';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutFaq => 'Häufige Fragen';

  @override
  String get aboutSupport => 'Support';

  @override
  String get aboutChangelog => 'Was ist neu';

  @override
  String get aboutPrivacy => 'Datenschutzerklärung';

  @override
  String get aboutDataDeletion => 'Daten löschen';

  @override
  String get aboutLicensesOffline => 'Open-Source-Lizenzen';

  @override
  String get aboutLicensesOfflineHint =>
      'Alle Pakete dieser App-Version, offline verfügbar';

  @override
  String get aboutLicensesOnline => 'Lizenzen im Web';

  @override
  String get aboutMailSupport => 'Hilfe anfordern';

  @override
  String get aboutMailFeedback => 'Feedback senden';

  @override
  String get aboutMailBug => 'Fehler melden';

  @override
  String get aboutMailBugHint =>
      'Enthält App-Version, Gerät und den letzten Fehler';

  @override
  String get aboutMailPrivacy => 'Datenschutzfrage stellen';

  @override
  String get aboutMailSecurity => 'Sicherheitslücke melden';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutOpenFailed => 'Konnte nicht geöffnet werden';

  @override
  String get linkSchemeNotSupported => 'Dieser Link kann nicht geöffnet werden';

  @override
  String get settingsOpen => 'Einstellungen';

  @override
  String get settingsSectionHelp => 'Hilfe';

  @override
  String get settingsSectionDataPrivacy => 'Daten und Datenschutz';

  @override
  String get settingsSectionPro => 'Pro';

  @override
  String get settingsSectionSupport => 'Unterstützung';

  @override
  String get settingsSectionDevelopment => 'Entwicklung';

  @override
  String get settingsManual => 'Anleitung';

  @override
  String get settingsFaq => 'Häufige Fragen';

  @override
  String get settingsShowIntro => 'App-Einleitung erneut anzeigen';

  @override
  String get settingsPrivacyEntry => 'Datenschutz und Daten';

  @override
  String get settingsPrivacyEntryHint =>
      'Was gespeichert wird, und wie du es löschst';

  @override
  String get settingsProEntry => 'Pro-Status';

  @override
  String get settingsAboutEntry => 'Über die App und Hilfe';

  @override
  String get settingsReportError => 'Letzten Fehler melden';

  @override
  String get settingsReportErrorHint =>
      'Öffnet eine Mail mit den technischen Angaben';

  @override
  String get settingsDiagnostics => 'Einstellungen-Diagnose';

  @override
  String get settingsDiagnosticsHint => 'Nur in Debug-Builds sichtbar';

  @override
  String get settingsResetSettings => 'Einstellungen zurücksetzen';

  @override
  String get settingsResetSettingsHint =>
      'Sprache und Erscheinungsbild zurück auf Systemeinstellung. Inhalte bleiben erhalten.';

  @override
  String get settingsResetSettingsConfirmTitle => 'Einstellungen zurücksetzen?';

  @override
  String get settingsResetSettingsConfirmBody =>
      'Alle Einstellungen kehren auf ihre Standardwerte zurück. Deine Inhalte bleiben erhalten.';

  @override
  String get settingsResetSettingsDone => 'Einstellungen zurückgesetzt';

  @override
  String get commonReset => 'Zurücksetzen';

  @override
  String get diagnosticsTitle => 'Einstellungen-Diagnose';

  @override
  String get diagnosticsIntro =>
      'Alle registrierten Einstellungen mit ihrem gespeicherten Rohwert. Nur lesend.';

  @override
  String get diagnosticsUnset => 'nicht gesetzt';

  @override
  String get helpManualTitle => 'Anleitung';

  @override
  String get helpFaqTitle => 'Häufige Fragen';

  @override
  String get helpLoadError => 'Das Dokument konnte nicht geladen werden.';

  @override
  String get privacyTitle => 'Datenschutz und Daten';

  @override
  String get privacyLocalTitle => 'Deine Daten bleiben auf diesem Gerät';

  @override
  String get privacyLocalBody =>
      'Die App speichert ihre Inhalte in einer Datenbank auf diesem Gerät. Es gibt kein Konto, keinen Server und keine Übertragung im Hintergrund. Was du hier löschst, ist weg.';

  @override
  String get privacyPermissionsSection => 'Berechtigungen';

  @override
  String get privacyPermissionGranted => 'Erteilt';

  @override
  String get privacyPermissionDenied => 'Abgelehnt';

  @override
  String get privacyPermissionPermanentlyDenied => 'Dauerhaft abgelehnt';

  @override
  String get privacyPermissionNotRequested => 'Nicht angefragt';

  @override
  String get privacyDocumentsSection => 'Veröffentlichte Dokumente';

  @override
  String get privacyContact => 'Datenschutz-Anfrage senden';

  @override
  String get privacyDangerSection => 'Gefahrenbereich';

  @override
  String get introSkip => 'Überspringen';

  @override
  String get introNext => 'Weiter';

  @override
  String get introStart => 'Los geht’s';

  @override
  String get introWelcomeTitle => 'Willkommen';

  @override
  String get introWelcomeBody =>
      'Diese App ist aus dem LumbreCode Flutter-Template entstanden. Die nächsten Seiten zeigen kurz, was sie kann.';

  @override
  String get introFeaturesTitle => 'Was die App kann';

  @override
  String get introFeaturesBody =>
      'Inhalte anlegen, wiederfinden und bearbeiten — offline, ohne Konto, auf diesem Gerät.';

  @override
  String get introPrivacyTitle => 'Deine Daten';

  @override
  String get introPrivacyBody =>
      'Alles bleibt lokal gespeichert. Nichts wird hochgeladen, und du kannst jederzeit alles wieder löschen.';

  @override
  String get introSettingsTitle => 'Sprache und Darstellung';

  @override
  String get introSettingsBody =>
      'Beides lässt sich später jederzeit in den Einstellungen ändern.';

  @override
  String get introReadyTitle => 'Fertig';

  @override
  String get introReadyBody =>
      'Anleitung, Datenschutz und alle Einstellungen findest du jederzeit über das Zahnrad.';

  @override
  String get proTitle => 'Pro';

  @override
  String get proStatusFree => 'Kostenlose Version';

  @override
  String get proStatusPro => 'Pro-Version';

  @override
  String get proAllFree => 'Alle Funktionen sind derzeit kostenlos.';

  @override
  String get proStoreChecking => 'Store wird geprüft ...';

  @override
  String get proStoreAvailable => 'Store verfügbar';

  @override
  String get proStoreUnavailable => 'Store nicht verfügbar';

  @override
  String get proRestore => 'Käufe wiederherstellen';

  @override
  String get proRestoreNone => 'Keine Käufe gefunden.';

  @override
  String get proRestoreRestored => 'Pro wurde wiederhergestellt.';

  @override
  String get proRestoreFailed => 'Der Store ist derzeit nicht erreichbar.';

  @override
  String get proNote =>
      'Diese Seite zeigt den Berechtigungsstatus. Käufe sind in dieser Version noch nicht aktiviert.';

  @override
  String diagnosticsDefault(String value) {
    return 'Standard: $value';
  }

  @override
  String get menuLabel => 'Anwendungsmenü';

  @override
  String get menuFile => 'Datei';

  @override
  String get menuGoTo => 'Gehe zu';

  @override
  String get menuHelp => 'Hilfe';

  @override
  String get menuQuit => 'Beenden';

  @override
  String get channelDev => 'Entwicklung';

  @override
  String get channelSnapshot => 'Snapshot – zum Ausprobieren';

  @override
  String get channelStaging => 'Staging';

  @override
  String get channelPrerelease =>
      'Pre-Release – Testversion vor der Veröffentlichung';

  @override
  String aboutChannel(String name) {
    return 'Kanal: $name';
  }
}
