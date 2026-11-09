# Branding assets (app icon layers)

Source images for `flutter_launcher_icons` (see `../../flutter_launcher_icons.yaml`).
The two adaptive layers are **build-time inputs only** and are not listed under
`flutter: assets:` in `pubspec.yaml`; the two icon PNGs are bundled because the
splash screen falls back to them when a Lottie asset cannot be loaded.

| File | Used as | Replace per app? |
|------|---------|------------------|
| `../images/app_icon.png` | `image_path` (Android legacy, iOS, web) and app-phase splash fallback | Yes |
| `lumbrecode_adaptive_foreground_432.png` | `adaptive_icon_foreground` (Android 8+) | Yes |
| `lumbrecode_monochrome_432.png` | `adaptive_icon_monochrome` (Android 13+ themed icons) | Yes |
| `lumbrecode_icon_512.png` | Company-phase splash fallback (bundled at runtime) | No — company branding |

Brand colors: background `#070A10`, accent `#FF9F1C`.

## Regenerating platform icons

`android/` and `ios/` are not committed in this template — the bootstrap script
creates them. After every bootstrap:

```bash
cd apps/mobile_app && dart run flutter_launcher_icons
```

This also regenerates `web/icons/` and `web/favicon.png`. The versions
committed in the template come from the icon pack and are hand-tuned per size
(the maskable variants respect the PWA safe zone); the generator's output is
plain downscaling, so it will look slightly different after the first run with
a new app icon.

## Requirements for replacements

- `app_icon.png`: 1024x1024, **opaque** (iOS rejects alpha in the store icon).
- Adaptive/monochrome layers: 432x432 with alpha; keep the artwork inside the
  central 66% safe zone — Android masks the outer ring.
- The monochrome layer must be a single-color silhouette (alpha carries the
  shape); Android tints it with the system theme color.

The editable masters (SVG + 1024px PNG + Play Store 512px) live in
`design/source/branding/`, versioned via `design/manifests/lumbrecode-icon.yaml`.
