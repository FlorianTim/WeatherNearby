# Acceptance criteria: In-app purchase placeholder

## Gateway

- [ ] `UnavailablePurchaseGateway.isStoreAvailable()` returns `false` and does
      not throw. (IAP-003)
- [ ] `UnavailablePurchaseGateway.restorePurchases()` returns
      `Entitlement.free`. (IAP-003)
- [ ] `FakePurchaseGateway` can be configured to report an available store, a
      restored Pro entitlement, and a throwing call. (IAP-004)
- [ ] With a throwing gateway, the store-availability provider yields
      "unavailable" and no error escapes. (IAP-006)
- [ ] A workspace-wide test asserts that no source file imports a billing
      package. (IAP-001)

## Entitlement cache

- [ ] A stored `pro-lifetime` decodes to that entitlement, and the
      pre-3.2.2 `pro_lifetime` still does too. (IAP-010)
- [ ] Stored `""`, `"nonsense"` and a missing key all decode to `free`.
      (IAP-011)
- [ ] The encoded form of every enum value is its stable string, asserted
      against a literal table so a reordering is caught. (IAP-012)
- [ ] `billing.checkedAt` is `null` until a verification is written.
      (IAP-013)
- [ ] Writing a verified entitlement writes both keys in one call, and the
      timestamp round-trips as UTC. (IAP-014)

## Gating

- [ ] `featureUnlocked('anything')` is `true` with the shipped empty
      catalogue. (IAP-021, IAP-022)
- [ ] With a catalogue that gates `demo.feature` behind Pro, a free
      entitlement locks it and a Pro entitlement unlocks it. (IAP-020)
- [ ] An unknown key stays unlocked even with a non-empty catalogue.
      (IAP-021)

## Pro page

- [ ] With a free entitlement the status row reads as the free version.
      (IAP-030)
- [ ] The "all features are currently free" note is present. (IAP-031)
- [ ] While store availability is loading, the row shows the pending state;
      after it resolves, it shows available or unavailable accordingly.
      (IAP-032)
- [ ] No price, product list or buy button is rendered in any state.
      (IAP-033)
- [ ] Restore with an unavailable store reports the outcome and leaves the
      cached entitlement at `free`. (IAP-034)
- [ ] Restore with a fake that returns Pro updates the status row and the
      cache. (IAP-034)
- [ ] The settings hub row opens the page. (IAP-035)

## Documentation

- [ ] The recipe exists, names the dependency, and its adapter code compiles
      against the shipped interface. (IAP-040)
- [ ] The recipe states that adding it changes exactly one provider override.
      (IAP-041)
