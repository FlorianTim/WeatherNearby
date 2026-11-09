# ADR 0009: Offline-First mit Drift/SQLite

## Status

Angenommen

## Kontext

Fachliche Daten (z.B. Aufgaben, Notizen) sollen lokal verfügbar sein, auch ohne
Netzwerkverbindung. Eine relationale, abfragbare Persistenzschicht erlaubt
komplexere Abfragen und garantiert Datenkonsistenz.

## Entscheidung

Drift (ehemals Moor) wird als lokale Persistenzschicht mit SQLite eingesetzt.

- Drift-Tabellen definieren das Schema typsicher in Dart
- DAOs kapseln Datenbankzugriffe
- Repositories abstrahieren die Datenschicht nach oben (Domain-Schicht kennt kein Drift)
- Mapper konvertieren zwischen Drift-Rows und Domain-Modellen
- In Tests wird `NativeDatabase.memory()` für Isolation genutzt

## Konsequenzen

### Positiv

- Typsichere Queries mit Compile-Zeit-Prüfung
- Reaktive Streams für UI-Updates bei Datenänderungen
- Schema-Migrationen als Teil des Codes
- Cross-Platform (Mobile, Desktop, Web via drift_worker)

### Negativ

- Code-Generierung erforderlich
- SQLite-Binaries müssen pro Plattform mitgeliefert werden
- Komplexer als einfache Key-Value-Speicher für triviale Daten
