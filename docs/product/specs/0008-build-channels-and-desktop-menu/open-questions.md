# Open questions: Build channels, separate data and a desktop menu

| # | Question | Needed for |
|---|---|---|
| 1 | Does the Gradle patch build? Run `APP_FLAVOR=snapshot flutter build apk --debug --dart-define=APP_FLAVOR=snapshot` on a bootstrapped project and check `applicationId` and the launcher name. | AC-006 |
| 2 | Does `PlatformMenuBar` show the entries and keys on macOS, and does `Cmd+Q` quit? | AC-015 |
| 3 | Should `staging` also get an Android id suffix? Today it only separates data, because it talks to a staging backend rather than being installed next to the release. | CH-005 |
| 4 | iOS: bundle id per flavor through `.xcconfig` build configurations? | non-goal today |
| 5 | Should the Windows/Linux runners be part of the default bootstrap? Today `docs/operations/build-windows.md` adds them by hand (`flutter create --platforms=windows .`). | MENU-002 |
