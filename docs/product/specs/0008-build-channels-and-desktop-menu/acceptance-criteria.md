# Acceptance criteria: Build channels, separate data and a desktop menu

| ID | Criterion | Requirement | Verified by |
|---|---|---|---|
| AC-001 | `resolve(isProduct: true)` is `prod`, `resolve(isProduct: false)` is `dev`, a named flavor wins, an unknown name falls back | CH-001, CH-002 | `app_flavor_test.dart` |
| AC-002 | `snapshot` and `prerelease` name their database `app_database_<flavor>`; `prod` and `dev` keep `app_database` | CH-003 | `app_flavor_test.dart` |
| AC-003 | A prefixed store writes under the prefix, reads back without it and never sees unprefixed keys | CH-004 | `prefixed_key_value_store_test.dart` |
| AC-004 | Only `dev` and `snapshot` show developer tools | CH-006 | `app_flavor_test.dart` |
| AC-005 | `apply_android_branding.sh` and `Apply-AndroidBranding.ps1` add the id suffix and the label resource to a fresh Android project, twice without change, with the same result | CH-005 | manual, 2026-10-01 |
| AC-006 | A snapshot APK installs next to the release APK | CH-005 | **not verified** |
| AC-007 | A Windows or Linux build shows a menu bar; Go to → Settings opens the settings | MENU-002, MENU-003 | `app_menu_integration_test.dart` |
| AC-008 | `Alt+2` opens the settings from any screen after the splash | MENU-004 | `app_menu_integration_test.dart` |
| AC-009 | `F10` opens the first menu | MENU-004 | `app_menu_host_test.dart` |
| AC-010 | Without a bar (phone) the keys still run the entries, a disabled entry ignores its key | MENU-004 | `app_menu_host_test.dart` |
| AC-011 | A phone shows no menu bar | MENU-002 | `app_menu_integration_test.dart` |
| AC-012 | Quit exists only on a desktop; keys differ on macOS | MENU-003, MENU-004 | `app_menus_test.dart` |
| AC-013 | The splash cannot be left through the menu | MENU-005 | `app_menu_integration_test.dart` |
| AC-014 | The tag `v1.2.0-rc.1` with `VERSION` 1.2.0 makes a pre-release; `v1.2.1-rc.1` stops the run | CH-008 | **not run** (workflow only) |
| AC-015 | The native menu on macOS shows the same entries | MENU-002 | **not verified** |
