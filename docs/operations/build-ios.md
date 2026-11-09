# iOS-App bauen

## Voraussetzungen

| Tool | Version | Zweck |
|------|---------|-------|
| Flutter SDK | 3.44+ | Framework |
| Xcode | 15+ | iOS-Toolchain, Simulator |
| CocoaPods | aktuell | Dependency-Manager für iOS |
| macOS | Ventura+ | Pflicht für iOS-Entwicklung |

> **Wichtig:** iOS-Builds sind nur auf macOS möglich. Weder Windows noch Linux können iOS-Apps kompilieren.

### Installation prüfen

```bash
flutter doctor -v
```

Unter **Xcode** müssen Xcode und die Command Line Tools erkannt werden.
Unter **CocoaPods** muss `pod` installiert sein:

```bash
# Falls nicht vorhanden:
sudo gem install cocoapods
```

## Projekt initialisieren

Stelle zunächst `ORG` und `PROJECT_NAME` in `project.env` im Repo-Root ein, dann:

**macOS:**

```bash
./scripts/bootstrap_ios.sh
```

Das erzeugt `apps/mobile_app/ios/` mit Xcode-Projekt, Runner-Target und Podfile.

### Dependencies installieren

```bash
cd apps/mobile_app
flutter pub get
cd ios && pod install && cd ..
```

## Debug-Build starten

### Simulator

```bash
# Verfügbare Simulatoren anzeigen
flutter devices

# App auf Simulator starten
cd apps/mobile_app
flutter run --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://localhost:8080
```

### Physisches Gerät

1. iPhone per USB anschließen
2. Dem Gerät vertrauen
3. In Xcode: **Signing & Capabilities** → Team auswählen (Apple Developer Account nötig)
4. Starten:

```bash
flutter run -d <device-id> --dart-define=APP_FLAVOR=dev
```

## Release-Build erzeugen

### Ohne Signierung (CI / Test)

```bash
cd apps/mobile_app
flutter build ios --release --no-codesign --dart-define=APP_FLAVOR=prod
```

Artefakt: `build/ios/iphoneos/Runner.app`

### Mit Signierung (App Store)

```bash
cd apps/mobile_app
flutter build ipa --release --dart-define=APP_FLAVOR=prod
```

Artefakt: `build/ios/ipa/my_app.ipa`

Voraussetzung: Gültiges Signing-Zertifikat und Provisioning-Profil in Xcode konfiguriert.

## Signierung

### Lokale Entwicklung

1. **Xcode** → `ios/Runner.xcworkspace` öffnen
2. **Signing & Capabilities** → Team auswählen → Automatic Signing aktivieren
3. Flutter übernimmt die Konfiguration beim Build

### CI/CD (GitHub Actions)

Die CI-Signierung wird über GitHub Secrets konfiguriert. Siehe [ios-signing.md](ios-signing.md) für Details.

Benötigte Secrets:

| Secret | Inhalt |
|--------|--------|
| `BUILD_CERTIFICATE_BASE64` | Signing-Zertifikat (.p12, Base64) |
| `P12_PASSWORD` | Passwort des Zertifikats |
| `BUILD_PROVISION_PROFILE_BASE64` | Provisioning-Profil (Base64) |
| `KEYCHAIN_PASSWORD` | Temporäres Keychain-Passwort |

> **Niemals** Zertifikate, Profile oder Passwörter ins Repository committen!

## Flavors (dev / staging / prod)

Gleich wie bei Android – über Dart-Defines:

```bash
# Dev
flutter run --dart-define=APP_FLAVOR=dev --dart-define=API_BASE_URL=http://localhost:8080

# Staging
flutter run --dart-define=APP_FLAVOR=staging --dart-define=API_BASE_URL=https://staging.example.com

# Prod
flutter build ipa --release --dart-define=APP_FLAVOR=prod --dart-define=API_BASE_URL=https://api.example.com
```

## CI/CD

Der Workflow `.github/workflows/build-ios.yml` baut automatisch bei:
- Tag `ios-v*` (z. B. `ios-v1.0.0`)
- Manueller Auslösung (workflow_dispatch)

Er erzeugt einen unsignierten iOS-Build und lädt ihn als GitHub-Artefakt hoch.

## Build-Artefakte (gitignored)

Folgende Verzeichnisse und Dateien entstehen beim Build und gehören **nicht** ins Git:

```
apps/mobile_app/build/                          # Alle Build-Ausgaben
apps/mobile_app/ios/Pods/                       # CocoaPods-Dependencies
apps/mobile_app/ios/.symlinks/                  # Plugin-Symlinks
apps/mobile_app/ios/Flutter/ephemeral/          # Generierte Flutter-Dateien
apps/mobile_app/ios/Flutter/App.framework       # Build-Artefakt
apps/mobile_app/ios/Flutter/Flutter.framework   # Framework-Kopie
apps/mobile_app/ios/Flutter/flutter_assets/     # Asset-Bundle
apps/mobile_app/ios/Runner/GeneratedPluginRegistrant.*
*.xcuserstate                                   # Xcode Benutzer-State
ios/DerivedData/                                # Xcode Build-Cache
*.mobileprovision                               # Provisioning-Profile
*.p12                                           # Signing-Zertifikate
```

Diese sind bereits in der `.gitignore` des Repositories ausgeschlossen.

## Bekannte Einschränkungen

- iOS-Entwicklung ist auf macOS beschränkt
- Für physische Geräte ist ein Apple Developer Account nötig (kostenlos für Entwicklung, 99 $/Jahr für Vertrieb)
- CocoaPods kann bei der ersten Installation langsam sein (`pod setup`)
- Simulator-Builds laufen auf Apple Silicon nativ, Intel-Macs emulieren ARM
