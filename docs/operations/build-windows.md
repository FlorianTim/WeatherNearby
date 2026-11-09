# Windows-App bauen

## Voraussetzungen

| Tool | Version | Zweck |
|------|---------|-------|
| Flutter SDK | 3.44+ | Framework |
| Visual Studio | 2022+ | C++-Desktop-Toolchain |
| Windows 10/11 | 1903+ | Zielplattform |

### Visual Studio Workloads

Bei der Installation von Visual Studio (nicht VS Code!) müssen folgende Workloads aktiviert sein:

- **Desktopentwicklung mit C++**
  - Enthält: MSVC-Compiler, Windows SDK, CMake

> **Hinweis:** Die kostenlose **Community Edition** reicht aus.

### Installation prüfen

```powershell
flutter doctor -v
```

Unter **Develop for Windows** müssen Visual Studio und die C++-Tools erkannt werden.

## Menüleiste und Tastatur

Auf Windows (und Linux) zeichnet Flutter die Menüleiste selbst — dort gibt es
kein natives Menü. Sie hat **Datei → Beenden** (`Strg+Q`), **Gehe zu**
(`Alt+1` … `Alt+4`) und **Hilfe** (`F1` öffnet das Handbuch); `F10` öffnet das
erste Menü, danach bedienen die Pfeiltasten es. Die Tasten gelten auch bei
geschlossener Leiste. Auf macOS ist es das Menü des Systems. Siehe
`docs/product/specs/0008-build-channels-and-desktop-menu/`.

## Windows-Plattform aktivieren

Standardmäßig generiert das Bootstrap-Skript nur Android und iOS.
Für Windows muss die Plattform separat hinzugefügt werden:

```powershell
cd apps/mobile_app
flutter create --platforms=windows .
```

Das erzeugt `apps/mobile_app/windows/` mit CMake-Konfiguration und Runner-Projekt.

### Dependencies installieren

```powershell
cd apps/mobile_app
flutter pub get
```

## Debug-Build starten

```powershell
cd apps/mobile_app
flutter run -d windows --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://localhost:8080
```

Alternativ in VS Code: Zielgerät auf **Windows (desktop)** stellen und F5 drücken.

## Release-Build erzeugen

```powershell
cd apps/mobile_app
flutter build windows --release --dart-define=APP_FLAVOR=prod
```

Artefakt-Verzeichnis: `build/windows/x64/runner/Release/`

Darin liegt die fertige `.exe` samt aller benötigten DLLs.

## Verteilung

### Manuell

Das komplette `Release/`-Verzeichnis als ZIP weitergeben. Alle DLLs müssen enthalten sein.

### MSIX-Paket (Microsoft Store)

Für eine saubere Installation und Store-Verteilung:

1. Dev-Dependency hinzufügen:

   ```powershell
   cd apps/mobile_app
   flutter pub add --dev msix
   ```

2. Konfiguration in `pubspec.yaml` ergänzen:

   ```yaml
   msix_config:
     display_name: My App
     publisher_display_name: My Company
     identity_name: com.example.myapp
     msix_version: 1.0.0.0
     logo_path: assets/images/app_icon.png
   ```

3. MSIX erzeugen:

   ```powershell
   dart run msix:create
   ```

## Flavors (dev / staging / prod)

Gleich wie bei Android – über Dart-Defines:

```powershell
# Dev
flutter run -d windows --dart-define=APP_FLAVOR=dev

# Prod
flutter build windows --release --dart-define=APP_FLAVOR=prod
```

## Build-Artefakte (gitignored)

Folgende Verzeichnisse entstehen beim Build und gehören **nicht** ins Git:

```
apps/mobile_app/build/                              # Alle Build-Ausgaben
apps/mobile_app/windows/flutter/ephemeral/          # Generierte Flutter-Bindings
apps/mobile_app/windows/flutter/generated_plugin_registrant.cc
apps/mobile_app/windows/flutter/generated_plugin_registrant.h
apps/mobile_app/windows/flutter/generated_plugins.cmake
```

Diese sind bereits in der `.gitignore` des Repositories ausgeschlossen.

## Bekannte Einschränkungen

- Windows-Builds laufen nur auf Windows (kein Cross-Compile)
- Keine CI-Unterstützung im Template vorkonfiguriert (GitHub Actions Hosted Runner ist `windows-latest`)
- Plugins, die native C++-Abhängigkeiten haben, benötigen ggf. zusätzliche CMake-Konfiguration
