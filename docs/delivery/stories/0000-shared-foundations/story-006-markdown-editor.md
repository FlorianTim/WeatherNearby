# Story: Markdown editor with toolbar and action row

## Metadata

- **Status:** ready
- **Feature:** none — template surface. Plan:
  `docs/delivery/implementation-plans/0000-shared-foundations.md`, component 7
- **Target release:** 3.1.0 (`now`)
- **Depends on:** story 005 (renderer)
- **Reference behaviour:** WasThereSomething spec 0025 (MDE-001..010)

## Goal

The shared text-editing experience: a formatting toolbar above the field and
an action row below, identical in every LumbreCode app.

## Context

This is the headline extraction of slice 0. The product owner named it
explicitly: every app with a free-text field should feel the same. The
reference app is its first consumer (spec 0001, TLD-104), and
`packages/design_system` currently holds three files — theme, spacing, one
section widget.

The temptation will be to build this inside `features/tasks/` because that is
where it is first needed, and extract it later. **Later does not happen**
(ADR-0011, decision 4). It goes in the package now.

## Scope

- `packages/design_system/lib/src/widgets/app_markdown_editor.dart` —
  `AppMarkdownEditor` and `AppMarkdownEditorLabels`.
- The formatting logic as pure string functions, separately testable.
- Export from the barrel.
- Tests.

## Out of scope

- A preview toggle, tables, images, or any element beyond the list below.
  Scope is MDE-001..010 and nothing else.
- Any caller. Spec 0001's slice 4 is the first.
- Persisting undo history. In-memory, per editor session.
- Localization. Labels arrive through `AppMarkdownEditorLabels`.
- A new editor package — explicitly excluded, see notes.

## Relevant files

- `packages/design_system/lib/src/widgets/app_markdown_view.dart` (story 005)
- `packages/design_system/lib/src/tokens/app_spacing.dart`
- `docs/architecture/contracts/07-accessibility.md` rules 1, 2, 4, 5

## Acceptance criteria

**Toolbar (above the field)**

- [ ] Heading toggles `# ` on the current line — adding and removing.
- [ ] Bold wraps `**…**`, italic `*…*`, strikethrough `~~…~~`.
- [ ] Bullet list toggles `- ` on the current line.
- [ ] Clear-line-formatting strips `#`, `**`, `*`, `~~` and a leading `- `
      from the current line.
- [ ] **With a selection**, the syntax wraps the selection and the selection
      is preserved.
- [ ] **Without a selection**, a marker pair is inserted and the cursor is
      placed between the markers.

**Action row (below the field)**

- [ ] Undo and redo step through the session's edit history, disabled when
      unavailable.
- [ ] Reset restores the initially loaded text, disabled when the text is
      unchanged.
- [ ] Save calls `onSave`; passing `onSave: null` **hides** the button.
- [ ] Copy puts the text on the clipboard through an injectable seam.
- [ ] Share calls `onShare`; null hides it.
- [ ] Close calls `onClose`; null hides it.
- [ ] **Copy and share hand over plain text with Markdown markers stripped**,
      so pasted text carries no `**`, `#` or `~~` (MDE-009).

**General**

- [ ] `maxLength`, when set, is enforced by refusing the change with a
      message — **never by silent truncation**.
- [ ] Every icon-only button has a localized tooltip and semantic label from
      `AppMarkdownEditorLabels`.
- [ ] Every button meets 48 dp.
- [ ] No overflow at `TextScaler.linear(2.0)` on a phone-sized surface; the
      toolbar wraps rather than shrinking its targets.
- [ ] `packages/design_system` gains **no** new dependency, and no import of
      any app's l10n.

## Test requirements

- `packages/design_system/test/markdown_formatting_test.dart` — the pure
  string functions: one test per button for insert-at-cursor **and**
  wrap-selection, plus the toggle-off case for heading and bullet, plus
  marker stripping for copy/share.
- `packages/design_system/test/app_markdown_editor_test.dart`:
  - the undo/redo/reset state machine, including disabled states
  - copy via a fake clipboard seam
  - share and save via injected callbacks; null hides each button
  - `maxLength` refuses with a message and does not truncate
  - 200 % text scale without overflow
  - every icon-only button findable by semantic label and ≥ 48 dp
- Commands: `melos run test:flutter`, `flutter analyze`,
  `scripts/dev/quality_gate.sh`.

## Documentation requirements

- Doc comment naming WasThereSomething spec 0025 as the reference behaviour
  and this widget as the **only** editor in any LumbreCode app.
- Doc comment on `AppMarkdownEditorLabels` explaining why strings come from
  outside the package.
- A note that undo history is per session and never persisted.

## Implementation notes

- **No new editor dependency.** A plain `TextField` plus a
  `TextEditingController`, exactly as WasThereSomething did. The formatting is
  string manipulation and is fully unit-testable as pure functions — write it
  that way and the widget test stays small.
- Keep the formatting functions in a separate file with no Flutter import
  beyond `TextEditingValue`, so they can be tested without pumping a widget.
- Undo/redo: a bounded in-memory stack of `TextEditingValue`s. Bound it (e.g.
  100 entries) so a long editing session cannot grow without limit.
- Marker stripping for copy/share is **not** a Markdown-to-HTML conversion. It
  is a plain-text extraction; keep it in the same pure-function file.
- **KI-005:** a test without an explicit locale resolves to `en` while the
  template ARB is `app_de.arb` — but this package takes labels as parameters,
  so its tests pass literals and are locale-independent. That is a feature of
  the design, not an accident.

## Review checklist

- [ ] Scope maintained — MDE-001..010, nothing more
- [ ] Acceptance criteria fulfilled
- [ ] Formatting logic is pure and separately tested
- [ ] No new dependency; no app-l10n import
- [ ] Accessibility assertions present (labels, 48 dp, 200 %)
- [ ] `features/todos/` untouched
