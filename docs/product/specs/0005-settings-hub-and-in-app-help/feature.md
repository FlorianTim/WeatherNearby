# Feature: Settings hub, in-app help and privacy page

## Metadata

- **Status:** specified
- **Target release:** 3.2.1
- **Source:** Product-owner decision 2026-08-26 — align the template's
  settings surface with *WasThereSomething* `release/1.3.1`
- **Created:** 2026-08-26
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`
- **Related specs:** 0006 (app intro), 0007 (purchase placeholder)
- **Requirement prefix:** `SET-`

## Summary

The template's settings page is a first-run language picker with a
"Continue" button. Every app derived from it immediately has to build the
same six things by hand: a hub you can come back to, an in-app manual, an
FAQ, a privacy page, a way to delete your data, and a way to see what the
app actually stored.

This spec makes those part of the template.

```text
Einstellungen
  Sprache          [ Systemsprache ] [ Deutsch ] [ English ]
  Erscheinungsbild [ System ] [ Hell ] [ Dunkel ]

  Hilfe
    Anleitung                                     >
    Häufige Fragen                                >
    App-Einleitung erneut anzeigen                >
  Daten und Datenschutz
    Datenschutz und Daten                         >
  Pro
    Pro-Status                                    >
  Unterstützung
    Über die App und Hilfe                        >
    Letzten Fehler melden          (nur wenn einer vorliegt)
  Entwicklung                      (nur in Debug-Builds)
    Einstellungen-Diagnose                        >
```

## Problem

Three problems, one shape.

**1. The settings page is a wizard step.** It sits between the splash and the
app and carries a "Continue" button, so it cannot be a place you return to.
A derived app either keeps a confusing first-run detour or rebuilds the page.

**2. Help is a web link.** The About page links to a hosted FAQ. That fails on
a plane, fails before the website exists, and fails for a reviewer of a store
submission who wants to see the help without leaving the app.

**3. There is nowhere to explain the data.** The template stores everything
locally, which is its single most reassuring property — and it says so
nowhere in the app. Store review guidelines expect a data-deletion path
reachable *from inside the app*; today the only such path is a row on the
settings page with no context around it.

## Goals

- A settings hub that is a destination, not a step.
- Bundled, localized help documents — manual and FAQ — that work offline.
- One privacy page that explains local storage, lists the permissions the
  app holds, links the published legal documents, and owns both destructive
  actions.
- Building blocks in `packages/design_system`, so a derived app composes its
  own hub instead of copying widgets out of the example.
- A debug-only diagnostics view over the `AppSettings` register — the payoff
  of making settings enumerable in 3.0.0.

## Non-goals

See `out-of-scope.md`.

## Architecture impact

- **New feature folders** `features/help/` and `features/privacy/`, and a
  second page under `features/settings/`. Feature-first structure unchanged
  (ADR-0002).
- **New shared widgets** in `packages/design_system` — no new dependency;
  Markdown rendering reuses `AppMarkdownView`, which already wraps
  `flutter_markdown_plus` behind the library-evaluation contract.
- **Startup contract:** the post-splash destination moves from `/settings`
  to the app itself (or to the intro, spec 0006). The startup coordinator is
  untouched.
- **External data ownership contract:** help documents are app assets, but
  links inside them are treated as untrusted text — they open through the
  scheme-allowlisted launcher seam, never directly.

## Acceptance

See `acceptance-criteria.md`. Requirements are in `requirements.md`.
