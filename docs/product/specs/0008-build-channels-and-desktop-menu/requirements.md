# Requirements: Build channels, separate data and a desktop menu

## Functional requirements

| ID | Requirement |
|---|---|
| CH-001 | `AppFlavor` has the values `dev`, `snapshot`, `staging`, `prerelease`, `prod`; `AppFlavor.current` is read once from `APP_FLAVOR`. |
| CH-002 | A build that names no flavor is `dev` in debug mode and `prod` in release mode; an unknown name is treated as unnamed. |
| CH-003 | The database file is `AppFlavor.databaseName('app_database')`: plain for `dev` and `prod`, suffixed for the others. |
| CH-004 | Preference keys are prefixed with `AppFlavor.preferencePrefix`; `dev` and `prod` read the keys exactly as before. |
| CH-005 | `snapshot` and `prerelease` builds on Android get the application id suffix `.snapshot` / `.prerelease` and the launcher name `<name> (Snapshot)` / `<name> (Pre-release)`. |
| CH-006 | The settings diagnostics are reachable in debug builds and in `snapshot`; never in `prerelease`, `staging` or `prod` (SET-051). |
| CH-007 | About names the flavor for every build but `prod`. |
| CH-008 | The tag `v<VERSION>-<suffix>` creates a GitHub pre-release; the numbers before the first hyphen must equal `VERSION`. |
| CH-009 | The Android release workflow takes a `flavor` (`prod`, `prerelease`, `snapshot`) and passes it to Dart and to Gradle. |
| MENU-001 | A menu is data (`AppMenuGroup`, `AppMenuItem`) with one handler; the renderers do not define entries. |
| MENU-002 | macOS draws it with `PlatformMenuBar`; Windows, Linux and the web with a Flutter `MenuBar` above the page; Android and iOS draw no bar. |
| MENU-003 | The menu has Go to (Tasks, Settings, Privacy, About), Help (Manual, FAQ) and, on a desktop only, File → Quit. |
| MENU-004 | `Alt+1`…`Alt+4` (macOS `Ctrl+Alt+1`…) go to the screens, `F1` opens the manual, `F10` opens the first menu of a Flutter bar, `Ctrl+Q` (macOS `Cmd+Q`) quits. The keys work with the bar closed and, without a bar, on a hardware keyboard. |
| MENU-005 | While the splash, the startup error page or the intro is shown, the entries that navigate are disabled and their keys do nothing. |

## Quality requirements

- Accessibility: the Flutter bar carries the semantic label `menuLabel`; every
  entry is reachable with the keyboard (F10, arrows, Enter).
- Both languages (de, en) have every new string.

## Constraints

- `AppFlavor` stays pure Dart (`packages/app_core`); the build mode is read
  with `dart.vm.product`.
- Generated files are not edited by hand (`flutter gen-l10n`).

## Data requirements

- No schema change. Only the file name and the preference keys depend on the
  flavor.

## Privacy / Security considerations

- A snapshot or pre-release can never open the release's database (CH-003).
- Developer tools are not reachable by deep link in a pre-release or release:
  the route is not registered (CH-006).

## Testability notes

- Automated: `packages/app_core/test/app_flavor_test.dart`,
  `test/core/menu/app_menu_host_test.dart`, `test/app/menu/app_menus_test.dart`,
  `test/app/app_menu_integration_test.dart`,
  `test/core/storage/prefixed_key_value_store_test.dart`.
- Manual: CH-005 and CH-009 (an Android build per flavor), MENU-002 on macOS
  and on a real Windows or Linux window.

## Traceability

See `acceptance-criteria.md`.
