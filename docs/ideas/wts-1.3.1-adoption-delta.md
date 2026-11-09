# Delta: WasThereSomething 1.3.1 → flutter_app_template 2.0.0

> **Was das ist.** Ein Abgleich zwischen der Referenzanalyse der App
> *WasThereSomething* (Stand `release/1.3.1`) und dem **tatsächlichen**
> Zustand dieses Templates auf `main` (`3382a50`, VERSION `2.0.0`).
>
> **Warum es existiert.** Die Referenzanalyse
> (`WasThereSomething/docs/template/flutter-app-reference-architecture.md`,
> 47 als wiederverwendbar identifizierte Konzepte) wurde ausschließlich
> gegen die App geschrieben. Sie weiß nicht, dass dieses Template seit der
> Ableitung der App eigenständig weiterentwickelt wurde und einen großen
> Teil davon bereits enthält. Eine ungeprüfte Übernahme würde Vorhandenes
> doppeln oder Besseres überschreiben.
>
> **Status:** Analyse und Umsetzungsplan. **Welle 1 bis 4 plus die
> Nacharbeiten sind auf `feat/adopt-wts-1.3.1-learnings` umgesetzt** — siehe
> Abschnitt 0. Offen bleibt bewusst nur noch die Versionsdrift (§ 5), die auf
> KI-001 wartet.
>
> **Vorgänger:** `docs/ideas/flutter_template_change.md` (403 Zeilen, aus
> der 1.3-Ära, 2026-07-15). Dessen Stand ist in Abschnitt 2 abgeglichen.
>
> **Ablage:** neben dem Vorgänger in `docs/ideas/`. Wenn das Dokument
> normativ werden soll, gehört es nach
> `docs/delivery/implementation-plans/`.

---

## 0. Umsetzungsstand

Branch `feat/adopt-wts-1.3.1-learnings` (von `main` `3382a50`).
Quality Gate grün: `melos run analyze` ohne Befund, **119 Flutter-Tests** und
**34 Dart-Tests** bestanden, `format:check` sauber, Codegen idempotent.
(Ausgangsstand auf `main`: 60 Flutter-Tests.)

### ✅ Welle 1 — Dokumentation und Regeln

- `docs/known-issues.md` — KI-001 … KI-009, an das Template angepasst
  (KI-009/010 der App zu **einer** generischen Regel über Pre-1.0-Pakete und
  transitive Constraint-Konflikte zusammengefasst).
- `docs/architecture/contracts/` — README plus sieben Verträge: Startup,
  Datenbank, Lokalisierung, Berechtigungen, Externe Datenhoheit,
  Bibliotheksauswahl, Barrierefreiheit. Jeder mit einer Tabelle „Stand im
  Template", damit nicht Erfülltes nicht wie Erfülltes aussieht.
- `docs/architecture/arc42/08-crosscutting-concepts.md` — neuer Abschnitt
  **Zeit- und Datumssemantik** plus FK-Enforcement und Downgrade-Hinweis.
- `AGENTS.md` — `known-issues.md` und die Verträge als Pflichtlektüre in der
  Orientierung und als normative Quellen eingetragen.

### ✅ Welle 2 — Kleine Codeänderungen

| Änderung | Datei |
|---|---|
| Systemsprache als Default (`Locale?`, `null` = System) | `lib/app/providers/locale_provider.dart` |
| `themeMode` als persistierte Einstellung | `lib/app/providers/theme_mode_provider.dart` (neu) |
| Sprache **und** Theme auf der Settings-Seite, je mit „Systemeinstellung" | `lib/features/settings/presentation/settings_page.dart` |
| `MaterialApp.title` aus `AppIdentity.displayName` | `lib/app/{app,app_identity}.dart` |
| `PRAGMA foreign_keys = ON` in `beforeOpen` | `lib/core/database/app_database.dart` |
| Downgrade-Schutz (`versionBefore > versionNow` bricht mit Meldung ab) | dito |
| `generateId()` — 128-bit-Hex, ohne UUID-Abhängigkeit | `lib/core/utils/id_generator.dart` (neu) |
| `Clock`/`SystemClock` als Zeit-Seam | `lib/core/utils/clock.dart` (neu) |
| Offline-Lizenzseite über `showLicensePage` (Webseite bleibt als Ergänzung) | `lib/features/about/presentation/about_page.dart` |
| `Entitlement` + `FeatureGates` (fail-open) | `packages/feature_flags/lib/feature_flags.dart` |
| CI analysiert **alle** Pakete und fährt `test:dart` | `.github/workflows/ci-mobile.yml` |

Test-Infrastruktur dazu:

- `TestAppHarness` seedet jetzt Sprache **und** Uhr, damit kein Test von der
  Systemsprache oder der Wanduhrzeit der CI-Maschine abhängt
  (`localeCode: null` testet den Systemsprachen-Pfad bewusst).
- `test/support/fixed_clock.dart` — `FixedClock` und `MutableClock`.
- `test/support/package_encapsulation.dart` — `expectPackageEncapsulated(...)`,
  der Guardrail-Test aus KI-009 als wiederverwendbarer Helper.
- Neue Tests: Theme-Persistenz, ID-Generator, FK-Enforcement,
  Offline-Lizenzseite; Locale-Tests auf die neue Semantik umgestellt.

### ✅ Welle 3 — Muster und Gerüste

| Baustein | Dateien |
|---|---|
| **`SettingDef`-Register** — Key, Default, Encode/Decode je Setting an einer Stelle; `AppSettings.all` macht die Menge aufzählbar. Locale und ThemeMode sind darauf migriert. | `lib/core/settings/{setting_def,app_settings}.dart` |
| **`StartupCoordinator`** — Phasen `blocking` (sequenziell, Fehler ist fatal), `guarded` (parallel, degradiert), `fireAndForget`. Die Splash-Warmup-Registry ist darin aufgegangen und wurde entfernt. | `lib/core/startup/` |
| **Recovery-Screen** für fatale Startfehler, mit Wiederholen und Fehlerbericht — ohne Exception-Text und ohne Stacktrace auf dem Bildschirm. | `lib/features/splash/presentation/startup_error_page.dart`, Route `/startup-error` |
| **`wipeAllData()`** — transaktional, Kinder vor Eltern, plus Eintrag auf der Settings-Seite mit Bestätigungsdialog. **Nur die Datenbank**; der Untertitel benennt, dass Sprache und Erscheinungsbild bleiben. | `lib/core/database/app_database.dart`, `settings_page.dart` |
| **Kapselungstest scharf geschaltet** auf `lottie` als Musterbeispiel. | `test/features/splash/lottie_encapsulation_test.dart` |
| **Gateway-Muster dokumentiert** — drei Stufen (Typedef-Seam, Gateway-Interface, Adapter mit Grenztypen), safety-assertende Fakes, Guardrail-Test, und wann man *nicht* kapselt. | `docs/architecture/patterns/platform-gateways.md` |
| **Die neuen Seams im Einsatz** statt nur vorhanden: `generateId()` und `clockProvider` ersetzen `DateTime.now()` im Todo-Notifier und auf der Greeting-Seite. | `todo_list_notifier.dart`, `greeting_page.dart` |

Nicht nötig war der geplante Punkt „Enum-mit-`dbValue`-Muster zeigen": das
Template speichert `TodoStatus` bereits über `.name` mit sicherem Fallback —
das Muster war schon korrekt umgesetzt.

Testabdeckung dazu: `startup_coordinator_test.dart` (7 Tests zur Policy, ohne
Widget), `app_settings_test.dart` (Register, Round-Trips, Degradation),
`wipe_all_data_test.dart`, `settings_page_test.dart` (inkl.
Bestätigungsdialog), `startup_error_page_test.dart` (inkl. Routing bis zum
Recovery-Screen und dem degradierten Pfad).

### ✅ Welle 4 — Capability-Module

Leitentscheidung: **was ohne neue Abhängigkeit auskommt, wird Code im
Template — was eine Dependency, einen Manifest-Eintrag oder eine
Store-Deklaration mitbringt, wird ein Rezept.** Andernfalls erbt jede
abgeleitete App Module, die sie löschen muss, und im schlimmsten Fall deren
Versionskonflikte: `device_calendar` hat in der Referenz-App das Upgrade
eines völlig unbeteiligten UI-Pakets blockiert (KI-009).

**Als Code umgesetzt — `core/permissions/` (null neue Dependencies):**

| Datei | Inhalt |
|---|---|
| `permission_gateway.dart` | `PermissionState` mit vier Zuständen inkl. `permanentlyDenied`, `PermissionGateway` |
| `permission_flow.dart` | `ensurePermission(...)` — status → (granted? fertig) → (permanentlyDenied? Settings-Weg) → Rationale → request |
| `permission_rationale_sheet.dart` | `PermissionCopy` (app-eigene Texte) und die beiden Sheets |
| `test/support/fake_permission_gateway.dart` | Fake mit Aufrufprotokoll: beweist die *Reihenfolge*, nicht nur das Ergebnis |

Damit schließt **AZ-2**: `permanentlyDenied` ist ein eigener Zustand mit Weg
in die Systemeinstellungen, und `status()` fragt das System statt einen Cache.
Der Permission Contract steht auf 8 × ✅.

**Als Rezept dokumentiert:**

| Dokument | Warum kein Code |
|---|---|
| `patterns/capability-modules.md` | Aufbau, Checkliste und Katalog aller Module mit ihren Kosten |
| `patterns/permissions.md` | Die konkrete Implementierung je Berechtigung bringt Plugin + Manifest + Store-Fragen |
| `patterns/external-source-sync.md` | Kostet mindestens eine Tabelle (`schemaVersion`-Bump) plus das Plugin der Quelle |
| `patterns/backup-restore.md` | Kostet ein File-Picker-Paket und eine Verschlüsselungsentscheidung |

Notifications sind im Katalog mit ihren Android-Randbedingungen erfasst
(`POST_NOTIFICATIONS` ab 13, exakte Alarme ab 12, `BOOT_COMPLETED`, Doze),
aber bewusst noch nicht ausgearbeitet.

### ✅ Nacharbeiten — Android-Ressourcen, A11y, Paketklassifikation

**Android-Ressourcen per Skript (§ 6.1 und § 6.2 erledigt).** Leitlinie:
Flutter-Bordmittel wo möglich, Android-Spezifisches per Skript an die
richtige Stelle. Konkret bedeutet das, dass **kein** eigener Generator nötig
war: `flutter_launcher_icons` erzeugt die Icons ohnehin, und der
Android-12-Splash zeigt mit `windowSplashScreenAnimatedIcon` einfach auf
`@mipmap/ic_launcher`. Übrig bleiben sechs XML-Dateien unter
`scripts/bootstrap/android-res/`, die `bootstrap_android.*` nach dem
`flutter create` einkopiert — das ist genau der Teil, den das Betriebssystem
liest, *bevor* die Flutter-Engine läuft.

Dazu setzt das Skript `android:allowBackup="false"` im Manifest. Ohne Angabe
gilt der Plattform-Default, der die Datenbank ins Google-Konto sichern kann —
bei einer App, die „deine Daten bleiben auf dem Gerät" verspricht, wäre das
eine still gebrochene Zusage. Eine App, die Plattform-Backup *will*, dreht
den Wert um; der Punkt ist, dass es eine Entscheidung wird statt eines Erbes.

**Dabei gefunden: KI-010.** Der Testlauf des Bootstraps hat gezeigt, dass
`flutter create` das Launch-Background **zweimal** anlegt und die Variante
unter `drawable-v21/` auf jedem Gerät ab API 21 gewinnt. Nur `drawable/` zu
branden wäre wirkungslos geblieben — und zwar unbemerkt. Beide Dateien sind
jetzt in den Vorlagen.

**A11y-Tests.** `test/a11y/accessibility_test.dart`, acht Tests: Touch-Targets
≥ 48 dp, Textskalierung 2.0 ohne Overflow auf telefongroßer Fläche,
Semantics-Labels je Option, Auswahl nicht nur über Farbe, keine Interaktion
allein per Wischgeste. Der Accessibility Contract steht damit auf 9 × ✅.

Auch hier ein echter Befund: die Sprachzeilen wurden als „Deutsch DE"
vorgelesen, weil `ListTile` Titel und Trailing zu **einem** Knoten
zusammenzieht. Das Sprachkürzel ist jetzt per `ExcludeSemantics` ausgenommen.

**Paketklassifikation korrigiert.** Die Prüfung hat meine eigene Empfehlung
widerlegt: `shared_models` und `api_client` sind nicht einfach tot —
`services/api` hängt an `shared_models`, und `remove_backend.dart` löscht
`api_client` bereits. Der tatsächliche Defekt lag woanders:
`--with-packages` löschte **`feature_flags`** mit, obwohl Entitlements eine
Store- und keine Backend-Sache sind und das Paket seit Welle 2 den
Gate-Katalog trägt. Getauscht: `feature_flags` bleibt immer, `shared_models`
geht mit dem Backend. READMEs entsprechend neu klassifiziert.

### ⏳ Offen

Nur noch die Versionsdrift aus § 5 — bewusst zurückgestellt, bis KI-001 sich
löst.

---

## 1. Kurzfassung

Das Template ist **weiter, als die Referenzanalyse annimmt** — und an
mehreren Stellen **besser als die App**:

| Baustein | Template 2.0.0 | WasThereSomething 1.3.1 | Besser |
|---|---|---|---|
| `AppLinks` | aus **einem** Slug abgeleitet (`AppLinks(slug:)`), Mailboxen als Enum | 7 URLs einzeln hartkodiert | **Template** |
| `LastErrorBuffer` | Provider, Kapazität 20, `AppError.source` (`flutter`/`zone`) | globales Singleton, Kapazität 1 | **Template** |
| Migrations-Gerüst | `addColumnIfMissing` / `tableExists` (idempotent) + Fixture-Testdatei + `sqlite3` als Dev-Dep | nur Baseline-Schematest, **keine** Fixture | **Template** |
| `melos run codegen` | build_runner **und** `gen-l10n`, plus CI-Drift-Check | nur build_runner, l10n manuell | **Template** |
| Test-Harness | Recording-Fakes für alle Seams, `wrapWithL10n(locale: de)`, `pumpPastSplash`, FakeAsync-Gotchas dokumentiert | Fakes ja, aber kein l10n-Helper | **Template** |
| Locale-Persistenz | vorhanden inkl. `locale_persistence_test.dart` | **fehlt komplett** | **Template** |
| Melos-Skripte | pfadbasiert (umbenennungssicher) | `scope:`-basiert | **Template** |
| `validate.sh` | prüft `VERSION` ↔ `pubspec.yaml` | keine Prüfung | **Template** |
| Datumsvalidierung | `app_core/date_validation.dart` mit dokumentierter `RangeError`-Falle | `core/utils/event_date_validation.dart` | gleichwertig |

Damit reduziert sich die Übernahme auf einen **deutlich kleineren, dafür
schärferen Satz** echter Lücken. Die drei wertvollsten:

1. **`docs/known-issues.md` fehlt vollständig** — zehn dokumentierte
   Fallen mit Symptom, Ursache, Beleg und Wiederholbedingung. Reine
   Dokumentation, null Risiko, sofort übertragbar.
2. **Die Datenbank ist nicht gehärtet** — kein `PRAGMA foreign_keys = ON`,
   kein `wipeAllData()`, keine stabile ID-Erzeugung, kein Downgrade-Schutz.
3. **Das Android-Splash-/Branding-Ressourcenset existiert nicht** — und
   kann es auch nicht als committete Datei, weil das Template bewusst kein
   `android/` mitliefert. Das braucht eine Designentscheidung (§ 6).

---

## 2. Abgleich mit `flutter_template_change.md`

Der Vorgänger hatte 24 nummerierte Punkte. Stand heute auf `main`:

### P1 — Initialisierungs-Sicherheit

| # | Punkt | Stand |
|---|---|---|
| 1 | `bootstrap_mobile.*` zerstörungsfrei | ⚠️ **nicht verifiziert** — Skript existiert, Inhalt nicht geprüft |
| 2 | Projektname aus einer Quelle | ✅ Melos-Skripte pfadbasiert; `project.env` vorhanden |
| 3 | Backend-Entfernung bündeln | ✅ `scripts/remove_backend.{sh,ps1}` |
| 4 | Keine nativen Ordner committen | ✅ kein `android/`, kein `ios/`, kein `linux/` |
| 5 | Screenshot-Infrastruktur entkoppeln | ✅ `integration_test/app_screenshots_test.dart` |

### P2 — Fachliche Basis-Lücken

| # | Punkt | Stand |
|---|---|---|
| 6 | Dark Theme + `ThemeMode.system` | ✅ `buildAppDarkTheme()`, `themeMode: ThemeMode.system` — **aber ohne Nutzereinstellung** |
| 7 | Locale persistieren | ✅ inkl. Test — **aber Default weiterhin `Locale('de')`, nie die Systemsprache** |
| 8 | Test-Harness von Tag 1 | ✅ vollständig, mit `wrapWithL10n` |
| 9 | Injectable-Seam-Konvention | ✅ `core/platform/platform_seams.dart` — url, share, clipboard, `packageInfo`, `deviceInfo` |
| 10 | Splash als Modul | ✅ `splash_timing.dart` + `splash_warmup.dart` |
| 11 | Fehler-Infrastruktur | ✅ `core/errors/` |
| 12 | Drift-Migrations-Gerüst | ✅ inkl. `TableMigration`-Warnung und FakeAsync-Gotcha |
| 13 | UI-Fallstricke als Basismuster | ⚠️ **nicht verifiziert** |
| 14 | Codegen bündeln + CI-Drift-Check | ✅ beides |

### P3 — Infrastruktur & Governance

| # | Punkt | Stand |
|---|---|---|
| 15 | Android-Release-Kette | ✅ `_android-release-build.yml`, `android-{build-release,publish-play}.yml`, `scripts/release/resolve_android_version.sh` |
| 16 | `pubspec.lock` committen | ✅ getrackt |
| 17 | `VERSION` ↔ `pubspec.yaml` | ✅ in `validate.sh` |
| 18 | OpenSpec-Validierung als Skript | ✅ `scripts/validate_openspec.{sh,ps1}` |
| 19 | Workspace-Datei umbenennen | ⚠️ **nicht verifiziert** |
| 20 | `.gitattributes` EOL-Regeln | ✅ vollständig |
| 21 | `api_client`/`feature_flags` klassifizieren | ⚠️ beide noch im Workspace, keine Kennzeichnung gefunden |
| 22 | Doku-Registry-Muster | ⚠️ **nicht verifiziert** |
| 23 | `time_machine2` als Core-Util | ✅ `app_core/date_validation.dart` |
| 24 | Dev-Skripte + Agent-Skills | ✅ `scripts/dev/` + `.claude/skills/{codegen,quality-gate,test-summary}` |

**Fazit:** P1 und P2 sind praktisch abgearbeitet, P3 zu ~⅔. Die vier
`⚠️`-Zeilen sollten vor dem Schließen des Vorgängerdokuments verifiziert
werden — ich habe sie nicht geprüft, weil sie außerhalb des Auftrags lagen.

---

## 3. Delta der 47 implementierten Konzepte

Legende: ✅ vorhanden · 🟡 teilweise · ❌ fehlt · ⬜ bewusst app-spezifisch

| # | Konzept (Kapitelbezug der Referenzanalyse) | Template 2.0.0 | Anmerkung |
|---|---|---|---|
| 1 | Monorepo: Pub-Workspace + Melos-Skripte (B) | ✅ | pfadbasiert, besser als App |
| 2 | Feature-first-Schichtung (B) | ✅ | Todo-App als Referenzslice inkl. `data/{dao,mapper,tables}` |
| 3 | Riverpod-Generator + `keepAlive` für Infrastruktur (C) | ✅ | |
| 4 | Overrides als Parameter des Composition Root (C, AJ) | ✅ | `App({this.overrides})` |
| 5 | go_router + `StatefulShellRoute` (Q) | 🟡 | Router vorhanden; **`go_router ^14.0.0` vs. `^17.3.0` in der App** |
| 6 | Zweiphasiger In-App-Splash mit injizierbaren Zeiten (F) | ✅ | |
| 7 | Android-12+-Splash gebrandet, inkl. `values-night-v31` (F, Y) | ❌ | **kein `android/` im Template** — § 6 |
| 8 | Eine Splash-Hintergrundfarbe über alle Schichten (F) | ❌ | dito |
| 9 | Splash-Warmup-Registry mit gekapselten Fehlern (F) | ✅ | |
| 10 | Key-Value-Settings + typisierte Notifier (E) | ✅ | `KeyValueStore` + `SettingDef`-Register in `lib/core/settings/`; Locale und ThemeMode darauf migriert |
| 11 | Onboarding-Flag (G) | ❌ | kein Onboarding im Template |
| 12 | Setup-Assistent-Zustandsautomat (G) | ❌ | |
| 13 | JIT-Permissions mit In-App-Rationale (H) | ✅ | `lib/core/permissions/` — Ablauf, Sheets, Fake, 10 Tests |
| 14 | Graceful Degradation bei Ablehnung (H) | ✅ | `ensurePermission` liefert den Zustand zurück statt zu werfen; Degradationstabelle je Berechtigung in `patterns/permissions.md` |
| 15 | Drift-Schema + additive Migration (I, K) | ✅ | **besser**: `addColumnIfMissing` idempotent |
| 16 | FK-Enforcement + DB-Constraints (I) | ❌ | **kein `beforeOpen`, kein `PRAGMA foreign_keys = ON`** |
| 17 | Partieller Unique-Index als Invariante (I) | ❌ | |
| 18 | Epoch-Day-Speicherung für Kalendertage (J) | ❌ | |
| 19 | Jahroptionale Teildatumsangaben (J) | 🟡 | `DateValidation.isValidAnnualDate` ✅; **kein `PartialDate`-Typ** |
| 20 | Halboffenes All-Day-Intervall (J) | ❌ | |
| 21 | Selbstheilende Prüfung plattformgespeicherter Bereiche (S) | ⬜ | Capability-Ebene |
| 22 | Stabile app-generierte IDs (I) | ❌ | **kein `generateId()`** |
| 23 | Enum mit `dbValue` + `fromDb(orElse:)` (I) | ❌ | Muster nicht vorgelegt |
| 24 | External-Source-Link mit Fingerprint + `sourceMissing` (M) | ⬜ | Capability |
| 25 | Idempotenter transaktionaler Import (M) | ⬜ | Capability |
| 26 | Ownership-Mapping + Content-Marker (S) | ⬜ | Capability |
| 27 | Ein Sync-Koordinator + persistiertes Protokoll (T) | ⬜ | Capability |
| 28 | Reason-Code-Enums, erst bei Anzeige lokalisiert (V) | ❌ | Muster fehlt, ist aber generisch |
| 29 | Personendatenfreie abgeleitete Speicher (W) | ❌ | als Regel dokumentierbar |
| 30 | Gateway-Interface + Fake + Provider (N) | 🟡 | Typedef-Seams ✅ und das Muster dokumentiert (`docs/architecture/patterns/platform-gateways.md`); ein konkretes Gateway entsteht mit dem ersten Capability-Modul |
| 31 | Typedef-Seams für Ein-Aufruf-Plugins (N) | ✅ | **besser**: zusätzlich `copyToClipboard` |
| 32 | Kapselungs-Guardrail-Test (N, AA) | ✅ | `test/support/package_encapsulation.dart`, scharf geschaltet auf `lottie` |
| 33 | Safety-assertende Test-Fakes (S, AB) | 🟡 | Recording-Fakes ✅, Muster dokumentiert; eine echte Invariante gibt es erst mit einem Capability-Modul zu prüfen |
| 34 | `CalendarDisplayEvent`-Adaptergrenztyp (R) | ⬜ | Capability |
| 35 | Typisierte, validierte externe Links (AI) | ✅ | **besser** als App |
| 36 | `showLicensePage` offline (P) | ✅ | Offline-Seite zuerst, Weblink als Ergänzung |
| 37 | Lokalisierte Markdown-Hilfe mit Bild-Fallback (AG) | ❌ | |
| 38 | Generisch → Plattform → Anbieter geschichtete Anleitungen (AG) | ❌ | Doku-Muster |
| 39 | Globale Fehlererfassung + Buffer (V) | ✅ | **besser** als App |
| 40 | Feature-Flags + Entitlements, fail-open (AH) | ✅ | `FeatureFlags`, `Entitlement`, `FeatureGates` inkl. Tests |
| 41 | Test-Harness mit In-Memory-DB und Fakes (AB) | ✅ | **besser** als App |
| 42 | `testApp`-Wrapper für Drift/Riverpod/FakeAsync (AB) | 🟡 | Gotchas **dokumentiert**, aber kein `testApp(...)`-Wrapper |
| 43 | Melos-CI mit `packageFilters` (AC) | ✅ | |
| 44 | `VERSION` als Wahrheit + Tag-Gate (AE) | ✅ | |
| 45 | Monotoner Android-`versionCode` (AE) | ✅ | |
| 46 | Deterministischer Branding-Generator mit `--check` (Z) | 🟡 | **anderer Ansatz**: `flutter_launcher_icons` statt Generator-Skript — § 6 |
| 47 | `known-issues.md` mit Wiederholbedingungen (AY) | ❌ | **fehlt vollständig** |

**Zusammenfassung nach Welle 1–4:** 23 ✅ · 7 🟡 · 10 ❌ · 7 ⬜
(Ausgangsstand: 17 ✅ · 8 🟡 · 15 ❌ · 7 ⬜)

Die verbleibenden ❌ sind bewusst offen: sieben davon sind Capability-Module,
die als Rezept vorliegen, zwei die Android-Splash-Ressourcen aus § 6.1.

---

## 4. Die echten Lücken, priorisiert

### Welle 1 — Dokumentation und Regeln (kein Code, kein Risiko)

| Lücke | Umfang | Quelle in WTS |
|---|---|---|
| **`docs/known-issues.md`** übernehmen (KI-001…KI-010), App-spezifisches herausnehmen (KI-009/010 zu `kalender`/`device_calendar` als Beispiele belassen oder streichen) | ~350 Zeilen | `WasThereSomething/docs/known-issues.md` |
| **Die sechs Verträge** als `docs/architecture/contracts/`: Startup, Database, Localization, Permission, External Data Ownership, Library Evaluation | ~6 × 30 Zeilen | Referenzanalyse Kap. AP–AU |
| **A11y-Standard** als prüfbare Checkliste (Touch-Targets, Textskalierung 2.0, Semantics, keine Information nur über Farbe) | ~40 Zeilen | Kap. X |
| **Datums-Semantik-Regeln** in arc42 Kap. 08 (Epoch-Day, halboffene Intervalle, Wanduhr vs. Instant, jahrlose Daten) | ~40 Zeilen | Kap. J |

### Welle 2 — Kleine, in sich geschlossene Codeänderungen

| Lücke | Umfang | Risiko |
|---|---|---|
| **Systemsprache als Default**: `MaterialApp.locale` darf `null` sein; `LocaleNotifier.build()` gibt `null` zurück, wenn nichts gespeichert ist | S | niedrig — Test `locale_persistence_test.dart` anpassen |
| **`themeMode` als Einstellung** (Notifier über `KeyValueStore`, Umschalter auf der Settings-Seite) | S | niedrig |
| **`MaterialApp.title` aus `AppIdentity`/l10n** statt `'Flutter App Template'` | XS | keins |
| **`PRAGMA foreign_keys = ON`** in `beforeOpen` von `AppDatabase` | XS | niedrig — Todo-Schema hat noch keine FKs |
| **Downgrade-Schutz**: `onUpgrade` bei `from > to` mit klarer Meldung abbrechen | XS | keins |
| **`generateId()`** als `core/utils/id_generator.dart` (8 Zeilen, `Random.secure()`) | XS | keins |
| **`Clock`-Interface + `FixedClock`** im Harness | S | keins |
| **`analyze` statt `analyze:flutter`** in `ci-mobile.yml` — reine Dart-Pakete werden heute im PR **nicht** analysiert | XS | niedrig |
| **`showLicensePage` in `about_page.dart`** — offline, ohne handgepflegte Paketliste, mit Version aus `package_info_plus` | S | keins |
| **`Entitlement` + `FeatureGates` (fail-open)** in `packages/feature_flags` ergänzen | S | keins |

### Welle 3 — Muster und Gerüste (Refactoring nötig)

| Lücke | Umfang | Anmerkung |
|---|---|---|
| **`assertPackageEncapsulated(package, allowedDir)`** als Test-Helper in `test/support/` | S | direkt aus `kalender_encapsulation_test.dart` verallgemeinerbar |
| **Gateway-Muster** dokumentieren und mit *einem* Beispiel vorlegen (Interface + produktive Impl + safety-assertender Fake + Provider) | M | Typedef-Seam bleibt für Ein-Aufruf-Plugins |
| **`SettingDef`-Register** über `KeyValueStore` (Key + Default + Encode/Decode + Migrationshaken), damit „welche Settings gibt es?" beantwortbar wird | M | |
| **`StartupCoordinator`** — Phasen `blocking` / `guarded` / `fireAndForget`, plus definierter **fataler Startup-Zustand** (heute nirgends modelliert) | L | die Splash-Warmup-Registry geht darin auf |
| **`wipeAllData()`** + Bestätigungsdialog als Referenzmuster (Kinder vor Eltern, FK-bewusst) | M | |
| **Enum-mit-`dbValue`-Muster** + Reason-Code-Muster an der Todo-App zeigen | S | |

### Welle 4 — Capability-Module (bewusst später)

External-Source-/Reconciliation-Modul, Ownership-Mapping für Plattform-Writes,
Sync-Koordinator mit Protokoll, Permissions-Modul, Backup/Restore,
Notifications, In-App-Hilfe, Kalender-UI. Alle brauchen eine eigene
Entscheidung über Abhängigkeiten und gehören **nicht** in die Baseline.

---

## 5. Versionsdrift zwischen Template und App

Vor der Übernahme zu klären, weil Codebeispiele sonst nicht kompilieren:

| Paket | Template 2.0.0 | WasThereSomething 1.3.1 |
|---|---|---|
| `go_router` | `^14.0.0` | `^17.3.0` |
| `riverpod_annotation` | `^3.0.0` | `^4.0.0` |
| `riverpod_generator` | `^3.0.0` | `^4.0.0+1` |
| `share_plus` | `^12.0.0` | `^10.1.0` |
| `Override`-Import | `package:flutter_riverpod/misc.dart` | `package:riverpod_annotation/riverpod_annotation.dart` |

Das Template ist bei go_router und riverpod_annotation **zurück**, bei
share_plus **vor**. Der `Override`-Importpfad unterscheidet sich dadurch —
beim Kopieren von Harness-Code beachten. **KI-001 aus WasThereSomething gilt
hier ebenfalls**, sobald `drift_dev` angehoben wird.

---

## 6. Zwei Designfragen, die vor Welle 2 entschieden werden müssen

### 6.1 Android-Splash- und Branding-Ressourcen ohne committetes `android/`

Das Template liefert bewusst kein `android/` mehr (Vorgänger P1.4, um die
Stale-Application-ID zu eliminieren). Das Ressourcenset aus WasThereSomething
— `values-v31/styles.xml`, `values-night-v31/styles.xml`, `colors.xml`,
`drawable/launch_background.xml`, `drawable/splash_icon.xml` — kann daher
nicht einfach als Datei mitkommen. Drei Optionen:

- **(a) Bootstrap-Templating:** die Dateien als Vorlagen unter
  `scripts/bootstrap/android-res/` ablegen; `bootstrap_android.*` kopiert
  sie nach dem `flutter create` und ersetzt Platzhalter aus `project.env`.
  *Robust, macht den Bootstrap zum Pflichtschritt — was er ohnehin ist.*
- **(b) Post-Bootstrap-Skript:** `scripts/branding/apply_android_splash.*`,
  vom Entwickler bewusst aufgerufen. *Einfacher, aber vergessbar.*
- **(c) Nur Dokumentation:** eine Anleitung in
  `docs/operations/branding-assets.md`. *Billigste Variante, aber genau die
  Fallen (`values-night-v31`, gepaddeter Icon-Viewport) werden dann wieder
  einzeln entdeckt.*

**Empfehlung: (a)**, weil die zwei teuersten Erkenntnisse — dass ohne
`values-night-v31` die Splash-Attribute im Dunkelmodus verloren gehen, und
dass Android das Splash-Icon auf den inneren Zweidrittelkreis maskiert —
sonst in jeder neuen App erneut Zeit kosten.

### 6.2 Icon-Pipeline: `flutter_launcher_icons` oder Generator-Skript?

Das Template nutzt `flutter_launcher_icons` mit Quellbildern unter
`assets/branding/`. WasThereSomething nutzt ein geliefertes Icon-Pack plus
`scripts/branding/generate_branding_assets.py --check`. Beides ist legitim;
zu klären ist, ob das Template zusätzlich braucht, was
`flutter_launcher_icons` **nicht** erzeugt:

- Notification-Small-Icon (weiß, Form im Alphakanal)
- Android-12+-Splash-VectorDrawable mit gepaddetem Viewport

Wenn ja, ist ein kleines Generator-Skript neben `flutter_launcher_icons` die
naheliegende Lösung — mit `--check` in CI, damit committete Assets nicht von
ihren Mastern abdriften.

---

## 7. Was ausdrücklich **nicht** übernommen wird

- Geburtstags-/Anlass-Domäne, 29.-Februar-Regel, Alter im Titel
- Beziehungsdomäne, Nachrichtenvorlagen, Selbst-Kontakt-Marker
- Kalendername `WasThereSomething`, `[WTS2:`-Marker, Drei-Jahres-Fenster
- `kalender`-Pin `0.14.3` und die vier Adapter-Korrekturen (nur als
  *Beispiel* im Guardrail-Kapitel)
- Die 414 Produkt-ARB-Schlüssel
- WasThereSomethings Settings-Backend (Drift statt `shared_preferences`) —
  das Template hat mit `KeyValueStore` bewusst die leichtere Variante; erst
  wenn ein App-Profil eine Datenbank *sowieso* mitbringt, lohnt der Wechsel

---

## 8. Offene Punkte für die Entscheidung

1. **§ 6.1** — Bootstrap-Templating, Post-Bootstrap-Skript oder nur Doku?
2. **§ 6.2** — Generator-Skript zusätzlich zu `flutter_launcher_icons`?
3. **Versionsdrift** — `go_router` und `riverpod_annotation` im Zuge dieser
   Arbeit anheben, oder getrennt?
4. **`known-issues.md`** — KI-009/KI-010 (`device_calendar`/`kalender`) als
   App-Beispiele belassen oder auf das generische Muster eindampfen?
5. **Ablage dieses Dokuments** — `docs/ideas/` (wie hier) oder
   `docs/delivery/implementation-plans/`?
6. **Vorgängerdokument** — die vier `⚠️`-Punkte aus § 2 verifizieren und
   `flutter_template_change.md` danach schließen?

---

## 9. Vorgeschlagene Reihenfolge

```
Welle 1  Doku/Regeln          known-issues.md, Verträge, A11y, Datums-Semantik
   ↓     (kein Code, sofort mergebar)
Welle 2  Kleine Codefixes     Systemsprache, themeMode, App-Titel, FK-Pragma,
   ↓                          Downgrade-Guard, generateId, Clock, Seams, CI-analyze
Welle 3  Muster/Gerüste       Encapsulation-Helper, Gateway-Muster, SettingDef,
   ↓                          StartupCoordinator + Recovery, wipeAllData
Welle 4  Capability-Module    je eigene Entscheidung und eigener PR
```

Welle 1 und 2 sind zusammen etwa ein Arbeitsdurchgang und berühren keine
bestehende Architektur. Welle 3 ist die eigentliche Arbeit.
