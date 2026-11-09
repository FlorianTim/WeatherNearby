# Story: In-app help documents

## Metadata

- **Status:** ready
- **Feature:** `docs/product/specs/0005-settings-hub-and-in-app-help/`
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`, slice 3
- **Target release:** 3.2.1 (`now`)
- **Depends on:** story 002

## Goal

A bundled, localized manual and FAQ that work offline.

## Scope

- `features/help/presentation/help_document_page.dart` — `HelpDocument` enum
  and the page.
- `assets/help/{manual,faq}_{de,en}.md` plus the pubspec asset entry.
- Routes `/help/manual` and `/help/faq`, wired to the hub rows.
- Links inside a document routed through the allowlisted launcher seam.

## Out of scope

- Search, a table of contents, images (SET out-of-scope).
- Replacing the About page's online FAQ link.
- Content beyond one honest template manual and FAQ.

## Relevant files

- `packages/design_system/lib/src/widgets/app_markdown_view.dart`
- `apps/mobile_app/lib/core/platform/platform_seams.dart`
- `apps/mobile_app/pubspec.yaml`

## Acceptance criteria

- [ ] `HelpDocument.manual` with app language `de` loads
      `assets/help/manual_de.md`; with `en`, the `_en` variant.
- [ ] An app language without a variant loads the `_en` file.
- [ ] A missing asset renders the localized error text; no exception reaches
      the framework.
- [ ] While loading, a progress indicator is shown.
- [ ] An `https` link inside a document calls the launcher seam with that URI.
- [ ] A `javascript:` link is refused by the seam and the refusal is reported
      to the user.
- [ ] Both documents exist in both languages and describe the template
      truthfully — no placeholder prose.

## Test requirements

- `test/features/help/help_document_page_test.dart` — path resolution,
  fallback, error state, link routing, refused scheme
- `flutter test`, `melos run analyze`

## Documentation requirements

- ARB entries for the titles and the load-error message.
- A note in `README.md` that a derived app replaces the help assets.

## Implementation notes

Resolve the asset path from `Localizations.localeOf(context)`, not from the
stored setting — the stored value may be `null` ("follow the system"), and
the rendered document must match what the rest of the UI is showing.

Pass `UrlPolicy.webOnly`, not `appAuthored`: a help document is text, and
text gets edited by translators. Only `http`/`https` may escape it.

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present
- [ ] No unauthorized scope expansion
- [ ] Existing structure preserved
