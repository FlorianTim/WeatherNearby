# Story: Privacy and data page

## Metadata

- **Status:** ready
- **Feature:** `docs/product/specs/0005-settings-hub-and-in-app-help/`
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`, slice 4
- **Target release:** 3.2.1 (`now`)
- **Depends on:** story 002

## Goal

One page that answers "what do you store about me?" and gives both ways to
take it back.

## Scope

- `features/privacy/presentation/privacy_page.dart` with four sections:
  local storage, permissions, published documents, danger zone.
- `PermissionOverviewEntry` — the seam the page renders; the template passes
  an empty list.
- Both destructive actions, each with its own confirmation:
  **delete app data** (content) and **reset settings** (register).
- Route `/privacy`, wired to the hub row.
- The "delete app data" row leaves the settings hub.

## Out of scope

- A concrete `PermissionGateway`.
- Backup or export.
- Changing `wipeAllData()` itself.

## Relevant files

- `apps/mobile_app/lib/core/database/app_database.dart` — `wipeAllData()`
- `apps/mobile_app/lib/core/settings/` — `resetAllSettings` (story 002)
- `apps/mobile_app/lib/core/permissions/permission_gateway.dart`
- `packages/app_core/lib/src/app_links.dart`

## Acceptance criteria

- [ ] The page states in the app language that data stays on the device.
- [ ] With an empty permission list, no permission section renders.
- [ ] With entries, each renders with its localized state.
- [ ] Privacy-policy and data-deletion rows open the URLs from
      `AppIdentity.links` through the launcher seam.
- [ ] The privacy-contact row opens a `mailto:` to the privacy mailbox whose
      body carries app version and language and **no** device identifier.
- [ ] "Delete app data" confirms, names the consequence, and on confirm
      clears content while leaving language and theme stored.
- [ ] "Reset settings" confirms separately and on confirm removes every
      registered key while content survives.
- [ ] Both report success afterwards, and providers holding removed data are
      invalidated.
- [ ] Cancelling either dialog changes nothing.

## Test requirements

- `test/features/privacy/privacy_page_test.dart` — both dialogs, both
  outcomes, cancel paths, permission section presence and absence, link and
  mail routing
- `test/core/database/wipe_all_data_test.dart` — unchanged, still passes
- `flutter test`, `melos run analyze`

## Documentation requirements

- ARB entries for every string, in both files.
- `docs/architecture/contracts/05-external-data-ownership.md` — a line that
  the privacy page states the storage promise the contract requires.

## Implementation notes

The two actions must not share a dialog or a message. They have different
blast radii, and a shared confirmation is how a user ends up deleting the
wrong thing.

After "reset settings", the locale and theme providers must be invalidated
so the UI returns to the system default without a restart.

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present
- [ ] No unauthorized scope expansion
- [ ] Existing structure preserved
