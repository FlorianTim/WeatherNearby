# 08. Querschnittliche Konzepte

> Die verbindlichen Regeln je Querschnittsbereich stehen als
> [Architektur-Verträge](../contracts/README.md). Dieses Kapitel beschreibt,
> *wie* das System gebaut ist; die Verträge beschreiben, *woran man erkennt*,
> dass es richtig gebaut ist. Fallen, die schon einmal Zeit gekostet haben,
> stehen in [`docs/known-issues.md`](../../known-issues.md).

## Persistenz & Datenmodell

- Lokale Persistenz über Drift (SQLite); Migrationen sind additiv
  (`addColumnIfMissing`, siehe `lib/core/database/app_database.dart`).
- **Pflichtregel:** Dieses Kapitel führt ein ER-Diagramm des lokalen
  Datenmodells (`docs/architecture/diagrams/`). Bei **jedem Schema-Bump**
  (`schemaVersion` in `app_database.dart`) wird das ER-Diagramm im selben
  PR aktualisiert — ein Schema-Bump ohne Diagramm-Update gilt als
  unvollständig.
- Das ER-Diagramm des aktuellen Drift-Schemas ist als Mermaid-Spezifikation unter
  [`docs/architecture/diagrams/src/mermaid/data-model-er.mmd`](../diagrams/src/mermaid/data-model-er.mmd)
  definiert.
- Je Schema-Version existiert ein Roh-SQL-Fixture-Test
  (`test/core/database/migration_test.dart`), der verlustfreie Upgrades
  absichert.
- **Fremdschlüssel werden erzwungen:** `PRAGMA foreign_keys = ON` in
  `beforeOpen` — das ist *nicht* der SQLite-Default. Deklarierte Referenzen
  ohne dieses Pragma sind reine Dokumentation.
- **Downgrades sind undefiniert.** `onUpgrade` deckt nur `from < to` ab; eine
  ältere App auf einer neueren Datenbank bricht daher bewusst mit einer
  verständlichen Meldung ab, statt beliebig weiterzulaufen.

## Zeit- und Datumssemantik

Verbindlich, weil Fehler hier still sind und erst beim Nutzer auffallen.
Vollständige Regeln im [Database Contract](../contracts/02-database.md).

- **Kalendertag ≠ Zeitpunkt.** Ein reines Datum wird als
  Epoch-Day-`INTEGER` gespeichert (Tage seit 1970-01-01, in UTC gerechnet),
  nicht als Mitternachts-`DateTime`. So kann keine Zeitzonenumrechnung den
  Tag verschieben, und Sommerzeit ist wirkungslos.
- **Aus einem eingehenden `DateTime` werden bei Datumsbedeutung
  ausschließlich Jahr/Monat/Tag gelesen** — Uhrzeitanteil und UTC-Flag
  werden bewusst ignoriert.
- **Ganztägige Intervalle sind halboffen:** `[Datum, Datum + 1 Tag)`. Das
  Ende ist der erste *nicht* mehr enthaltene Moment. So definieren es sowohl
  iCalendar als auch der Android Calendar Provider. Ein inklusives Enddatum
  macht aus einem Ein-Tages-Termin einen Zwei-Tages-Termin.
- **Optionale Datumsteile sind `NULL`, nie ein Sentinel.** Ein Geburtstag
  ohne Jahr wird nicht in ein Ersatzjahr (1900, 1970, aktuelles Jahr)
  gezwungen — sonst entstehen falsche Alter, falsche Sortierungen und
  falsche „vor X Jahren"-Angaben. Die Abwesenheit ändert den *Satz*, nicht
  nur die Zahl: es braucht zwei Textbausteine, nicht einen mit Lücke.
- **Wanduhrzeit und Zeitpunkt sind verschiedene Dinge.** „18:00 lokal, wo ich
  gerade bin" (floating) und „18:00 in Europe/Berlin" (zoned) werden mit
  einem Modus neben dem Wert gespeichert.
- **Kalendarische Gültigkeit** (29. Februar nur in Schaltjahren, jahrlose
  Daten) wird über `DateValidation` in `packages/app_core` geprüft, nicht
  über handgeschriebene Monatslängen.
- **`DateTime` persistiert Drift sekundengenau** — siehe
  [KI-008](../../known-issues.md#ki-008). Zählt die Reihenfolge zweier
  Zeilen fachlich, braucht es einen monotonen Zähler statt des Zeitstempels.

## Konfiguration

- `dart-define` für Flavor und API-URL
- keine Secrets im Repository

## Qualität

- Analyse + Tests in CI
- ADRs bei Architekturänderungen

## Dokumentation

- arc42 für Architektur
- OpenAPI für Schnittstellen
- Runbooks für Betrieb
