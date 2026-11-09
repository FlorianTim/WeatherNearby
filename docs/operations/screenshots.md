# Producing Screenshots

Two routes, for two different purposes.

| | Manual (`capture`) | Automated (`auto`) |
|---|---|---|
| Source | a running device or emulator | the screenshot integration test |
| Control over the screen | you drive the app | the test drives the app |
| Reproducible | no | yes — same flow, same sizes, every run |
| Needs | adb + a device | Docker |
| Good for | store listings, bug reports, quick visuals | release documentation, regression evidence |

Everything lands under `design/screenshots/<profile>/<name>.png`.

## Manual capture

1. Get a device up. Either connect a phone with USB debugging enabled, or:

   ```bash
   scripts/dev/emulator.sh start
   ```

   `start` returns only once the device is genuinely usable, not just visible.

2. Install and run the app:

   ```bash
   scripts/dev/adb.sh run
   ```

3. Capture. `--delay` gives you time to navigate to the right screen after
   hitting enter:

   ```bash
   scripts/dev/screenshots.sh capture 01-greeting --delay 3
   scripts/dev/screenshots.sh capture 02-settings --delay 3
   ```

   The subfolder defaults to the device model (`pixel_7`, `sdk_gphone64_x86_64`,
   …), so shots from different form factors do not overwrite each other. Force
   one with `--profile phone`.

4. Check what you have:

   ```bash
   scripts/dev/screenshots.sh list
   ```

For a clean, notification-free status bar (worth it for store listings), enable
demo mode before capturing:

```bash
scripts/dev/adb.sh shell settings put global sysui_demo_allowed 1
scripts/dev/adb.sh shell am broadcast -a com.android.systemui.demo -e command enter
scripts/dev/adb.sh shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0900
scripts/dev/adb.sh shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
# afterwards:
scripts/dev/adb.sh shell am broadcast -a com.android.systemui.demo -e command exit
```

## Automated capture

```bash
scripts/dev/screenshots.sh auto
```

This runs `integration_test/app_screenshots_test.dart` through the
`mobile-integration-test-web` container for every profile in
`docs/public-site/screenshot-profiles.json` (phone portrait 390×844,
tablet 1024×768, desktop 1440×900), then copies the results from
`apps/mobile_app/test_results/screenshots/` into `design/screenshots/`.

The GitHub workflow also runs for relevant pull requests. PR screenshots and
reports are available as a seven-day `integration-report` Actions artifact.
Pushes to `main` and manual runs retain the existing screenshot commit and
handbook release steps. The workflow has a 30-minute limit; each profile has
an eight-minute limit, and each screenshot request has a 30-second limit. A driver run fails
if a screenshot is missing or navigation does not reach its expected page.

### Adding a screenshot step

Edit `apps/mobile_app/integration_test/app_screenshots_test.dart` and add a
`_shot(...)` call at the point in the flow you want captured:

```dart
await tester.tap(find.byIcon(Icons.settings));
await tester.pumpAndSettle();
await _shot(binding, '03-settings', 'Settings', 'Theme and language options');
```

The name becomes the file name, title and description end up in the generated
test report (`scripts/automation/integration-test/generate_test_docs.sh`).

### Adding a screen size

Add an entry to `docs/public-site/screenshot-profiles.json`. That is the
whole change: the runner reads the file and passes `SCREEN_WIDTH` and
`SCREEN_HEIGHT` in as dart-defines, so the test carries no list of its own.

The file is a **shared LumbreCode contract**
(`schemas/screenshots/v1/profiles.schema.json`). The web template's
Playwright capture reads the same profiles and writes into the same
`design/screenshots/<profile>/` layout, so a guide can reference a shot
without knowing which stack produced it.

### Referencing a screenshot from the documentation

Declare it in `docs/public-site/screenshots.yaml`, then use
`{{screenshot:<id>}}` in a guide or an FAQ answer. See
`docs/operations/help-content.md`.

## Store sizes

Google Play wants at least two phone screenshots, 16:9 or 9:16, with each edge
between 320 px and 3840 px. The Pixel emulator profiles produce 1080×2400,
which qualifies as is. The App Store requires 6.7" (1290×2796) and 5.5"
(1242×2208) — create matching AVDs when you need them:

```bash
scripts/dev/emulator.sh create store-67 --api 35 --device pixel_7_pro
scripts/dev/emulator.sh create --devices # list all hardware profiles
```

## Cleaning up

```bash
scripts/dev/screenshots.sh clean
```

`design/screenshots/` is a working directory. Commit only the shots that are
actually referenced by docs or store metadata.
