# Release Checklist

Use this skill before preparing a mobile release.

## Checklist

- Verify app version and build number (`VERSION` and
  `apps/mobile_app/pubspec.yaml` must agree)
- Verify environment configuration
- Confirm release notes
- Run `flutter analyze`
- Run `flutter test`
- Build Android release artifact
- Build iOS release artifact
- Confirm signing material is configured outside the repo
- Update `docs/operations/release-checklist.md` if process changed

## App shell (template 3.2.1+)

The shell is what a store review reaches first. Full list with reasoning:
`docs/operations/release-checklist.md` → "App-Shell".

- In-app data deletion reachable: Settings → Privacy and data → Delete app
  data. **Google Play requires an in-app deletion path**; it lives in
  `lib/features/privacy/`
- Published privacy-policy and data-deletion pages are live under
  `https://lumbrecode.de/apps/<web-slug>/`
- `privacyLocalBody` still tells the truth — it claims local-only storage,
  which stops being true the moment the app syncs, adds an account or sends
  telemetry
- `assets/help/*.md` describes the real app, not the template
- The Pro page shows no price and no buy action unless a working billing
  adapter is in place (ADR-0015)
- The development section is absent from a release build
- Shell tests pass:
  `flutter test test/features/{settings,onboarding,help,privacy,monetization} test/a11y`
