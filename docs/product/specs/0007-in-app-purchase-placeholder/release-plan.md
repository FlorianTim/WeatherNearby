# Release plan: In-app purchase placeholder

Target release **3.2.1**. Slice 6 of
`docs/delivery/implementation-plans/0002-settings-and-app-shell.md`.

## Single phase

Depends on the settings hub (spec 0005, phase 2), which carries the Pro row.

Order inside the slice:

1. The two settings in the register, with their unit tests — including the
   literal table that pins every enum's stored value.
2. `PurchaseGateway`, `UnavailablePurchaseGateway`, `FakePurchaseGateway`.
3. The providers: gateway, gate catalogue, entitlement notifier,
   `featureUnlocked`, `storeAvailable`.
4. The Pro page, tested in all three store states plus both restore
   outcomes.
5. The hub row.
6. The recipe: `docs/architecture/patterns/in-app-purchase-gateway.md`.

**Done when:** the encapsulation test proves no billing package is imported
anywhere, the cache degrades correctly for every bad input, and the page
renders no price or buy action in any state.

## The path this leaves open

When a derived app does sell something, the change is bounded by design:

| Step | Files |
|---|---|
| Add the dependency | `apps/<app>/pubspec.yaml` |
| Add the adapter | one new file under `features/monetization/data/` |
| Point the provider at it | one line in `monetization_providers.dart` |
| Platform setup and store declarations | per the recipe |
| Extend the page with products and a buy flow | `pro_page.dart` |

No call site changes, because there are no call sites outside the page —
app code asks `featureUnlocked(key)` and nothing else (IAP-020).

## Not part of this release

Everything in `out-of-scope.md`, and in particular anything that requires a
configured store account. The next monetization step is a product decision,
not a template one.
