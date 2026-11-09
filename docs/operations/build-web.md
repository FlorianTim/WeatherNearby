# Web-App bauen

## Voraussetzungen

| Tool | Version | Zweck |
|------|---------|-------|
| Flutter SDK | 3.44+ | Framework |
| Chrome | aktuell | Debug-Browser |

Keine zusätzlichen SDKs nötig – Flutter bringt den Dart-zu-JavaScript/Wasm-Compiler mit.

### Installation prüfen

```bash
flutter doctor -v
```

Unter **Chrome** muss der Browser erkannt werden.

## Web-Plattform aktivieren

Standardmäßig generiert das Bootstrap-Skript nur Android und iOS.
Für Web muss die Plattform separat hinzugefügt werden:

```bash
cd apps/mobile_app
flutter create --platforms=web .
```

Das erzeugt `apps/mobile_app/web/` mit `index.html`, `manifest.json` und Service-Worker-Konfiguration.

> **Achtung:** Der Ordner existiert im Template bereits und enthält gebrandete
> Favicons sowie die beiden Drift-Dateien (siehe unten). `flutter create`
> überschreibt ihn. Nach einem Neuaufsetzen die Branding-Dateien aus der
> Versionskontrolle zurückholen und die Drift-Assets neu erzeugen.

## Datenbank im Browser: `sqlite3.wasm` und `drift_worker.js`

Der Browser hat kein Dateisystem. Drift betreibt sqlite3 deshalb als
WebAssembly in einem Worker und braucht dafür zwei Dateien **direkt neben der
`index.html`**:

| Datei | Was es ist |
|-------|------------|
| `web/sqlite3.wasm` | sqlite3 als WebAssembly-Build — die Datenbank-Engine |
| `web/drift_worker.js` | `tool/drift_worker_entrypoint.dart`, kompiliert mit `dart compile js` |

`lib/core/database/app_database.dart` verweist über `DriftWebOptions` auf
beide. Fehlt eine davon oder das Options-Argument, scheitert die App **nur zur
Laufzeit und nur im Browser**: Der blockierende Startup-Task `database` wirft,
der Recovery-Screen erscheint, und sein „Erneut versuchen" kann nichts
ausrichten, weil an dem Fehler nichts vorübergehend ist.

Beide Dateien sind Build-Artefakte, werden aber **committet** — `flutter run -d
chrome` liefert `web/` unverändert aus, ein frischer Klon muss also ohne
Extraschritt starten können.

Worker und Client sprechen ein versioniertes Protokoll. Nach **jedem
Drift-Upgrade** neu erzeugen:

```bash
cd apps/mobile_app
dart run tool/sync_web_database_assets.dart
```

Das Skript kopiert `sqlite3.wasm` aus dem aufgelösten `drift`-Paket im
Pub-Cache und kompiliert den Worker aus `tool/drift_worker_entrypoint.dart`.
Liefert ein künftiges Drift-Release das Wasm nicht mehr mit, meldet das Skript
das und nennt die [sqlite3.dart-Releases](https://github.com/simolus3/sqlite3.dart/releases)
als manuelle Quelle.

### Dependencies installieren

```bash
cd apps/mobile_app
flutter pub get
```

## Debug-Build starten

```bash
cd apps/mobile_app
flutter run -d chrome --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://localhost:8080
```

Alternativ für einen bestimmten Port:

```bash
flutter run -d chrome --web-port=8888 --dart-define=APP_FLAVOR=dev
```

In VS Code: Zielgerät auf **Chrome** stellen und F5 drücken.

## Release-Build erzeugen

### Standard (JavaScript)

```bash
cd apps/mobile_app
flutter build web --release --dart-define=APP_FLAVOR=prod --dart-define=API_BASE_URL=https://api.example.com
```

Artefakt-Verzeichnis: `build/web/`

### WebAssembly (experimentell, bessere Performance)

```bash
cd apps/mobile_app
flutter build web --wasm --release --dart-define=APP_FLAVOR=prod
```

> **Hinweis:** Wasm-Builds benötigen einen Server mit korrekten MIME-Types für `.wasm`-Dateien.

## Renderer-Auswahl

Flutter Web unterstützt verschiedene Renderer:

| Renderer | Beschreibung | Empfehlung |
|----------|-------------|------------|
| **CanvasKit** | Skia via WebAssembly, pixelgenaues Rendering | Standard für Desktop-Browser |
| **HTML** | DOM-basiert, kleiner Download | Für besonders kleine Bundle-Größe |

```bash
# Explizit CanvasKit
flutter build web --web-renderer canvaskit --release

# Explizit HTML
flutter build web --web-renderer html --release
```

## Deployment

### Statisches Hosting

Der `build/web/`-Ordner enthält eine vollständige statische Web-App.
Er kann auf jedem Webserver oder statischen Hosting bereitgestellt werden:

**Firebase Hosting:**

```bash
firebase init hosting   # Einmalig: public directory = build/web
firebase deploy
```

**Nginx / Apache:**

Den Inhalt von `build/web/` in das Document-Root kopieren.

**GitHub Pages:**

```bash
# Beispiel mit dem gh-pages-Paket
cd apps/mobile_app
flutter build web --release --base-href "/repo-name/"
# Inhalt von build/web/ in den gh-pages-Branch deployen
```

> **Wichtig:** Bei Subpfaden `--base-href` korrekt setzen, damit Routing funktioniert.

### SPA-Routing

Für clientseitiges Routing (z. B. Navigator 2.0) muss der Server so konfiguriert werden,
dass alle Pfade auf `index.html` umgeleitet werden (Fallback-Route).

## Flavors (dev / staging / prod)

Gleich wie bei anderen Plattformen – über Dart-Defines:

```bash
# Dev (lokal)
flutter run -d chrome --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://localhost:8080

# Prod (Build)
flutter build web --release --dart-define=APP_FLAVOR=prod --dart-define=API_BASE_URL=https://api.example.com
```

## CORS beachten

Bei Web-Apps gelten Browser-Sicherheitsrichtlinien. Das Backend muss CORS-Header setzen,
damit die Web-App API-Anfragen stellen darf:

```
Access-Control-Allow-Origin: https://meine-app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

Während der Entwicklung kann `--web-browser-flag="--disable-web-security"` als Workaround dienen
(nur lokal, niemals in Produktion).

## Build-Artefakte (gitignored)

Folgende Verzeichnisse entstehen beim Build und gehören **nicht** ins Git:

```
apps/mobile_app/build/web/         # Kompilierte Web-App (JS/Wasm, Assets, index.html)
apps/mobile_app/build/             # Alle Build-Ausgaben generell
```

Diese sind bereits über die allgemeine `build/`-Regel in der `.gitignore` ausgeschlossen.

### web/-Verzeichnis selbst

Das generierte `apps/mobile_app/web/`-Verzeichnis (mit `index.html`, `manifest.json` etc.)
**gehört ins Git** – es ist die Startvorlage, die bei `flutter create --platforms=web` erzeugt wird
und die du anpassen wirst (Favicon, Title, Meta-Tags, PWA-Konfiguration).

## Bekannte Einschränkungen

- Nicht alle Flutter-Plugins unterstützen Web (z. B. kamera-, sensor-basierte Plugins)
- Performance-intensive Animationen können im Browser langsamer sein als nativ
- Dateigröße: CanvasKit lädt ~2 MB Skia-Wasm; HTML-Renderer ist deutlich kleiner
- SEO ist eingeschränkt, da Flutter Web eine Single-Page-App rendert
- Hot Reload funktioniert auf Web, Hot Restart ist aber üblicher
