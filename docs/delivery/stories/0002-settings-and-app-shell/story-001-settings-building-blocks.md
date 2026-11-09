# Story: Settings building blocks in `design_system`

## Metadata

- **Status:** ready
- **Feature:** `docs/product/specs/0005-settings-hub-and-in-app-help/`
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`, slice 1
- **Target release:** 3.2.1 (`now`)

## Goal

The three widgets every LumbreCode settings surface is built from, in the
shared package instead of inside the example app.

## Context

`settings_page.dart` currently holds a private `_OptionTile` with the
accessibility rules baked into its comments — the exact widget the intro
(spec 0006) and every derived app need next. Copying it is how two versions
of an accessibility rule start to exist.

## Scope

- `packages/design_system/lib/src/widgets/app_option_tile.dart` —
  `AppOptionTile`.
- `packages/design_system/lib/src/widgets/app_settings_tiles.dart` —
  `AppSettingsSection`, `AppSettingsTile`.
- Barrel exports.
- Tests.

## Out of scope

- Any caller. Story 002 is the first.
- A settings *page* widget in the package. Composition stays in the app —
  the section order is a product decision, not a design-system one.
- Localization. Labels arrive as parameters.

## Relevant files

- `apps/mobile_app/lib/features/settings/presentation/settings_page.dart`
- `packages/design_system/lib/design_system.dart`
- `docs/architecture/contracts/07-accessibility.md` rules 1, 3, 9

## Acceptance criteria

- [ ] `AppOptionTile` renders a radio icon **and** a container colour for the
      selected state.
- [ ] Its optional trailing text is wrapped in `ExcludeSemantics`.
- [ ] `AppSettingsSection` renders a heading plus a card around its children.
- [ ] `AppSettingsSection` renders **nothing** when its children list is
      empty.
- [ ] `AppSettingsTile` supports leading icon, title, optional subtitle,
      optional trailing chevron, and a `destructive` flag that switches the
      icon and title to the theme's error colour.
- [ ] No hardcoded colour or font size; everything derives from `Theme`.
- [ ] Every tile is at least 48 dp tall.
- [ ] Renders without overflow at `TextScaler.linear(2.0)` on a phone-sized
      surface.
- [ ] `_OptionTile` is deleted from `settings_page.dart`, which now uses
      `AppOptionTile`.

## Test requirements

- `packages/design_system/test/app_option_tile_test.dart`
- `packages/design_system/test/app_settings_tiles_test.dart`
- Existing `apps/mobile_app/test/features/settings/settings_page_test.dart`
  and `test/a11y/accessibility_test.dart` still pass unchanged in intent.
- `melos run analyze`, `flutter test`

## Documentation requirements

- Doc comments carry the accessibility reasoning that lived in the app.

## Implementation notes

Move the comments with the code. The reason `ExcludeSemantics` wraps the
language code is not obvious, and it is the kind of thing that gets deleted
by someone tidying up.

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present
- [ ] No unauthorized scope expansion
- [ ] Existing structure preserved
