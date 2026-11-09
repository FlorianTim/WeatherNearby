# External Source & Sync

Wie eine App Daten aus einer fremden Quelle liest (Kontakte, Kalender,
Dateien, Sensoren, später APIs) und wie sie in ein System schreibt, das sie
sich mit dem Nutzer teilt.

Regeln: [External Data Ownership Contract](../contracts/05-external-data-ownership.md).
Dies ist das Rezept dazu — als Capability-Modul, nicht als Baseline
(siehe [Capability-Module](capability-modules.md)).

Herkunft: destilliert aus der Kontakt- und Kalenderintegration der ersten
App auf diesem Template. Die Fehler, gegen die die Regeln schützen, sind dort
alle real aufgetreten.

---

## Teil 1 — Lesen

### Die Kette

```
Externe Quelle
      ↓   Gateway — nur lesende Operationen
DTO mit Fingerprint
      ↓   Link-Zeile
Stabile lokale Identität     ← app-generierte ID, NIE die externe
      ↓
App-eigene Erweiterungen     ← Notizen, Flags, Verknüpfungen
```

### Die Link-Tabelle

Die eine Entscheidung, aus der alles andere folgt: **die externe ID ist kein
Primärschlüssel.**

```dart
class ExternalLinks extends Table {
  TextColumn get id => text()();
  TextColumn get entityId =>
      text().references(Entities, #id, onDelete: KeyAction.cascade)();

  /// Welche Quelle — z. B. 'device_contacts'.
  TextColumn get provider => text()();

  /// Die ID der Quelle. UNIQUE(provider, external_id) als Index.
  TextColumn get externalId => text()();

  /// Hinweis der Quelle zum Wiederfinden nach einem Restore.
  TextColumn get lookupKey => text().nullable()();

  /// Hash der importierten Felder — billige Delta-Erkennung.
  TextColumn get sourceFingerprint => text()();

  /// Beim letzten Lauf nicht gefunden. NIEMALS automatisch löschen.
  BoolColumn get sourceMissing => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Was diese Trennung kauft:

- Ein Eintrag überlebt das Verschwinden seiner Quelle, ohne die Identität zu
  verlieren.
- Ein Eintrag kann später an mehrere Quellen gekoppelt werden, ohne
  Schema-Umbau.
- Der Nutzer kann lokal etwas anhängen, das kein Import je überschreibt.

### Der Fingerprint gehört in die Domäne

```dart
String get fingerprint =>
    '$displayName|${birthday?.year}-${birthday?.month}|${emails.join(',')}';
```

Nicht in die Datenschicht: Was eine „Änderung an der Quelle" ist, ist eine
fachliche Aussage. Nur die Felder aufnehmen, die tatsächlich importiert
werden — sonst löst jede irrelevante Änderung einen Schreibvorgang aus.

### Die vier Abgleichregeln

```dart
await db.transaction(() async {
  for (final external in await gateway.load()) {
    final link = byExternalId[external.externalId];

    if (link == null) {
      await _create(external);                      // 1. neu
    } else if (link.sourceFingerprint != external.fingerprint ||
               link.sourceMissing) {
      await _updateImportedFields(link, external);  // 2. geändert
    } else {
      await _touch(link);                           // 3. unverändert
    }
  }

  for (final link in links) {
    if (!seen.contains(link.externalId) && !link.sourceMissing) {
      await _markMissing(link);                     // 4. verschwunden
    }                                               //    NIE löschen
  }
});
```

Dazu eine fünfte Regel, die als **Spalte** existiert, nicht als Heuristik:

```dart
/// Der Nutzer hat den Namen lokal geändert; der Import überschreibt ihn nicht.
BoolColumn get manualNameOverride => boolean().withDefault(const Constant(false))();
```

Ein Flag pro überschreibbarem Feld. „Der lokale Wert sieht gepflegter aus"
ist keine Regel, die man testen kann.

### Das Gateway kann Unsicheres nicht ausdrücken

```dart
/// Read-only access to the device address book.
///
/// Deliberately exposes NO write operation.
abstract interface class ContactGateway {
  Future<List<ExternalContact>> load();
}
```

Ergänzt durch das Manifest, das kein Schreibrecht anfordert. Zusammen ist das
eine prüfbare Zusicherung statt einer Absichtserklärung.

---

## Teil 2 — Schreiben

```
Write only what you own.
Track what you created.
Never mutate unidentified foreign data.
```

### Ownership-Zuordnung

```dart
class OwnedItems extends Table {
  /// Der logische Schlüssel der App — was geschrieben werden SOLL.
  TextColumn get logicalKey => text()();

  /// Wohin geschrieben wurde.
  TextColumn get containerId => text()();

  /// Was der Provider zurückgegeben hat.
  TextColumn get providerItemId => text().nullable()();

  /// Änderungserkennung.
  TextColumn get contentHash => text()();

  /// 'active' | 'user_removed'
  TextColumn get status => text()();
  DateTimeColumn get lastWrittenAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {logicalKey};
}
```

### Plus ein Marker im Inhalt

Die Zuordnung kann verloren gehen — Neuinstallation, Restore, gelöschte
Datenbank. Ein versionierter Marker im geschriebenen Inhalt macht eigene
Einträge trotzdem wiedererkennbar:

```dart
static String marker(String key) => '[APP2:$key]';
static const markerPrefix = '[APP2:';
```

Versioniert, weil ein Modellwechsel alte Marker hinterlässt, die eine
einmalige Bereinigung finden können muss.

### Den Container verifizieren, nicht nur finden

```dart
if (calendar.name == name && calendar.accountName == localAccountName) {
  return calendar.id;
}
```

Nur der Name reicht nicht: ein gleichnamiger Kalender des Nutzers wäre sonst
plötzlich „der eigene".

### Zurücklesen und selbst heilen

```dart
final malformed = stored[mapping.itemId]?.divergesFrom(expected) ?? false;
if (mapping.contentHash == event.contentHash && !malformed) {
  unchanged++;
  continue;
}
```

Prüfen, was der Provider **tatsächlich** gespeichert hat, und eigene Einträge
reparieren, auch wenn der Content-Hash stimmt. Mit der Gegenregel:
**unbekannte Werte gelten nie als Abweichung** — sonst entsteht eine
Schreibschleife.

### Nutzerlöschungen sind endgültig

Fehlt ein zugeordneter Eintrag beim Provider, wird die Zuordnung auf
`user_removed` gesetzt und **nie** automatisch neu erzeugt. Zurück kommt er
nur durch eine ausdrückliche Regenerierung.

### Löschen nur bei positiver Identifikation

```dart
if (mappedIds.contains(item.id) ||
    item.content.contains(markerPrefix) ||
    item.content.contains(legacyMarkerPrefix)) {
  await gateway.delete(containerId, item.id);
}
// Alles andere bleibt unangetastet.
```

---

## Teil 3 — Der Sync-Lauf

```
Read source → Normalize → Compare → Plan → Execute → Persist → Report
```

### Ein Koordinator für alle Auslöser

Manueller Sync, App-Start, Import, Einrichtungsassistent, Regenerierung —
**alle** durch dieselbe Funktion. Sonst driften die Pfade auseinander und nur
einer von ihnen ist getestet.

```dart
class SyncCoordinator {
  Future<SyncReport> run({required SyncTrigger trigger}) async {
    final startedAt = clock.now();
    final report = await _pipeline.run();
    await _reports.record(trigger: trigger, report: report, startedAt: startedAt);
    return report;
  }

  /// Beantwortet „würde jetzt überhaupt etwas passieren?" — **ohne** einen
  /// Berechtigungsdialog auszulösen, den der Nutzer nicht angefordert hat.
  Future<bool> canRun();
}
```

### Fehler pro Element isolieren

Ein fehlgeschlagenes Element bricht den Lauf nicht ab. `partial` ist ein
eigenständiges Ergebnis — es in `failed` zu falten verbirgt, dass der Rest
funktioniert hat.

### Gründe sind Enums, nie Ausnahmetexte

```dart
enum SyncReason {
  disabled('disabled'),
  permissionMissing('permissionMissing'),
  userRemoved('userRemoved'),
  writeFailed('writeFailed');

  const SyncReason(this.storedValue);
  final String storedValue;
}
```

Stabil gespeichert, erst bei der Anzeige lokalisiert. Nie eine
Exception-Nachricht, nie ein Stacktrace in der normalen Oberfläche.

### Übersprungene Läufe protokollieren

Wenn nichts passiert ist, muss der Nutzer sehen **warum**. Ein leeres
Protokoll beantwortet die Frage nicht, die er stellt.

### Das Protokoll dupliziert keine Personendaten

Pro Eintrag nur der technische Schlüssel, das aufgelöste Datum und der
Ausgang. Titel und Namen werden beim Anzeigen aus den Livedaten gerendert.
In der Referenz-App prüft ein Test, dass es gar keine Spalte gibt, die einen
Namen aufnehmen könnte.

### Die Rechnung anzeigen, nicht nur die Summe

Wenn ein Lauf n Quellen × m Perioden erzeugt, wird der Faktor gespeichert und
angezeigt: „4 Termine × 4 Jahre = 16 erwartete Einträge". Ohne die Rechnung
liest sich ein korrektes Ergebnis wie ein Duplikatsfehler — genau das ist
passiert.

### Aufbewahrung begrenzen

Neueste N Läufe, maximal X Tage, jederzeit löschbar, ohne echte Daten zu
berühren.

---

## Testaufbau

Der Fake erzwingt die Regeln:

```dart
class FakeTargetGateway implements TargetGateway {
  final appCreatedIds = <String>{};

  /// Ein Eintrag, den der NUTZER dort angelegt hat. Muss jeden Lauf
  /// überleben — ohne Ausnahme.
  String addForeignItem(String containerId) { ... }

  @override
  Future<void> delete(String containerId, String itemId) async {
    if (!appCreatedIds.contains(itemId)) {
      throw StateError('SAFETY VIOLATION: delete of foreign item $itemId');
    }
    ...
  }
}
```

Mindestens abzudecken: Idempotenz (zweiter Lauf schreibt nichts), Änderung,
Löschung, verschwundene Quelle, vom Nutzer gelöschter Eintrag,
Teilfehlschlag, fremder Eintrag bleibt unberührt.

Dazu **ein** Test auf einem echten Gerät gegen den echten Provider — er prüft
den Plattformvertrag, den kein Fake kennt.
