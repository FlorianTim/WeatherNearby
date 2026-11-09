# flutter_app_template — Change-Prompt

> Diese Datei ist ein **anwendbarer Arbeitsauftrag** für einen KI-Agenten
> (oder Menschen) im Repo `flutter_app_template`. Sie bündelt alle
> Erkenntnisse aus der kompletten Initialisierung und drei
> Release-Zyklen (1.0 → 1.3) der daraus gebauten App *WasThereSomething*.
> Quelle: Product-Owner-Review + Agent-Erfahrung, 2026-07-15.

---

## PROMPT (ab hier in den Agenten geben)

Du arbeitest im Repository `flutter_app_template`. Setze die folgenden
Änderungen um. Arbeite in der angegebenen Reihenfolge (P1 → P3), mache
kleine, nachvollziehbare Commits pro Nummer, und halte dich an die
bestehenden Konventionen des Templates (Struktur, Doku-Stil, Skripte für
Bash **und** PowerShell). Ziel: Die nächste App soll sich schneller, mit
weniger Handarbeit und deutlich weniger KI-Token aus dem Template ableiten
lassen. Schreibe für jede Änderung Tests bzw. Validierungs-Checks, wo das
möglich ist, und aktualisiere `template-initialization.md`.

### P1 — Initialisierungs-Sicherheit (Reibungspunkte aus erster Hand)

1. **`bootstrap_mobile.*` darf keine App-Dateien zerstören.**
   `flutter create . --overwrite` überschreibt heute `pubspec.yaml`
   (alle Dependencies weg), `lib/main.dart`, `test/widget_test.dart`,
   `README.md`, `analysis_options.yaml`, `.gitignore`. Umbau: `flutter
   create` in ein Temp-Verzeichnis laufen lassen und **nur die
   Plattformordner** (`android/`, `ios/`, `web/`, …) ins Projekt kopieren;
   alternativ die geschützten Dateien vorher sichern und danach
   wiederherstellen. Zusätzlich fette Warnung in
   `template-initialization.md`.
2. **Projektname aus einer Quelle speisen.** `mobile_app` ist hartkodiert
   in `docker-compose.yml` (3 Fallback-Bootstraps, dort fehlt zudem
   `--org`), `scripts/automation/integration-test/run_web_tests.sh` und im
   Melos-Script `build:web` (`scope:`). Alle Stellen aus `project.env`
   ableiten (oder per Initializer ersetzen) und in die
   Initialisierungs-Checkliste aufnehmen. `project.env` erweitern um:
   `APP_NAME`, `APPLICATION_ID`/`--org`, Workspace-Dateiname,
   Devcontainer-Name, Melos-Scope.
3. **Backend-Entfernung bündeln.** Referenzen liegen heute an ~10 Stellen
   (`backend/`, `services/api/`, 2 CI-Workflows, 4 compose-Services,
   `build.sh`/`build.ps1`/`build-local.ps1`/`pre-commit.sh`/`bootstrap.sh`/
   `upgrade_deps.sh`, Root-`pubspec.yaml`-Workspace, `.codex/config.toml`,
   Copilot-Instructions, README, `.code-workspace`-Tasks/Launch). Entweder
   `scripts/remove_backend.(sh|ps1)` bauen oder die Referenzen so bündeln
   (eigene compose-Datei per `include`, eigener Workflow-Ordner), dass
   Entfernen = 2–3 Löschungen ist. Auch die Workspace-Datei muss dann ohne
   `API:`-Tasks/Launch-Configs auskommen.
4. **Keine nativen Ordner committen.** Die committeten `android/`/`linux/`
   tragen die Stale-ID `de.kroschewski.flutter_test_app` und müssen sowieso
   regeneriert werden (`linux/` erzeugt der Bootstrap nicht mal neu).
   Native Ordner aus dem Template entfernen, Bootstrap zum Pflichtschritt
   machen — eliminiert die Stale-ID-Falle komplett.
5. **Screenshot-Infrastruktur entkoppeln.** `counter_test.dart` ist in
   `run_web_tests.sh`, README und `docs/testing/README.md` hartkodiert.
   Neutral benennen (`app_screenshots_test.dart`), Zielpfad nur an einer
   Stelle definieren.

### P2 — Fachliche Basis-Lücken schließen

6. **Dark Theme:** `buildAppDarkTheme()` + `themeMode: ThemeMode.system`
   in die Template-Basis (in der App bereits nachgerüstet — upstreamen).
7. **Locale persistieren:** `LocaleNotifier` überlebt heute keinen
   Neustart. Persistenz über den Key-Value-Store als Referenzmuster.
8. **Test-Harness von Tag 1** (wichtigste Einzelverbesserung aus der
   Praxis): `test/support/test_app.dart` mit `TestAppHarness`, der
   standardmäßig overrided: In-Memory-Datenbank, Fake-Gateways
   (Kontakte/Kalender/Launcher/Share/Clipboard), kurze Splash-Zeiten.
   Dazu `wrapWithL10n(locale: 'de')`-Helper — Widget-Tests ohne explizite
   Locale laufen auf `en`, das ARB-Template ist `de`; genau daran scheitert
   sonst der erste Test jeder neuen App.
9. **Injectable-Seam-Konvention dokumentieren und vorlegen:** je ein
   Provider für `urlLauncher`, `shareText`, `clipboard`, `deviceInfo`,
   `packageInfo` (Muster: `Provider<Future<void> Function(...)>`), damit
   Widget-Tests nie echte Plugins treffen. Hat sich in jeder Welle
   ausgezahlt.
10. **Splash als Modul:** Zwei-Phasen-Splash mit `splashTimingProvider`
    (Produktion 3 s/3 s, Tests 1 s/1 s via Harness-Override) und
    `splashWarmupTasksProvider` (Registry von Futures, die während der
    Splash-Animation DB & primäre Provider vorladen; jede Task fängt ihre
    eigenen Fehler). Lokalisierte Lottie-Assets pro Phase (de/en) als
    Muster.
11. **Fehler-Infrastruktur als optionales Modul:** `runZonedGuarded` +
    `FlutterError.onError` → In-Memory-`LastErrorBuffer`; Feedback-/
    Fehler-Mail-Builder (mailto, Metadaten-Block, Stacktrace-Kürzung,
    Ausfüll-Template, `package_info_plus`/`device_info_plus` hinter
    Seams). Aus der App übernehmbar.
12. **Drift-Migrations-Gerüst:** additive Migrationen mit
    `_addColumnIfMissing`/`_tableExists`, Fixture-Test-Datei mit
    Roh-SQL-Snapshots pro Schema-Version, und als Kommentar-Warnung: bei
    `TableMigration`-Rebuilds müssen **alle später ergänzten Spalten** in
    `newColumns` nachgetragen werden. Test-Gotcha dokumentieren: `await
    driftStream.first` im `testWidgets`-Body deadlockt in FakeAsync —
    `tester.runAsync()` verwenden.
13. **UI-Fallstricke als Basismuster:** (a) Editor-/Toolbar-Widgets neben
    einem `TextField` in `TextFieldTapRegion` wickeln (sonst kollabiert
    die Selection bei Button-Taps auf Web/Desktop); (b) FABs in mehreren
    Shell-Branches brauchen eindeutige `heroTag`s (sonst Hero-Crash beim
    Push von Root-Routen); (c) Root-Routen wechseln per `context.go` in
    Shell-Branches, nie per `push` zurück in die Shell.
14. **Codegen bündeln:** `flutter gen-l10n` in das Melos-`codegen`-Script
    aufnehmen (`melos run codegen` erzeugt heute Drift/Freezed/Riverpod,
    aber **nicht** l10n — in der App mehrfach vergessen und erst im Test
    aufgefallen). Zusätzlich CI-Check „Codegen-Drift": `melos run codegen
    && git diff --exit-code`.

### P3 — Infrastruktur & Governance

15. **Android-Release-Kette komplett mitliefern** (in der App komplett
    nachgerüstet — gehört ins Template): wiederverwendbarer Workflow
    `_android-release-build.yml` (Quality-Gate, Keystore aus Secret,
    AAB+APK, Checksums, Cleanup `if: always()`), Dispatch-Workflows
    `android-build-release.yml`/`android-publish-play.yml`
    (Environments `google-play-internal`/`-production`, Staged Rollout),
    `scripts/release/resolve_android_version.sh` (Branch
    `release/<maj.min>/<semver>` → versionName/monotoner versionCode:
    beta.N < rc.N < final), `key.properties`-Block in
    `build.gradle.kts` mit Debug-Fallback, und
    `docs/operations/android-release-secrets.md` (Keystore erzeugen,
    Service-Account, `gh secret set`).
16. **`pubspec.lock` committen** (App-Repos): `*.lock` aus `.gitignore`
    nehmen — Reproduzierbarkeit der CI.
17. **`VERSION` vs. `pubspec.yaml` abgleichen:** Check in `validate.sh`
    (Template stand auf `1.0.0+1` bei `VERSION 0.1.0`).
18. **OpenSpec-Validierung als Skript:** `scripts/validate_openspec.*` +
    Check in `validate.yml` (heute nur Prosa-Checkliste).
19. **Workspace-Datei beim Initialisieren umbenennen** (`<app>.code-workspace`)
    und Devcontainer-`name` mitziehen — aus `project.env`.
20. **`.gitattributes` mit EOL-Regeln** (`* text=auto`, `*.sh eol=lf`,
    `*.ps1 eol=crlf`): beseitigt die CRLF-Warnungsflut von
    `flutter create` auf Windows.
21. **`api_client`/`feature_flags` klassifizieren:** bei
    `backend_enabled: false` als „optional entfernbar" markieren, damit
    der Initializer sie löschen darf statt toten Ballast mitzuschleppen.
22. **Doku-Registry-Muster übernehmen:** manuelle Testpläne mit global
    fortlaufenden `T-NNN`-Nummern (Registry-Tabelle „nächste freie
    Nummer" im README), arc42-Kap. 08 mit ER-Diagramm-Pflichtpflege bei
    jedem Schema-Bump, `CHANGELOG`-Wellen-Struktur.
23. **`time_machine2`-Datumsvalidierung als Core-Util** (`AnnualDate`/
    `LocalDate`; 29.02. nur in Schaltjahren, jahrlos erlaubt) statt
    handgeschriebener Monatslängen-Switches. Achtung: Version 0.14 kennt
    kein `ArgumentOutOfRangeException` — `RangeError` + generisches
    `catch` fangen.

24. **Dev-Skripte mit Agent-Skills koppeln** (Token-Sparmuster): häufige
    Arbeitsabläufe als kompakte Skripte unter `scripts/dev/` ausliefern und
    je einen Projekt-Skill unter `.claude/skills/<name>/SKILL.md` dazu, der
    dem Agenten sagt, WANN und WIE er sie nutzt. Startpaket:
    `test_summary.sh` (Suite laufen lassen, nur Fail-Namen + erste
    Exception ausgeben statt des vollen Logs), `quality_gate.sh`
    (format + analyze + test, kompakt), `codegen.sh` (build_runner +
    gen-l10n). Snippets siehe unten.

### Akzeptanzkriterien

- Eine frische Initialisierung (Spec-Phase + Apply + Bootstrap) läuft ohne
  manuelle Reparatur von `pubspec.yaml`/`main.dart` durch.
- `grep -r "mobile_app"` außerhalb von `apps/mobile_app` liefert nach der
  Initialisierung keine Treffer mehr (bzw. nur bewusst dokumentierte).
- Backend-Entfernung erfordert ≤ 3 Lösch-Operationen.
- `melos run codegen` erzeugt auch l10n; CI schlägt bei Codegen-Drift fehl.
- Die Android-Release-Workflows laufen im Template-Repo bis zum
  Artefakt-Upload (mit Dummy-Keystore-Secrets) durch.
- `validate.sh` prüft VERSION↔pubspec und OpenSpec.

### Nicht-Ziele

- Keine neuen Produkt-Features im Template; nur Gerüst, Muster, Skripte.
- Keine Umstellung des State-Managements oder der Ordnerstruktur.

---

## Referenz-Snippets (aus `WasThereSomething` übernehmen/anpassen)

### Zu 1 — Bootstrap ohne Zerstörung (Kern des Skripts)

```bash
# bootstrap_mobile.sh — flutter create in ein Temp-Verzeichnis, dann NUR
# die Plattformordner kopieren; App-Dateien bleiben unangetastet.
source project.env   # APP_NAME, APPLICATION_ORG, PLATFORMS
tmp="$(mktemp -d)"
( cd "$tmp" && flutter create --org "$APPLICATION_ORG" \
    --platforms "$PLATFORMS" --project-name "$APP_NAME" app )
for p in ${PLATFORMS//,/ }; do
  rm -rf "apps/mobile_app/$p"
  cp -R "$tmp/app/$p" "apps/mobile_app/$p"
done
rm -rf "$tmp"
# NIE: flutter create . --overwrite  (zerstört pubspec.yaml, main.dart, …)
```

### Git-Hooks (bestehendes Muster beibehalten und dokumentieren)

```bash
# scripts/install-hooks.sh → verlinkt scripts/pre-commit.sh als Hook:
ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit

# scripts/pre-commit.sh (Kern): Format + Analyze vor jedem Commit
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
(cd apps/mobile_app && dart format --output=none --set-exit-if-changed lib test)
(cd apps/mobile_app && flutter analyze --no-pub)
```

### Zu 8 — TestAppHarness (Kern)

```dart
class TestAppHarness {
  final settings = InMemoryAppSettingsRepository(onboardingCompleted: true);
  final gateway = FakeContactGateway();
  final calendarGateway = FakeCalendarGateway();
  final database = AppDatabase(NativeDatabase.memory());

  List<Override> get overrides => [
    appSettingsRepositoryProvider.overrideWithValue(settings),
    contactGatewayProvider.overrideWithValue(gateway),
    calendarGatewayProvider.overrideWithValue(calendarGateway),
    appDatabaseProvider.overrideWith((ref) {
      ref.onDispose(database.close);
      return database;
    }),
    // Produktion: 3 s Splash-Phasen; Tests: 1 s, damit pump(3 s) → Shell.
    splashTimingProvider.overrideWithValue(
      const SplashTiming(company: Duration(seconds: 1),
                         appMinimum: Duration(seconds: 1))),
  ];
  App buildApp() => App(overrides: overrides);
}
// Merksatz-Gotchas für die Template-Doku:
// * `await driftStream.first` im testWidgets-Body deadlockt (FakeAsync)
//   → DB-Setup/-Asserts in `tester.runAsync(() async { ... })`.
// * Lazy ListViews bauen Offscreen-Kinder nicht → hoher Viewport:
//   tester.view.physicalSize = const Size(1080, 3600);
```

### Zu 9 — Injectable Seam (ein Muster für alle Plugins)

```dart
typedef ShareText = Future<void> Function(String text);
final shareTextProvider =
    Provider<ShareText>((ref) => (text) => Share.share(text));
// Widget: final ShareText share = widget.shareText ?? ref.read(shareTextProvider);
// Test:   MessageSuggestionsSheet(shareText: (t) async => shared = t)
// Gleiches Muster: urlLauncher, clipboard, deviceInfo, packageInfo.
```

### Zu 10 — Splash-Timing + Warmup-Registry

```dart
final splashTimingProvider = Provider<SplashTiming>((ref) =>
    const SplashTiming(company: Duration(seconds: 3),
                       appMinimum: Duration(seconds: 3)));

typedef SplashWarmupTask = Future<void> Function();
final splashWarmupTasksProvider = Provider<List<SplashWarmupTask>>((ref) {
  Future<void> guard(Future<void> Function() t) async {
    try { await t(); } catch (_) {/* Start nie blockieren */}
  }
  return [
    () => guard(() => ref.read(primaryDashboardProvider.future)),
    () => guard(() => ref.read(openTasksProvider.future)),
  ];
});
// Router-Splash: initialization: () async {
//   ...; await Future.wait([for (final t in ref.read(splashWarmupTasksProvider)) t()]);
// }
```

### Zu 12 — Additive Drift-Migration (Gerüst)

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await _addColumnIfMissing(m, people, people.firstName); // idempotent
    }
    // TableMigration-Rebuild? Dann ALLE später ergänzten Spalten in
    // newColumns nachtragen, sonst crasht das Upgrade alter DBs!
  },
);

Future<void> _addColumnIfMissing(
    Migrator m, TableInfo table, GeneratedColumn column) async {
  final info = await customSelect(
      'PRAGMA table_info(${table.actualTableName})').get();
  if (info.isEmpty) return; // Tabelle fehlt: createAll/Heilung übernimmt
  final names = info.map((r) => r.read<String>('name')).toSet();
  if (!names.contains(column.name)) await m.addColumn(table, column);
}
// + je Schema-Version ein Fixture-Test: Roh-SQL-Snapshot des alten
// Schemas anlegen, DB öffnen, verlustfreie Daten + user_version asserten.
```

### Zu 13 — UI-Fallstricke

```dart
// (a) Toolbar neben TextField: ohne TapRegion kollabiert die Selection
// bei Button-Taps auf Web/Desktop zu -1 → Präfix landet am Textende.
return TextFieldTapRegion(child: Column(children: [toolbar, textField]));

// (b) Mehrere Shell-Tabs mit FABs: eindeutige Tags, sonst Hero-Crash
// beim Push einer Root-Route.
FloatingActionButton(heroTag: 'fab-today', ...)

// (c) Root-Route → Shell-Branch immer per go, nie push:
onTap: () => context.go(AppRoutes.personDetail(id)),
```

### Zu 14 — Codegen bündeln + CI-Drift-Check

```yaml
# melos (root pubspec.yaml):
codegen:
  steps:
    - melos exec --depends-on=build_runner -- \
        dart run build_runner build --delete-conflicting-outputs
    - melos exec --scope="$APP_PACKAGE" -- flutter gen-l10n   # NICHT vergessen!

# CI-Step (validate.yml):
- name: Codegen drift
  run: |
    melos run codegen
    git diff --exit-code || {
      echo "::error::Generated sources out of date — run 'melos run codegen'"; exit 1; }
```

### Zu 15 — versionCode-Ableitung + Gradle-Signing

```bash
# scripts/release/resolve_android_version.sh (Kern):
# release/<maj.min>/<semver> oder v<semver> → Name + monotoner Code
version_code=$((major*10000000 + minor*100000 + patch*1000 + pre))
# pre: beta.N → N (1..499), rc.N → 500+N, final → 999
# ⇒ 1.3.0-beta.1 < 1.3.0-rc.1 < 1.3.0, Play-Limit 2.1e9 nie erreicht.
```

```kotlin
// android/app/build.gradle.kts — key.properties mit Debug-Fallback:
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}
signingConfigs { create("release") { if (keystorePropertiesFile.exists()) {
    keyAlias = keystoreProperties["keyAlias"] as String
    keyPassword = keystoreProperties["keyPassword"] as String
    storeFile = file(keystoreProperties["storeFile"] as String)
    storePassword = keystoreProperties["storePassword"] as String } } }
buildTypes { release {
    signingConfig = if (keystorePropertiesFile.exists())
        signingConfigs.getByName("release")
    else signingConfigs.getByName("debug") // lokale --release ohne Secrets
} }
```

### Zu 20 — `.gitattributes`

```gitattributes
* text=auto
*.sh   text eol=lf
*.ps1  text eol=crlf
*.bat  text eol=crlf
*.jks  binary
*.png  binary
```

### Zu 24 — Dev-Skript + Agent-Skill (Test-Summary)

```bash
# scripts/dev/test_summary.sh — eine Zeile bei Grün, sonst nur Fail-Namen
# + erste Exception (statt des vollen flutter-test-Logs):
log="$(mktemp)"; trap 'rm -f "$log"' EXIT
flutter test "$@" >"$log" 2>&1; code=$?
if [ $code -eq 0 ]; then grep -E "All tests passed" "$log" | tail -1; exit 0; fi
echo "== TESTS FAILED (exit $code) =="
awk '/^Failing tests:/{f=1;next} f&&NF{print "  "$0} f&&!NF{exit}' "$log"
awk '/EXCEPTION CAUGHT|TestFailure|Expected:|Actual:|Which:/{s=1} s{print;c++} c>40{exit}' "$log" | head -50
exit $code
```

```markdown
<!-- .claude/skills/test-summary/SKILL.md -->
---
name: test-summary
description: Run the Flutter test suite (or a subset) and get a compact
  pass/fail summary instead of the full log. Use whenever tests need to
  be executed or a change verified.
---
Run `bash scripts/dev/test_summary.sh [args]` instead of raw
`flutter test`. Exit 0 = green. Fall back to the raw log only when the
truncated details are insufficient.
```

---

*Ende des Prompts. Referenz-Implementierungen für 6–15 und 22–24 liegen im
Repo `WasThereSomething` (Branch `feat/v1.3-message-suggestions-feedback`) —
u. a. `test/support/test_app.dart`, `lib/features/splash/application/`,
`lib/core/ui/markdown_editor.dart`, `lib/core/database/app_database.dart`,
`scripts/release/resolve_android_version.sh`, `scripts/dev/test_summary.sh`,
`.claude/skills/test-summary/SKILL.md`,
`docs/operations/android-release-secrets.md`.*
