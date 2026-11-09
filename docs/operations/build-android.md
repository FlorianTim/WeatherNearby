# Android-App bauen

## Voraussetzungen

| Tool           | Version | Zweck                            |
|----------------|---------|----------------------------------|
| Flutter SDK    | 3.44+ | Framework                        |
| Java JDK       | 17      | Android-Toolchain                |
| Android SDK    | API 34+ | Plattform-SDK                    |
| Android Studio | aktuell | SDK-Manager, Emulator (optional) |

### Installation prüfen

```bash
flutter doctor -v
```

Unter **Android toolchain** müssen alle Häkchen grün sein. Falls nicht:

```bash
# Android-Lizenzen akzeptieren
flutter doctor --android-licenses
```

## Projekt initialisieren

Das Template liefert den Dart/Flutter-Code, aber **keine nativen Android-Projektdateien**.
Diese werden einmalig generiert:

Stelle zunächst `ORG` und `PROJECT_NAME` in `project.env` im Repo-Root ein, dann:

**macOS / Linux:**

```bash
./scripts/bootstrap_android.sh
```

**Windows (PowerShell):**

```powershell
.\scripts\bootstrap_mobile.ps1
```

Die Werte in `project.env`:

- `ORG` → deine Android Application-ID (umgekehrte Domain, z. B. `com.example.myapp`)
- `PROJECT_NAME` → Dart-Projektname (snake_case, z. B. `my_app`)

Das erzeugt `apps/mobile_app/android/` mit Gradle-Konfiguration, Manifest und nativen Dateien.

### Dependencies installieren

```bash
cd apps/mobile_app
flutter pub get
```

## Debug-Build starten

```bash
cd apps/mobile_app
flutter run --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

> **Hinweis:** `10.0.2.2` ist im Android-Emulator die Adresse des Host-Rechners.

Alternativ in VS Code: Launch-Konfiguration **"Flutter: mobile_app (dev)"** verwenden.

## Release-Build erzeugen

### APK (zum Testen / Sideloading)

```bash
cd apps/mobile_app
flutter build apk --release --dart-define=APP_FLAVOR=prod
```

Artefakt: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (für Google Play)

```bash
cd apps/mobile_app
flutter build appbundle --release --dart-define=APP_FLAVOR=prod
```

Artefakt: `build/app/outputs/bundle/release/app-release.aab`

## Signierung

Für den Play Store muss die App signiert werden.

### 1. Keystore erzeugen

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

> **Wichtig:** Den Keystore **niemals** ins Repository committen! Er ist per `.gitignore` ausgeschlossen.

### 2. key.properties anlegen

Erstelle `apps/mobile_app/android/key.properties` (ebenfalls gitignored):

```properties
storePassword=<dein-passwort>
keyPassword=<dein-passwort>
keyAlias=upload
storeFile=<absoluter-pfad>/upload-keystore.jks
```

### 3. build.gradle anpassen

In `apps/mobile_app/android/app/build.gradle` die Signing-Config referenzieren
(siehe [Flutter-Doku: Build and release an Android app](https://docs.flutter.dev/deployment/android)).

## Flavors (dev / staging / prod)

Das Template nutzt Dart-Defines für Flavor-Konfiguration:

```bash
# Dev
flutter run --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Staging
flutter run --dart-define=APP_FLAVOR=staging --dart-define=API_BASE_URL=https://staging.example.com

# Prod
flutter build apk --release --dart-define=APP_FLAVOR=prod --dart-define=API_BASE_URL=https://api.example.com
```

Im Code wird der Flavor über `AppConfig.fromEnvironment()` aus `package:app_core` ausgelesen.

## CI/CD

Der Workflow `.github/workflows/build-android.yml` baut automatisch bei:

- Tag `android-v*` (z. B. `android-v1.0.0`)
- Manueller Auslösung (workflow_dispatch)

Er erzeugt APK + App Bundle und lädt sie als GitHub-Artefakte hoch.

## Build-Artefakte (gitignored)

Folgende Verzeichnisse und Dateien entstehen beim Build und gehören **nicht** ins Git:

```
apps/mobile_app/build/              # Alle Build-Ausgaben
apps/mobile_app/android/.gradle/    # Gradle-Cache
apps/mobile_app/android/local.properties  # Lokale SDK-Pfade
apps/mobile_app/android/key.properties    # Signing-Credentials
*.jks / *.keystore                  # Keystores
```

Diese sind bereits in der `.gitignore` des Repositories ausgeschlossen.
