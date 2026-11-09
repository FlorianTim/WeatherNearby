# Capability-Module

Fähigkeiten, die **nicht** jede App braucht, gehören nicht in die Baseline.
Jede Abhängigkeit, jeder Manifest-Eintrag und jede Store-Deklaration, die im
Template steht, muss von jeder abgeleiteten App entweder verstanden oder
gelöscht werden — und beides kostet.

## Die Regel

> Was ohne neue Abhängigkeit auskommt, ist Code im Template.
> Was eine Dependency, einen Manifest-Eintrag oder eine
> Store-Deklaration mitbringt, ist hier ein Rezept.

Beispiel für den Unterschied: die Berechtigungslogik — Zustandsmodell,
Ablauf, Rationale-Sheet, Fake — ist reines Flutter und liegt als Code unter
`lib/core/permissions/`. Das Plugin, das eine *konkrete* Berechtigung
abfragt, liegt nicht dort, denn es zieht Manifest-Einträge und
Store-Fragen nach sich.

Warum das nicht übervorsichtig ist: `device_calendar` hat in der
Referenz-App das Upgrade eines völlig unbeteiligten UI-Pakets blockiert
(siehe [KI-009](../../known-issues.md#ki-009)). Eine ungenutzte
Capability-Dependency in der Baseline hätte diesen Konflikt jeder App
vererbt, die nie einen Kalender angefasst hat.

## Aufbau eines Moduls

Jedes Capability-Modul liefert dieselben sieben Teile:

| Teil | Ort |
|---|---|
| Domänen-Interface (Gateway) und Wertetypen | `lib/core/<capability>/` oder `lib/features/<feature>/domain/` |
| Produktive Implementierung (die **einzige** Datei, die das Plugin importiert) | `.../data/` |
| Riverpod-Provider | `.../data/<capability>_providers.dart` |
| Fake mit Invarianten-Prüfung | `test/support/fake_<capability>_gateway.dart` |
| Tests: glücklicher Pfad **und** degradierter Pfad | `test/…` |
| Manifest-/Plattform-Hinweise | im Modul-README bzw. in `docs/operations/` |
| Absatz für die Datenschutzerklärung | im Modul-README |

Dazu, wenn die Abhängigkeit pre-1.0 oder plattformnah ist: ein
Kapselungstest (`expectPackageEncapsulated`, siehe
[Platform Gateways](platform-gateways.md)).

## Checkliste beim Hinzufügen

- [ ] [Library Evaluation Contract](../contracts/06-library-evaluation.md)
      durchgegangen, Entscheidung in einer ADR festgehalten
- [ ] Transitive Constraints gegen den bestehenden Baum geprüft — **vorher**
- [ ] Pre-1.0? Dann exakt gepinnt plus dokumentierte Upgrade-Bedingung
- [ ] Gateway-Interface enthält **keine** Operation, die die App nicht
      ausführen darf
- [ ] Fake wirft bei Verletzung der Sicherheitsregel
- [ ] Der degradierte Pfad ist getestet, nicht nur der glückliche
- [ ] Manifest-Einträge auf das tatsächlich Genutzte beschränkt
- [ ] Kapselungstest, falls anwendbar
- [ ] `docs/known-issues.md` ergänzt, sobald etwas Zeit gekostet hat

## Katalog

Stand und Kosten der Module, die aus der Referenz-App bekannt sind.

### Permissions — **im Template**

Code: `lib/core/permissions/`. Zustandsmodell mit vier Zuständen,
`ensurePermission(...)`-Ablauf, Rationale-Sheet, Fake, Tests. **Keine neue
Abhängigkeit.**
Offen bleibt die konkrete Implementierung je Berechtigung — Rezept:
[permissions.md](permissions.md).

### External Source + Sync — **Rezept**

Kosten: eine Tabelle im Schema (also ein `schemaVersion`-Bump) plus das
Plugin der jeweiligen Quelle.
Rezept: [external-source-sync.md](external-source-sync.md).

### Backup / Restore — **Rezept**

Kosten: ein File-Picker-Paket, ein Archivformat, und die Entscheidung über
Verschlüsselung.
Rezept: [backup-restore.md](backup-restore.md).

### Notifications — **Rezept, noch nicht ausgearbeitet**

Kosten: `flutter_local_notifications` + `timezone`, `POST_NOTIFICATIONS` ab
Android 13, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` ab Android 12 für exakte
Alarme, ein `BOOT_COMPLETED`-Receiver, damit geplante Meldungen einen Neustart
überleben.

Die Punkte, die aus der Referenz-App bereits feststehen:

- Der Scheduler gehört hinter ein `ReminderScheduler`-Gateway, nicht direkt
  ins Feature.
- Die Abstimmung muss **idempotent** sein: erneutes Planen darf keine
  Dubletten erzeugen.
- Es gilt dieselbe Ownership-Regel wie bei Plattform-Schreibzugriffen:
  **nur abbrechen, was man selbst geplant hat.**
- Die Nachricht enthält keine sensiblen Inhalte — der Text steht auf dem
  Sperrbildschirm.
- Doze, App-Standby-Buckets und OEM-Batteriemanager verschieben Arbeit
  unvorhersehbar. Was zu einem exakten Zeitpunkt passieren muss, braucht eine
  eigene Begründung.

### Kalender-UI — **nicht empfohlen**

Trägt den Pin aus [KI-009](../../known-issues.md#ki-009). Nur mit Adapter,
Grenztypen und Kapselungstest — und nur, wenn die App wirklich fünf
Ansichtsmodi braucht.

### Background Work — **nicht vorhanden**

Das Template führt keine Hintergrundarbeit aus. Kommt erst mit einem Feature,
dessen Nutzen entsteht, **während die App geschlossen ist**. Alles andere
gehört in Startup (kurz, lokal, für den ersten Screen nötig) oder Lazy
Loading.
