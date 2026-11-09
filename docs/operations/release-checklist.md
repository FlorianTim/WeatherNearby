# Release Checklist

## Vor dem Build

- Versionsnummer erhöht
- Release Notes aktualisiert
- relevante Tests grün
- kritische Bugs bewertet

## App-Shell (ab Template 3.2.1)

Die Shell ist das, was ein Store-Review als Erstes anfasst. Bei einer aus dem
Template abgeleiteten App vor **jeder** Einreichung prüfen:

- **In-App-Weg zum Datenlöschen erreichbar** — Einstellungen → Datenschutz
  und Daten → App-Daten löschen. Google Play verlangt einen Löschweg
  *innerhalb* der App; er liegt in `lib/features/privacy/`
- **Veröffentlichte Rechtsdokumente erreichbar und online**:
  `https://lumbrecode.de/apps/<web-slug>/privacy` und `.../data-deletion` —
  beide werden aus `AppIdentity.webSlug` abgeleitet und von der
  Datenschutz-Seite verlinkt. Vor der Einreichung veröffentlichen
- **Datenschutz-Text stimmt mit der Realität überein** — `privacyLocalBody`
  behauptet „alles lokal, nichts wird hochgeladen". Sobald die App
  synchronisiert, ein Konto hat oder Telemetrie sendet, ist der Text falsch
  und muss vor der Einreichung angepasst werden
- **Anleitung und häufige Fragen beschreiben die echte App** —
  `assets/help/*.md` darf keine Template-Prosa mehr enthalten
- **App-Einleitung fragt keine Berechtigung an** — Berechtigungen holt die
  Funktion, die sie braucht, wenn sie sie braucht
- **Pro-Seite zeigt keinen Preis und keinen Kauf-Button**, solange kein
  funktionierender Billing-Adapter eingebaut ist (ADR-0015). Eine
  Kaufoberfläche ohne funktionierenden Kauf ist ein Ablehnungsgrund
- **Diagnose-Eintrag fehlt im Release-Build** — `Einstellungen → Entwicklung`
  darf im AAB nicht auftauchen (`kReleaseMode`, Route ist nicht registriert)
- **Lizenzseite offline erreichbar** — Über die App → Open-Source-Lizenzen
- Die Shell-Tests laufen mit:
  `flutter test test/features/{settings,onboarding,help,privacy,monetization} test/a11y`

## Android

- AAB gebaut
- Signing-Konfiguration geprüft
- Play Console Metadaten vorbereitet
- Data-Safety-Formular ausgefüllt und deckungsgleich mit der
  Datenschutz-Seite in der App

## iOS

- Bundle ID / Signing geprüft
- Zertifikat und Profil in CI-Secrets vorhanden
- Build in App Store Connect Strategie eingeordnet

## Nach dem Release

- Smoke-Test
- Monitoring prüfen
- Support-/Kommunikationskanäle informieren
