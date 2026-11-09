# Story: Markdown renderer in `packages/design_system`

## Metadata

- **Status:** ready
- **Feature:** none — template surface. Plan:
  `docs/delivery/implementation-plans/0000-shared-foundations.md`, component 6
- **Target release:** 3.1.0 (`now`)

## Goal

One Markdown renderer with one set of defaults, shared by every LumbreCode
app, wrapping the package so a swap touches one file.

## Context

The reference app stores task bodies as Markdown source, verbatim (spec 0001,
TLD-102). It needs to render them, and so will every other app with a
free-text field.

Two things make this a wrapper rather than a direct dependency:

- **Library-evaluation contract:** a UI package with API drift must be
  wrapped behind an adapter, enforced by an encapsulation test.
- **Security:** a body may have arrived in an imported document. Links inside
  it must go through the allowlisted URL seam (story 003), never straight to
  the platform.

## Scope

- `packages/design_system/lib/src/widgets/app_markdown_view.dart` —
  `AppMarkdownView`.
- `flutter_markdown_plus` as a dependency of `packages/design_system`
  (**new**).
- Export from the barrel.
- Tests, including an encapsulation test.

## Out of scope

- The editor. Story 006 depends on this one.
- Any caller. Spec 0001's slice 4 is the first.
- Rendering images, HTML blocks or tables beyond the package default. Nothing
  in 3.1.0 needs them, and each is a decision.
- Converting Markdown to HTML or to plain text. The editor's copy/share
  behaviour (story 006) owns plain-text extraction.

## Relevant files

- `packages/design_system/lib/design_system.dart`
- `packages/design_system/lib/src/theme/app_theme.dart` — styling comes from
  the theme, not from hardcoded values
- `apps/mobile_app/lib/core/platform/platform_seams.dart` — the allowlisted
  `LaunchUrl` (story 003)
- `docs/architecture/contracts/06-library-evaluation.md`

## Acceptance criteria

- [ ] `AppMarkdownView(source: …)` renders headings, bold, italic,
      strikethrough, bullet lists and links.
- [ ] `contentType` defaults to `text/markdown; charset=utf-8`.
- [ ] When `contentType` is `text/plain`, the source renders **literally** —
      `**not bold**` shows its asterisks and no Markdown is applied.
- [ ] An unrecognized `text/*` content type renders as plain text.
- [ ] A link tap calls the injected `onLinkTap` callback and **never** reaches
      a platform plugin directly.
- [ ] With `onLinkTap` null, links render but are not tappable.
- [ ] **No network request is made** for any input — asserted by a test that
      fails if any HTTP client is constructed.
- [ ] Text styles derive from the ambient `Theme`, with no hardcoded colour or
      font size.
- [ ] Renders without overflow at `TextScaler.linear(2.0)` on a phone-sized
      surface.
- [ ] An encapsulation test asserts `flutter_markdown_plus` is imported by
      exactly one file in the workspace: this widget.

## Test requirements

- `packages/design_system/test/app_markdown_view_test.dart`:
  - each supported element renders
  - `text/plain` renders literally
  - link tap routes to `onLinkTap`, and a null callback makes links inert
  - no HTTP client is constructed for any input
  - 200 % text scale without overflow
- `packages/design_system/test/package_encapsulation_test.dart` — scans
  `lib/` across the workspace and fails on any `flutter_markdown_plus` import
  outside the adapter.
- Commands: `melos run test:flutter`, `flutter analyze`,
  `scripts/dev/quality_gate.sh`.

## Documentation requirements

- Doc comment stating the wrapper's purpose: one renderer, one set of
  defaults, one file to change on a swap.
- Doc comment on `onLinkTap` stating that callers must route it through the
  scheme-allowlisted seam and **must not** call `url_launcher` directly.
- The dependency justification (purpose, licence, maintenance, platforms,
  network, abstraction, removal path) goes in the PR — required by the
  library-evaluation contract.

## Implementation notes

- **Resolve `flutter_markdown_plus` against the existing tree before adding
  it** (library-evaluation rule 10). This repository carries the KI-001
  analyzer ceiling (`analyzer 8.4.0`, `custom_lint 0.8.1`). The package is
  runtime-only and should not move it — verify, do not assume.
- Licence BSD-3. It is the maintained continuation of the discontinued
  first-party `flutter_markdown`.
- **Verify there is no network access**: image support that fetches a remote
  URL must not be enabled. The contract forbids fetching anything from an
  imported document, including for a preview.
- **Removal path**, for the PR: replace the widget's body with a
  `SelectableText` of the source. Markdown was chosen partly because the raw
  source stays readable — which is exactly what the interop guide says to do
  when a receiver cannot render it (§10.10).
- `design_system` must not import the app's l10n. Nothing here needs a string.

## Review checklist

- [ ] Scope maintained — renderer only, no editor
- [ ] Acceptance criteria fulfilled
- [ ] Tests present and passing, including the encapsulation test
- [ ] Dependency justified in the PR against all eleven contract points
- [ ] No network access
- [ ] `features/todos/` untouched
