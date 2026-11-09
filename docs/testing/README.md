# Flutter Web App Testing & Documentation

This document describes the testing setup for the Flutter web application.

## Quick Start

### 1. Build Web App

```bash
# Using Docker (no local SDK required)
./scripts/build.sh web

# Or locally
cd apps/mobile_app
flutter build web --release
```

### 2. Start Development Server

```bash
# Local development server
./scripts/test_web_app.sh          # Linux/Mac
.\scripts\test_web_app.ps1         # Windows

# Or manually
cd apps/mobile_app
flutter run -d web-server --web-port=8080
```

Access the app at: **http://localhost:8080**

### 3. Run Integration Tests

```bash
# Unit tests
./scripts/build.sh test

# Integration tests (Docker)
./scripts/build.sh integration-test

# Integration tests (locally with Chrome)
cd apps/mobile_app
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_screenshots_test.dart \
  -d chrome
```

## Test Structure

```
apps/mobile_app/
├── test/                      # Unit tests
│   └── smoke_test.dart
├── integration_test/          # Integration tests
│   ├── app_screenshots_test.dart  # Screenshot-capturing main-flow test
│   └── app_flow_test.dart     # Full app flow test
└── test_driver/               # Test drivers
    └── integration_test.dart  # Driver with screenshot capture
```

## Integration Tests with Screenshots

The integration tests automatically capture screenshots during execution.

### Running with Screenshots

```bash
cd apps/mobile_app

# Run tests and capture screenshots
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_screenshots_test.dart \
  -d chrome --headless
```

Screenshots are saved to: `apps/mobile_app/test_results/screenshots/`

### Generate Test Documentation

After running tests with screenshots:

```bash
./scripts/automation/integration-test/generate_test_docs.sh      # Linux/Mac
.\scripts\automation\integration-test\generate_test_docs.ps1     # Windows
```

This generates: `docs/testing/integration-test-report.md` with all screenshots.

## Test Coverage

### Unit Tests
- ✅ Widget tests for UI components
- ✅ Business logic tests
- ✅ Smoke tests for app initialization

### Integration Tests
- ✅ Full user flows
- ✅ Counter functionality
- ✅ UI element verification
- ✅ Tooltip interactions
- ✅ State management

## Continuous Integration

The CI pipeline runs:

1. **Format Check** — Dart code formatting
2. **Analyze** — Static analysis (mobile + API)
3. **Unit Tests** — All test/ files
4. **Integration Tests** — Full app flows (Docker)

```bash
# Run all CI checks locally
./scripts/build.sh ci
```

## Manual Testing Checklist

When testing the web app manually:

- [ ] App loads without errors
- [ ] Counter increments on button click
- [ ] UI is responsive on different screen sizes
- [ ] No console errors in browser DevTools
- [ ] Icons and fonts load correctly
- [ ] Navigation works smoothly

## Screenshot Guidelines

For documentation purposes:

1. **Viewport**: Use 1280x720 for consistency
2. **Browser**: Chrome or Edge (latest)
3. **Theme**: Test both light and dark modes
4. **States**: Capture initial, interactive, and final states

## Troubleshooting

### WebDriver Issues

If `flutter drive` fails with "Unable to start a WebDriver session":

1. Install ChromeDriver:
   ```bash
   # Mac
   brew install chromedriver

   # Windows (via Chocolatey)
   choco install chromedriver

   # Or download from:
   https://chromedriver.chromium.org/
   ```

2. Start ChromeDriver:
   ```bash
   chromedriver --port=4444
   ```

3. Run tests in another terminal

### Build Failures

If web build fails:

```bash
cd apps/mobile_app
flutter clean
flutter pub get
flutter build web --release
```

### Port Already in Use

If port 8080 is occupied:

```bash
# Use different port
flutter run -d web-server --web-port=8081
```

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Flutter Web Testing](https://flutter.dev/to/integration-test-on-web)
- [Integration Test Package](https://pub.dev/packages/integration_test)
