# Database Contract

Gilt für jede App, die das Datenbank-Modul verwendet.

> **Leitsatz:** Eine App-Version darf bestehende Nutzerdaten nicht
> stillschweigend verlieren.

## Regeln

1. **Das Schema ist versioniert.** Genau eine `schemaVersion`, erhöht bei
   jeder ausgelieferten Schemaänderung.
2. **Migrationen sind explizit und additiv.** `createTable`, `addColumn` mit
   Default, `createIndex`. Alles Destruktive braucht eine ADR.
   Migrationsschritte sind idempotent (`addColumnIfMissing`), damit ein
   halb angewendetes Upgrade beim erneuten Lauf nicht abstürzt.
   ⚠️ Bei `TableMigration`-Rebuilds müssen **alle später ergänzten Spalten**
   in `newColumns` stehen, sonst bricht das Upgrade einer alten Datenbank.
3. **Migrationstests existieren.** Pro Schema-Version ein Roh-SQL-Fixture
   der Vorgängerversion plus ein Test, der öffnet, migriert und beweist,
   dass die alten Zeilen überlebt haben.
4. **IDs sind stabil und app-generiert.** Nie von einem Fremdsystem
   abgeleitet, nie wiederverwendet, ab Anlage extern referenzierbar
   (Deep-Links, Export).
5. **Fremdschlüssel-Semantik ist dokumentiert und erzwungen.**
   `PRAGMA foreign_keys = ON` in `beforeOpen` — **nicht** der SQLite-Default.
   CASCADE für rein abhängige Zeilen, RESTRICT für Kanten, deren Löschung
   eine fachliche Entscheidung ist.
6. **Zeit- und Datumssemantik ist explizit.**
   - Kalendertage als Epoch-Day-INTEGER, nicht als Mitternachts-`DateTime`.
   - Ganztägige Intervalle sind **halboffen**: das Ende ist der erste nicht
     mehr enthaltene Moment.
   - Aus einem eingehenden `DateTime` werden bei Datumsbedeutung
     **ausschließlich** Jahr/Monat/Tag gelesen.
   - Optionale Datumsteile sind `NULL`, niemals ein Sentinel wie `0` oder
     `1900`.
   - Wanduhrzeit und Zeitpunkt sind verschiedene Dinge; der Modus wird neben
     dem Wert gespeichert.
   - `DateTime` wird sekundengenau persistiert — siehe
     [KI-008](../../known-issues.md#ki-008). Wenn die Reihenfolge zweier
     Zeilen fachlich zählt, braucht es einen monotonen Zähler.
7. **Externe IDs sind nie lokale Primärschlüssel.** Sie leben in einer
   Link-Tabelle mit `UNIQUE(provider, external_id)` — siehe
   [Externe Datenhoheit](05-external-data-ownership.md).
8. **Nutzerdaten werden bei App-Upgrades nicht stillschweigend gelöscht.**
   Ein *Downgrade* (`from > to`) ist in Drift undefiniert und muss mit einer
   verständlichen Meldung abbrechen statt beliebig weiterzulaufen.
9. **Backup-/Exportformate haben eine eigene Version.** `formatVersion`
   unabhängig von `schemaVersion`; Import akzeptiert nur gleich oder älter
   und meldet „neuer als die App" als verständlichen Fehler.
10. **Datenmigration und App-Versionierung sind getrennte Konzepte.** Sechs
    Versionsbegriffe existieren nebeneinander und dürfen nicht vermischt
    werden: Repo-`VERSION`, `pubspec`-Version, Android-`versionCode`,
    Release-Tag, `schemaVersion`, `formatVersion`.
11. **Die Verbindung ist auf jedem Zielplattform-Target konfiguriert.**
    Im Browser gibt es kein Dateisystem: Drift braucht dort `sqlite3.wasm`
    und `drift_worker.js` neben der `index.html` sowie ein
    `DriftWebOptions`-Argument. Fehlt eines davon, scheitert erst zur
    Laufzeit der blockierende Startup-Task `database` — und der Retry auf
    dem Recovery-Screen kann daran nichts ändern. Beide Dateien sind
    Build-Artefakte und werden mit
    `dart run tool/sync_web_database_assets.dart` erzeugt (siehe
    [Web-App bauen](../../operations/build-web.md)).

## Regel 3 konkret: das Fixture pro Version

Regel 3 verlangt pro Schema-Version ein Fixture. So sieht ein Schritt aus —
hier v1 → v2:

```dart
// 1. Roh-SQL-Schnappschuss der ALTEN Version, mit Nutzdaten.
const schemaV1 = '''
CREATE TABLE "todo_items" ( "id" TEXT NOT NULL, ... PRIMARY KEY ("id") );
''';

final raw = sqlite3.openInMemory()
  ..execute(schemaV1)
  ..execute("INSERT INTO todo_items (id, title, created_at) VALUES (...)")
  ..execute('PRAGMA user_version = 1');

// 2. Die aktuelle Datenbank darauf öffnen — das führt die Migration aus.
// 3. Beweisen: alte Zeilen unverändert, neue Struktur da, user_version neu.
```

Der Punkt, der leicht übersehen wird: **das Fixture ist Roh-SQL, nicht
Drift-Code.** Ein mit den *heutigen* Tabellenklassen erzeugtes Fixture
beschreibt das heutige Schema — es beweist über das alte nichts. Beispiel im
Repo: `test/core/database/migration_test.dart`.

Die vollständige Migrationsmatrix einer datenlastigen App steht in
`docs/product/specs/0001-task-and-list-domain/data-contract.md`.

### ⚠️ `@ReferenceName` — greift noch nicht, wird aber greifen

Zwei Fremdschlüssel **derselben** Tabelle auf **dasselbe** Ziel lösen eine
Codegen-Warnung aus, und die generierten Filter/Orderings fehlen danach
stillschweigend — **der Build läuft trotzdem durch** ([KI-004](../../known-issues.md#ki-004)).

Heute tritt der Fall nicht auf: `tasks.list_id` und `tasks.parent_task_id`
zeigen auf verschiedene Tabellen. Er tritt in dem Moment auf, in dem eine
zweite Kante auf dieselbe Tabelle dazukommt — dann brauchen **beide**
Spalten `@ReferenceName('…')`.

## Empfohlene Migrations-Testmatrix

| Fall | Erwartete Zusicherung |
|---|---|
| Neuinstallation (`onCreate`) | alle Tabellen, Indizes, Seeds, Constraints |
| N-1 → N | alte Zeilen unversehrt, neue Struktur vorhanden |
| N-2 → N (verkettet) | kein Datenverlust über zwei Stufen |
| Teilmigrierte DB (Absturz mitten im Upgrade) | erneutes Öffnen läuft durch oder scheitert sauber |
| Fehlende optionale Spalte | nullable-Read liefert `null`, kein Absturz |
| Ungültiger/korrupter Zustand | definierter Recovery-Pfad, kein stiller Wipe |
| FK-verletzende Altzeilen | Migration scheitert laut, statt Zeilen zu löschen |

## Stand im Template

| Regel | Stand |
|---|---|
| 1, 2 | ✅ `lib/core/database/app_database.dart` — inkl. `addColumnIfMissing` und `TableMigration`-Warnung |
| 3 | ✅ `test/core/database/migration_test.dart` |
| 4 | ✅ `lib/core/utils/id_generator.dart` |
| 5 | ✅ `beforeOpen` mit `PRAGMA foreign_keys = ON` |
| 6 | 🟡 `EpochDay`, `MinuteOfDay` und ihre Drift-Converter liegen in `lib/core/domain/time/` — Epoch-Day-Speicherung, Wanduhrzeit getrennt vom Zeitpunkt, `NULL` statt Sentinel. **Offen bleibt `AllDayInterval`** (halboffene Ganztagsintervalle): keine 3.1.0-Anforderung erzwingt es, und ein spekulativer Helfer ist genau der Weg, auf dem `core/` ungenutzte Oberfläche ansammelt. |
| 7 | ⬜ Capability-Modul |
| 8 | ✅ Downgrade bricht mit Meldung ab |
| 9, 10 | 🟡 dokumentiert; Backup-Modul existiert noch nicht |
| 11 | ✅ `DriftWebOptions` in `app_database.dart`, Assets via `tool/sync_web_database_assets.dart` |
