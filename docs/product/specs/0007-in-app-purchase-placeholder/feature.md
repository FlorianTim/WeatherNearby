# Feature: In-app purchase placeholder

## Metadata

- **Status:** specified
- **Target release:** 3.2.1
- **Source:** Product-owner decision 2026-08-26 — align the template's
  settings surface with *WasThereSomething* `release/1.3.1`
- **Created:** 2026-08-26
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`
- **Depends on:** spec 0005 (the hub carries the Pro row)
- **Decisions:** ADR-0015
- **Requirement prefix:** `IAP-`

## Summary

Everything a paid feature needs **except** the billing plugin: a cached
entitlement, a gateway interface with a store-less default, a gate catalogue
that fails open, and a Pro page that states the truth — all features are
currently free.

```text
Pro-Status
  +--------------------------------------------+
  | [*] Kostenlose Version                     |
  |     Alle Funktionen sind derzeit kostenlos |
  +--------------------------------------------+
  | [s] Store nicht verfuegbar                 |
  +--------------------------------------------+
  [ Kaeufe wiederherstellen ]
```

## Problem

`packages/feature_flags` already ships `Entitlement` and `FeatureGates` —
the *decision* half of monetization. Nothing supplies them. There is no
cache, no gateway, no page, and no documented way to add one.

So the first derived app that sells anything writes all of it from scratch,
usually by importing `in_app_purchase` directly into a widget. That is
exactly the coupling the library-evaluation contract forbids, and it is
unfixable later without touching every call site.

The opposite mistake is just as bad: shipping `in_app_purchase` in the
template. Then **every** derived app inherits a billing dependency, its
platform manifests, its store declarations, and its version constraints — and
KI-009 records what a single unnecessary plugin can do to an unrelated
upgrade.

## Goals

- A `PurchaseGateway` interface, with the default implementation reporting
  "no store" and a fake for tests.
- A cached entitlement in the settings register, decoded fail-safe.
- `featureUnlocked(key)` as the single question app code asks, wired to the
  existing fail-open `FeatureGates`.
- A Pro page reachable from the settings hub, honest about the current state.
- A recipe documenting exactly how to add the real billing adapter, so the
  first app that needs it changes one file and adds one dependency.

## Non-goals

Products, prices, buying, subscription management, receipt validation,
server-side verification. See `out-of-scope.md`.

## Architecture impact

- **New feature folder** `features/monetization/` — `data/` for the gateway,
  `application/` for the providers, `presentation/` for the page.
- **Two new settings** in the register (`billing.entitlement`,
  `billing.checkedAt`). No database change.
- **No new dependency** (ADR-0015). The adapter that needs one is a recipe in
  `docs/architecture/patterns/in-app-purchase-gateway.md`.
- **Gateway pattern:** follows `docs/architecture/patterns/platform-gateways.md`
  — interface in the app, plugin behind an adapter, fake in tests, one file
  to change on a swap.

## Acceptance

See `acceptance-criteria.md`. Requirements are in `requirements.md`.
