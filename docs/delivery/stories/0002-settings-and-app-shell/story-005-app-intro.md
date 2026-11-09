# Story: App intro (onboarding)

## Metadata

- **Status:** ready
- **Feature:** `docs/product/specs/0006-onboarding-and-app-intro/`
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`, slice 5
- **Target release:** 3.2.1 (`now`)
- **Depends on:** story 002

## Goal

A five-page intro on first start, replayable from settings, that also carries
the language and appearance choice.

## Scope

- `app.onboardingCompleted` in the `AppSettings` register.
- `features/onboarding/application/onboarding_notifier.dart`.
- `features/onboarding/presentation/onboarding_page.dart` — pager, skip,
  indicator, the language and appearance step.
- Route `/intro`; the splash routes into it on first start.
- The "show the intro again" row on the settings hub.
- `TestAppHarness` seeds the flag as completed by default.

## Out of scope

- Any permission request (forbidden, ONB-013).
- A setup assistant, a feature tour, a "what's new" screen.
- Animations or Lottie content.

## Relevant files

- `apps/mobile_app/lib/app/router/app_router.dart` — the splash's
  `onFinished`
- `apps/mobile_app/lib/core/settings/app_settings.dart`
- `apps/mobile_app/test/support/test_app.dart`
- `packages/design_system/lib/src/widgets/app_option_tile.dart`

## Acceptance criteria

- [ ] No stored flag → the intro follows the splash; flag `true` → the app
      does.
- [ ] A fatal startup failure still wins over the intro.
- [ ] No intermediate loading screen between splash and intro.
- [ ] Skip is on every page and has the same effect as finishing.
- [ ] The last page's primary action is labelled as a start action.
- [ ] Swiping and the buttons stay in sync.
- [ ] The language and appearance page changes the intro itself immediately,
      and the choice survives leaving it.
- [ ] Finishing and skipping both persist the flag.
- [ ] A store whose write throws still lets the user out, with no error
      surfacing.
- [ ] The settings row opens the intro although the flag is `true`, and
      finishing it again changes nothing else.
- [ ] No permission gateway is called anywhere in the flow.
- [ ] Renders without overflow at `TextScaler.linear(2.0)`.

## Test requirements

- `test/features/onboarding/onboarding_page_test.dart` — flow, skip, finish,
  failing store, language switch
- `test/features/onboarding/onboarding_routing_test.dart` — all three
  destinations
- `test/core/settings/app_settings_test.dart` — flag round-trip and
  degradation
- `test/smoke_test.dart` — updated
- `flutter test`, `melos run analyze`

## Documentation requirements

- ARB entries for all five pages, in both files.
- `README.md` — the startup flow diagram.

## Implementation notes

Read the flag synchronously through `SettingDef.read`; `bootstrap()` has
already installed the persistent store by the time the splash finishes, so
the routing decision needs no `await` (ONB-004).

Wrap the flag write in a `try`/`catch` that swallows: a storage failure must
never trap a user inside a modal flow (ONB-031).

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present
- [ ] No unauthorized scope expansion
- [ ] Existing structure preserved
