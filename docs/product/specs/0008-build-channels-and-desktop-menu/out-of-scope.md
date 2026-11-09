# Out of scope: Build channels, separate data and a desktop menu

- A native menu on Windows and Linux. Flutter draws the bar there; a native
  one would need a platform channel per OS (ADR-0016).
- Separate iOS bundle ids per flavor. The data is separated (database and
  keys), but a snapshot installed on an iPhone still replaces the release app.
- Moving documents between flavors; the app's own backup does that.
- Menu entries for the Todo feature (new, find, …): they belong to the app that
  replaces the reference app. The menu is data, so adding them is a change to
  `buildAppMenus`.
- Database migrations for released versions.
- Showing key text in the native macOS menu for entries without a shortcut.
