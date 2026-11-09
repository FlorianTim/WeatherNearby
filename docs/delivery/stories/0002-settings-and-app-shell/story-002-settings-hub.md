# Story: The settings hub

## Metadata

- **Status:** ready
- **Feature:** `docs/product/specs/0005-settings-hub-and-in-app-help/`
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`, slice 2
- **Target release:** 3.2.1 (`now`)
- **Depends on:** story 001

## Goal

Turn the settings page from a first-run wizard step into a hub you can come
back to, and add the debug-only diagnostics view over the settings register.

## Context

The page sits between splash and app and carries a "Continue" button
(SET-001, SET-002). Everything spec 0005, 0006 and 0007 add needs a row on
this page, so it comes before all of them.

## Scope

- Rebuild `settings_page.dart` around `AppSettingsSection` /
  `AppSettingsTile`: language, appearance, help, data and privacy, Pro,
  support, development.
- Remove `onContinue`; route the splash to the app instead of to settings.
- Keep the entry point from the main screen's app bar.
- `settings_diagnostics_page.dart` — read-only list over `AppSettings.all`,
  debug builds only.
- `resetAllSettings(store)` in `core/settings/`.
- Routes for every page the later slices add, wired to placeholders that the
  slices replace.
- The "report the last error" row, shown only while an error is buffered.

## Out of scope

- The pages behind the rows. Stories 003–006 own them.
- Changing the About page.
- Any new setting key.

## Relevant files

- `apps/mobile_app/lib/features/settings/presentation/settings_page.dart`
- `apps/mobile_app/lib/app/router/{routes,app_router}.dart`
- `apps/mobile_app/lib/core/settings/app_settings.dart`
- `apps/mobile_app/lib/core/errors/last_error_buffer.dart`
- `apps/mobile_app/test/a11y/accessibility_test.dart`

## Acceptance criteria

- [ ] The hub has no "Continue" button and no wizard affordance.
- [ ] Language and appearance are changeable inline; a tap takes effect
      immediately.
- [ ] Sections render in the order of SET-005.
- [ ] A section with no available rows renders nothing, heading included.
- [ ] "Report the last error" is absent with no buffered error and present
      after one is recorded; tapping it opens the diagnostics bug mail
      through the launcher seam.
- [ ] The development section and the `/settings/diagnostics` route do not
      exist in release builds.
- [ ] Diagnostics lists every entry of `AppSettings.all` with key, raw stored
      value and default, marks unset entries, and offers no way to edit.
- [ ] `resetAllSettings` removes every registered key and nothing else.
- [ ] The splash routes to the app; `/settings` is reachable from the app bar.

## Test requirements

- `test/features/settings/settings_page_test.dart` — extended
- `test/features/settings/settings_diagnostics_page_test.dart` — new
- `test/core/settings/app_settings_test.dart` — `resetAllSettings`
- `test/smoke_test.dart` — updated for the new startup destination
- `test/a11y/accessibility_test.dart` — extended to the rebuilt hub
- `flutter test`, `melos run analyze`

## Documentation requirements

- ARB entries for every new string, in **both** files.
- `README.md` settings section updated.

## Implementation notes

Keep the page provider-free: values and callbacks in, no `ProviderScope`
needed for a widget test. That property is why the current tests are cheap,
and it is worth preserving through the rebuild.

Use `kReleaseMode` for the development section — a const-folded check, so
the widgets are not merely hidden but absent from a release build.

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present
- [ ] No unauthorized scope expansion
- [ ] Existing structure preserved
