# Feature: App intro (onboarding)

## Metadata

- **Status:** specified
- **Target release:** 3.2.1
- **Source:** Product-owner decision 2026-08-26 — align the template's
  settings surface with *WasThereSomething* `release/1.3.1`
- **Created:** 2026-08-26
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`
- **Depends on:** spec 0005 (the hub carries the replay row)
- **Requirement prefix:** `ONB-`

## Summary

A short, skippable introduction on first start — what the app is, what it
does with your data, and the language and appearance choice — plus a way to
see it again later.

```text
    (1)  Willkommen             (2)  Was die App kann
    (3)  Deine Daten            (4)  Sprache und Erscheinungsbild
    (5)  Los geht's

    * * * * o                   [ Ueberspringen ]  [ Weiter ]
```

## Problem

The template currently routes the splash straight into the settings page,
which then acts as a first-run wizard with a "Continue" button. That has
three consequences:

1. **The first thing a new user sees is a settings form.** No explanation of
   what the app is, and no chance to say that the data stays on the device —
   the one thing that most reassures a user, and the one thing a store
   reviewer looks for.
2. **The settings page cannot become a hub** while it is also a wizard step
   (spec 0005, SET-002).
3. **There is no way to see the introduction again.** Every derived app
   eventually gets the support question "how did this work again?", and the
   answer is either a manual (spec 0005) or the intro — but only if the intro
   can be reopened.

## Goals

- A pager shown exactly once, on the first start, with skip available on
  every page.
- The language and appearance choice preserved as a step inside it, so the
  first-run capability the template has today is not lost.
- A persisted completion flag, read during startup so routing stays
  synchronous.
- A "show the intro again" row in the settings hub that opens it immediately.
- Failure to persist the flag must never trap a user inside the intro.

## Non-goals

See `out-of-scope.md`. In particular: the intro **never requests a
permission**. Permissions are requested just-in-time by the feature that
needs them (permissions contract), and an intro that asks for four
permissions up front is exactly the anti-pattern that contract exists to
prevent.

## Architecture impact

- **New feature folder** `features/onboarding/`, with the flag notifier in
  `application/` and the pager in `presentation/`.
- **New setting** `app.onboardingCompleted` in the existing register — no new
  storage mechanism, and `resetAllSettings()` covers it for free.
- **Routing:** the splash's completion handler gains one branch. The startup
  coordinator itself is unchanged; the flag is read through the key-value
  store, which `bootstrap()` has already made persistent by then (startup
  contract).
- **No new dependency.**

## Acceptance

See `acceptance-criteria.md`. Requirements are in `requirements.md`.
