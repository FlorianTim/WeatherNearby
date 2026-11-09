# Story: In-app purchase placeholder

## Metadata

- **Status:** ready
- **Feature:** `docs/product/specs/0007-in-app-purchase-placeholder/`
- **Plan:** `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`, slice 6
- **Target release:** 3.2.1 (`now`)
- **Depends on:** story 002
- **Decisions:** ADR-0015

## Goal

Everything a paid feature needs except the billing plugin.

## Scope

- `billing.entitlement` and `billing.checkedAt` in the register.
- `features/monetization/data/purchase_gateway.dart` — interface,
  `UnavailablePurchaseGateway`, `FakePurchaseGateway`.
- `features/monetization/application/monetization_providers.dart` — gateway,
  gate catalogue, entitlement notifier, `featureUnlocked`, `storeAvailable`.
- `features/monetization/presentation/pro_page.dart` and route `/pro`.
- The hub row.
- `docs/architecture/patterns/in-app-purchase-gateway.md` — the recipe.

## Out of scope

- The `in_app_purchase` dependency (ADR-0015).
- Products, prices, a buy flow, subscriptions, receipts, a paywall.
- Gating any actual feature — the shipped catalogue stays empty.

## Relevant files

- `packages/feature_flags/lib/feature_flags.dart`
- `apps/mobile_app/lib/core/settings/app_settings.dart`
- `docs/architecture/patterns/platform-gateways.md`

## Acceptance criteria

- [ ] The default gateway reports no store and `Entitlement.free`, and throws
      on no platform including web.
- [ ] The fake can report an available store, a restored Pro entitlement, and
      a throwing call.
- [ ] A throwing gateway degrades to "unavailable" with no error escaping.
- [ ] Stored `pro-lifetime` decodes to that entitlement; `""`, nonsense and a
      missing key all decode to `free`.
- [ ] The pre-3.2.2 forms `pro_lifetime` and `pro_subscription` still decode,
      so a stored entitlement is never silently downgraded.
- [ ] The stored form of every enum value is asserted against a literal
      table.
- [ ] `checkedAt` is `null` until a verification is written, then round-trips
      as UTC.
- [ ] `featureUnlocked` is `true` for any key with the shipped catalogue, and
      an unknown key stays unlocked with a non-empty one.
- [ ] The Pro page shows the entitlement in words, the "currently free" note,
      and three distinct store states.
- [ ] No price, product list or buy button in any state.
- [ ] Restore reports its outcome and only changes the cache when something
      was actually restored.
- [ ] A test asserts that no source file in the workspace imports a billing
      package.

## Test requirements

- `test/features/monetization/monetization_providers_test.dart`
- `test/features/monetization/pro_page_test.dart`
- `test/core/settings/app_settings_test.dart` — the two new keys
- `flutter test`, `melos run analyze`

## Documentation requirements

- ADR-0015.
- The recipe, with adapter code that compiles against the shipped interface.
- ARB entries in both files.

## Implementation notes

Reuse `expectPackageEncapsulated(...)` from `test/support/` for the
"no billing import" assertion — the guardrail already exists.

`isStoreAvailable()` is only ever called from the Pro page's provider, never
during startup (IAP-005). Keep it that way: a platform call in the startup
path is how a splash screen starts hanging on a device with no Play services.

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present
- [ ] No unauthorized scope expansion
- [ ] Existing structure preserved
