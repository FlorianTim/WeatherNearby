# Splash animations (Lottie)

The two-phase splash screen uses local Lottie animations. The company phase
plays the official LumbreCode logo reveal; the app phase uses a placeholder
that is replaced per app. Do not load splash animations from external URLs
at runtime.

| File | Used by | Replace? |
|------|---------|----------|
| `lumbrecode_logo_reveal_3s_de_sequential.json` | Company splash phase (LumbreCode), German locale | No — official LumbreCode branding, keep in every app |
| `lumbrecode_logo_reveal_3s_en_sequential.json` | Company splash phase (LumbreCode), all non-German locales | No — official LumbreCode branding, keep in every app |
| `app_splash_placeholder.json` | App splash phase | Yes — per app, derived from the app spec |

The company phase picks the DE or EN variant at runtime based on the active
locale (`Localizations.localeOf`), i.e. the in-app language selection with
the system language as fallback.

Rules:

- Lottie files are bundled as local assets (`assets/animations/` in `pubspec.yaml`).
- Never fetch splash animations from the network.
- Keep files small (< 100 KB) — the splash must not delay startup.
- The splash sequence runs app initialization in parallel
  (see `lib/features/splash/presentation/splash_page.dart`).

## Authoring a splash animation

The splash draws these files **fullscreen**, and the company resp. app name is
part of the animation — the screen deliberately renders no title next to it.
That puts three requirements on a replacement asset:

- **Canvas 1080 × 1920** (portrait 9:16), like the LumbreCode files. The
  animation is scaled with `BoxFit.contain`, so a different aspect ratio only
  costs screen area; it never crops the name.
- **The name is inside the file.** A replacement for
  `app_splash_placeholder.json` has to draw the app name itself — the
  placeholder shows a plain dot precisely because it has no name yet. Keep
  the ARB key
  `splashTitle` in sync: it is the screen-reader label and the text of the
  fallback shown when the animation cannot be loaded.
- **A full-canvas background layer in `#070A10`.** Same colour as the native
  Android splash (`scripts/bootstrap/android-res/values/splash_colors.xml`)
  and as the Flutter surface behind the animation, so neither the handover
  from the system splash nor the letterbox edge is visible.
