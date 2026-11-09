# Runbook: Lokale Entwicklung

## Mobile

```bash
# Set ORG and PROJECT_NAME in project.env, then:
./scripts/bootstrap_mobile.sh
cd apps/mobile_app
flutter pub get
flutter run
```

## API

```bash
cd services/api
dart pub get
dart run bin/server.dart
```

## Validierung

```bash
./scripts/validate.sh
```
