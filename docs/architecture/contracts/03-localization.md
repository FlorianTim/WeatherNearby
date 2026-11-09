# Localization Contract

## Regeln

1. **Alle sichtbaren Texte kommen aus l10n.** Keine hartkodierten Strings in
   Widgets. Ausnahme mit Begründung: technische Kennungen, die absichtlich
   nicht übersetzt werden (z. B. Mail-Betreffe, nach denen ein gemeinsames
   Postfach filtert).
2. **ARB ist die Quelle**, eine Datei ist das Template
   (`template-arb-file`), die übrigen sind Übersetzungen. Ein in der
   Template-Sprache fehlender Schlüssel ist ein Build-Fehler, kein stiller
   Leerstring.
3. **Die Systemsprache ist der Default.** `MaterialApp.locale` bleibt `null`,
   solange der Nutzer nichts gewählt hat — nur dann greift Flutters eigene
   Auflösung gegen `supportedLocales`.
4. **Eine explizite Nutzerwahl ist optional** und wird aus
   `AppLocalizations.supportedLocales` erzeugt, nie aus einer handgepflegten
   Liste.
5. **Die Wahl wird persistiert** und beim Start wiederhergestellt;
   „Systemsprache" ist ein eigener, wählbarer Zustand.
6. **Datum, Zeit und Zahlen werden lokalisiert** — über `intl` mit dem
   aktiven Locale-Tag, nie mit einem festen Muster. Das Stundenformat folgt
   `MediaQuery.alwaysUse24HourFormatOf`.
7. **Barrierefreiheitstexte sind lokalisiert.** Semantics-Labels und
   Tooltips sind ARB-Nachrichten. Zusammengesetzte Beschreibungen entstehen
   in einem Mapper, nicht im Widget.
8. **Plugin-UI wird auf fehlende Lokalisierung geprüft.** System-Dialoge
   gehören dem Betriebssystem und werden nicht nachgebaut; UI-Pakete mit
   eigenen Beschriftungen brauchen eine Prüfung oder einen eigenen Header.
9. **Generierte Dateien werden nie von Hand geändert**, aber committet und
   in CI regeneriert (`melos run codegen` erzeugt auch `gen-l10n`; der
   Codegen-Drift-Check schlägt sonst fehl).
10. **Mindestens zwei Locale-Tests je zentralem Screen**, dazu ein Test für
    den Sprachwechsel zur Laufzeit.

## Checkliste: dritte Sprache hinzufügen

1. `lib/core/l10n/arb/app_<code>.arb` anlegen, `"@@locale": "<code>"`, alle
   Schlüssel der Template-ARB übernehmen und nur die Werte übersetzen
   (`@`-Metadaten bleiben in der Template-Datei).
2. `melos run codegen` ausführen, generierte Dateien committen.
3. Prüfen, dass `AppLocalizations.supportedLocales` die Sprache enthält —
   die Sprachauswahl wird daraus gespeist und braucht keine Codeänderung.
4. Datums-, Zahlen- und Wochentagsformate stichprobenhaft prüfen
   (erster Wochentag, Monatsnamen).
5. Sprachvariante der Splash-Assets ergänzen **oder** das Asset
   sprachneutral halten.
6. Sprachvariante gebündelter Hilfedokumente ergänzen und die Liste der
   unterstützten Sprachen des Hilfe-Loaders erweitern — sonst fällt die
   Seite still auf die Fallback-Sprache zurück.
7. Textüberlauf bei den längsten Strings prüfen.
8. Je einen Widget-Test der zentralen Screens in der neuen Sprache.
9. Store-Texte unter `design/store/texts/<locale>/` ergänzen.

> Schritte 5 und 6 werden am häufigsten vergessen, weil die Sprachwahl dort
> im Code verzweigt statt in einer Tabelle nachzuschlagen.

## Stand im Template

| Regel | Stand |
|---|---|
| 1, 2 | ✅ `app_de.arb` ist Template, `nullable-getter: false` |
| 3 | ✅ `LocaleNotifier` liefert `null` für „Systemsprache" |
| 4 | ✅ `SettingsPage` iteriert `supportedLocales` |
| 5 | ✅ Definition in `lib/core/settings/app_settings.dart`, Tests `test/app/locale_persistence_test.dart` und `test/core/settings/app_settings_test.dart` |
| 6 | 🟡 `intl` vorhanden; das Template zeigt noch kein Formatierungsbeispiel |
| 7 | 🟡 Tooltips ja, Semantics-Mapper noch nicht vorgelegt |
| 8 | ✅ keine UI-Pakete mit eigenen Texten im Template |
| 9 | ✅ `melos run codegen` inkl. `gen-l10n`, CI-Drift-Check |
| 10 | 🟡 Sprachwechsel getestet; Locale-Tests je Screen fehlen |
