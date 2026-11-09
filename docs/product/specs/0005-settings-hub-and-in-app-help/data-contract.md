# Data contract: Settings hub, in-app help and privacy page

## Stored data

No database change. One new key in the `AppSettings` register; the other two
new keys belong to spec 0007.

| Key | Type | Encoding | Default |
|---|---|---|---|
| `app.locale` | `Locale?` | language code, `""` = follow system | `null` (existing) |
| `app.themeMode` | `ThemeMode` | enum **name** | `system` (existing) |

`resetAllSettings(store)` removes every key in `AppSettings.all`. It is
defined over the register, not over a hand-written list — a setting added
later is reset automatically.

## The two destructive actions

They are deliberately separate, because they have different blast radii:

| Action | Clears | Keeps |
|---|---|---|
| Delete app data | every content table, children before parents, in one transaction | every setting |
| Reset settings | every key in `AppSettings.all` | all content |

Neither touches anything outside the app sandbox. Device contacts,
calendars, files and the platform's own settings are never modified — that
promise is what the privacy page is allowed to make.

## Help assets

```text
apps/mobile_app/assets/help/
  manual_de.md   manual_en.md
  faq_de.md      faq_en.md
```

- Path rule: `assets/help/<document>_<languageCode>.md`.
- Resolution: the active app locale's language code if a variant exists,
  otherwise `en`.
- Content type: Markdown (`text/markdown; charset=utf-8`), rendered by
  `AppMarkdownView`.
- Images are **not** part of this contract. A help document that references
  one renders nothing in its place rather than an error box.

## Permission overview

The privacy page does not query permissions itself; it renders what it is
given:

```dart
class PermissionOverviewEntry {
  final IconData icon;
  final String label;
  final PermissionState state;   // core/permissions/permission_gateway.dart
}
```

The template passes an empty list. A derived app builds the list from its own
gateways, which keeps the page free of any plugin dependency.

## Mail

The privacy-contact mail reuses `AppLinks.mailto(SupportMailbox.privacy, …)`.
Body content is limited to app version and app language. No device model, no
identifiers, no user content — a privacy enquiry must not itself leak data.
