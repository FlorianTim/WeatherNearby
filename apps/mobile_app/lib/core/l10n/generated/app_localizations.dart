import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Title shown on the splash screen
  ///
  /// In de, this message translates to:
  /// **'Flutter App Template'**
  String get splashTitle;

  /// Title of the settings page (language and appearance)
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// Section heading above the language options
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get settingsLanguageSection;

  /// Language option that follows the device language
  ///
  /// In de, this message translates to:
  /// **'Systemsprache'**
  String get settingsSystemLanguage;

  /// Section heading above the light/dark options
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get settingsThemeSection;

  /// Theme option that follows the device light/dark setting
  ///
  /// In de, this message translates to:
  /// **'Systemeinstellung'**
  String get settingsSystemTheme;

  /// Light theme option
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get settingsThemeLight;

  /// Dark theme option
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get settingsThemeDark;

  /// Section heading above the destructive data actions
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get settingsDataSection;

  /// Destructive action that clears the local database
  ///
  /// In de, this message translates to:
  /// **'App-Daten löschen'**
  String get settingsDeleteData;

  /// States the exact scope: content only, settings survive
  ///
  /// In de, this message translates to:
  /// **'Löscht alle Inhalte. Sprache und Erscheinungsbild bleiben erhalten.'**
  String get settingsDeleteDataHint;

  /// Title of the delete confirmation dialog
  ///
  /// In de, this message translates to:
  /// **'App-Daten löschen?'**
  String get settingsDeleteDataConfirmTitle;

  /// Names the consequence instead of asking 'are you sure?'
  ///
  /// In de, this message translates to:
  /// **'Alle lokal gespeicherten Inhalte werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get settingsDeleteDataConfirmBody;

  /// Confirmation shown after the data was cleared
  ///
  /// In de, this message translates to:
  /// **'App-Daten gelöscht'**
  String get settingsDeleteDataDone;

  /// Generic cancel action
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// Generic delete action
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// Continues from the in-app rationale to the system dialog
  ///
  /// In de, this message translates to:
  /// **'Erlauben'**
  String get permissionAllow;

  /// Declines a permission rationale without consequences
  ///
  /// In de, this message translates to:
  /// **'Nicht jetzt'**
  String get permissionNotNow;

  /// Opens the system settings for a permanently denied permission
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get permissionOpenSettings;

  /// Title of the startup recovery screen
  ///
  /// In de, this message translates to:
  /// **'Die App konnte nicht starten'**
  String get startupErrorTitle;

  /// Explains the situation and the next step
  ///
  /// In de, this message translates to:
  /// **'Beim Start ist ein Fehler aufgetreten, der sich nicht automatisch beheben ließ. Versuche es erneut — bleibt der Fehler bestehen, hilft ein Fehlerbericht.'**
  String get startupErrorBody;

  /// Technical task identifier; never a stack trace
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagener Schritt: {task}'**
  String startupErrorTask(String task);

  /// Re-runs the startup pipeline
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get startupErrorRetry;

  /// Opens a prefilled bug report mail
  ///
  /// In de, this message translates to:
  /// **'Fehler melden'**
  String get startupErrorReport;

  /// Label for the greet button
  ///
  /// In de, this message translates to:
  /// **'Begrüß mich!'**
  String get greetMe;

  /// Greeting message shown after tapping the button
  ///
  /// In de, this message translates to:
  /// **'Hallo! Willkommen zur Beispiel-App.'**
  String get greeting;

  /// Label shown above the current time
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Uhrzeit'**
  String get currentTime;

  /// Title of the todos page
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get todosTitle;

  /// Title of the create todo dialog
  ///
  /// In de, this message translates to:
  /// **'Neue Aufgabe'**
  String get todoCreateTitle;

  /// Label for the todo title field
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get todoTitleLabel;

  /// Label for the todo description field
  ///
  /// In de, this message translates to:
  /// **'Beschreibung (optional)'**
  String get todoDescriptionLabel;

  /// Label for pending status
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get todoStatusPending;

  /// Label for in progress status
  ///
  /// In de, this message translates to:
  /// **'In Bearbeitung'**
  String get todoStatusInProgress;

  /// Label for completed status
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get todoStatusCompleted;

  /// Message shown when there are no todos
  ///
  /// In de, this message translates to:
  /// **'Keine Aufgaben vorhanden'**
  String get todoEmpty;

  /// Label for delete action
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get todoDelete;

  /// Label for create button
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get todoCreate;

  /// Validation message for required fields
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld'**
  String get todoRequired;

  /// Error message when loading todos fails
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden'**
  String get todoErrorLoading;

  /// Label for retry button
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get todoRetry;

  /// Title of the about/help page
  ///
  /// In de, this message translates to:
  /// **'Über & Hilfe'**
  String get aboutTitle;

  /// Tooltip of the app bar action that opens the about page
  ///
  /// In de, this message translates to:
  /// **'Über & Hilfe öffnen'**
  String get aboutOpen;

  /// Section heading for the informational web links
  ///
  /// In de, this message translates to:
  /// **'Hilfe & Informationen'**
  String get aboutSectionHelp;

  /// Section heading for privacy, data deletion and licenses
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get aboutSectionLegal;

  /// Section heading for the support mail addresses
  ///
  /// In de, this message translates to:
  /// **'Kontakt'**
  String get aboutSectionContact;

  /// Link to the app landing page
  ///
  /// In de, this message translates to:
  /// **'Website'**
  String get aboutWebsite;

  /// Link to the FAQ page
  ///
  /// In de, this message translates to:
  /// **'Häufige Fragen'**
  String get aboutFaq;

  /// Link to the support page
  ///
  /// In de, this message translates to:
  /// **'Support'**
  String get aboutSupport;

  /// Link to the public release notes
  ///
  /// In de, this message translates to:
  /// **'Was ist neu'**
  String get aboutChangelog;

  /// Link to the privacy policy
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get aboutPrivacy;

  /// Link to the data deletion request page
  ///
  /// In de, this message translates to:
  /// **'Daten löschen'**
  String get aboutDataDeletion;

  /// Opens the bundled, offline license page (LicenseRegistry)
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get aboutLicensesOffline;

  /// Explains that the bundled license page needs no network
  ///
  /// In de, this message translates to:
  /// **'Alle Pakete dieser App-Version, offline verfügbar'**
  String get aboutLicensesOfflineHint;

  /// Link to the published license page
  ///
  /// In de, this message translates to:
  /// **'Lizenzen im Web'**
  String get aboutLicensesOnline;

  /// Opens a mail to the support mailbox
  ///
  /// In de, this message translates to:
  /// **'Hilfe anfordern'**
  String get aboutMailSupport;

  /// Opens a mail to the feedback mailbox
  ///
  /// In de, this message translates to:
  /// **'Feedback senden'**
  String get aboutMailFeedback;

  /// Opens a prefilled bug report mail
  ///
  /// In de, this message translates to:
  /// **'Fehler melden'**
  String get aboutMailBug;

  /// Explains which diagnostic data the bug report mail contains
  ///
  /// In de, this message translates to:
  /// **'Enthält App-Version, Gerät und den letzten Fehler'**
  String get aboutMailBugHint;

  /// Opens a mail to the privacy mailbox
  ///
  /// In de, this message translates to:
  /// **'Datenschutzfrage stellen'**
  String get aboutMailPrivacy;

  /// Opens a mail to the confidential security mailbox
  ///
  /// In de, this message translates to:
  /// **'Sicherheitslücke melden'**
  String get aboutMailSecurity;

  /// App version line at the bottom of the about page
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// Shown when no app can handle the link or mail address
  ///
  /// In de, this message translates to:
  /// **'Konnte nicht geöffnet werden'**
  String get aboutOpenFailed;

  /// Shown when a link uses a scheme the app deliberately refuses to open. Only http and https are opened, and only on an explicit tap.
  ///
  /// In de, this message translates to:
  /// **'Dieser Link kann nicht geöffnet werden'**
  String get linkSchemeNotSupported;

  /// App bar action that opens the settings hub
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsOpen;

  /// Section heading above the help rows
  ///
  /// In de, this message translates to:
  /// **'Hilfe'**
  String get settingsSectionHelp;

  /// Section heading above the privacy row
  ///
  /// In de, this message translates to:
  /// **'Daten und Datenschutz'**
  String get settingsSectionDataPrivacy;

  /// Section heading above the entitlement row
  ///
  /// In de, this message translates to:
  /// **'Pro'**
  String get settingsSectionPro;

  /// Section heading above the about and error-report rows
  ///
  /// In de, this message translates to:
  /// **'Unterstützung'**
  String get settingsSectionSupport;

  /// Section heading above the debug-only rows. Never shown in a release build.
  ///
  /// In de, this message translates to:
  /// **'Entwicklung'**
  String get settingsSectionDevelopment;

  /// Opens the bundled manual
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get settingsManual;

  /// Opens the bundled FAQ
  ///
  /// In de, this message translates to:
  /// **'Häufige Fragen'**
  String get settingsFaq;

  /// Reopens the first-start intro at any time
  ///
  /// In de, this message translates to:
  /// **'App-Einleitung erneut anzeigen'**
  String get settingsShowIntro;

  /// Opens the in-app privacy page
  ///
  /// In de, this message translates to:
  /// **'Datenschutz und Daten'**
  String get settingsPrivacyEntry;

  /// Subtitle naming what the privacy page contains
  ///
  /// In de, this message translates to:
  /// **'Was gespeichert wird, und wie du es löschst'**
  String get settingsPrivacyEntryHint;

  /// Opens the entitlement page
  ///
  /// In de, this message translates to:
  /// **'Pro-Status'**
  String get settingsProEntry;

  /// Opens the existing about page with external links and support mailboxes
  ///
  /// In de, this message translates to:
  /// **'Über die App und Hilfe'**
  String get settingsAboutEntry;

  /// Only shown while an uncaught error is buffered
  ///
  /// In de, this message translates to:
  /// **'Letzten Fehler melden'**
  String get settingsReportError;

  /// States that the mail is prefilled with diagnostics
  ///
  /// In de, this message translates to:
  /// **'Öffnet eine Mail mit den technischen Angaben'**
  String get settingsReportErrorHint;

  /// Debug-only page listing the settings register
  ///
  /// In de, this message translates to:
  /// **'Einstellungen-Diagnose'**
  String get settingsDiagnostics;

  /// Makes clear the row does not exist in a release build
  ///
  /// In de, this message translates to:
  /// **'Nur in Debug-Builds sichtbar'**
  String get settingsDiagnosticsHint;

  /// Destructive action that clears every registered setting
  ///
  /// In de, this message translates to:
  /// **'Einstellungen zurücksetzen'**
  String get settingsResetSettings;

  /// States the exact scope: settings only, content survives
  ///
  /// In de, this message translates to:
  /// **'Sprache und Erscheinungsbild zurück auf Systemeinstellung. Inhalte bleiben erhalten.'**
  String get settingsResetSettingsHint;

  /// Title of the reset confirmation dialog
  ///
  /// In de, this message translates to:
  /// **'Einstellungen zurücksetzen?'**
  String get settingsResetSettingsConfirmTitle;

  /// Names the consequence instead of asking whether the user is sure
  ///
  /// In de, this message translates to:
  /// **'Alle Einstellungen kehren auf ihre Standardwerte zurück. Deine Inhalte bleiben erhalten.'**
  String get settingsResetSettingsConfirmBody;

  /// Confirmation shown after the settings were cleared
  ///
  /// In de, this message translates to:
  /// **'Einstellungen zurückgesetzt'**
  String get settingsResetSettingsDone;

  /// Confirming label of the reset dialog
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get commonReset;

  /// Title of the debug-only diagnostics page
  ///
  /// In de, this message translates to:
  /// **'Einstellungen-Diagnose'**
  String get diagnosticsTitle;

  /// Explains what the diagnostics list shows
  ///
  /// In de, this message translates to:
  /// **'Alle registrierten Einstellungen mit ihrem gespeicherten Rohwert. Nur lesend.'**
  String get diagnosticsIntro;

  /// Shown instead of a raw value when nothing was ever written
  ///
  /// In de, this message translates to:
  /// **'nicht gesetzt'**
  String get diagnosticsUnset;

  /// Title of the bundled manual page
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get helpManualTitle;

  /// Title of the bundled FAQ page
  ///
  /// In de, this message translates to:
  /// **'Häufige Fragen'**
  String get helpFaqTitle;

  /// Shown when a bundled help asset is missing or unreadable
  ///
  /// In de, this message translates to:
  /// **'Das Dokument konnte nicht geladen werden.'**
  String get helpLoadError;

  /// Title of the in-app privacy page
  ///
  /// In de, this message translates to:
  /// **'Datenschutz und Daten'**
  String get privacyTitle;

  /// Headline of the local-storage explanation
  ///
  /// In de, this message translates to:
  /// **'Deine Daten bleiben auf diesem Gerät'**
  String get privacyLocalTitle;

  /// The storage promise, stated in the app itself
  ///
  /// In de, this message translates to:
  /// **'Die App speichert ihre Inhalte in einer Datenbank auf diesem Gerät. Es gibt kein Konto, keinen Server und keine Übertragung im Hintergrund. Was du hier löschst, ist weg.'**
  String get privacyLocalBody;

  /// Section heading above the permission overview. Omitted when the app holds none.
  ///
  /// In de, this message translates to:
  /// **'Berechtigungen'**
  String get privacyPermissionsSection;

  /// Permission state
  ///
  /// In de, this message translates to:
  /// **'Erteilt'**
  String get privacyPermissionGranted;

  /// Permission state
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get privacyPermissionDenied;

  /// Permission state that can only be changed in the system settings
  ///
  /// In de, this message translates to:
  /// **'Dauerhaft abgelehnt'**
  String get privacyPermissionPermanentlyDenied;

  /// Permission state before the app has ever asked
  ///
  /// In de, this message translates to:
  /// **'Nicht angefragt'**
  String get privacyPermissionNotRequested;

  /// Section heading above the legal web links
  ///
  /// In de, this message translates to:
  /// **'Veröffentlichte Dokumente'**
  String get privacyDocumentsSection;

  /// Opens a mail to the privacy mailbox
  ///
  /// In de, this message translates to:
  /// **'Datenschutz-Anfrage senden'**
  String get privacyContact;

  /// Section heading above the destructive actions
  ///
  /// In de, this message translates to:
  /// **'Gefahrenbereich'**
  String get privacyDangerSection;

  /// Leaves the intro from any page
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get introSkip;

  /// Advances to the next intro page
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get introNext;

  /// Primary action on the last intro page
  ///
  /// In de, this message translates to:
  /// **'Los geht’s'**
  String get introStart;

  /// Title of the first intro page
  ///
  /// In de, this message translates to:
  /// **'Willkommen'**
  String get introWelcomeTitle;

  /// Body of the first intro page
  ///
  /// In de, this message translates to:
  /// **'Diese App ist aus dem LumbreCode Flutter-Template entstanden. Die nächsten Seiten zeigen kurz, was sie kann.'**
  String get introWelcomeBody;

  /// Title of the second intro page
  ///
  /// In de, this message translates to:
  /// **'Was die App kann'**
  String get introFeaturesTitle;

  /// Body of the second intro page
  ///
  /// In de, this message translates to:
  /// **'Inhalte anlegen, wiederfinden und bearbeiten — offline, ohne Konto, auf diesem Gerät.'**
  String get introFeaturesBody;

  /// Title of the third intro page
  ///
  /// In de, this message translates to:
  /// **'Deine Daten'**
  String get introPrivacyTitle;

  /// Body of the third intro page. The same promise the privacy page makes.
  ///
  /// In de, this message translates to:
  /// **'Alles bleibt lokal gespeichert. Nichts wird hochgeladen, und du kannst jederzeit alles wieder löschen.'**
  String get introPrivacyBody;

  /// Title of the fourth intro page, which carries the two settings
  ///
  /// In de, this message translates to:
  /// **'Sprache und Darstellung'**
  String get introSettingsTitle;

  /// Body of the fourth intro page
  ///
  /// In de, this message translates to:
  /// **'Beides lässt sich später jederzeit in den Einstellungen ändern.'**
  String get introSettingsBody;

  /// Title of the last intro page
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get introReadyTitle;

  /// Body of the last intro page
  ///
  /// In de, this message translates to:
  /// **'Anleitung, Datenschutz und alle Einstellungen findest du jederzeit über das Zahnrad.'**
  String get introReadyBody;

  /// Title of the entitlement page
  ///
  /// In de, this message translates to:
  /// **'Pro'**
  String get proTitle;

  /// Current entitlement, in words
  ///
  /// In de, this message translates to:
  /// **'Kostenlose Version'**
  String get proStatusFree;

  /// Current entitlement, in words
  ///
  /// In de, this message translates to:
  /// **'Pro-Version'**
  String get proStatusPro;

  /// States that nothing is gated. Keeps the row from reading as a paywall.
  ///
  /// In de, this message translates to:
  /// **'Alle Funktionen sind derzeit kostenlos.'**
  String get proAllFree;

  /// Store availability is still being fetched
  ///
  /// In de, this message translates to:
  /// **'Store wird geprüft ...'**
  String get proStoreChecking;

  /// Platform billing answered
  ///
  /// In de, this message translates to:
  /// **'Store verfügbar'**
  String get proStoreAvailable;

  /// No platform billing on this device or build
  ///
  /// In de, this message translates to:
  /// **'Store nicht verfügbar'**
  String get proStoreUnavailable;

  /// Asks the store for a previously bought entitlement
  ///
  /// In de, this message translates to:
  /// **'Käufe wiederherstellen'**
  String get proRestore;

  /// Restore succeeded but found nothing
  ///
  /// In de, this message translates to:
  /// **'Keine Käufe gefunden.'**
  String get proRestoreNone;

  /// Restore found and applied an entitlement
  ///
  /// In de, this message translates to:
  /// **'Pro wurde wiederhergestellt.'**
  String get proRestoreRestored;

  /// Restore failed or no store is available
  ///
  /// In de, this message translates to:
  /// **'Der Store ist derzeit nicht erreichbar.'**
  String get proRestoreFailed;

  /// Explains why there is no price and no buy button (ADR-0015)
  ///
  /// In de, this message translates to:
  /// **'Diese Seite zeigt den Berechtigungsstatus. Käufe sind in dieser Version noch nicht aktiviert.'**
  String get proNote;

  /// Default of a setting, shown under its stored value
  ///
  /// In de, this message translates to:
  /// **'Standard: {value}'**
  String diagnosticsDefault(String value);

  /// Accessible label of the menu bar
  ///
  /// In de, this message translates to:
  /// **'Anwendungsmenü'**
  String get menuLabel;

  /// Title of the File menu
  ///
  /// In de, this message translates to:
  /// **'Datei'**
  String get menuFile;

  /// Title of the menu that jumps between the screens
  ///
  /// In de, this message translates to:
  /// **'Gehe zu'**
  String get menuGoTo;

  /// Title of the Help menu
  ///
  /// In de, this message translates to:
  /// **'Hilfe'**
  String get menuHelp;

  /// Menu entry that quits the desktop application
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get menuQuit;

  /// Name of the development flavor
  ///
  /// In de, this message translates to:
  /// **'Entwicklung'**
  String get channelDev;

  /// Name of the snapshot flavor
  ///
  /// In de, this message translates to:
  /// **'Snapshot – zum Ausprobieren'**
  String get channelSnapshot;

  /// Name of the staging flavor
  ///
  /// In de, this message translates to:
  /// **'Staging'**
  String get channelStaging;

  /// Name of the pre-release flavor
  ///
  /// In de, this message translates to:
  /// **'Pre-Release – Testversion vor der Veröffentlichung'**
  String get channelPrerelease;

  /// Channel line at the bottom of the about page; shown for every build but the release
  ///
  /// In de, this message translates to:
  /// **'Kanal: {name}'**
  String aboutChannel(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
